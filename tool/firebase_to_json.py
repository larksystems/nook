# Temporary tool that reads from Firebase and writes a JSON file
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger
from firebase_root_keys import root_keys
import time

import json
import sys

log = Logger(__name__)

firebase_client = None

def init(CRYPTO_TOKEN_PATH):
    global firebase_client
    log.info("Setting up Firebase client")    
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Done")

def list_for_collection_twophase_strategy(col):
    log.info (f"processing: {col._path}")

    lst = []
    for doc in col.stream():
        log.info (f"processing: {doc.id}")
        dt = doc.to_dict()
        dt["__id"] = doc.id
        dt["__reference_path"] = doc.reference.path
        lst.append(dt)

    log.info("load phase 1 done")

    i = 0
    for dt in lst:
        doc_ref = firebase_client.document(dt["__reference_path"])
        doc_ref_cols = doc_ref.collections()
        dt["__subcollections"] = []
        for col in doc_ref_cols:
            dt[col.id] = list_for_collection_twophase_strategy(col)
            dt["__subcollections"].append(col.id)
        log.info(f"doc {i}/{len(lst)} done")
        i += 1

    log.info("load phase 2 done")
    return lst


def import_data_for_firestore_col_root(collection_root):

    log.info (f"import_data_for_firestore_col_root collection_root: {collection_root}")

    col = firebase_client.collection(collection_root)
    
    time_start = time.perf_counter_ns()
    lst = list_for_collection_twophase_strategy(col)
    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"import_data_for_firestore_col_root collection_root: {len(lst)} in {ms_elapsed} ms")

    return lst


if (len(sys.argv) != 3):
    print ("Usage python firebase_to_json.py crypto_token output_path")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
OUTPUT_PATH = sys.argv[2]
init(CRYPTO_TOKEN_PATH)

data = {}

for key in root_keys:
    data[key] = import_data_for_firestore_col_root(key)

log.info(f"Writing to {OUTPUT_PATH}")
json.dump(data, open(OUTPUT_PATH, 'w'), indent=2)
log.info(f"Export done")

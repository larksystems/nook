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

def delete_collection_twophase_strategy(col):
    log.info (f"processing: {col._path}")

    batch = firebase_client.batch()

    lst_of_doc_refs = []
    for doc in col.stream():
        log.info (f"processing: {doc.id}")
        lst_of_doc_refs.append(doc.reference)
    log.info("load phase 1 done")

    i = 0
    batch_count = 0
    for doc_ref in lst_of_doc_refs:
        doc_ref_cols = doc_ref.collections()
        for col in doc_ref_cols:
            delete_collection_twophase_strategy(col)
        batch.delete(doc_ref)
        if batch_count > 450:
            log.info(f"Batch about to commit size: {batch_count}")
            batch.commit()
            batch_count = 0
            log.info(f"Batch committed")


        log.info(f"doc {i}/{len(lst_of_doc_refs)} done")
        i += 1
    
    batch.commit()
    log.info("clear phase 2 done")
    return lst_of_doc_refs



def delete_data_for_firestore_col_root(collection_root):

    log.info (f"delete_data_for_firestore_col_root collection_root: {collection_root}")

    col = firebase_client.collection(collection_root)
    
    time_start = time.perf_counter_ns()
    lst = delete_collection_twophase_strategy(col)
    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"delete_data_for_firestore_col_root collection_root: {len(lst)} in {ms_elapsed} ms")

    return lst


if (len(sys.argv) != 2):
    print ("Usage python clear_firebase.py crypto_token")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
init(CRYPTO_TOKEN_PATH)

data = {}

for key in root_keys:
    delete_data_for_firestore_col_root(key)

log.info(f"Clear done")

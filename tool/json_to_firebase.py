# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger
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

def push_collection_to_firestore(collection_root, documents):
    log.info (f"push_collection_to_firestore {collection_root}")
    col = firebase_client.collection(collection_root)
    time_start = time.perf_counter_ns()
    for document_dict in documents:
        push_document_to_firestore(collection_root, document_dict)
    time_end = time.perf_counter_ns()
    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"push_collection_to_firestore {collection_root} in {ms_elapsed} ms")

def push_document_to_firestore(collection_root, data):
    ref_path = data["__reference_path"]
    doc_id = data["__id"]
    sub_collections = data["__subcollections"]

    log.info (f"push_document_to_firestore {ref_path}")

    del data["__reference_path"]
    del data["__id"]
    del data["__subcollections"]

    firebase_client.document(ref_path).set(data)


if (len(sys.argv) != 3):
    print ("Usage python json_to_firebase.py crypto_token input_path")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
INPUT_PATH = sys.argv[2]
init(CRYPTO_TOKEN_PATH)

with open(INPUT_PATH, 'r') as f:
    data_dict = json.load(f)

for collection_root in data_dict.keys():
    documents = data_dict[collection_root]
    push_collection_to_firestore(collection_root, documents)

log.info(f"Import done")

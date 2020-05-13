import time

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from katikati_pylib.logging import logging

log = None
firebase_client = None

def init_firebase_client(CRYPTO_TOKEN_PATH):
    global log
    if log is None:
        log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Done")
    return firebase_client

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
    if "__id" in data:
        ref_path = data["__reference_path"]
        doc_id = data["__id"]
        sub_collections = data["__subcollections"]

        log.info (f"push_document_to_firestore {ref_path}")

        del data["__reference_path"]
        del data["__id"]
        del data["__subcollections"]

        field_data = {}
        for field in data:
            if field in sub_collections:
                # it's not actually a field, it's a collection, process these later
                continue
            field_data[field] = data[field]
        firebase_client.document(ref_path).set(field_data)

        for sub_collection in sub_collections:
            push_collection_to_firestore(f"{ref_path}/{sub_collection}", data[sub_collection])
    else:
        _push_document_fields_to_firestore(collection_root, data)

def _push_document_fields_to_firestore(collection_root, data):
    doc_id = list(data.keys())[0]
    doc_fields = data[doc_id]
    ref_path = f"{collection_root}/{doc_id}"
    firebase_client.document(ref_path).set(doc_fields)

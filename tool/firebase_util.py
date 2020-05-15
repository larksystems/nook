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
    global firebase_client
    if firebase_client is None:
        firebase_client = firestore.client()
    log.info("Done")
    return firebase_client

def push_collection_to_firestore(collection_root, documents):
    log.info (f"push_collection_to_firestore {collection_root}")
    col = firebase_client.collection(collection_root)
    time_start = time.perf_counter_ns()
    for document_dict in documents:
        firestore_format_document_dict = _convert_to_firestore_format(collection_root, document_dict)
        push_document_to_firestore(collection_root, firestore_format_document_dict)
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

    field_data = {}
    for field in data:
        if field in sub_collections:
            # it's not actually a field, it's a collection, process these later
            continue
        field_data[field] = data[field]
    firebase_client.document(ref_path).set(field_data)

    for sub_collection in sub_collections:
        push_collection_to_firestore(f"{ref_path}/{sub_collection}", data[sub_collection])

def convert_documents_to_firestore_format(collection_root, documents):
    firestore_documents = []
    for doc in documents:
        firestore_doc = {}
        doc_id = list(doc.keys())[0]
        firestore_doc["__id"] = doc_id
        firestore_doc["__reference_path"] = f"{collection_root}/{doc_id}"
        firestore_doc["__subcollections"] = []
        firestore_doc.update(doc[doc_id])
        firestore_documents.append(firestore_doc)
    return firestore_documents

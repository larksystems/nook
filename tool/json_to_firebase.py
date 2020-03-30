# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from katikati_pylib.logging import logging
import tool_utils
import time
import argparse
import json
import sys

log = None

firebase_client = None

def init(CRYPTO_TOKEN_PATH):
    global firebase_client
    global log
    log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)
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


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("crypto_token_file",
                        help="path to Firebase crypto token file")
    parser.add_argument("input_path",
                        help="path to the input backup file.")  

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) != 3:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    CRYPTO_TOKEN_PATH = args.crypto_token_file
    INPUT_PATH = args.input_path

    init(CRYPTO_TOKEN_PATH)


    with open(INPUT_PATH, 'r') as f:
        data_dict = json.load(f)

    collection_keys = list(data_dict.keys())

    short_id = tool_utils.short_id()
    log.audit(f"json_to_firebase: JobID ({short_id}), keys to download {json.dumps(collection_keys)}")

    for collection_root in collection_keys:
        documents = data_dict[collection_root]
        push_collection_to_firestore(collection_root, documents)

    log.info(f"Import done")
    log.notify(f"json_to_firebase completed: JobID {short_id}")

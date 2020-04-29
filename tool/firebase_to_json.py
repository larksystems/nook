# Temporary tool that reads from Firebase and writes a JSON file
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import time
import argparse
import json
import sys

import firebase_util
from firebase_util import firebase_client
from katikati_pylib.logging import logging
from firebase_root_keys import root_keys
import tool_utils

log = None

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


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("crypto_token_file",
                        help="path to Firebase crypto token file")
    parser.add_argument("output_path",
                        help="path to the output backup file."
                             "if the file already exists, this process will overwrite it.")
    parser.add_argument("root_collections", nargs="*",
                        help="a list of root collection keys to export, "
                             "if not key is passed, it will use a hardcoded list of root keys")

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) < 3:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    CRYPTO_TOKEN_PATH = args.crypto_token_file
    OUTPUT_PATH = args.output_path

    root_keys_to_export = root_keys
    if len(args.root_collections) > 0:
        root_keys_to_export = list(args.root_collections)
    
    log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)

    firebase_util.init(CRYPTO_TOKEN_PATH, log)

    data = {}

    short_id = tool_utils.short_id()
    log.audit(f"firebase_to_json: JobID ({short_id}), keys to download {json.dumps(root_keys_to_export)}")
    for key in root_keys_to_export:
        data[key] = import_data_for_firestore_col_root(key)

    log.info(f"Writing to {OUTPUT_PATH}")
    json.dump(data, open(OUTPUT_PATH, 'w'), indent=2)
    log.info(f"Export done")
    log.notify(f"firebase_to_json completed: JobID {short_id}")

# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import time
import argparse
import json
import sys

from firebase_util import init_firebase_client, push_collection_to_firestore
from katikati_pylib.logging import logging
import tool_utils

log = None
firebase_client = None


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

    log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)

    firebase_client = init_firebase_client(CRYPTO_TOKEN_PATH)


    with open(INPUT_PATH, 'r') as f:
        data_dict = json.load(f)

    collection_keys = list(data_dict.keys())

    short_id = tool_utils.short_id()
    log.audit(f"json_to_firebase: JobID ({short_id}), keys to download {json.dumps(collection_keys)}")

    for collection_root in collection_keys:
        documents = data_dict[collection_root]
        push_collection_to_firestore(collection_root, documents, firebase_client, CRYPTO_TOKEN_PATH)

    log.info(f"Import done")
    log.notify(f"json_to_firebase completed: JobID {short_id}")

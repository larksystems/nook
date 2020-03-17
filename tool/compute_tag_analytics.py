# Temporary tool that reads from Firebase and writes a JSON file
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger
from firebase_root_keys import root_keys
from datetime import datetime
import time
import argparse
import json
import sys

log = Logger(__name__)

nook_firebase_client = None
metrics_firebase_client = None

CONVERSATIONS_COLLECTION_KEY = 'nook_conversations'
CONVERSATION_TAGS_COLLECTION_KEY = 'conversationTags'
METRICS_COLLECTION_KEY = 'metrics'

NEEDS_REPLY = 'Needs Reply'
ESCALATE = 'escalate'
ANSWER = 'answer'
ATTITUDE = 'attitude'
BEHAVIOUR = 'behaviour'
GRATITUDE = 'gratitude'
KNOWLEDGE = 'knowledge'
QUESTION = 'question'

tags_of_interest = [NEEDS_REPLY, ESCALATE, ANSWER, ATTITUDE, BEHAVIOUR, GRATITUDE, KNOWLEDGE, QUESTION]

def init(CRYPTO_TOKEN_PATH, app_name=None):
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_app = None
    if app_name == None:
        firebase_app = firebase_admin.initialize_app(firebase_cred)
    else:
        firebase_app = firebase_admin.initialize_app(firebase_cred, name=app_name)
    firebase_client = firestore.client(app=firebase_app)
    log.info("Done")
    return firebase_client

def list_for_collection_twophase_strategy(firebase_client, col):
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
            dt[col.id] = list_for_collection_twophase_strategy(firebase_client, col)
            dt["__subcollections"].append(col.id)
        log.info(f"doc {i}/{len(lst)} done")
        i += 1

    log.info("load phase 2 done")
    return lst


def import_data_for_firestore_col_root(firebase_client, collection_root):
    log.info (f"import_data_for_firestore_col_root collection_root: {collection_root}")

    col = firebase_client.collection(collection_root)

    time_start = time.perf_counter_ns()
    lst = list_for_collection_twophase_strategy(firebase_client, col)
    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"import_data_for_firestore_col_root collection_root: {len(lst)} in {ms_elapsed} ms")

    return lst


def push_collection_to_firestore(firebase_client, collection_root, documents):
    log.info (f"push_collection_to_firestore {collection_root}")
    col = firebase_client.collection(collection_root)
    time_start = time.perf_counter_ns()
    for document_dict in documents:
        push_document_to_firestore(firebase_client, collection_root, document_dict)
    time_end = time.perf_counter_ns()
    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"push_collection_to_firestore {collection_root} in {ms_elapsed} ms")


def push_document_to_firestore(firebase_client, collection_root, data):
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
    parser.add_argument("nook_crypto_token_file",
                        help="path to Firebase crypto token file to read Nook data")
    parser.add_argument("metrics_crypto_token_file",
                        help="path to Firebase crypto token file to write metrics data")

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) != 3:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    NOOK_CRYPTO_TOKEN_PATH = args.nook_crypto_token_file
    METRICS_CRYPTO_TOKEN_PATH = args.metrics_crypto_token_file

    nook_firebase_client = init(NOOK_CRYPTO_TOKEN_PATH)
    metrics_firebase_client = init(METRICS_CRYPTO_TOKEN_PATH, "metrics")

    conversation_tags = import_data_for_firestore_col_root(nook_firebase_client, CONVERSATION_TAGS_COLLECTION_KEY)
    nook_conversations = import_data_for_firestore_col_root(nook_firebase_client, CONVERSATIONS_COLLECTION_KEY)

    tag_name_to_id = {}
    for tag in conversation_tags:
        if tag["text"] in tags_of_interest:
            tag_name_to_id[tag["text"]] = tag["__id"]

    metrics = {}
    for tag in tags_of_interest:
        metrics[tag] = {
            "count": 0,
            "dates": []
        }

    time_start = time.perf_counter_ns()
    for conversation in nook_conversations:
        tags = conversation["tags"]
        if tag_name_to_id[NEEDS_REPLY] not in tags:
            continue

        for tag in tags_of_interest:
            if tag_name_to_id[tag] not in tags:
                continue

            metrics[tag]["count"] = metrics[tag]["count"] + 1
            tagged_message_in = None
            last_message_in = None
            for message in conversation["messages"]:
                if message["direction"] == "MessageDirection.out":
                    continue
                last_message_in = message
                if tag_name_to_id[tag] in message["tags"]:
                    tagged_message_in = message
            if tagged_message_in is not None:
                metrics[tag]["dates"].append(tagged_message_in["datetime"])
                continue
            if last_message_in is not None:
                metrics[tag]["dates"].append(last_message_in["datetime"])
                continue
            log.warning(f"Encountered a conversation with no incoming messages, skipping")

    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"computing metrics on: {len(nook_conversations)} conversations in {ms_elapsed} ms")

    now = datetime.utcnow().isoformat(timespec='minutes')
    metrics_id = f"metrics-{now}"

    metrics_collection = {
        "__id": metrics_id,
        "__subcollections": [],
        "__reference_path": f"{METRICS_COLLECTION_KEY}/{metrics_id}",
        "metrics": metrics
    }

    push_collection_to_firestore(metrics_firebase_client, METRICS_COLLECTION_KEY, [metrics_collection])
    log.info("Done")

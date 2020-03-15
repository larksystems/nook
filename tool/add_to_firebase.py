# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import argparse
from core_data_modules.logging import Logger
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import hashlib
import json
import time
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
    log.info(f"push_collection_to_firestore {collection_root}")
    col = firebase_client.collection(collection_root)
    time_start = time.perf_counter_ns()
    for document_dict in documents:
        push_document_to_firestore(collection_root, document_dict)
    time_end = time.perf_counter_ns()
    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info(f"push_collection_to_firestore {collection_root} in {ms_elapsed} ms")

def push_document_to_firestore(collection_root, data):
    doc_id = list(data.keys())[0]
    doc_fields = data[doc_id]
    ref_path = f"{collection_root}/{doc_id}"
    firebase_client.document(ref_path).set(doc_fields)

def text_to_doc_id(prefix, text):
    return f"{prefix}-" + hashlib.sha256(text.encode("utf-8")).hexdigest()[0:8]

seq_no = 0

def text_to_doc_id_maintain_order(prefix, text):
    global seq_no
    seq_no = seq_no + 1
    return f"{prefix}-{seq_no}-" + hashlib.sha256(text.encode("utf-8")).hexdigest()[0:8]

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("crypto_token_file",
                        help="path to Firebase crypto token file")
    parser.add_argument("content_type",
                        help="name of the content type. Supported types: suggested_replies | message_tags | conversation_tags")
    parser.add_argument("input_path",
                        help="path to the input backup file.")
    parser.add_argument("--maintain_order", default=False, action='store_true',
                        help="maintain the order of the items when generating firebase doc ids")

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) < 4:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    CRYPTO_TOKEN_PATH = args.crypto_token_file
    CONTENT_TYPE = args.content_type
    INPUT_PATH = args.input_path
    MAINTAIN_ORDER = args.maintain_order

    init(CRYPTO_TOKEN_PATH)

    valid_content_type = ["suggested_replies", "message_tags", "conversation_tags"]
    if CONTENT_TYPE not in valid_content_type:
        log.error("Content type '{}' not known, expected one of {}".format(CONTENT_TYPE, valid_content_type))
        exit(1)

    with open(INPUT_PATH, 'r') as f:
        data_dict = json.load(f)

    if CONTENT_TYPE == "suggested_replies":
        # Make sure that the fields that the Firestore model expects exist
        # TODO(mariana): Move to using a validator
        assert len(data_dict.keys()) == 1
        suggested_replies_collection = "suggestedReplies"
        suggested_replies = data_dict[suggested_replies_collection]
        suggested_replies_documents = []
        assert isinstance(suggested_replies, list)
        for reply_data in suggested_replies:
            assert isinstance(reply_data, dict)
            reply_fields = {}
            assert "text" in reply_data.keys()
            reply_fields["text"] = reply_data["text"]
            reply_id = text_to_doc_id_maintain_order("reply", reply_fields["text"]) if MAINTAIN_ORDER else text_to_doc_id("reply", reply_fields["text"])
            assert "translation" in reply_data.keys()
            reply_fields["translation"] = reply_data["translation"]
            reply_fields["shortcut"] = reply_data["shortcut"] if "shortcut" in reply_data.keys() else ""

            suggested_replies_documents.append({reply_id : reply_fields})

        push_collection_to_firestore(suggested_replies_collection, suggested_replies_documents)
        log.info(f"Uploaded {len(suggested_replies_documents)} suggested replies")

    elif CONTENT_TYPE == "conversation_tags" or CONTENT_TYPE == "message_tags":
        content_type = CONTENT_TYPE.replace("_tags", "")
        # Make sure that the fields that the Firestore model expects exist
        # TODO(mariana): Move to using a validator
        assert len(data_dict.keys()) == 1
        tags_collection = f"{content_type}Tags"
        tags = data_dict[tags_collection]
        tags_documents = []
        assert isinstance(tags, list)
        for tag_data in tags:
            assert isinstance(tag_data, dict)
            tag_fields = {}
            assert "text" in tag_data.keys()
            tag_fields["text"] = tag_data["text"]
            tag_id = text_to_doc_id_maintain_order("tag", tag_fields["text"]) if MAINTAIN_ORDER else text_to_doc_id("tag", tag_fields["text"])
            assert "shortcut" in tag_data.keys()
            tag_fields["shortcut"] = tag_data["shortcut"]
            assert "type" in tag_data.keys()
            assert tag_data["type"] == "normal" or tag_data["type"] == "important"
            tag_fields["type"] = f'TagType.{tag_data["type"]}'

            tags_documents.append({tag_id : tag_fields})

        push_collection_to_firestore(tags_collection, tags_documents)
        log.info(f"Uploaded {len(tags_documents)} {content_type} tags")

    else:
        log.error("Content type '{}' not known, expected one of {}".format(CONTENT_TYPE, valid_content_type))
        exit(1)

    log.info("Done")

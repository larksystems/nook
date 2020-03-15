# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import hashlib
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

if (len(sys.argv) != 4):
    print ("Usage python add_to_firebase.py crypto_token suggested_replies|message_tags|conversation_tags input_path")
    print ("Adds data items that don't currently exist, and overwrittes items that already exist.")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
CONTENT_TYPE = sys.argv[2]
INPUT_PATH = sys.argv[3]
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
        reply_id = text_to_doc_id("reply", reply_fields["text"])
        assert "translation" in reply_data.keys()
        reply_fields["translation"] = reply_data["translation"]
        reply_fields["shortcut"] = reply_data["shortcut"] if "shortcut" in reply_data.keys() else ""
        if "seq_no" in reply_data.keys():
            reply_fields["seq_no"] = reply_data["seq_no"]

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
        tag_id = text_to_doc_id("tag", tag_fields["text"])
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

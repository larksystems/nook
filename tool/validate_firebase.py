# Validation tool for firebase collections
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger
import time

import json
import sys
import os.path

import validate_nook_model as model
import validate_nook_model_custom as custom

log = Logger(__name__)

firebase_client = None

def init(crypto_token_path):
    global firebase_client
    log.info("Setting up Firebase client")    
    firebase_cred = credentials.Certificate(crypto_token_path)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Done")

def validate_documents(collection_root, validationMethod):
    log.info (f"validate_documents {collection_root}")
    
    time_start = time.perf_counter_ns()
    
    doc_count = 0
    for doc in firebase_client.collection(collection_root).stream():
        log.info(f"validating '{doc.id}'")
        data = doc.to_dict()
        try:
            validationMethod("doc", doc.id, data)
        except model.ValidationError as e:
            print(f"")
            print(f"Validation failed:")
            print(f"  {collection_root}")
            print(f"  {doc.id}")
            print(f"  {e.message}")
            print(f"")
            raise
        doc_count += 1

    time_end = time.perf_counter_ns()
    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"validated {doc_count} ids in {ms_elapsed} ms")

def usage():
    print ("Usage python validate_firebase.py crypto_token")

if len(sys.argv) != 2:
    usage()
    exit(1)

crypto_token_path = sys.argv[1]
if not os.path.isfile(crypto_token_path):
    print(f"Expected crypto token file {crypto_token_path}")
    usage()
    exit(1)

init(crypto_token_path)
validate_documents("suggestedReplies",   model.validate_SuggestedReply_doc)
validate_documents("conversationTags",   custom.validate_ConversationTag)
validate_documents("messageTags",        custom.validate_MessageTag)
validate_documents("nook_conversations", custom.validate_Conversation)

log.info(f"Validation complete")

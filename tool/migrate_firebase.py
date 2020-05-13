# Migration tool for firebase collections
# Relies on an undocumented .collections() API call and a hard coded list of top level collections

import time
import json
import sys
import os.path

from firebase_admin import firestore
import migrate_nook_model
import firebase_util
from core_data_modules.logging import Logger

log = Logger(__name__)
firebase_client = None

def read_document_ids(collection_root):
    log.info (f"read_document_ids {collection_root}")
    cache_file_path = f"{cache_dir}/{collection_root}_doc_ids.json"
    doc_ids = []

    if reset_flag and os.path.exists(cache_file_path):
        os.remove(cache_file_path)

    if os.path.isfile(cache_file_path):
        log.info (f"reloading cached ids from {cache_file_path}")
        with open(cache_file_path, "r") as f:
            doc_ids = json.load(f)
    else:
        time_start = time.perf_counter_ns()

        for doc in firebase_client.collection(collection_root).stream():
            doc_ids.append(doc.id)

        time_end = time.perf_counter_ns()
        ms_elapsed = (time_end - time_start) / (1000 * 1000)
        log.info (f"read {len(doc_ids)} ids in {ms_elapsed} ms")

        log.info (f"caching ids in {cache_file_path}")
        with open(cache_file_path, "w") as f:
            json.dump(doc_ids, f, indent=2)

    return doc_ids

def migrate_collection(collection_root, migrationMethod):
    global doc_count
    global skip_count
    global migration_count

    doc_ids = read_document_ids(collection_root)
    migrated_file_path = f"{cache_dir}/{collection_root}_migrated.txt"
    if not replay_flag and not reset_flag and os.path.isfile(migrated_file_path):
        with open(migrated_file_path, "r") as f:
            count = int(f.readline().strip())
        log.info(f"already migrated {count} documents in {collection_root}")
        skip_count += count
        doc_count += count
        if (count >= len(doc_ids)):
            return
        doc_ids = doc_ids[count:]
    else:
        count = 0

    @firestore.transactional
    def update_in_transaction(transaction, doc_ref, migrationMethod):
        snapshot = doc_ref.get(transaction=transaction)
        data = snapshot.to_dict()
        if migrationMethod(data):
            transaction.set(doc_ref, data)
            return True
        return False

    with open(migrated_file_path, "w") as f:
        for id in doc_ids:
            log.info(f"migrating '{id}'")
            transaction = firebase_client.transaction()
            doc_ref = firebase_client.collection(collection_root).document(id)
            if update_in_transaction(transaction, doc_ref, migrationMethod):
                migration_count += 1
            doc_count += 1
            count += 1
            f.seek(0)
            f.write(str(count))
            f.flush()

def usage():
    print ("Usage python migrate_firebase.py crypto_token cache_dir [ --reset | --replay ]")
    print ("  use --replay to restart migration with existing cached document ids")
    print ("  use --reset to discard all cached document ids")

if len(sys.argv) < 3:
    usage()
    exit(1)

crypto_token_path = sys.argv[1]
if not os.path.isfile(crypto_token_path):
    print(f"Expected crypto token file {crypto_token_path}")
    usage()
    exit(1)

cache_dir = sys.argv[2]
if not os.path.isdir(cache_dir):
    print(f"Expected cache directory {cache_dir}")
    usage()
    exit(1)

reset_flag = False
replay_flag = False
if len(sys.argv) == 4:
    reset_flag = sys.argv[3] == '--reset'
    replay_flag = sys.argv[3] == '--replay'
    if (not reset_flag and not replay_flag):
        print(f"Unknown flag: {sys.argv[3]}")
        usage()
        exit(1)

if len(sys.argv) > 4:
    print(f"Unexpected argument {sys.argv[4]}")
    usage()
    exit(1)

doc_count = 0
skip_count = 0
migration_count = 0
firebase_client = firebase_util.init_firebase_client(crypto_token_path)
# migrate_collection("suggestedReplies",   migrate_nook_model.migrate_SuggestedReply)
migrate_collection("nook_conversations", migrate_nook_model.migrate_Conversation)
migrate_collection("conversationTags",   migrate_nook_model.migrate_Tag)
migrate_collection("messageTags",        migrate_nook_model.migrate_Tag)

log.info(f"Migration complete")
log.info(f"  {migration_count} documents migrated")
log.info(f"  {skip_count} documents already migrated")
log.info(f"  {doc_count - skip_count - migration_count} documents unchanged")
if migrate_nook_model.warning_count == 0:
    log.info(f"  no warnings")
else:
    log.info(f"")
    log.info(f"  {migrate_nook_model.warning_count} WARNINGS")
    log.info(f"")

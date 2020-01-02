# Reads a JSON file containing exported firebase data,
# migrates that data to it's new format,
# then writes that data back to a JSON file.

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger
import time

import json
import os.path
import sys

import migrate_nook_model

log = Logger(__name__)

firebase_client = None

def migrate_collection(doc_collection, migrationMethod):
    global doc_count
    global migration_count

    for doc_data in doc_collection:
        log.info(f"Migrating {doc_data['__id']}")
        if (migrationMethod(doc_data)):
            migration_count += 1
        doc_count += 1

if (len(sys.argv) != 2):
    print ("Usage python migrate_json.py input_path")
    exit(1)

input_path = sys.argv[1]
splitext = os.path.splitext(input_path)
output_path = f"{splitext[0]}.migrated{splitext[1]}"

log.info(f"Reading {input_path}")
with open(input_path, 'r') as f:
    data = json.load(f)

doc_count = 0
migration_count = 0
migrate_collection(data["nook_conversations"], migrate_nook_model.migrate_Conversation)
migrate_collection(data["conversationTags"],   migrate_nook_model.migrate_Tag)
migrate_collection(data["messageTags"],        migrate_nook_model.migrate_Tag)
log.info(f"Migrated {migration_count} of {doc_count} documents")

log.info(f"Writing {output_path}")
with open(output_path, 'w') as f:
    json.dump(data, f, indent=2)

log.info(f"Migration complete")

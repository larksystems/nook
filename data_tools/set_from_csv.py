import firebase_client_wrapper as fcw
import uuid

import json
import sys
import csv

if (len(sys.argv) != 4):
    print ("Usage python set_from_csv.py crypto_token data_type path_to_csv_file")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATA_TYPE = sys.argv[2]
PATH_TO_CSV = sys.argv[3]

SUPPORTED_DATA_TYPES = ['message_tags', 'conversation_tags', 'suggested_replies']
if DATA_TYPE not in SUPPORTED_DATA_TYPES:
    print (f"data_type must be one of {SUPPORTED_DATA_TYPES}")
    exit(1)

data = []

with open(PATH_TO_CSV) as csvfile:
    reader = csv.reader(csvfile, dialect='excel')
    for row in reader:
        data.append(row)

for row in data:
    if DATA_TYPE == "message_tags":
        fcw.set_message_tag(row[0], row[1], row[2], row[3]) # id, text, type, shortcut
    if DATA_TYPE == "conversation_tags":
        fcw.set_conversation_tag(row[0], row[1], row[2], row[3])
    if DATA_TYPE == "suggested_replies":
        fcw.set_suggested_reply(row[0], row[1], row[2], row[3])

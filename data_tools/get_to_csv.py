import firebase_client_wrapper as fcw
import uuid

import json
import sys
import csv

if (len(sys.argv) != 4):
    print ("Usage python get_to_csv.py crypto_token data_type path_to_csv_file")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

DATA_TYPE = sys.argv[2]
PATH_TO_CSV = sys.argv[3]

SUPPORTED_DATA_TYPES = ['message_tags', 'conversation_tags', 'suggested_replies']
if DATA_TYPE not in SUPPORTED_DATA_TYPES:
    print (f"data_type must be one of {SUPPORTED_DATA_TYPES}")
    exit(1)

print(DATA_TYPE)

if DATA_TYPE == "message_tags":
    data = []
    for data_dict in fcw.get_message_tags():
        row = [data_dict['id'], data_dict['text'], data_dict['type'], data_dict['shortcut']]
        data.append(row)
if DATA_TYPE == "conversation_tags":
    data = []
    for data_dict in fcw.get_conversation_tags():
        row = [data_dict['id'], data_dict['text'], data_dict['type'], data_dict['shortcut']]
        data.append(row)
if DATA_TYPE == "suggested_replies":
    data = []
    for data_dict in fcw.get_suggested_replies():
        row = [data_dict['id'], data_dict['text'], data_dict['translation'], data_dict['shortcut']]
        data.append(row)

with open(PATH_TO_CSV, 'w') as csvfile:
    writer = csv.writer(csvfile)
    for row in data:
        writer.writerow(row)
    
    print (f"exported {len(data)} rows")

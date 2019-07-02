import firebase_client_wrapper as fcw
import uuid

import json
import sys

if (len(sys.argv) != 5):
    print ("Usage python add_conv_tag.py crypto_token text shortcut type")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

TEXT = sys.argv[2]
SHORTCUT = sys.argv[3]
TYPE = sys.argv[4]

if TYPE not in  ["normal", "important"]:
    print ("Only normal and import tag types are currently supported")
    exit(1)

new_tag_id = "tag-" + str(uuid.uuid4()).split('-')[0]
fcw.set_msg_tag(new_tag_id, TEXT, TYPE, SHORTCUT)

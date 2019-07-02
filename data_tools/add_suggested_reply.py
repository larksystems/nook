import firebase_client_wrapper as fcw
import uuid

import json
import sys

if (len(sys.argv) != 5):
    print ("Usage python add_suggested_reply.py crypto_token text translation shortcut")
    exit(1)

CRYPTO_TOKEN_PATH = sys.argv[1]
fcw.init_client(CRYPTO_TOKEN_PATH)

TEXT = sys.argv[2]
TRANSLATION = sys.argv[3]
SHORTCUT = sys.argv[4]

new_reply_id = "reply-" + str(uuid.uuid4()).split('-')[0]
fcw.set_suggested_reply(new_reply_id, TEXT, TRANSLATION, SHORTCUT)

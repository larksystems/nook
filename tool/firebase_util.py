import enum

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

firebase_client = None

def init(CRYPTO_TOKEN_PATH, log):
    global firebase_client
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Done")

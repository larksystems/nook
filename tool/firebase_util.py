import enum

import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

from katikati_pylib.logging import logging
from core_data_modules.logging import Logger

firebase_client = None

log = None

def init(CRYPTO_TOKEN_PATH, logger_type):
    global firebase_client
    global log

    if logger_type == LoggerType.KATIKATI_PYLIB:
        log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)
    elif logger_type == LoggerType.CORE_DATA_MODULES:
        log = Logger(__name__)
        
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Done")

class LoggerType(enum.Enum):
    KATIKATI_PYLIB = 1,
    CORE_DATA_MODULES = 2

import argparse
import os
import time
import threading

from firebase_util import init_firebase_client
from data_dir_stat import get_size_and_upload

CRYPTO_TOKEN_PATH = None
DEFAULT_INTERVAL = 600 # 10 minutes
project = None
dirpath = None
firebase_client = None

def run():
    while True:
        get_size_and_upload(CRYPTO_TOKEN_PATH, dirpath, project, firebase_client)
        time.sleep(DEFAULT_INTERVAL)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Monitor data dir size")
    parser.add_argument("crypto_token_file", type=str, help="path to Firebase crypto token file")
    parser.add_argument("project", type=str, help="name of the project")
    parser.add_argument("dirname", type=str, help="path of directory to monitor")
    args = parser.parse_args()
    
    CRYPTO_TOKEN_PATH = args.crypto_token_file
    dirpath = os.path.abspath(args.dirname)
    project = args.project
    firebase_client = init_firebase_client(CRYPTO_TOKEN_PATH)
    runner = threading.Thread(target=run)
    runner.start()

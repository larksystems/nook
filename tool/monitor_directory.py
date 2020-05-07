import argparse
import os
import time
import datetime

from firebase_util import init_firebase_client
from katikati_pylib.logging import logging

DEFAULT_INTERVAL = 600 # 10 minutes
firebase_client = None
log = None

def get_size_and_upload(dirpath, project):
    dirname = os.path.basename(dirpath)
    dir_size = get_dir_size_in_mb(dirpath)
    log.info(f'Retrieved size of directory {dirname} as {dir_size}MB')
    entry = {
        'project': project,
        'dirname': dirname,
        'size_in_mb': dir_size
    }
    collection = 'dir_size_metrics'
    timestamp = datetime.datetime.now().isoformat()
    firebase_client.collection(collection).document(timestamp).set(entry)
    log.info(f'Pushed size of directory {dirname} successfully to Firestore')

def get_dir_size_in_mb(dirpath):
    dir_size = 0
    for (path, dirs, files) in os.walk(dirpath):
        for file in files:
            filename = os.path.join(path, file)
            dir_size += os.path.getsize(filename)
    return round((dir_size / (1024 * 1024)), 1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Monitor size of a directory")
    parser.add_argument("crypto_token_file", type=str, help="path to Firebase crypto token file")
    parser.add_argument("project", type=str, help="name of the project")
    parser.add_argument("dirpath", type=str, help="path of directory to monitor")
    args = parser.parse_args()
    
    dirpath = os.path.abspath(args.dirpath)
    project = args.project
    
    log = logging.Logger(__file__, args.crypto_token_file)
    firebase_client = init_firebase_client(args.crypto_token_file)
    
    while True:
        get_size_and_upload(dirpath, project)
        time.sleep(DEFAULT_INTERVAL)

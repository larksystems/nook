import os
import datetime

from katikati_pylib.logging import logging

log = None

def get_size_and_upload(CRYPTO_TOKEN_PATH, dirpath, project, firebase_client):
    global log
    if log is None:
        log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)
    dirname = os.path.basename(dirpath)
    dir_size = get_dir_size(dirpath)
    entry = {
        'project': project,
        'size': round(dir_size, 1)
    }
    collection = dirname + '_dir_size_metrics'
    timestamp = datetime.datetime.now().isoformat()
    firebase_client.collection(collection).document(timestamp).set(entry)
    log.info('Pushed size of directory {} successfully to Firestore'.format(dirname))

# size in MB
def get_dir_size(dirpath):
    dir_size = 0
    for (path, dirs, files) in os.walk(dirpath):
        for file in files:
            filename = os.path.join(path, file)
            dir_size += os.path.getsize(filename)
    return dir_size / (1024 * 1024)

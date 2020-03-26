import time
import datetime as dt
import threading
import sys
import argparse
import psutil
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger

COLLECTION = 'pipeline_system_metrics' #name of the firebase collections to store metrics
DEFAULT_INTERVAL = 60 # wait interval between each set of metric readings in seconds

log = Logger(__name__)


def initialize_firebase(CRYPTO_TOKEN_PATH):
    global firebase_client
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Firebase client ready")


def get_and_publish_system_metrics(interval):
    while True:
        metrics = {}

        # record datetime
        metrics['datetime'] = dt.datetime.now(dt.timezone.utc).isoformat()

        # current cpu utlization
        cpu_utilization = psutil.cpu_percent(interval=0.1)
        metrics['cpu_percent'] = cpu_utilization

        # cpu load over the last 1, 5 and 15 minutes in percentage
        cpu_load = [round((value / psutil.cpu_count() * 100), 2)
                    for value in psutil.getloadavg()]
        metrics['cpu_load_interval_percent'] = dict(
            {
                '1min': cpu_load[0],
                '5min': cpu_load[1],
                '15min': cpu_load[2]
            }
        )

        # memory usage
        memory_usage = psutil.virtual_memory()
        metrics['memory_usage'] = dict(
            {
                'available': memory_usage[1],
                'used': memory_usage[3],
                'percent': memory_usage[2],
                'free': memory_usage[4]
            }
        )

        # disk usage
        metrics['disk_usage'] = []
        for partition in psutil.disk_partitions():
            disk_usage = dict(psutil.disk_usage(partition[0])._asdict())
            disk_usage['disk'] = partition[0]
            metrics['disk_usage'].append(disk_usage)

        log.info("Recorded metrics: {}".format(metrics))

        publish_metrics_to_firestore(metrics)
        time.sleep(interval)


def publish_metrics_to_firestore(metrics):
    firebase_client.collection(COLLECTION).add(metrics)
    log.info("Successfully published metrics to firebase {} collection".format(COLLECTION))


def run_system_metric_monitor(interval=DEFAULT_INTERVAL):
    parser = argparse.ArgumentParser(description='Retrieve system metrics i.e cpu utilization, memory & disk usage')
    parser.add_argument("crypto_token_file", type=str, help="path to Firebase crypto token file")
    args = parser.parse_args()

    initialize_firebase(args.crypto_token_file)
    runner = threading.Thread(target=get_and_publish_system_metrics, args=(interval,))
    runner.start()


run_system_metric_monitor()

import time
import threading
import psutil
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from core_data_modules.logging import Logger

log = Logger(__name__)

def initialize_firebase(CRYPTO_TOKEN_PATH):
    global firebase_client
    log.info("Setting up Firebase client")
    firebase_cred = credentials.Certificate(CRYPTO_TOKEN_PATH)
    firebase_admin.initialize_app(firebase_cred)
    firebase_client = firestore.client()
    log.info("Firbase client ready")

def get_metrics(interval):
    while True:
        metrics = {}

        # current cpu utlization
        cpu_utilization = psutil.cpu_percent(interval=0.1)
        metrics['cpu_percent'] = cpu_utilization

        # cpu load over the last 1, 5 and 15 minutes
        cpu_load = [round((value / psutil.cpu_count() * 100), 2)
                    for value in psutil.getloadavg()]
        metrics['cpu_load_interval'] = cpu_load

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
        disk_usage = psutil.disk_usage('/')
        metrics['disk_usage'] = dict(disk_usage._asdict())

        # disk i/o
        disk_io = psutil.disk_io_counters('/')
        metrics['disk_io'] = disk_io

        publish_metrics_to_firebase(metrics)
        time.sleep(interval)


def publish_metrics_to_firestore(metrics):
    print(metrics)

def run_metric_monitor():
    runner = threading.Thread(target=get_metrics, args=(3,))
    runner.start()

run_metric_monitor()

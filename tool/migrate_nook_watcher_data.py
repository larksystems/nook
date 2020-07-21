import argparse
import textwrap

import firebase_util
from core_data_modules.logging import Logger

firebase_client = None
log = None

def strip_project(data):
    for entry in data:
        try:
            del list(entry.values())[0]['project']
        except KeyError:
            log.warning(f"project key doesn't exist in entry: {entry}")
    return data

def migrate():
    if args.project:
        docs = firebase_client.collection(args.source).where('project', '==', args.project).stream()
    else:
        docs = firebase_client.collection(args.source).stream()
    data = [{doc.id: doc.to_dict()} for doc in docs]
    data = strip_project(data) if args.project else data
    log.info(f'migrating data of length {len(data)}')
    collection_path = f'{args.target}/metrics'
    for entry in data:
        doc_label = list(entry.keys())[0]
        doc_data = list(entry.values())[0]
        firebase_client.collection(collection_path).document(doc_label).set(doc_data)
    log.info('done migration')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=textwrap.dedent("""
        Examples:
        python migrate_nook_watcher_data.py [CRYPRO_TOKEN_PATH] needs_reply_metrics Lark_KK-Project-2020-COVID19-KE-URBAN/needs_reply --project Lark/KK-Project-2020-COVID19-KE-URBAN
        python migrate_nook_watcher_data.py [CRYPRO_TOKEN_PATH] system_events Lark_KK-Project-2020-COVID19-KE-URBAN/system_events --project Lark/KK-Project-2020-COVID19
        python migrate_nook_watcher_data.py [CRYPRO_TOKEN_PATH] pipeline_system_metrics system_metrics/miranda
        """)
    )
    parser.add_argument('crypto_token', help='crypto token path')
    parser.add_argument('source', help='path to the source collection')
    parser.add_argument("target", help="path to the destination collection")
    parser.add_argument('--project', help='project records to migrate')

    args = parser.parse_args()
    firebase_client = firebase_util.init_firebase_client(args.crypto_token)
    log = Logger(__name__)
    migrate()

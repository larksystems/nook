import argparse
import textwrap
import time

import firebase_util
from core_data_modules.logging import Logger

firebase_client = None
log = None

def migrate_project(project):
    collection_path = f"projects/{project}/conversation_metrics"
    batch = firebase_client.batch()
    batch_count = 0
    docs = []
    for doc in firebase_client.collection(collection_path).stream():
        docs.append(doc)

    for doc in docs:
        doc_label = doc.id
        doc_data = doc.to_dict()
        tags_count = {}
        if "tags_count" in doc_data.keys():
            tags_count = doc_data.pop("tags_count")
        if "escalate_conversations" in doc_data.keys():
            tags_count["escalate"] = doc_data.pop("escalate_conversations")
        if "escalate_conversations_our_turn" in doc_data.keys():
            tags_count["escalate our turn"] = doc_data.pop("escalate_conversations_our_turn")

        doc_data["tags_count"] = tags_count

        batch.set(doc.reference, doc_data)

        batch_count += 1
        if batch_count > 450:
            log.info(f"Batch about to commit size: {batch_count}")
            batch.commit()
            batch_count = 0
            log.info(f"Batch committed")


    batch.commit()
    log.info('done migration')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        formatter_class=argparse.RawTextHelpFormatter,
        epilog=textwrap.dedent("""
        Examples:
        python migrate_conversation_metrics_model.py <CRYPRO_TOKEN_PATH> Lark_KK-Project-2020-COVID19-KE-URBAN
        """)
    )
    parser.add_argument('crypto_token', help='crypto token path')
    parser.add_argument('project', help='which project records to migrate')

    args = parser.parse_args()
    firebase_client = firebase_util.init_firebase_client(args.crypto_token)
    log = Logger(__name__)
    migrate_project(args.project)

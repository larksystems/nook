# Temporary tool that reads from JSON and uploads it to Firebase
# Relies on an undocumented .collections() API call and a hard coded list of top level collections
import hashlib
import time
import tool_utils
import json
import sys

import firebase_util
from katikati_pylib.logging import logging

log = None
firebase_client = None

def text_to_doc_id(prefix, text):
    return f"{prefix}-" + hashlib.sha256(text.encode("utf-8")).hexdigest()[0:8]

if __name__ == '__main__':
    if (len(sys.argv) != 4):
        print ("Usage python add_to_firebase.py crypto_token suggested_replies|message_tags|conversation_tags input_path")
        print ("Adds data items that don't currently exist, and overwrittes items that already exist.")
        exit(1)

    CRYPTO_TOKEN_PATH = sys.argv[1]
    CONTENT_TYPE = sys.argv[2]
    INPUT_PATH = sys.argv[3]

    log = logging.Logger(__file__, CRYPTO_TOKEN_PATH)

    firebase_client = firebase_util.init_firebase_client(CRYPTO_TOKEN_PATH)

    valid_content_type = ["suggested_replies", "message_tags", "conversation_tags"]
    if CONTENT_TYPE not in valid_content_type:
        log.error("Content type '{}' not known, expected one of {}".format(CONTENT_TYPE, valid_content_type))
        exit(1)

    with open(INPUT_PATH, 'r') as f:
        data_dict = json.load(f)

    if CONTENT_TYPE == "suggested_replies":
        # Make sure that the fields that the Firestore model expects exist
        # TODO(mariana): Move to using a validator
        assert len(data_dict.keys()) >= 1
        suggested_replies_collection = "suggestedReplies"
        suggested_replies = data_dict[suggested_replies_collection]
        suggested_replies_documents = []
        assert isinstance(suggested_replies, list)
        for reply_data in suggested_replies:
            assert isinstance(reply_data, dict)
            reply_fields = {}
            assert "text" in reply_data.keys()
            reply_fields["text"] = reply_data["text"]
            if "__id" in reply_data.keys():
                reply_id = reply_data["__id"]
                if reply_id == "":
                    log.info(f"Skipping: {reply_data}")
                    continue
            else:
                reply_id = text_to_doc_id("reply", reply_fields["text"])
            assert "translation" in reply_data.keys()
            reply_fields["translation"] = reply_data["translation"]
            reply_fields["shortcut"] = reply_data["shortcut"] if "shortcut" in reply_data.keys() else ""
            if "seq_no" in reply_data.keys():
                reply_fields["seq_no"] = reply_data["seq_no"]
            if "category" in reply_data.keys():
                reply_fields["category"] = reply_data["category"]
            if "group_id" in reply_data.keys():
                reply_fields["group_id"] = reply_data["group_id"]
            if "group_description" in reply_data.keys():
                reply_fields["group_description"] = reply_data["group_description"]
            if "index_in_group" in reply_data.keys():
                reply_fields["index_in_group"] = reply_data["index_in_group"]

            suggested_replies_documents.append({reply_id : reply_fields})

        short_id = tool_utils.short_id()
        log.audit(f"add_to_firebase, suggested_replies: JobID ({short_id}), keys to download {json.dumps(suggested_replies_documents)}")
        suggested_replies_documents = firebase_util.convert_documents_to_firestore_format(suggested_replies_collection, suggested_replies_documents)
        firebase_util.push_collection_to_firestore(suggested_replies_collection, suggested_replies_documents)
        log.notify(f"add_to_firebase, suggested_replies: JobID {short_id}")
        log.info(f"Uploaded {len(suggested_replies_documents)} suggested replies")

    elif CONTENT_TYPE == "conversation_tags" or CONTENT_TYPE == "message_tags":
        content_type = CONTENT_TYPE.replace("_tags", "")
        # Make sure that the fields that the Firestore model expects exist
        # TODO(mariana): Move to using a validator
        assert len(data_dict.keys()) >= 1
        tags_collection = f"{content_type}Tags"
        tags = data_dict[tags_collection]
        tags_documents = []
        assert isinstance(tags, list)
        for tag_data in tags:
            assert isinstance(tag_data, dict)
            tag_fields = {}
            assert "text" in tag_data.keys()
            tag_fields["text"] = tag_data["text"]
            if "__id" in tag_data.keys():
                tag_id = tag_data["__id"]
                if tag_id == "":
                    log.info(f"Skipping: {tag_data}")
                    continue
            else:
                tag_id = text_to_doc_id("tag", tag_fields["text"])
            assert "shortcut" in tag_data.keys()
            tag_fields["shortcut"] = tag_data["shortcut"]
            assert "type" in tag_data.keys()
            assert tag_data["type"] == "TagType.normal" or tag_data["type"] == "TagType.important"
            tag_fields["type"] = f'TagType.{tag_data["type"]}'

            tags_documents.append({tag_id : tag_fields})

        short_id = tool_utils.short_id()
        log.audit(f"add_to_firebase, conversation_tags: JobID ({short_id}), keys to download {json.dumps(tags_documents)}")
        tags_documents = firebase_util.convert_documents_to_firestore_format(tags_collection, tags_documents)
        firebase_util.push_collection_to_firestore(tags_collection, tags_documents)
        log.notify(f"add_to_firebase, conversation_tags: JobID {short_id}")
        log.info(f"Uploaded {len(tags_documents)} {content_type} tags")

    else:
        log.error("Content type '{}' not known, expected one of {}".format(CONTENT_TYPE, valid_content_type))
        exit(1)

    log.info("Done")

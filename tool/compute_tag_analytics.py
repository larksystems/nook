import argparse
import hashlib
import json
import sys
import time

from core_data_modules.logging import Logger
from datetime import datetime

import demogs_helper as demogs

log = Logger(__name__)

CONVERSATIONS_COLLECTION_KEY = 'nook_conversations'
CONVERSATION_TAGS_COLLECTION_KEY = 'conversationTags'
DAILY_TAG_METRICS_COLLECTION_KEY = 'daily_tag_metrics'

coda_tags = {}

tag_id_to_name = {}

def tag_ids(tags):
    return [tag_to_tag_id(tag_name) for tag_name in tags]

def tag_to_tag_id(text):
    return "tag-" + hashlib.sha256(text.encode("utf-8")).hexdigest()[0:8]

def empty_daily_metrics(response_themes):
    return {
        "gender": dict.fromkeys(demogs.gender_options, 0),
        "age": dict.fromkeys(demogs.age_ranges, 0),
        "response_themes": dict.fromkeys(response_themes, 0)
    }

def compute_daily_tag_distribution(nook_conversations, ignore_stop=False):
    log.info (f"compute_daily_tag_distribution: processing {len(nook_conversations)} conversations...")

    time_start = time.perf_counter_ns()

    daily_metrics = {}
    response_themes = coda_tags["response_themes"]
    response_themes_ids = tag_ids(response_themes)
    age_ids = tag_ids(coda_tags["age"])
    gender_ids = tag_ids(coda_tags["gender"])

    for conversation in nook_conversations:
        conversation_tags = conversation["tags"]

        if not ignore_stop and tag_to_tag_id("STOP") in conversation_tags:
            continue

        # get conversation demogs
        age = "unknown"
        age_tags = set(conversation_tags).intersection(age_ids)
        if len(age_tags) == 1:
            age = demogs.age_range(tag_id_to_name[list(age_tags)[0]])

        gender = "unknown"
        gender_tags = set(conversation_tags).intersection(gender_ids)
        if len(gender_tags) == 1:
            gender = tag_id_to_name[list(gender_tags)[0]]

        # process response themes for each message
        messages = conversation["messages"]
        conversation_metrics = {}
        for message in messages:
            if message["direction"] == "MessageDirection.out":
                continue
            matched_tags = set(response_themes_ids).intersection(message["tags"])
            if len(matched_tags) == 0:
                continue
            date = datetime.fromisoformat(message["datetime"]).date().isoformat()
            date_metrics = conversation_metrics.get(date, {})

            # demogs
            if "age" not in date_metrics:
                date_metrics["age"] = {}
            date_metrics["age"][age] = True

            if "gender" not in date_metrics:
                date_metrics["gender"] = {}
            date_metrics["gender"][gender] = True

            # themes
            if "response_themes" not in date_metrics:
                date_metrics["response_themes"] = {}
            for tag in matched_tags:
                date_metrics["response_themes"][tag_id_to_name[tag]] = True
            conversation_metrics[date] = date_metrics

        # add conversation metrics to overall metrics
        for date, date_metrics in conversation_metrics.items():
            total_date_metrics = daily_metrics.get(date, empty_daily_metrics(response_themes))
            for key1 in date_metrics.keys():
                if (total_date_metrics[key1] is int):
                    total_date_metrics[key1] += 1
                    continue
                total_value = total_date_metrics[key1]
                for key2 in date_metrics[key1]:
                    total_value[key2] += 1
            daily_metrics[date] = total_date_metrics

    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"compute_daily_tag_distribution: processed {len(nook_conversations)} conversations in {ms_elapsed} ms")

    return daily_metrics


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("nook_export",
                        help="path to the Nook export to analyse")
    parser.add_argument("output_folder",
                        help="path to output folder where the analytics should be exported")
    parser.add_argument("coda_tags",
                        help="path to a file with the coda tags used by the project")
    parser.add_argument("--ignore_stop", action="store_true",
                        help="whether to ignore a stop response")

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) < 4:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    NOOK_EXPORT = args.nook_export
    OUTPUT_FOLDER = args.output_folder
    CODA_TAGS_FILE = args.coda_tags
    IGNORE_STOP = args.ignore_stop

    with open(NOOK_EXPORT, mode="r") as nook_export_file:
        nook_export_data = json.load(nook_export_file)
    conversation_tags = nook_export_data[CONVERSATION_TAGS_COLLECTION_KEY]
    nook_conversations = nook_export_data[CONVERSATIONS_COLLECTION_KEY]

    with open(CODA_TAGS_FILE, mode="r") as coda_tags_file:
        coda_tags = json.load(coda_tags_file)
        assert("age" in coda_tags)
        assert("gender" in coda_tags)
        assert("response_themes" in coda_tags)


    all_tags = []
    for tag_list in coda_tags.values():
        all_tags.extend(tag_list)

    for tag in all_tags:
        tag_id_to_name[tag_to_tag_id(tag)] = tag

    now = datetime.utcnow().isoformat(timespec='minutes')
    now = now.replace(":", "-")

    daily_metrics = compute_daily_tag_distribution(nook_conversations, IGNORE_STOP)
    # prepare for writing to a json file that can be uploaded to firebase
    daily_metrics_list = []
    for day in daily_metrics:
        day_metrics = daily_metrics[day]
        day_metrics["__id"] = day
        day_metrics["__reference_path"] = f"{DAILY_TAG_METRICS_COLLECTION_KEY}/{day}"
        day_metrics["__subcollections"] = []
        daily_metrics_list.append(day_metrics)
    daily_metrics_json = {DAILY_TAG_METRICS_COLLECTION_KEY : daily_metrics_list}

    daily_metrics_file = f"{OUTPUT_FOLDER}/nook-analysis-daily_metrics_{now}.json"
    with open(daily_metrics_file, mode="w", encoding='utf-8') as output_file:
        json.dump(daily_metrics, output_file, indent=2)
        log.info(f"compute_daily_tag_distribution saved to {daily_metrics_file}")

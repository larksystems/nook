import argparse
import hashlib
import json
import sys
import time

from core_data_modules.logging import Logger
from datetime import datetime, timezone, timedelta

import demogs_helper as demogs

log = Logger(__name__)

CONVERSATIONS_COLLECTION_KEY = 'nook_conversations'
CONVERSATION_SHARDS_COLLECTION_KEY = 'nook_conversation_shards'
CONVERSATION_TAGS_COLLECTION_KEY = 'conversationTags'
DAILY_TAG_METRICS_COLLECTION_KEY = 'daily_tag_metrics'
TOTAL_COUNTS_METRICS_COLLECTION_KEY = 'total_counts_metrics'
NEEDS_REPLY_METRICS_COLLECTION_KEY = 'needs_reply_metrics'

NEEDS_REPLY_TAG = "Needs Reply"
ESCALATE_TAG = "escalate"

KK_PROJECT = None

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

        # Add the computed conversation metrics to overall metrics
        # - conversation_metrics only has fields corresponding to the tags that apply to it
        #   so the presence of a metric name in the data structure indicates
        #   that it should be counted against that metric
        # - daily_metrics tracks the actual conversation counts for all metrics
        for date in conversation_metrics.keys():
            date_daily_metrics = daily_metrics.get(date, empty_daily_metrics(response_themes))
            for metric in conversation_metrics[date].keys():
                # Some metrics are top-level metrics, with a direct int value associated to them
                if (date_daily_metrics[metric] is int):
                    date_daily_metrics[metric] += 1
                    continue
                # Other metrics are groupings of other sub-metrics, such as gender -> male, female, unknown
                date_daily_metrics_group = date_daily_metrics[metric]
                for sub_metric in conversation_metrics[date][metric]:
                    date_daily_metrics_group[sub_metric] += 1
            daily_metrics[date] = date_daily_metrics

    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"compute_daily_tag_distribution: processed {len(nook_conversations)} conversations in {ms_elapsed} ms")

    return daily_metrics


def compute_total_counts(nook_conversations, ignore_stop=False):
    log.info (f"compute_total_counts: processing {len(nook_conversations)} conversations...")

    time_start = time.perf_counter_ns()

    age_ids = tag_ids(coda_tags["age"])
    gender_ids = tag_ids(coda_tags["gender"])
    location_ids = tag_ids(coda_tags.get("county", []))
    location_ids.extend(tag_ids(coda_tags.get("constituency", [])))

    conversations_count = 0
    incoming_messages_count = 0
    incoming_non_demogs_messages_count = 0
    outgoing_messages_count = 0
    messages_count = 0

    for conversation in nook_conversations:
        conversation_tags = conversation["tags"]

        if not ignore_stop and tag_to_tag_id("STOP") in conversation_tags:
            continue

        conversations_count += 1

        # process each message
        messages = conversation["messages"]
        for message in messages:
            messages_count += 1
            if message["direction"] == "MessageDirection.out":
                outgoing_messages_count += 1
                continue
            incoming_messages_count += 1

            # message is a demogs message if it's been tagged with an age, gender or location tag
            if (len(set(age_ids).intersection(message["tags"])) != 0 or
                len(set(gender_ids).intersection(message["tags"])) != 0 or
                len(set(location_ids).intersection(message["tags"])) != 0):
                incoming_non_demogs_messages_count += 1

    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"compute_total_counts: processed {len(nook_conversations)} conversations in {ms_elapsed} ms")

    total_counts = {
        "conversations_count" : conversations_count,
        "messages_count": messages_count,
        "incoming_messages_count": incoming_messages_count,
        "incoming_non_demogs_messages_count": incoming_non_demogs_messages_count,
        "outgoing_messages_count": outgoing_messages_count
    }

    return total_counts


def compute_needs_reply_metrics(nook_conversations):
    log.info (f"compute_needs_reply: processing {len(nook_conversations)} conversations...")

    time_start = time.perf_counter_ns()

    needs_reply_count = 0
    needs_reply_more_than_24h = 0
    needs_reply_and_escalate_more_than_24h = 0
    needs_reply_dates = []
    needs_reply_tag_id = tag_to_tag_id(NEEDS_REPLY_TAG)
    needs_reply_and_escalate_count = 0
    escalate_tag_id = tag_to_tag_id(ESCALATE_TAG)

    def get_last_incoming_message_dt(messages):
        for message in messages[::-1]:
            if message["direction"] == "MessageDirection.out":
                continue
            return message["datetime"]

    for conversation in nook_conversations:
        conversation_tags = conversation["tags"]

        if needs_reply_tag_id not in conversation_tags:
            continue

        # Increase needs reply count
        needs_reply_count += 1

        # Get the date of the last incoming message
        date_of_last_incoming_message = get_last_incoming_message_dt(conversation["messages"])
        delay = datetime.now(timezone.utc) - datetime.fromisoformat(date_of_last_incoming_message)

        if delay > timedelta(days=1):
            needs_reply_more_than_24h += 1
            if escalate_tag_id in conversation_tags:
                needs_reply_and_escalate_more_than_24h += 1

        needs_reply_dates.append(date_of_last_incoming_message)

        # Count if this conversation is also tagged as escalate
        if escalate_tag_id in conversation_tags:
            needs_reply_and_escalate_count += 1

    earliest_date = datetime.now(timezone.utc)
    needs_reply_messages_by_date = {}

    for date in needs_reply_dates:
        iso_date = datetime.fromisoformat(date)
        if iso_date < earliest_date:
            earliest_date = iso_date

        day_date = date.split("T")[0]
        if day_date not in needs_reply_messages_by_date.keys():
            needs_reply_messages_by_date[day_date] = 0

        needs_reply_messages_by_date[day_date] += 1

    needs_reply_metrics = {
        "datetime": datetime.now().isoformat(),
        "needs_reply_count": needs_reply_count,
        "needs_reply_more_than_24h": needs_reply_more_than_24h,
        "needs_reply_and_escalate_count": needs_reply_and_escalate_count,
        "needs_reply_and_escalate_more_than_24h": needs_reply_and_escalate_more_than_24h,
        "needs_reply_messages_by_date": needs_reply_messages_by_date,
        "earliest_needs_reply_date": earliest_date.isoformat(),
    }

    time_end = time.perf_counter_ns()

    ms_elapsed = (time_end - time_start) / (1000 * 1000)
    log.info (f"compute_needs_reply: processed {len(nook_conversations)} conversations in {ms_elapsed} ms")

    return needs_reply_metrics

def merge_shards(nook_conversation_shards):
    nook_conversations = []
    for shard in nook_conversation_shards:
        nook_conversations.extend(shard["conversations"])
    return nook_conversations

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("nook_export",
                        help="path to the Nook export to analyse")
    parser.add_argument("kk_project",
                        help="the name of the katikati project for this Nook export")
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
    global KK_PROJECT
    KK_PROJECT = args.kk_project

    with open(NOOK_EXPORT, mode="r") as nook_export_file:
        nook_export_data = json.load(nook_export_file)
    conversation_tags = nook_export_data[CONVERSATION_TAGS_COLLECTION_KEY]

    # If the data is nook_conversations, use it, otherwise try to read from nook_conversation_shards
    if CONVERSATION_SHARDS_COLLECTION_KEY in nook_export_data:
        nook_conversation_shards = nook_export_data[CONVERSATION_SHARDS_COLLECTION_KEY]
        nook_conversations = merge_shards(nook_conversation_shards)
    elif CONVERSATIONS_COLLECTION_KEY in nook_export_data:
        nook_conversations = nook_export_data[CONVERSATIONS_COLLECTION_KEY]
    else:
        log.error('neither nook_conversations nor nook_conversation_shards exists in the firebase export, aborting analytics...')
        exit(1)

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

    daily_metrics_file = f"{OUTPUT_FOLDER}/nook-analysis-daily_metrics.json"
    with open(daily_metrics_file, mode="w", encoding='utf-8') as output_file:
        json.dump(daily_metrics_json, output_file, indent=2)
        log.info(f"compute_daily_tag_distribution saved to {daily_metrics_file}")


    total_counts = compute_total_counts(nook_conversations, IGNORE_STOP)
    # prepare for writing to a json file that can be uploaded to firebase
    total_counts["__id"] = TOTAL_COUNTS_METRICS_COLLECTION_KEY
    total_counts["__reference_path"] = f"{TOTAL_COUNTS_METRICS_COLLECTION_KEY}/{TOTAL_COUNTS_METRICS_COLLECTION_KEY}"
    total_counts["__subcollections"] = []
    total_counts_json = {TOTAL_COUNTS_METRICS_COLLECTION_KEY : [total_counts]}

    total_counts_file = f"{OUTPUT_FOLDER}/nook-analysis-total_counts.json"
    with open(total_counts_file, mode="w", encoding='utf-8') as output_file:
        json.dump(total_counts_json, output_file, indent=2)
        log.info(f"compute_total_counts saved to {total_counts_file}")


    needs_reply_metrics = compute_needs_reply_metrics(nook_conversations)
    # prepare for writing to a json file that can be uploaded to firebase

    isotime = needs_reply_metrics["datetime"]
    needs_reply_metrics["__id"] = isotime
    needs_reply_metrics["__reference_path"] = f"{NEEDS_REPLY_METRICS_COLLECTION_KEY}/{isotime}"
    needs_reply_metrics["__subcollections"] = []

    needs_reply_metrics_json = {
        NEEDS_REPLY_METRICS_COLLECTION_KEY : [needs_reply_metrics]
    }

    needs_reply_metrics_file = f"{OUTPUT_FOLDER}/nook-analysis-needs_reply_metrics.json"
    with open(needs_reply_metrics_file, mode="w", encoding='utf-8') as output_file:
        json.dump(needs_reply_metrics_json, output_file, indent=2)
        log.info(f"compute_needs_reply saved to {needs_reply_metrics_file}")

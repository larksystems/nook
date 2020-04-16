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
CONVERSATION_TAGS_COLLECTION_KEY = 'conversationTags'
DAILY_TAG_METRICS_COLLECTION_KEY = 'daily_tag_metrics'
TOTAL_COUNTS_METRICS_COLLECTION_KEY = 'total_counts_metrics'
NEEDS_REPLY_METRICS_COLLECTION_KEY = 'needs_reply_metrics'

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("nook_export",
                        help="path to the Nook export to analyse")
    parser.add_argument("output_folder",
                        help="path to output folder where the analytics should be exported")
    parser.add_argument("--ignore_stop", action="store_true",
                        help="whether to ignore a stop response")

    def _usage_and_exit(error_message):
        print(error_message)
        print()
        parser.print_help()
        exit(1)

    if len(sys.argv) < 3:
        _usage_and_exit("Wrong number of arguments")
    args = parser.parse_args(sys.argv[1:])

    NOOK_EXPORT = args.nook_export
    OUTPUT_FOLDER = args.output_folder
    # CODA_TAGS_FILE = args.coda_tags
    IGNORE_STOP = args.ignore_stop

    with open(NOOK_EXPORT, mode="r") as nook_export_file:
        nook_export_data = json.load(nook_export_file)
    # conversation_tags = nook_export_data[CONVERSATION_TAGS_COLLECTION_KEY]
    nook_conversations = nook_export_data[CONVERSATIONS_COLLECTION_KEY]

    standard_messages = set(
        [
            "1/4 Tungependa kutumia majibu yako kwenye utafiti utakaosaidia katika mikakati ya kuzuia ugonjwa wa coronavirus na tungependa kukuuliza maswali mengine.",
            "2/4 Iwapo hungependa kushiriki, tuma neno STOP na hautapokea maswali zaidi na ujumbe wako hautatumika katika utafiti huu.",
            "3/4 Iwapo unakubali kushiriki katika utafiti huu, tutahifadhi nambari yako ya simu hadi mwisho wa mradi huu kwa mda usiozidi miezi kumi na miwili.",
            "4/4 Unaishi katika eneo gani la ubunge?",
            "Wewe ni Mme ama Mke?",
             "Una miaka mingapi? Tafadhali jibu kwa nambari.\n",
             "Asante kwa kushiriki! Tafadhali sikiliza Radio Jambo Jumatatu hii, saa Tano asubuhi (11am), Bustani ya Masawe Japanni!",
             "Asante. Ujumbe wako utaweza somwa hewani, lakini hautatumika kama sehemu ya utafiti wa mradi huu na hutaulizwa maswali zaidi."
        ]
    )

    total = 0

    
    for conversation in nook_conversations:
        messages = conversation["messages"]

        print ("raw")
        print (json.dumps(messages, indent=2))

        for standard_message in standard_messages:
            for i in range(0, len(messages)):
                if messages[i]['text'] == standard_message:
                    messages.pop(i)
                    break

        print ("::::::::::::::::::::::::::")
        print ("filtered")
        print (json.dumps(messages, indent=2))


        blocks = 0
        last_direction = 'MessageDirection.in'
        for i in range(0, len(messages)):
            msg = messages[i]
            msg_direction = msg["direction"]

            if msg_direction == last_direction: # within a block
                continue

            if msg_direction == 'MessageDirection.out':
                assert last_direction == 'MessageDirection.in'
                blocks += 1
                last_direction = 'MessageDirection.out'
                continue
            
            if msg_direction == 'MessageDirection.in':
                assert last_direction == 'MessageDirection.out'
                last_direction = 'MessageDirection.in'
                continue

            raise "Unknown direction"

        total += blocks
        print (f"Blocks: {blocks}")
        print ("==========================")
    
    print (total)




    # # with open(CODA_TAGS_FILE, mode="r") as coda_tags_file:
    # #     coda_tags = json.load(coda_tags_file)
    # #     assert("age" in coda_tags)
    # #     assert("gender" in coda_tags)
    # #     assert("response_themes" in coda_tags)

    # all_tags = []
    # for tag_list in coda_tags.values():
    #     all_tags.extend(tag_list)

    # for tag in all_tags:
    #     tag_id_to_name[tag_to_tag_id(tag)] = tag

    # now = datetime.utcnow().isoformat(timespec='minutes')
    # now = now.replace(":", "-")




    # daily_metrics = compute_daily_tag_distribution(nook_conversations, IGNORE_STOP)
    # # prepare for writing to a json file that can be uploaded to firebase
    # daily_metrics_list = []
    # for day in daily_metrics:
    #     day_metrics = daily_metrics[day]
    #     day_metrics["__id"] = day
    #     day_metrics["__reference_path"] = f"{DAILY_TAG_METRICS_COLLECTION_KEY}/{day}"
    #     day_metrics["__subcollections"] = []
    #     daily_metrics_list.append(day_metrics)
    # daily_metrics_json = {DAILY_TAG_METRICS_COLLECTION_KEY : daily_metrics_list}

    # daily_metrics_file = f"{OUTPUT_FOLDER}/nook-analysis-daily_metrics.json"
    # with open(daily_metrics_file, mode="w", encoding='utf-8') as output_file:
    #     json.dump(daily_metrics_json, output_file, indent=2)
    #     log.info(f"compute_daily_tag_distribution saved to {daily_metrics_file}")


    # total_counts = compute_total_counts(nook_conversations, IGNORE_STOP)
    # # prepare for writing to a json file that can be uploaded to firebase
    # total_counts["__id"] = TOTAL_COUNTS_METRICS_COLLECTION_KEY
    # total_counts["__reference_path"] = f"{TOTAL_COUNTS_METRICS_COLLECTION_KEY}/{TOTAL_COUNTS_METRICS_COLLECTION_KEY}"
    # total_counts["__subcollections"] = []
    # total_counts_json = {TOTAL_COUNTS_METRICS_COLLECTION_KEY : [total_counts]}

    # total_counts_file = f"{OUTPUT_FOLDER}/nook-analysis-total_counts.json"
    # with open(total_counts_file, mode="w", encoding='utf-8') as output_file:
    #     json.dump(total_counts_json, output_file, indent=2)
    #     log.info(f"compute_total_counts saved to {total_counts_file}")


    # needs_reply_metrics = compute_needs_reply_metrics(nook_conversations)
    # # prepare for writing to a json file that can be uploaded to firebase

    # isotime = needs_reply_metrics["datetime"]
    # needs_reply_metrics["__id"] = isotime
    # needs_reply_metrics["__reference_path"] = f"{NEEDS_REPLY_METRICS_COLLECTION_KEY}/{isotime}"
    # needs_reply_metrics["__subcollections"] = []

    # needs_reply_metrics_json = {
    #     NEEDS_REPLY_METRICS_COLLECTION_KEY : [needs_reply_metrics]
    # }

    # needs_reply_metrics_file = f"{OUTPUT_FOLDER}/nook-analysis-needs_reply_metrics.json"
    # with open(needs_reply_metrics_file, mode="w", encoding='utf-8') as output_file:
    #     json.dump(needs_reply_metrics_json, output_file, indent=2)
    #     log.info(f"compute_needs_reply saved to {needs_reply_metrics_file}")

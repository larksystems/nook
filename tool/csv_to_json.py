import argparse
import csv
import json
import sys


if __name__ == '__main__':
  parser = argparse.ArgumentParser()
  parser.add_argument("collection",
                      help="the Firebase collection for which data will be generated"
                           "usually one of suggestedReplies, conversationTags and messageTags,"
                           "but not restrictions are set")
  parser.add_argument("csv_file",
                      help="path to CSV file to be converted")
  parser.add_argument("json_file",
                      help="path to the output JSON file that will be generated")

  def _usage_and_exit(error_message):
    print(error_message)
    print()
    parser.print_help()
    exit(1)

  if len(sys.argv) != 4:
    _usage_and_exit("Unexpected number or arguments")
  args = parser.parse_args(sys.argv[1:])

  ROOT_COLLECTION = args.collection
  CSV_FILE = args.csv_file
  JSON_FILE = args.json_file

  output = { ROOT_COLLECTION : [] }
  entries = output[ROOT_COLLECTION]

  with open(CSV_FILE) as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
    line_count = 0
    column_names = []
    for row in csv_reader:
      line_count += 1
      if line_count == 1:
        column_names = list(row)
        continue
      entries.append(dict(zip(column_names, row)))
    print(f'Processed {line_count} lines from the CSV file.')

  with open(JSON_FILE, mode="w", encoding='utf-8') as json_file:
    json.dump(output, json_file, indent=2)

  print(f'Done. CSV file exported to JSON successfully.')

import csv
import sys
import pprint

def parse_jtl(file_name):
    with open(file_name, mode='r') as infile:
        reader = csv.DictReader(infile)
        return [row for row in reader]

result_records = parse_jtl(sys.argv[1])

summary_fields = []
for key in result_records[0].keys():
    try:
        n = int(result_records[0][key])
        summary_fields.append(key)
    except:
        pass

labels = sorted(list(set([record['label'] for record in result_records])))

statistics = {}
for label in labels:
    records = list(filter(lambda r: r['label'] == label,result_records))
    stats = dict(zip(summary_fields,[0 for i in summary_fields]))
    for record in records:
        for field in summary_fields:
            stats[field] = stats[field] + int(record[field])

    for field in summary_fields:
        stats[field] = float(stats[field]) / len(records)

    statistics[label] = stats

pprint.PrettyPrinter().pprint(statistics)


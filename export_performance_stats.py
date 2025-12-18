import json
import csv
import sys

def process_stats():
    try:
        with open('stats_dump.json', 'r') as f:
            data = json.load(f)
    except FileNotFoundError:
        print("Error: stats_dump.json not found.")
        sys.exit(1)

    if not data:
        print("No data to process.")
        return

    # Extract all unique keys from the 'data' dictionary across all records
    data_keys = set()
    for record in data:
        if 'data' in record and isinstance(record['data'], dict):
            data_keys.update(record['data'].keys())
    
    # Sort keys for consistent column order
    sorted_data_keys = sorted(list(data_keys))
    
    # Define CSV headers
    headers = ['id', 'user_id', 'updated_at'] + sorted_data_keys

    with open('performance_stats.csv', 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=headers)
        writer.writeheader()

        for record in data:
            row = {
                'id': record.get('id', ''),
                'user_id': record.get('user_id', ''),
                'updated_at': record.get('updated_at', '')
            }
            
            # Flatten data fields
            if 'data' in record and isinstance(record['data'], dict):
                for key in sorted_data_keys:
                    row[key] = record['data'].get(key, '')
            
            writer.writerow(row)

    print(f"Successfully wrote {len(data)} records to performance_stats.csv")

if __name__ == "__main__":
    process_stats()

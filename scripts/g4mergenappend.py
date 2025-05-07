#!/usr/bin/env python3
import argparse
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser(
        description="Merging csv files and appending"
    )
    parser.add_argument(
        '--list', '-l',
        type=str,
        required=True,
        help="List of items to merge"
    )
    parser.add_argument(
        '--output', '-o',
        type=str,
        required=True,
        help="Output file name"
    )
    return parser.parse_args()

def merge_csv_files(all_files, output_filename):

    all_df = []
    for f in all_files:
        df = pd.read_csv(f)
        all_df.append(df)
    merged_df = pd.concat(all_df, ignore_index=True)
    merged_df.to_csv(output_filename, index=False)

def main():
    args = parse_args()
    result_list_dir = (args.list).split()
    print(type(args.list))
    print(result_list_dir)
    merge_csv_files(result_list_dir, args.output)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import argparse
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser(
        description="Merging csv files and appending"
    )
    parser.add_argument(
        '--listfile', '-l',
        type=str,
        required=True,
        help="Path to a file containing a list of CSV files to merge (one per line)"
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

    # Read input files from listfile
    with open(args.listfile, 'r') as file:
        file_list = [line.strip() for line in file if line.strip()]

    print(f"Merging {len(file_list)} files from {args.listfile}...")
    merge_csv_files(file_list, args.output)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
import argparse
import pandas as pd

def parse_args():
    parser = argparse.ArgumentParser(
        description="Converts a merged G4Hunter output (.txt) file to .bed file"
    )
    parser.add_argument(
        '--input', '-i',
        type=str,
        required=True,
        help="Path to Merged G4Hunter Output"
    )
    parser.add_argument(
        '--output', '-o',
        type=str,
        required=True,
        help="Output file name"
    )
    return parser.parse_args()

def consolidate_txt_to_bed(input_file, output_file):
    bed_rows = []

    with open(input_file, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    chrom = None
    block = []

    for line in lines:
        if line.startswith('>'):
            # Process the previous block (if any)
            if (chrom) and (len(block) >= 2):
                for data_line in block[1:]:  # Skip the 2 header lines
                    parts = data_line.split('\t')
                    if len(parts) < 5:
                        print(f"Skipping malformed line in {chrom}: {data_line}")
                        continue
                    start, end, score = parts[0], parts[1], parts[4]
                    bed_rows.append([chrom, start, end, '', score, '.'])
            # Start a new block
            chrom = line.lstrip('>')
            block = []
        else:
            block.append(line)

    # Process the last block
    if (chrom) and (len(block) >= 2):
        for data_line in block[1:]:
            parts = data_line.split('\t')
            if len(parts) < 5:
                print(f"Skipping malformed line in {chrom}: {data_line}")
                continue
            start, end, score = parts[0], parts[1], parts[4]
            bed_rows.append([chrom, start, end, '', score, '.'])

    # Write to BED file
    bed_df = pd.DataFrame(bed_rows, columns=['chrom', 'start', 'end', 'name', 'score', 'strand'])
    bed_df.to_csv(output_file, sep='\t', header=False, index=False)


def main():
    args = parse_args()
    # Convert the input .txt file to a .bed file
    consolidate_txt_to_bed(args.input, args.output)

if __name__ == "__main__":
    main()

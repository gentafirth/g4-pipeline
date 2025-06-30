#!/usr/bin/env python3
import argparse
from Bio import SeqIO

# Define your static keys
WINDOW = 'Window'
THRESHOLD = 'Threshold'
REF = 'Accession'
NPQS = 'Number of PQS'
BP = 'Base Pairs'
NGC = 'Number of GCs'
PGC = 'Percentage of GCs'
FRQ = 'Frequency of PQS'
# G4 Result .txt file to Database Globals
SEQ_ID = 'Sequence_ID'
START = 'Start'
END = 'End'
SEQUENCE = 'Sequence'
LENGTH = 'Length'
SCORE = 'Score'

def parse_args():
    parser = argparse.ArgumentParser(
        description="Compute PQS statistics over a set of FASTA sequences."
    )
    parser.add_argument(
        '--window', '-w',
        type=int,
        required=True,
        help="Window size (integer)"
    )
    parser.add_argument(
        '--threshold', '-t',
        type=float,
        required=True,
        help="Threshold value (integer)"
    )
    parser.add_argument(
        '--file', '-f',
        type=str,
        required=True,
        help="Path to the input PQS file"
    )
    parser.add_argument(
        '--genome', '-g',
        type=str,
        required=True,
        help="Path to the input genome file (FASTA)"
    )
    parser.add_argument(
        '--ref', '-r',
        type=str,
        required=True,
        help="Path to the input genome file (FASTA)"
    )
    return parser.parse_args()

def main():
    args = parse_args()
    # Initialize the stats dict with the passed‐in values
    output_stats = {
        REF: args.ref,
        NPQS: 0,
        BP: 0,
        NGC: 0,
        PGC: 0.0,
        FRQ: 0.0,
        WINDOW: args.window,
        THRESHOLD: args.threshold
    }

    # Parse all sequences in the file
    for record in SeqIO.parse(args.genome, "fasta"):
        seq = record.seq.upper()
        output_stats[BP] += len(seq)
        output_stats[NGC] += seq.count("G") + seq.count("C")


    output_stats[NPQS] = process_txt_file(args.file)

    # Calculate percentage GC and frequency of PQS
    if output_stats[BP] > 0:
        output_stats[PGC] = (output_stats[NGC] / output_stats[BP]) * 100
        output_stats[FRQ] = 1000 * output_stats[NPQS] / output_stats[BP]

    # Print to terminal
    print(f"{REF},{NPQS},{BP},{NGC},{PGC},{FRQ},{WINDOW},{THRESHOLD}")
    for k, v in output_stats.items():
        print(f"{v}", end="")
        if k == THRESHOLD:
            break
        print(",", end="")

def process_txt_file(file_path):
    data = []
    current_sequence = None
    PQS = 0

    with open(file_path, 'r') as file:
        for line in file:
            line = line.strip()

            # If the line starts with '>', it indicates a new sequence section
            if line.startswith('>'):
                current_sequence = line[1:]  # Remove '>' and store the sequence identifier
            elif line and not line.startswith(START):
                # Process the data lines
                parts = line.split()
                if len(parts) == 5:  # Ensures correct number of columns
                    start, end, sequence, length, score = parts
                    data.append({
                        SEQ_ID: current_sequence,
                        START: int(start),
                        END: int(end),
                        SEQUENCE: sequence,
                        LENGTH: int(length),
                        SCORE: float(score)
                    })
                elif len(parts) == 6:  # Ensures correct number of columns
                    start, end, sequence, length, score, nbr = parts
                    data.append({
                        SEQ_ID: current_sequence,
                        START: int(start),
                        END: int(end),
                        SEQUENCE: sequence,
                        LENGTH: int(length),
                        SCORE: float(score)
                    })

                    PQS += int(nbr) # Save number of putative quadruplex sequences

    # Convert the list of dictionaries to a DataFrame
    #df = pd.DataFrame(data)
    return PQS

if __name__ == "__main__":
    main()

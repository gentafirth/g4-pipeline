#!/usr/bin/env python3

import argparse

def read_fasta(fasta_file):
    """Reads the whole FASTA file into a list of strings."""
    with open(fasta_file) as f:
        lines = f.readlines()
    return lines

def filter_gff_to_cds(gff_file):
    """Reads GFF file, keeps only header lines and CDS features."""
    cds_lines = []
    with open(gff_file) as f:
        for line in f:
            line = line.strip()
            if line.startswith("#") or line == "":
                cds_lines.append(line)
                continue
            parts = line.split("\t")
            if len(parts) > 2 and parts[2] == "CDS":
                cds_lines.append(line)
    return cds_lines

def write_roary_gff(cds_lines, fasta_lines, output_file):
    """Writes filtered GFF and genome FASTA into output GFF file."""
    with open(output_file, "w") as f:
        for line in cds_lines:
            f.write(line + "\n")
        f.write("##FASTA\n")
        for line in fasta_lines:
            f.write(line if line.endswith("\n") else line + "\n")

def main():
    parser = argparse.ArgumentParser(description="Prepare Prokka-style GFF for Roary by filtering CDS and appending FASTA.")
    parser.add_argument("--gff", required=True, help="Input GFF file")
    parser.add_argument("--fasta", required=True, help="Genome FASTA file")
    parser.add_argument("--output", required=True, help="Output Roary-ready GFF file")
    args = parser.parse_args()

    print("[+] Reading genome FASTA...")
    fasta_lines = read_fasta(args.fasta)

    print("[+] Filtering GFF to CDS only...")
    cds_lines = filter_gff_to_cds(args.gff)

    print("[+] Writing Roary-compatible GFF...")
    write_roary_gff(cds_lines, fasta_lines, args.output)

    print(f"[✓] Done! Output written to: {args.output}")

if __name__ == "__main__":
    main()

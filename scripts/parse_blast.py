#!/usr/bin/env python3
import argparse
import pandas as pd
import sys

def main():
    p = argparse.ArgumentParser(
        description="Parse BLAST TSV and build a matrix of (chrom,strand,start,end)."
    )
    p.add_argument("--blast-results", required=True,
                   help="BLAST outfmt6 with: qseqid sseqid pident length qlen slen evalue bitscore sstart send sstrand")
    p.add_argument("--identity", type=float, required=True,
                   help="Min percent identity")
    p.add_argument("--coverage", type=float, required=True,
                   help="Min query coverage (%)")
    p.add_argument("--output", required=True,
                   help="Output TSV matrix")
    args = p.parse_args()

    # 1) Read BLAST
    cols = ['qseqid','sseqid','pident','length','qlen','slen',
            'evalue','bitscore','sstart','send','sstrand']
    try:
        df = pd.read_csv(
            args.blast_results, sep="\t", header=None, names=cols,
            dtype={'qseqid': str, 'sseqid': str, 'sstrand': str}
        )
    except Exception as e:
        print(f"[ERROR] Cannot read BLAST results: {e}", file=sys.stderr)
        sys.exit(1)

    # 2) Filter by identity & coverage
    df['coverage'] = df['length'] / df['qlen'] * 100
    df = df[(df.pident >= args.identity) & (df.coverage >= args.coverage)]
    if df.empty:
        print("[WARN] No hits passed thresholds", file=sys.stderr)
        # write only header
        pd.DataFrame().to_csv(args.output, sep="\t")
        sys.exit(0)

    # 3) Parse genome_id and contig header
    # sseqid is "GENOMEID|contig header..."
    split = df['sseqid'].str.split('|', n=1, expand=True)
    df['genome_id']    = split[0]
    df['contig_header']= split[1]

    # 4) Extract just the chromosome name (first token of contig_header)
    df['chromosome'] = df['contig_header'].str.split(r'\s+', n=1).str[0]

    # 5) Build lists
    queries = sorted(df['qseqid'].unique())
    genomes = sorted(df['genome_id'].unique())

    # 6) Init empty matrix
    mat = pd.DataFrame(index=queries, columns=genomes, dtype=str).fillna('')

    # 7) Fill with "(chrom,strand,start,end)"
    for _, r in df.iterrows():
        tpl = f"({r.chromosome},{r.sstrand},{int(r.sstart)},{int(r.send)})"
        mat.at[r.qseqid, r.genome_id] = tpl

    # 8) Save with custom index label
    mat.to_csv(
        args.output,
        sep="\t",
        index_label="Reference"
    )

    print(f"[OK] Wrote {args.output}: {len(queries)} × {len(genomes)}")

if __name__ == "__main__":
    main()

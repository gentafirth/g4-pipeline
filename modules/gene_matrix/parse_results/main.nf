process PARSE_RESULTS {
    tag "Parsing BLAST results"
    label 'process_low'
    
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path blast_results
    path genome_files

    output:
    path "gene_presence_absence.tsv", emit: matrix

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/usr/bin/env python3
    
    import pandas as pd
    import sys
    from pathlib import Path
    
    # Parameters
    identity_threshold = ${params.identity}
    coverage_threshold = ${params.coverage}
    
    print(f"Parsing BLAST results with thresholds:")
    print(f"  Identity >= {identity_threshold}%")
    print(f"  Coverage >= {coverage_threshold}%")
    
    # Read BLAST results
    blast_df = pd.read_csv("${blast_results}", sep='\\t', header=None,
                          names=['qseqid', 'sseqid', 'pident', 'length', 'qlen', 'slen', 'evalue', 'bitscore'])
    
    print(f"Total BLAST hits: {len(blast_df)}")
    
    # Calculate coverage
    blast_df['coverage'] = (blast_df['length'] / blast_df['qlen']) * 100
    
    # Apply thresholds
    filtered_df = blast_df[
        (blast_df['pident'] >= identity_threshold) & 
        (blast_df['coverage'] >= coverage_threshold)
    ]
    
    print(f"Hits passing thresholds: {len(filtered_df)}")
    
    # Extract genome IDs from sseqid (split on first "|")
    filtered_df['genome_id'] = filtered_df['sseqid'].str.split('|').str[0]
    
    # Get all genome IDs from input files
    genome_files = "${genome_files}".split()
    all_genome_ids = [Path(f).stem for f in genome_files]
    all_genome_ids.sort()
    
    # Get all query IDs
    all_query_ids = sorted(filtered_df['qseqid'].unique())
    
    print(f"Queries: {len(all_query_ids)}")
    print(f"Genomes: {len(all_genome_ids)}")
    
    # Create presence/absence matrix
    matrix = pd.DataFrame(index=all_query_ids, columns=all_genome_ids, dtype=str)
    matrix = matrix.fillna('')  # Fill with empty strings
    
    # Fill matrix with gene IDs where hits exist
    for _, row in filtered_df.iterrows():
        query_id = row['qseqid']
        genome_id = row['genome_id']
        if genome_id in all_genome_ids:
            matrix.loc[query_id, genome_id] = query_id
    
    # Save matrix
    matrix.to_csv('gene_presence_absence.tsv', sep='\\t')
    
    print("Gene presence/absence matrix created successfully!")
    print(f"Matrix dimensions: {matrix.shape[0]} queries x {matrix.shape[1]} genomes")
    
    # Summary statistics
    presence_counts = (matrix != '').sum(axis=1)
    print("\\nPresence summary:")
    for query_id in all_query_ids:
        count = presence_counts[query_id]
        percentage = (count / len(all_genome_ids)) * 100
        print(f"  {query_id}: {count}/{len(all_genome_ids)} genomes ({percentage:.1f}%)")
    """
}
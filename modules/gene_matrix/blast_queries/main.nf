process BLAST_QUERIES {
    tag "Running BLAST search"
    label 'process_high'

    input:
    path query_file
    path blast_db

    output:
    path "blast_results.tsv", emit: blast_results

    when:
    task.ext.when == null || task.ext.when

    script:
    def blast_cmd = params.blast_type == 'blastp' ? 'blastp' : 'blastn'
  """
  ${blast_cmd} \
    -query ${query_file} \
    -db genomes_db \
    -out blast_results.tsv \
    -outfmt "6 qseqid sseqid pident length qlen slen evalue bitscore sstart send sstrand" \
    -evalue ${params.evalue} \
    -max_target_seqs ${params.max_target_seqs} \
    -num_threads ${task.cpus}

    rm ${query_file}
    rm ${blast_db}
  """
}

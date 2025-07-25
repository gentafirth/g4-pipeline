process PARSE_RESULTS {
    tag "Parsing BLAST results"
    label 'process_low'

    publishDir "${params.outdir}/${params.species}", mode: 'copy'

    input:
    path blast_results
    path parse_blast

    output:
    path "gene_presence_absence.tsv", emit: matrix

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    python3 ${parse_blast} \
      --blast-results blast_results.tsv \
      --identity ${params.identity} \
      --coverage ${params.coverage} \
      --output gene_presence_absence.tsv
    """
}

process PARSE_RESULTS {
    tag "Parsing BLAST results"
    label 'process_low'

    publishDir "${params.outdir}/${params.species}_${params.thresh_value}", mode: 'copy', pattern: "*_blast_results.tsv"

    input:
    path blast_results
    path parse_blast

    output:
        path "${params.species}_${params.thresh_value}_blast_results.tsv", emit: matrix
        path "separated/*.tsv", emit: separated_files

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    mkdir separated/
    python3 ${parse_blast} \
      --blast-results blast_results.tsv \
      --identity ${params.identity} \
      --coverage ${params.coverage} \
      --output ${params.species}_${params.thresh_value}_blast_results.tsv
    """
}

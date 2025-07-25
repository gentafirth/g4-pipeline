process MERGE_SUMMARIES {
    tag "Merging G4Hunter summary results"
    label 'process_low'

    publishDir "${params.outdir}/${params.species}", mode: 'copy'

    input:
    path result_files
    path merge_script

    output:
    path "${params.species}_results.csv", emit: merged_results

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    tmp_list=\$(mktemp)
    for f in ${result_files}; do
        echo \$f
    done > \$tmp_list
    python ${merge_script} --listfile \$tmp_list -o "${params.species}_results.csv" ${args}
    rm \$tmp_list
    """

    stub:
    """
    touch ${params.species}_results.csv
    """
}

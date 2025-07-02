process MERGE_SUMMARIES {
    tag "Merging G4Hunter summary results"
    label 'process_low'
    
    publishDir "${params.outdir}", mode: 'copy'

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
    echo "Processing files: ${result_files}"
    python '${merge_script}' -l "${result_files}" -o ${params.species}_results.csv ${args}
    """

    stub:
    """
    touch ${params.species}_results.csv
    """
}
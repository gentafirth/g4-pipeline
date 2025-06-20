process G4HUNTER {
    tag "G4Hunter: ${ref}"
    label 'process_medium'
    
    publishDir "${params.outdir}/${fasta_file.baseName}_${params.thresh_value}", mode: 'copy', pattern: "GC*.txt"

    input:
    tuple path(fasta_file), val(ref)

    output:
    path "GC*.txt", emit: g4results
    path "results_${ref}.csv", emit: g4summary

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo "Running G4Hunter on ${fasta_file}"
    python ${params.g4script} \\
        -i ${fasta_file} \\
        -o . \\
        -w ${params.window} \\
        -s ${params.thresh_value} \\
        ${args}
    
    mv Results_*/*-Merged.txt .
    rm -r Results_*/
    
    python ${params.g4dataproc} \\
        -w ${params.window} \\
        -t ${params.thresh_value} \\
        -f *-Merged.txt \\
        -g ${fasta_file} \\
        -r ${ref} > results_${ref}.csv
    """

    stub:
    """
    touch GC_${ref}.txt
    touch results_${ref}.csv
    """
}
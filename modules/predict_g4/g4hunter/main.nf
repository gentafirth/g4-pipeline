process G4HUNTER {
    tag "G4Hunter: ${ref}"
    label 'process_medium'
    
    publishDir "${params.outdir}/${fasta_file.baseName}_${params.thresh_value}", mode: 'copy', pattern: "GC*.bed"

    input:
    tuple path(fasta_file), path(gff_file), val(ref)

    output:
    path "GC*.txt", emit: g4results
    path "results_${ref}.csv", emit: g4summary
    tuple path("GC_${ref}.bed"), path(gff_file), val(ref), emit: g4hunterbed // Change this variable name

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    echo "Running G4Hunter on ${fasta_file}"
    python '${params.g4script}' \\
        -i ${fasta_file} \\
        -o . \\
        -w ${params.window} \\
        -s ${params.thresh_value} \\
        ${args}
    
    mv Results_*/*-Merged.txt .
    rm -r Results_*/
    
    python '${params.g4dataproc}' \\
        -w ${params.window} \\
        -t ${params.thresh_value} \\
        -f *-Merged.txt \\
        -g ${fasta_file} \\
        -r ${ref} > results_${ref}.csv
    
    python '${params.g4hunter2bed}' \\
        --input *-Merged.txt \\
        --output GC_${ref}.bed
    """

    stub:
    """
    touch GC_${ref}.txt
    touch results_${ref}.csv
    touch GC_${ref}.bed
    """
}
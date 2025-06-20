process runG4Hunter {

    publishDir "results/${fasta_file.baseName}_${params.thresh_value}", mode: 'copy'

    input:
        tuple path(fasta_file), val(ref)

    output:
        path "GC*.txt", emit: g4results_ch                      // Published by publishDir
        path "results_${ref}.csv", emit: g4summary_ch, hidden: true    // Not published by publishDir

    script:
    """
    echo "Running G4Hunter on ${fasta_file}"
    python ${params.g4script} -i ${fasta_file} -o . -w ${params.window} -s ${params.thresh_value}
    mv Results_*/*-Merged.txt .
    rm -r Results_*/
    python ${params.g4dataproc} -w ${params.window} -t ${params.thresh_value} -f *-Merged.txt -g ${fasta_file} -r ${ref}> results_${ref}.csv
    """
}
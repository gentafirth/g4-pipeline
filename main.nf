#!/usr/bin/env nextflow
nextflow.enable.dsl=2

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

process mergeResults {

    publishDir "results/", mode: 'copy'

    input:
    path result_files
    path merge_script

    output:
    path "${params.species}_results.csv"

    script:
    """
    echo "${result_files}"
    python ${merge_script} -l "${result_files}" -o ${params.species}_results.csv
    """
}
workflow {

    genomes_ch = Channel
        .fromPath(params.genomes, checkIfExists: true)
        .map { fasta ->
      //
      // In your tree the fasta is at:
      //   genomes/K_pneumoniae/GCF_xxx/…/GCF_xxx_ASM…_genomic.fna
      // so three levels up is the GCF_xxx folder:
      //
      def ref = fasta.getParent().getName()
      tuple(fasta, ref)
    }

    // genomes_ch.view()
    results = runG4Hunter(genomes_ch)
    
    merge_script = Channel.fromPath(params.g4mergenappend, checkIfExists: true) // Manually parsing python script
    mergeResults(results.g4summary_ch.collect(), merge_script)

    // results.g4summary_ch.view()

}

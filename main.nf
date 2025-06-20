#!/usr/bin/env nextflow
nextflow.enable.dsl=2



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

include { runG4Hunter } from 'g4hunter/runG4Hunter'

workflow {

    genomes_ch = Channel
        .fromPath(params.genomes, checkIfExists: true)
        .map { fasta ->
      //
      // In your tree the fasta is at:
      // genomes/K_pneumoniae/GCF_xxx/…/GCF_xxx_ASM…_genomic.fna
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

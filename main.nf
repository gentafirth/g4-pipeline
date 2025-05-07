#!/usr/bin/env nextflow
nextflow.enable.dsl=2

process runG4Hunter {
    tag "running G4Hunter.py on each genome"
    cache 'lenient' // Allowing for timestamp leniency. Look into how this works. This is really weird. I can't think of what is updating an input file time stamp
    conda 'g4hunter_env.yml'

    publishDir "results/${fasta_file.baseName}_${params.thresh_value}", mode: 'copy'

    input:
        tuple path(fasta_file), val(ref)

    output:
        path "GC*.txt", emit: g4results_ch                      // Published by publishDir
        path "results_${ref}.csv", emit: g4summary_ch, hidden: true    // Not published by publishDir

    script:
    """
    echo "Running G4Hunter on ${fasta_file}"
    python ${workflow.projectDir}/${params.g4script} -i ${fasta_file} -o . -w ${params.window} -s ${params.thresh_value}
    mv Results_*/*-Merged.txt .
    rm -r Results_*/
    python ${workflow.projectDir}/${params.g4dataproc} -w ${params.window} -t ${params.thresh_value} -f *-Merged.txt -g ${fasta_file} -r ${ref}> results_${ref}.csv
    """
}

process mergeResults {
    tag "merging results.csv files and appending strain"

    publishDir "results/", mode: 'copy'

    input:
    path result_files

    output:
    path "${params.species}_results.csv"

    script:
    """
    echo "${result_files}"
    python ${workflow.projectDir}/${params.g4mergenappend} -l "${result_files}" -o ${params.species}_results.csv
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
      def ref = fasta.getParent().getParent().getParent().getParent().getName()
      tuple(fasta, ref)
    }

    // genomes_ch.view()
    results = runG4Hunter(genomes_ch)

    mergeResults(results.g4summary_ch.collect())

    // results.g4summary_ch.view()

}

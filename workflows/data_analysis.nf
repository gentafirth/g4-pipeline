/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLOTTING          } from '../modules/data_analysis/plotting/main'
include { MERGE_SUMMARIES   } from '../modules/data_analysis/merge_summaries/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: DATA_ANALYSIS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DATA_ANALYSIS {

    take:
    fasta_bed_gff_tuple // channel: [ path(fasta), path(bed), val(ref) ]
    summary_csvs  // channel: [ path(csv) ]
    presence_absence_matrix

    main:

    //
    // MODULE: Merge summary results
    //
    merge_script = Channel.fromPath(params.g4mergenappend, checkIfExists: true)
    MERGE_SUMMARIES (
        summary_csvs.collect(),
        merge_script
    )

    //
    // MODULE: Plot
    //
    analysis_script = Channel.fromPath(params.analysisscript, checkIfExists: true)
    PLOTTING (
        fasta_bed_gff_tuple.map{ fasta, bed, ref -> bed }.collect(),
        presence_absence_matrix,
        analysis_script
    )

    emit:
    outputtxt      = PLOTTING.out.pqs_heatmap
    merged_results = MERGE_SUMMARIES.out.merged_results
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLOTTING } from '../modules/data_analysis/plotting/main'
include { MERGE_SUMMARIES } from '../modules/data_analysis/merge_summaries/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: DATA_ANALYSIS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DATA_ANALYSIS {
    
    take:
    bed_gff_pairs // channel: [ path(bed), path(gff), val(ref) ]
    summary_csvs  // channel: [ path(csv) ]
    
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
        bed_gff_pairs,
        analysis_script)
    
    emit:
    outputtxt      = PLOTTING.out.outputtxt
    merged_results = MERGE_SUMMARIES.out.merged_results
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLOTTING              } from '../modules/data_analysis/plotting/main'
include { MERGE_SUMMARIES       } from '../modules/data_analysis/merge_summaries/main'

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
    separated_blast_files // channel: [ path(separated/*.tsv) ]

    main:
    merged_results = null
    if ( params.bed_files == '' ){
        //
        // MODULE: Merge summary results
        //
        merge_script = Channel.fromPath(params.g4mergenappend, checkIfExists: true)
        MERGE_SUMMARIES (
            summary_csvs.collect(),
            merge_script
        )
        merged_results = MERGE_SUMMARIES.out.merged_results
    } else {
        merged_results = summary_csvs
    }
    //
    // MODULE: Plot - Run for each separated TSV file
    //
    analysis_script = Channel.fromPath(params.analysisscript, checkIfExists: true)
    bed_files_collection = fasta_bed_gff_tuple.map{ fasta, bed, ref -> bed }.collect()

    plotting_input = separated_blast_files
        .flatten()
        .combine(bed_files_collection.map { beds -> [beds] })  // Wrap in extra list to prevent flattening
        .combine(analysis_script)

    PLOTTING (
        plotting_input.map { tsv_file, bed_list, script -> bed_list },
        plotting_input.map { tsv_file, bed_list, script -> tsv_file },
        plotting_input.map { tsv_file, bed_list, script -> script }
    )

    emit:
    pqs_heatmaps   = PLOTTING.out.pqs_heatmap.collect()
    merged_results
}

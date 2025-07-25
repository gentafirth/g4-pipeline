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

    // Prepare bed files collection (reused for each plotting run)
    bed_files_collection = fasta_bed_gff_tuple.map{ fasta, bed, ref -> bed }.collect()

    // Flatten separated files and run PLOTTING for each one
    separated_blast_files
        .flatten()
        .combine(bed_files_collection)
        .combine(analysis_script)
        .set { plotting_input }

    PLOTTING (
        plotting_input.map { tsv_file, bed_collection, script -> bed_collection },
        plotting_input.map { tsv_file, bed_collection, script -> tsv_file },
        plotting_input.map { tsv_file, bed_collection, script -> script }
    )

    emit:
    pqs_heatmaps   = PLOTTING.out.pqs_heatmap.collect()
    merged_results = MERGE_SUMMARIES.out.merged_results
}

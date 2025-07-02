/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PLOTTING          } from '../modules/data_analysis/plotting/main'
include { MERGE_SUMMARIES   } from '../modules/data_analysis/merge_summaries/main'
include { COMBINE_GFF_FASTA } from '../modules/data_analysis/combine_gff_fasta/main'
include { CLUSTER_GENES     } from '../modules/data_analysis/cluster_genes/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: DATA_ANALYSIS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow DATA_ANALYSIS {
    
    take:
    fasta_bed_gff_tuple // channel: [ path(fasta), path(bed), path(gff), val(ref) ]
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
    // MODULE: Combine GFF and AA files per strain (parallel processing)
    //
    addsequence_script = Channel.fromPath(params.addsequence, checkIfExists: true)
    COMBINE_GFF_FASTA ( fasta_bed_gff_tuple.combine( addsequence_script ) )
    
    //
    // MODULE: Cluster genes using all combined GFF3 files
    //
    CLUSTER_GENES ( COMBINE_GFF_FASTA.out.combined_gff.collect() )

    //
    // MODULE: Plot
    //
    analysis_script = Channel.fromPath(params.analysisscript, checkIfExists: true)
    PLOTTING (
        fasta_bed_gff_tuple.combine( analysis_script )
    )
    
    emit:
    outputtxt      = PLOTTING.out.outputtxt
    merged_results = MERGE_SUMMARIES.out.merged_results
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { G4HUNTER      } from '../modules/g4pipeline/g4hunter/main'
include { MERGE_RESULTS } from '../modules/g4pipeline/merge_results/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: G4PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow G4PIPELINE {
    
    take:
    genomes // channel: [ path(fasta), val(ref) ]
    
    main:
    
    //
    // MODULE: Run G4Hunter analysis
    //
    G4HUNTER ( genomes )
    
    //
    // MODULE: Merge results
    //
    merge_script = Channel.fromPath(params.g4mergenappend, checkIfExists: true)
    MERGE_RESULTS ( 
        G4HUNTER.out.g4summary.collect(), 
        merge_script 
    )
    
    emit:
    g4results      = G4HUNTER.out.g4results      // channel: [ path(txt) ]
    g4summary      = G4HUNTER.out.g4summary      // channel: [ path(csv) ]
    merged_results = MERGE_RESULTS.out.merged_results // channel: [ path(csv) ]
}
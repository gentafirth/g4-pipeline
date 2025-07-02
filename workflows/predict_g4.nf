/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { G4HUNTER      } from '../modules/predict_g4/g4hunter/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: PREDICT_G4
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PREDICT_G4 {
    
    take:
    genomes // channel: [ path(fasta), path(gff), val(ref) ]
    
    main:
    
    //
    // MODULE: Run G4Hunter analysis
    //
    G4HUNTER ( genomes )
    
    emit:
    g4results      = G4HUNTER.out.g4results      // channel: [ path(txt) ]
    g4summary      = G4HUNTER.out.g4summary      // channel: [ path(csv) ]
    fasta_bed_gff_tuple    = G4HUNTER.out.fasta_bed_gff_tuple // channel: [ path(csv) ]
}
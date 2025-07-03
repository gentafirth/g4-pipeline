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
    genomes // channel: [ path(fasta), val(ref) ]
    
    main:
    
    //
    // MODULE: Run G4Hunter analysis
    //
    g4script = Channel.fromPath(params.g4script, checkIfExists: true)
    g4dataproc = Channel.fromPath(params.g4dataproc, checkIfExists: true)
    g4hunter2bed = Channel.fromPath(params.g4hunter2bed, checkIfExists: true)
    // Combine all scripts into a single tuple
    scripts_tuple = g4script.combine(g4dataproc).combine(g4hunter2bed)
    // Then combine with genomes
    G4HUNTER(genomes.combine(scripts_tuple))
    
    emit:
    g4results      = G4HUNTER.out.g4results      // channel: [ path(txt) ]
    g4summary      = G4HUNTER.out.g4summary      // channel: [ path(csv) ]
    fasta_bed_gff_tuple    = G4HUNTER.out.fasta_bed_gff_tuple // channel: [ path(csv) ]
}
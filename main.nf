#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { PREDICT_G4    } from './workflows/predict_g4'
include { DATA_ANALYSIS } from './workflows/data_analysis.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    //
    // Create input channel from genomes with paired GFF and protein files
    //
    genomes_ch = Channel
        .fromPath(params.genomes, checkIfExists: true)
        .map { fasta ->
            // Extract reference name from path structure
            // genomes/K_pneumoniae/GCF_xxx/…/GCF_xxx_ASM…_genomic.fna
            def ref = fasta.getParent().getName()
            
            // Find corresponding .gff file in the same directory
            def gff_pattern = fasta.getParent().toString() + "/*.gff*"
            def gff_files = file(gff_pattern, type: 'file')
            def gff_file = gff_files.size() > 0 ? gff_files[0] : null
            
            // Return tuple with fasta, gff, protein (or null), and reference
            tuple(fasta, gff_file, ref)
        }

    //
    // WORKFLOW: Run G4Hunter pipeline
    //
    PREDICT_G4 ( genomes_ch )
    
    //
    // WORKFLOW: Run Data Analysis (Optional)
    //
    if ( params.run_analysis ) {
        DATA_ANALYSIS ( 
            PREDICT_G4.out.fasta_bed_gff_tuple,
            PREDICT_G4.out.g4summary
        )
    }
}
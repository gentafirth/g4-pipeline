#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GENE_MATRIX        } from './workflows/gene_matrix.nf'
include { PREDICT_G4         } from './workflows/predict_g4'
include { DATA_ANALYSIS      } from './workflows/data_analysis.nf'

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
            
            // Return tuple with fasta, gff, and reference
            tuple(fasta, ref)
        }

    // Channel for query file
    query_file_ch = Channel
        .fromPath(params.query_fasta, checkIfExists: true)

    //
    // WORKFLOW: Run Gene Presence/Absence Analysis
    //
    GENE_MATRIX ( 
        genomes_ch,
        query_file_ch
    )

    //
    // WORKFLOW: Run G4 prediction pipeline
    //
    PREDICT_G4 ( genomes_ch )
    
    //
    // WORKFLOW: Run Data Analysis (Optional)
    //
    if ( params.run_analysis ) {
        DATA_ANALYSIS ( 
            PREDICT_G4.out.fasta_bed_gff_tuple,
            PREDICT_G4.out.g4summary,
            GENE_MATRIX.out.presence_absence_matrix
        )
    }
}
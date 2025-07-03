#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { GENERATE_PANGENOME } from './workflows/generate_pangenome.nf'
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
            
            // Find corresponding .gff file in the same directory
            def gff_pattern = fasta.getParent().toString() + "/*.gff*"
            def gff_files = file(gff_pattern, type: 'file')
            def gff_file = gff_files.size() > 0 ? gff_files[0] : null
            
            // Return tuple with fasta, gff, protein (or null), and reference
            tuple(fasta, gff_file, ref)
        }
        
    //
    // WORKFLOW: Generate Pangenome Reference
    //
    if ( params.pangenome_ref ) {
        log.info "Using provided pangenome reference: ${params.pan_genome_ref}"
        log.info "This method is not recommended. Please use pipeline generated pangenome reference using --generate_pangenome"
        pan_genome_ch = Channel.fromPath(params.pan_genome_ref)
    } else if ( params.generate_pangenome ) {
        log.info "Forcful generating new pan genome reference from input genomes"
        if ( file( params.pangenome_path ).exists() ) {
            log.info "Existing pangenome reference folder was found and deleted"
            file(params.pangenome_path).delete()
        }
        pan_genome_ch = GENERATE_PANGENOME(genomes_ch)
    } else if ( file( params.pangenome_path ).exists() ) {
        log.info "Found existing pangenome reference: ${params.pangenome_path}"
        log.info "To regenerate, delete the file or use --generate_pangenome"
        pan_genome_ch = Channel.fromPath(params.pangenome_path)
    } else {
        log.info "No pangenome reference was detected and no pangenome was provided"
        log.info "Generating new pan genome reference from input genomes"
        pan_genome_ch = GENERATE_PANGENOME(genomes_ch)
    }

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
            PREDICT_G4.out.g4summary
        )
    }
}
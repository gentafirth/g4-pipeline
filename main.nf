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
            // Strip extension only, keep full accession+ASM part
            def ref = fasta.getBaseName().replaceFirst(/\.fna$/, '')
            tuple(fasta, ref)
        }


    // Channel for query file
    query_file_ch = Channel
        .fromPath(params.query_fasta, checkIfExists: true)

    //
    // WORKFLOW: Run Gene Presence/Absence Analysis
    //
    if ( params.run_analysis ) {
        GENE_MATRIX (
            genomes_ch,
            query_file_ch
        )
    }

    fasta_bed_gff_tuple = null
    g4_summary = null
    if ( params.bed_files == ''){
        //
        // WORKFLOW: Run G4 prediction pipeline
        //
        PREDICT_G4 ( genomes_ch )
        fasta_bed_gff_tuple = PREDICT_G4.out.fasta_bed_gff_tuple
        g4_summary = PREDICT_G4.out.g4summary
    } else {
        //
        // User provided BED files in a directory. Build channels that mimic outputs of PREDICT_G4.
        //
        // Beds live in: <params.bed_files>/putative_peaks/*.bed
        // Summary file(s) live in: <params.bed_files>/*_results.csv
        //

        // channel of bed files keyed by basename (without .bed)
        beds_kv = Channel
            .fromPath("${params.bed_files}/putative_peaks/*.bed", checkIfExists: true)
            .map { bedFile ->
                def base = bedFile.getName().replaceFirst(/\.bed$/, '')
                tuple(base, bedFile)
            }

        // convert genomes_ch (fasta, ref) -> (ref, fasta)
        genomes_kv = genomes_ch
            .map { fasta, ref -> tuple(ref, fasta) }

        // join genomes with bed files by ref -> emit (fasta, bedFile, ref)
        fasta_bed_gff_tuple = genomes_kv
            .join(beds_kv)
            .map { ref, fasta, bedFile -> tuple(fasta, bedFile, ref) }
        g4_summary = Channel
            .fromPath("${params.bed_files}/*_results.csv", checkIfExists: true)
    }
    //
    // WORKFLOW: Run Data Analysis (Optional)
    //
    if ( params.run_analysis ) {
        DATA_ANALYSIS (
            fasta_bed_gff_tuple,
            g4_summary,
            GENE_MATRIX.out.presence_absence_matrix,
            GENE_MATRIX.out.separated_blast_files
        )
    }
}

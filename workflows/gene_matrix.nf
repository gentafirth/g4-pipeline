/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CONCAT_GENOMES } from '../modules/gene_matrix/concat_genomes/main'
include { MAKE_BLAST_DB  } from '../modules/gene_matrix/make_blast_db/main'
include { BLAST_QUERIES  } from '../modules/gene_matrix/blast_queries/main'
include { PARSE_RESULTS  } from '../modules/gene_matrix/parse_results/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENE_MATRIX {
    take:
    genome_files    // channel: [ tuple(path(fasta), val(ref)), ... ]
    query_file      // channel: path(queries.fna)

    main:
    //
    // Extract fasta and gff files from tuples for concatenation
    //
    fasta_files_ch = genome_files.map { fasta, ref -> fasta }

    //
    // MODULE: Concatenate all genome files with prefixed headers
    //
    CONCAT_GENOMES ( fasta_files_ch.collect() )

    //
    // MODULE: Create BLAST database from concatenated genomes
    //
    MAKE_BLAST_DB ( CONCAT_GENOMES.out.concatenated_fasta )

    //
    // MODULE: Run BLAST search
    //
    BLAST_QUERIES ( 
        query_file,
        MAKE_BLAST_DB.out.blast_db
    )

    //
    // MODULE: Parse BLAST results and create presence/absence matrix
    //
    parse_blast = Channel.fromPath(params.parse_blast, checkIfExists: true)
    PARSE_RESULTS ( 
        BLAST_QUERIES.out.blast_results,
        parse_blast
    )

    emit:
    presence_absence_matrix = PARSE_RESULTS.out.matrix
    blast_results          = BLAST_QUERIES.out.blast_results
    concatenated_genomes   = CONCAT_GENOMES.out.concatenated_fasta
}
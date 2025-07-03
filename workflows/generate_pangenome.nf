/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { COMBINE_GFF_FASTA } from '../modules/generate_pangenome/combine_gff_fasta/main'
include { CLUSTER_GENES     } from '../modules/generate_pangenome/cluster_genes/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    WORKFLOW: GENERATE_PANGENOME
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENERATE_PANGENOME {
    
    take:
    genomes // channel: [ path(fasta), path(gff), val(ref) ]
    
    main:
    //
    // MODULE: Combine GFF and AA files per strain (parallel processing)
    //
    addsequence_script = Channel.fromPath(params.addsequence, checkIfExists: true)
    COMBINE_GFF_FASTA ( genomes.combine( addsequence_script ) )
    
    //
    // MODULE: Cluster genes using all combined GFF3 files
    //
    CLUSTER_GENES ( COMBINE_GFF_FASTA.out.combined_gff.collect() )
    
    emit:
    pangenome_reference = CLUSTER_GENES.out.pangenome_reference
}
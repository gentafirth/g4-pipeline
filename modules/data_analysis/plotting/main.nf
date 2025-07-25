process PLOTTING {
    tag "Analysing "
    label 'process_medium'

    publishDir "${params.outdir}/${params.species}/", mode: 'copy', pattern: "*PQSs_heatmap.pdf"

    input:
    path putative_g4_bed
    path matrix
    path analysis_script

    output:
    path "PQSs_heatmap.pdf", emit: pqs_heatmap

    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    """
    # Run analysis with BED file and GFF file
    Rscript ${analysis_script}
    """
}

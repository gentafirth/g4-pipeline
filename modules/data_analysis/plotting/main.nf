process PLOTTING {
    tag "Analysing ${matrix.baseName}"
    label 'process_low'

    publishDir "${params.outdir}/${params.species}_${params.thresh_value}/plots/", mode: 'copy', pattern: "*_PQSs_heatmap.pdf"

    input:
    path putative_g4_bed
    path matrix
    path analysis_script

    output:
    path "${matrix.baseName}_PQSs_heatmap.pdf", emit: pqs_heatmap

    script:
    """
    # Run analysis with BED files and TSV file
    Rscript ${analysis_script} ${matrix}

    # Rename output to include TSV basename
    #if [ -f "PQSs_heatmap.pdf" ]; then
    #    mv PQSs_heatmap.pdf ${matrix.baseName}_PQSs_heatmap.pdf
    #fi
    """
}

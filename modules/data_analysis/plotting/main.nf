process PLOTTING {
    tag "Analysing ${matrix.baseName}"
    label 'process_medium'

    publishDir "${params.outdir}/${params.species}_${params.thresh_value}/plots/", mode: 'copy', pattern: "*_PQSs_heatmap*.png"

    input:
    path putative_g4_bed
    path matrix
    path analysis_script

    output:
    path "${matrix.baseName}_PQSs_heatmap*.png", emit: pqs_heatmap

    script:
    """
    # Run analysis with BED files and TSV file
    Rscript ${analysis_script} ${matrix}

    rm ${putative_g4_bed}
    rm ${matrix}
    rm ${analysis_script}
    rm *.pdf
    """
}

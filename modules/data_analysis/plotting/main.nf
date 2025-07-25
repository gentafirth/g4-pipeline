process PLOTTING {
    tag "Analysing ${matrix.baseName}"
    label 'process_medium'

    publishDir "${params.outdir}/${params.species}/plots/", mode: 'copy', pattern: "*_PQSs_heatmap.pdf"

    input:
    path putative_g4_bed
    path matrix
    path analysis_script

    output:
    path "${matrix.baseName}_PQSs_heatmap.pdf", emit: pqs_heatmap

    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    """
    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    Rscript ${analysis_script}

    if [ -f "PQSs_heatmap.pdf" ]; then
        mv PQSs_heatmap.pdf ${matrix.baseName}_PQSs_heatmap.pdf
    fi
    """
}

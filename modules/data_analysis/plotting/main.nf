process PLOTTING {
    tag "Analysing "
    label 'process_medium'

    input:
    path putative_g4_bed
    path matrix
    path analysis_script

    output:
    path "output.txt", emit: outputtxt

    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    """
    # Run analysis with BED file and GFF file
    Rscript ${analysis_script}
    echo "Analysis completed for with BED: ${putative_g4_bed}" > output.txt
    """
}
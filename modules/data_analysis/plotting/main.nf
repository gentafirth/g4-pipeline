process PLOTTING {
    tag "Analysing ${ref}"
    label 'process_medium'

    input:
    tuple path(putative_g4_bed), path(gff_file), path(protein_file), val(ref), path(analysis_script) // BED file with paired GFF and protein files and analysis script

    output:
    path "output_${ref}.txt", emit: outputtxt

    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    """
    # Run analysis with BED file and GFF file
    Rscript ${analysis_script} -i ${putative_g4_bed}
    echo "Analysis completed for ${ref} with BED: ${putative_g4_bed}" > output_${ref}.txt
    """
}
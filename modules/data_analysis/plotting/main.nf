process PLOTTING {
    tag "Analysing"
    label 'process_medium'

    input:
    path putative_g4_bed // Path to G4HUNTER prediction results
    path analysis_script // Path to R script

    output:
    path "output.txt", emit: outputtxt

    script:
    """
    Rscript ${analysis_script} -i ${putative_g4_bed}
    echo "new test" > output.txt
    """
}
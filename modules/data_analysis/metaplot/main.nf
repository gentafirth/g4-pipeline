process METAPLOT {
    tag "Analysing"
    label 'process_medium'

    input:
    path merged_results // Path to G4HUNTER prediction results

    output:
    path "output.txt", emit: outputtxt

    script:
    """
    head ${merged_results} > output.txt
    """
}
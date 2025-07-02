process CLUSTER_GENES {
    tag "Clustering genes using Roary"
    label 'process_high'

    input:
    path gff3_files // List of GFF3 files from COMBINE_GFF_FASTA

    output:
    path "clustered_gene_dictionary.csv", emit: clustered_gene_dictionary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    echo "Hello Process"
    roary -f ./roary_output -e -n -v ${gff3_files}
    touch clustered_gene_dictionary.csv
    """

}
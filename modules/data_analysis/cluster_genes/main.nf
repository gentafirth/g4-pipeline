process CLUSTER_GENES {
    tag "Clustering genes using Roary"
    label 'process_low'

    input:
    tuple path(gff_file), path(protein_file), val(temporary)

    output:
    path "clustered_gene_dictionary.csv", emit: clustered_gene_dictionary

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    echo "Hello Process"
    echo ${gff_file} > clustered_gene_dictionary.csv
    """

}
process CLUSTER_GENES {
    tag "Clustering genes using Roary"
    label 'process_high'
    publishDir "${params.pangenome_path}/references", mode: 'copy', enabled: true

    input:
    path gff3_files // List of GFF3 files from COMBINE_GFF_FASTA

    output:
    path "roary_output/gene_presence_absence.csv", emit: pangenome_reference
    path "pangenome_info.json", emit: info

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    echo "Hello Process"
    roary -f ./roary_output -e -n -v ${gff3_files}
    # Create info file for tracking
    cat > pangenome_info.json << EOF
    {
        "generated_date": "\$(date -Iseconds)",
        "input_genomes": [\$(echo '${gff3_files}' | tr ' ' '\n' | sed 's/.*/"&"/' | paste -sd,)],
        "genome_count": ${gff3_files.size()},
        "nextflow_session": "${workflow.sessionId}",
        "pipeline_version": "${workflow.manifest.version ?: 'dev'}"
    }
    EOF
    """

}
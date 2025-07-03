process COMBINE_GFF_FASTA {
    tag "Combining GFF and AA for ${ref}"
    label 'process_low'

    input:
    tuple path(fasta_file), path(gff_file), val(ref), path(addsequence_script) // channel: [ path(fasta), path(gff), val(ref), path(addsequence_script) ]

    output:
    path("${ref}.gff"), emit: combined_gff

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    grep -E '^#|[[:alnum:]\\.\\-]+[[:space:]]+[[:alnum:]\\.\\-]+[[:space:]]+CDS' ${gff_file} > ${ref}.gff

    echo '##FASTA' >> ${ref}.gff

    cat ${fasta_file} >> ${ref}.gff
    """

    stub:
    """
    touch ${ref}.gff
    """
}
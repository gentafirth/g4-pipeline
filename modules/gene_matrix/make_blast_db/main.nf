process MAKE_BLAST_DB {
    tag "Creating BLAST database"
    label 'process_low'

    input:
    path fasta_file

    output:
    path "genomes_db*", emit: blast_db

    when:
    task.ext.when == null || task.ext.when

    script:
    def dbtype = params.blast_type == 'blastp' ? 'prot' : 'nucl'
    """
    makeblastdb \\
        -in ${fasta_file} \\
        -dbtype ${dbtype} \\
        -out genomes_db \\
        -title "Concatenated Genomes Database"
    
    echo "BLAST database created successfully"
    ls -la genomes_db*
    """
}
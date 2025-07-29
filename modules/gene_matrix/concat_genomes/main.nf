process CONCAT_GENOMES {
    tag "Concatenating ${fasta_file.size()} genome files"
    label 'process_low'

    input:
    path fasta_file

    output:
    path "all_genomes.fna", emit: concatenated_fasta

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    #!/bin/bash

    touch all_genomes.fna

    # Process each genome file
    for genome_file in ${fasta_file.join(' ')}; do
        # Extract genome ID from filename (remove .fna extension)
        genome_id=\$(basename "\$genome_file" .fna)

        echo "Processing \$genome_id..."

        # Add sequences with prefixed headers
        awk -v genome_id="\$genome_id" '
        /^>/ {
            # Remove the ">" and add genome_id prefix
            header = substr(\$0, 2)
            print ">" genome_id "|" header
            next
        }
        {
            # Print sequence lines as-is
            print \$0
        }' "\$genome_file" >> all_genomes.fna
    done

    echo "Concatenated \$(grep -c '^>' all_genomes.fna) sequences from ${fasta_file.size()} genome files"
    rm ${fasta_file}
    """
}

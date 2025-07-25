process PREP_BLAST_RESULTS {
    tag "Preparing Blast Result tab-separated-values"
    label 'process_medium'

    input:
        path matrix

    output:
        path "PROCESSED_*.tsv", emit: separated_matrix

    script:
    // def gff_arg = gff_file && gff_file.getName() != 'null' ? "-g ${gff_file}" : ""
    """
        set -euo pipefail

        header=\$(head -n1 "${matrix}")

        tail -n +2 "${matrix}" | while IFS= read -r line; do

            name=\$(printf '%s' "\$line" | cut -f1)

            {
            printf '%s\\n' "\$header"
            printf '%s\\n' "\$line"
        } > "PROCESSED_\${name}.tsv"
        done
    """
}

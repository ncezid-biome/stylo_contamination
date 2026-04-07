process EXTRACT_CONTAMINATION {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python%3A3.13':
        'https://depot.galaxyproject.org/singularity/python%3A3.13' }"

    input:
    tuple val(meta), path(kraken)

    output:
    tuple val(meta), path('*_contaminated.tsv'),  emit: tsv
    tuple val(meta), path('*_contamination.log'), emit: log
    tuple val(meta), stdout,                      emit: status
    path "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    prefix   = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''

    """
    extract_contamination.py \\
        ${args} \\
        -s ${prefix} \\
        -k ${prefix}.kraken2.report.txt \\
        -o ${prefix}_contaminated.tsv \\
        | tee ${prefix}_contamination.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_contaminated.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

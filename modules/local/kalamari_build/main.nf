process KALAMARI_BUILD {
    tag "kalamari_build"
    label 'process_low'

    container "library://arzoopatel5/kalamari/kalamari:5.8.3"

    input:
    path kalamari_db
    val ncbi_key
    val ncbi_email

    output:
    // TODO check if k2d files follow the path
    path kalamari_db                             , emit: db
    // path "share/kalamari-5.8.3/kalamari-kraken2/" , emit: db
    path "versions.yml"                           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: ""
    """
    kalamari_version=\$(downloadKalamari.pl --version)

    # NCBI
    export NCBI_API_KEY=$ncbi_key
    export EMAIL=$ncbi_email

    mkdir -p \$(readlink ${kalamari_db})
    echo \$HOME
    echo kalamari db param ${kalamari_db}

    # if any of the 3 files do not exist we rebuild the database
    if [[ ! -f $kalamari_db/hash.k2d || ! -f $kalamari_db/opts.k2d || ! -f $kalamari_db/taxo.k2d ]]; then
        echo "database is missing files, rebuilding"
        # long step, downloads from NCBI
        downloadKalamari.sh
        # get taxonomy from NCBI and filter it
        buildTaxonomy.sh
        filterTaxonomy.sh
        # build k2d files
        buildKraken2.sh

        # TODO change to dynamic version
        mkdir -p $kalamari_db
        cp share/kalamari-5.8.3/kalamari-kraken2/*.k2d $kalamari_db
    else
        echo "database already exists, skipping rebuild"
    fi


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kalamari: \$( downloadKalamari.pl --version )
        kraken2: \$( k2 --version )
        perl: \$( perl -v | grep -oP '\\d+\\.\\d+\\.\\d+' )
        taxonkit: \$( taxonkit version | grep -oP '\\d+\\.\\d+\\.\\d+' )
        ncbi-entrez: \$( esearch -version )
        jellyfish: \$( jellyfish --version | cut -f 2 -d ' ' )
    END_VERSIONS
    """
}

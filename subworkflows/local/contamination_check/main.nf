//
// Subworkflow with functionality specific to the ncezid-biome/stylo pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { KRAKEN2_KRAKEN2        } from '../../../modules/nf-core/kraken2/kraken2/main'
include { EXTRACT_CONTAMINATION  } from '../../../modules/local/contamination/main'
// include { KRAKEN2_BUILD       } from '../../../modules/nf-core/kraken2/build/main'
include { KALAMARI_BUILD         } from '../../../modules/local/kalamari_build/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow CONTAMINATION_CHECK {

    take:
    ch_samplesheet // meta, reads

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: build db
    //
    KALAMARI_BUILD (
        params.kalamari_db,
        params.ncbi_key,
        params.ncbi_email
    )
    ch_versions = ch_versions.mix(KALAMARI_BUILD.out.versions)

    //
    // MODULE: run kraken2
    //
    KRAKEN2_KRAKEN2 (
        ch_samplesheet,
        KALAMARI_BUILD.out.db,
        false,
        false
    )
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(KRAKEN2_KRAKEN2.out.report.map{ meta, report -> tuple (report) } )

    //
    // MODULE: extract contamination
    //
    EXTRACT_CONTAMINATION (
        KRAKEN2_KRAKEN2.out.report
    )
    ch_versions = ch_versions.mix(EXTRACT_CONTAMINATION.out.versions)

    //logging for warnings and errors
    // remove anything with no data
    EXTRACT_CONTAMINATION.out.status
        .filter{ it[1] =~ /NO DATA/ }
        .subscribe { row -> log.error "${row[0].id}} does not have enough data to be identified in kalamari, this sample will be removed from the remaining pipeline" }
    // remove anything that is contaminated
    EXTRACT_CONTAMINATION.out.status
        .filter{ it[1] =~ /CONTAM/ }
        .subscribe { row -> log.error "${row[0].id}} has two or more genera above the contamination threshold, see contamination output for details" }
    // warn if organism is unsupported
    EXTRACT_CONTAMINATION.out.status
        .filter{ it[1] =~ /UNSUPPORTED/ }
        .subscribe { row -> log.warn "${row[0].id}} is unsupported by the current cutoff table, please update or use a different cutoff table" }
    // warn if organism has index hopping or low level contamination
    EXTRACT_CONTAMINATION.out.status
        .filter{ it[1] =~ /INDEX/ }
        .subscribe { row -> log.warn "${row[0].id}} has potential index hopping or low level contamination" }

    // logic for channel that is returned
    // extract primary genus from all passed status samples
    // meta, genus
    ch_pass = EXTRACT_CONTAMINATION.out.status
        .filter{ it[1] =~ /PASS/ || it[1] =~ /UNSUPPORTED/ || it[1] =~ /INDEX/ }
        .map { meta, genus -> [meta, genus.split('_')[1]] }
        .view()

    emit:
    pass = ch_pass
    versions = ch_versions
    multiqc_files = ch_multiqc_files
}

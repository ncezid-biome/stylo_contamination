//
// Subworkflow with functionality specific to the ncezid-biome/stylo pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { NANOQ               } from '../../../modules/nf-core/nanoq/main'
include { RASUSA              } from '../../../modules/nf-core/rasusa/main'

include { CONTAMINATION_CHECK } from '../../../subworkflows/local/contamination_check/main'

/*
========================================================================================
    SUBWORKFLOW TO INITIALISE PIPELINE
========================================================================================
*/

workflow READS_PREPROCESSING {

    take:
    ch_samplesheet

    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // MODULE: readfiltering ONT longreads
    //
    NANOQ (
        ch_samplesheet,
        params.nanoq_format
    )
    ch_versions = ch_versions.mix(NANOQ.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(NANOQ.out.stats.map{ meta, stats -> tuple (stats) })

    //
    // SUBWORKFLOW: check for contamination
    //
    CONTAMINATION_CHECK {
        NANOQ.out.reads
    }
    ch_versions = ch_versions.mix(CONTAMINATION_CHECK.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(CONTAMINATION_CHECK.out.multiqc_files)

    ch_genome_size = CONTAMINATION_CHECK.out.pass.map { meta, genus -> [genus, meta] }
        .combine(ch_lookup_table) // genus, meta, genome_size
        .map { genus, meta, genome_size -> [meta, genome_size] }
    // TODO maybe we can simplify the logic

    //
    // MODULE: downsampling to specific coverage
    //
    ch_rasusa_in = NANOQ.out.reads.combine( ch_genome_size, by: 0 )

    RASUSA (
        ch_rasusa_in,
        params.coverage
    )
    ch_versions = ch_versions.mix(RASUSA.out.versions)

    emit:
    reads = RASUSA.out.reads
    genome_size = ch_genome_size
    versions = ch_versions
    multiqc_files = ch_multiqc_files
}

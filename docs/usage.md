# ncezid-biome/stylo_contamination: Usage

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyze before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 2 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Full samplesheet

There is a strict requirement for the first 2 columns of the samplesheet to match those defined in the table below.

An example is shown below and included in [assets](../assets/).

```csv title="samplesheet.csv"
sample,fastq
sample1,/path/to/sample1.fastq.gz
sample2,/path/to/sample2.fastq.gz
sample3,/path/to/sample3.fastq.gz
sample4,/path/to/sample4.fastq.gz
sample5,/path/to/sample5.fastq.gz
```

| Column    | Format | Description                                                                                                                                                                            |
| --------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | string | Custom sample name. This entry must be unique. |
| `fastq` | path | Full path to FastQ file for ONT longreads. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz". |


## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run ncezid-biome/stylo_contamination -r v1.0.0 --input /path/to/samplesheet.csv --outdir ./results -profile singularity
```

This will launch the pipeline with the `singularity` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

Note: if you're on CDC servers the work dir will be in the scratch space

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

:::warning
Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).
:::

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run /path/to/stylo_contamination/main.nf -profile singularity -params-file params.yaml
```

with `params.yaml` containing:

```yaml
input: './samplesheet.csv'
outdir: './results/'
<...>
```

## Advanced Usage

### model parameter
If the model parameter is left blank, the pipeline will choose the bacterial methylation model `r1041_e82_400bps_bacterial_methylation`.
It's best to let the pipleine use the bacterial methylation model, but if you must specify the model parameter make sure to use one of the models from the following list

```
dna_r10.4.1_e8.2_400bps_fast@v5.2.0
dna_r10.4.1_e8.2_400bps_hac@v5.2.0
dna_r10.4.1_e8.2_400bps_sup@v5.2.0
dna_r10.4.1_e8.2_400bps_fast@v5.0.0
dna_r10.4.1_e8.2_400bps_hac@v5.0.0
dna_r10.4.1_e8.2_400bps_sup@v5.0.0
dna_r10.4.1_e8.2_400bps_fast@v4.3.0
dna_r10.4.1_e8.2_400bps_hac@v4.3.0
dna_r10.4.1_e8.2_400bps_sup@v4.3.0
dna_r10.4.1_e8.2_400bps_fast@v4.2.0
dna_r10.4.1_e8.2_400bps_hac@v4.2.0
dna_r10.4.1_e8.2_400bps_sup@v4.2.0
```

for more details about model selection in dorado, see [dorado model documentation](https://software-docs.nanoporetech.com/dorado/latest/models/models/)

> [!NOTE]
> by default stylo_contamination downloads and looks for models to `$HOME/.dorado/models`. This can be changed using the parameter `--model_dir`.

## Core Nextflow arguments

:::note
These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).
:::

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Two profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Singularity, Rosalind) - see below.

:::info
We highly recommend the use of Singularity containers for full pipeline reproducibility.
:::

Note that multiple profiles can be loaded, for example: `-profile test,singularity` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `docker`
  - A generic configuration profile to be used with [Docker](https://docs.docker.com/)

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customize the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher requests (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases you may wish to change which container or conda environment a step of the pipeline uses for a particular tool. By default nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customizing tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted by your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

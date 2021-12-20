// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'
// include { trimSuffix } from './custom_functions'

params.options = [:]
// options        = initOptions(params.options)
options        = initOptions([:])

process INTERLACE_FASTA {
    // tag "$meta.id"
    // tag "$input_name"
    tag "${trimSuffix(magicblast_output.simpleName, '_output')}"
    label 'process_low'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:[:], publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::magicblast=1.6.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/magicblast:1.6.0--h95f258a_0"
    } else {
        container "quay.io/biocontainers/magicblast:1.6.0--h95f258a_0"
    }

    input:
    // path(paired_fastq)
    tuple val(meta), path(reads)
    // each path(db)
    // path(db_files)
    path(magicblast_output)
    TRIMMOMATIC.out.trimmed_reads

    output:
    // path("*_output.txt"), emit: mb_result
    path("*_histogram.txt"), emit: mb_histogram
    // path "*.version.txt"          , emit: version

    script:
    // def software = getSoftwareName(task.process)
    // def prefix   = "${trimSuffix(reads[0].baseName, '_R1.fastq.gz')}_${trimSuffix(db, '.tar.gz')}"
    // def prefix   = "${reads[0].simpleName}_${db.simpleName}"
    def input_name  = "${trimSuffix(magicblast_output.simpleName, '_output')}"

    """
    READCOUNT=`<${magicblast_output} \\
        tail -n +4 | \\
        wc -l`
    <${magicblast_output} \\
        tail -n +4 | \\
        awk '{print \$2}' | \\
        sort | \\
        uniq -c | \\
        sort -k1,1nr | \\
        head -5 |
        awk -F" " -v var="\${READCOUNT}" '{print (\$1 / var * 100) "% " \$2}' > \\
        ${input_name}_histogram.txt
    """

}

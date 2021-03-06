// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'
// include { trimSuffix } from './custom_functions'

params.options = [:]
// options        = initOptions(params.options)
options        = initOptions([:])

process MAGICBLAST {
    tag "$meta.id"
    label 'process_long'
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
    each path(db)
    //path(db_files)

    output:
    path("*_output.txt"), emit: mb_results
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    // def prefix   = "${trimSuffix(reads[0].baseName, '_R1.fastq.gz')}_${trimSuffix(db, '.tar.gz')}"
    def prefix   = "${reads[0].simpleName}_${db.simpleName}"

    """
    magicblast \\
        $options.args \\
        -num_threads $task.cpus \\
        -infmt fastq \\
        -outfmt tabular \\
        -query ${reads[0]} \\
        -query_mate ${reads[1]} \\
        -db ${db}/${db.simpleName} \\
        -out ${prefix}_output.txt \\

    magicblast -version | head -1 | awk '{print \$2}' > ${software}.version.txt
    """
}

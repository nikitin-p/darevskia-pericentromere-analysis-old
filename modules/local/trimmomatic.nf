include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
// options        = initOptions(params.options)
options        = initOptions([:])

process TRIMMOMATIC {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:[:], publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::trimmomatic=0.39" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/trimmomatic:0.39--hdfd78af_2"
    } else {
        container "quay.io/biocontainers/trimmomatic:0.39--hdfd78af_2"
    }

    input:
    tuple val(meta), path(reads)
    each path(primer)

    output:
    tuple val(meta), path("*_trimmed_*_p.fastq.gz"), emit: trimmed_reads_p
    tuple val(meta), path("*_trimmed_*_u.fastq.gz"), emit: trimmed_reads_u
    path "*_trimlog.txt" , emit: trimlog
    path "*.version.txt"          , emit: version

    script:
    def software = getSoftwareName(task.process)
    def prefix   = "${meta.id}_trimmed"
    
    """
    trimmomatic \\
        PE \\
        -phred33 \\
        -threads $task.cpus \\
        -trimlog ${prefix}_trimlog.txt \\
        ${reads[0]} \\
        ${reads[1]} \\
        ${prefix}_f_p.fastq.gz \\
        ${prefix}_f_u.fastq.gz \\
        ${prefix}_r_p.fastq.gz \\
        ${prefix}_r_u.fastq.gz \\
        HEADCROP:25 \\
        ILLUMINACLIP:${primer}:8:30:10 \\
        ILLUMINACLIP:TruSeq2-PE.fa:2:30:10 \\
        SLIDINGWINDOW:4:20 \\
        MINLEN:20

    trimmomatic -version 2>&1 | tail -1 > ${software}.version.txt
    """
}

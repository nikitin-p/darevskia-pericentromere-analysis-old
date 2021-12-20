// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'
include { trimSuffix } from './custom_functions'

params.options = [:]
// options        = initOptions(params.options)
options        = initOptions([:])

process INTERLACE_FASTA {
    // tag "$meta.id"
    // tag "$input_name"
    tag "${trimSuffix(forward_reads.baseName, '_f_p.fastq.gz')}"
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
    tuple val(meta), path(forward_reads)
    tuple val(meta), path(reverse_reads)
    // each path(db)
    // path(db_files)

    output:
    path("*.fasta"), emit: interlaced_reads
    // path("*_histogram.txt"), emit: mb_histogram
    // path "*.version.txt"          , emit: version

    script:
    // def software = getSoftwareName(task.process)
    def prefix   = "${trimSuffix(forward_reads.baseName, '_f_p.fastq.gz')}"
    def prefix_forward   = "${forward_reads.simpleName}"
    def prefix_reverse   = "${reverse_reads.simpleName}"
    // def input_name  = "${trimSuffix(magicblast_output.simpleName, '_output')}"

    """
    gzip -d ${forward_reads} | \\
        sed -n '1\~4s/^@/>/p;2\~4p' > ${prefix_forward}.fa

    gzip -d ${reverse_reads} | \\
        sed -n '1\~4s/^@/>/p;2\~4p' > ${prefix_reverse}.fa

    <${prefix_forward}.fa \\
        awk '{if (\$0 ~ /^>/) {printf ">" (NR + 1) / 2 "f|"} else {print}}' > ${prefix_forward}.fa.txt

    <${prefix_reverse}.fa \\
        awk '{if (\$0 ~ /^>/) {printf ">" (NR + 1) / 2 "r|"} else {print}}' > ${prefix_reverse}.fa.txt

    cat ${prefix_forward}.fa.txt ${prefix_reverse}.fa.txt | \\
        sort | \\
        tr "|" "\n" > ${prefix}.fasta
    """

}

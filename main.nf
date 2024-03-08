
process MANTLE_STAGE_INPUTS {
    tag "${pipelineId}-mantleSDK_stageInputs"

    secret 'MANTLE_USER'
    secret 'MANTLE_PASSWORD'

    container 'mantle-cli-tool:latest'

    input:
    val pipelineId

    output:
    tuple val(pipelineId), path('*R1*.fastq.gz'), path('*R2*.fastq.gz'), emit: staged_fastqs

    script:
    def stage_directory = "./"

    """
    test.sh
    
    get_data.py ${pipelineId} ${stage_directory} \
        --mantle_env ${ENVIRONMENT} \
        --tenant ${TENANT}
    """
}

process MANTLE_UPLOAD_RESULTS {
    tag "${pipelineId}-mantleSDK_uploadResults"

    publishDir "${params.outdir}/mantle_upload_results", mode: 'copy'

    secret 'MANTLE_USER'
    secret 'MANTLE_PASSWORD'

    container 'mantle-cli-tool:latest'

    input:
    val pipelineId
    val _fastqc_completion_ch
    val test_ch
    path outdir, stageAs: 'results/*'

    output:
    tuple val(pipelineId), path('*.txt'), emit: completion_timestamp

    script:
    def file = new File(outdir)
    absolutePath = file.getAbsolutePath().toString()

    """
    mantle_upload_results.py ${pipelineId} ${absolutePath} \
        --mantle_env ${ENVIRONMENT} \
        --tenant ${TENANT}

    date > results_uploaded_mantle.txt
    """
}

workflow {
     // Get FatsQs and sample metadata using pipeline Run ID from mantle SDK
    MANTLE_STAGE_INPUTS (
        params.pipelineId
    )

    // ... add your pipeline modules here...

    // Sync outputs back into mantle
    MANTLE_UPLOAD_RESULTS (
        params.pipelineId,
        // Add all files that you want to register as outputs here
        params.outdir
    )
}

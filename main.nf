
process MANTLE_STAGE_INPUTS {
    tag "${pipeline_run_id}-mantleSDK_stageInputs"

    secret 'MANTLE_USER'
    secret 'MANTLE_PASSWORD'

    container 'mantle-cli-tool:latest'

    input:
    val pipeline_run_id

    output:
    path('*.fastq.gz'), emit: test_ch

    script:
    def stage_directory = "./"

    """
    test.sh
    
    get_data.py ${pipeline_run_id} ${stage_directory}
    """
}

process MANTLE_UPLOAD_RESULTS {
    tag "${pipeline_run_id}-mantleSDK_uploadResults"

    publishDir "${params.outdir}/mantle_upload_results", mode: 'copy'

    secret 'MANTLE_USER'
    secret 'MANTLE_PASSWORD'

    container 'mantle-cli-tool:latest'

    input:
    val pipeline_run_id
    path outdir, stageAs: 'results/*'

    output:
    tuple val(pipeline_run_id), path('*.txt'), emit: completion_timestamp

    script:
    def file = new File(outdir)
    absolutePath = file.getAbsolutePath().toString()

    """
    mantle_upload_results.py ${pipeline_run_id} ${absolutePath}

    date > results_uploaded_mantle.txt
    """
}

workflow {
     // Get FatsQs and sample metadata using pipeline Run ID from mantle SDK
    MANTLE_STAGE_INPUTS (
        params.pipeline_run_id
    )

    // ... add your pipeline modules here...

    // Sync outputs back into mantle
    MANTLE_UPLOAD_RESULTS (
        params.pipeline_run_id,
        params.outdir
    )
}

CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_gbs_recruitment_funnel`
COMMENT 'Auto Loader ingestion from Dataiku source GBS_RECRUITMENT_FUNNEL'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/gbs_recruitment_funnel/',
  format => 'csv',
  sep => ',',
  header => true,
  pathGlobFilter => 'GBS_RECRUITMENT_FUNNEL.csv'
);

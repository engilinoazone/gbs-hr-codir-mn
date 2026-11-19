CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_applications_gbs`
COMMENT 'Auto Loader ingestion from Dataiku source applications_gbs'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/applications_gbs/',
  format => 'csv',
  sep => ',',
  header => false
);

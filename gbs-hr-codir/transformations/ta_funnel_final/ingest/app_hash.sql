CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_app_hash`
COMMENT 'Auto Loader ingestion from Dataiku source APP_HASH'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/app_hash/',
  format => 'csv',
  sep => ',',
  header => true,
  pathGlobFilter => 'APP_HASH.csv'
);

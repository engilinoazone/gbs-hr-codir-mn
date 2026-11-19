CREATE OR REFRESH STREAMING TABLE `brz`.`bronze_holidays_1`
COMMENT 'Auto Loader ingestion from Dataiku source holidays_1'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/holidays_1/',
  format => 'csv',
  sep => ',',
  header => true,
  encoding => 'UTF-8'
);

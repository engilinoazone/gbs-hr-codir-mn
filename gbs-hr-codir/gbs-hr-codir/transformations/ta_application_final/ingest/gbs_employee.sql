CREATE OR REFRESH STREAMING TABLE `brz`.`bronze_gbs_employee`
COMMENT 'Auto Loader ingestion from Dataiku source GBS_Employee'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/gbs_employee/',
  format => 'csv',
  sep => ',',
  header => true,
  pathGlobFilter => 'GBS_Employee.csv'
);

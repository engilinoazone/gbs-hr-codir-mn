CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_jobreq_history`
COMMENT 'Auto Loader ingestion from Dataiku source JOBREQ-HISTORY'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/jobreq_history/',
  format => 'csv',
  sep => ',',
  header => false
);

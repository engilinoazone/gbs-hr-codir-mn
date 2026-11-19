CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_ref_pos`
COMMENT 'Auto Loader ingestion from Dataiku source REF_POS'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/ref_pos/',
  format => 'csv',
  sep => ',',
  header => false
);

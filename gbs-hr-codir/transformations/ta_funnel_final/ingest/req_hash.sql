CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_req_hash`
COMMENT 'Auto Loader ingestion from Dataiku source REQ_HASH'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/req_hash/',
  format => 'csv',
  sep => ',',
  header => true,
  pathGlobFilter => 'REQ_HASH.csv'
);

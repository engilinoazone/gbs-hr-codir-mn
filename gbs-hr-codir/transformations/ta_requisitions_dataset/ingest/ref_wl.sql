-- NOTE: Partitioned dataset (day): columns extracted from file path.
CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_ref_wl`
COMMENT 'Auto Loader ingestion from Dataiku source REF_WL'
AS SELECT
  *,
  _metadata.file_path AS _source_path,
  concat_ws('-', regexp_extract(_metadata.file_path, '/(\\d{4})/(\\d{2})/(\\d{2})/.*', 1), regexp_extract(_metadata.file_path, '/(\\d{4})/(\\d{2})/(\\d{2})/.*', 2), regexp_extract(_metadata.file_path, '/(\\d{4})/(\\d{2})/(\\d{2})/.*', 3)) AS `day`
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/ref_wl/',
  format => 'csv',
  sep => ',',
  header => false
);

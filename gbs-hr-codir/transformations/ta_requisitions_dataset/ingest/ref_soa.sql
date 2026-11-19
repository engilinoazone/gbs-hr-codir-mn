-- NOTE: Partitioned dataset (date): columns extracted from file path.
CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_ref_soa`
COMMENT 'Auto Loader ingestion from Dataiku source Ref_SOA'
AS SELECT
  *,
  _metadata.file_path AS _source_path,
  concat_ws('-', regexp_extract(_metadata.file_path, '(\\d{4})/(\\d{2})/(\\d{2})/.*', 1), regexp_extract(_metadata.file_path, '(\\d{4})/(\\d{2})/(\\d{2})/.*', 2), regexp_extract(_metadata.file_path, '(\\d{4})/(\\d{2})/(\\d{2})/.*', 3)) AS `date`
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/ref_soa/',
  format => 'csv',
  sep => ',',
  header => false
);

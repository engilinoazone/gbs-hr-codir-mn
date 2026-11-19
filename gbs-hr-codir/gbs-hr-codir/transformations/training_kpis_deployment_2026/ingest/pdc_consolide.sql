CREATE OR REFRESH STREAMING TABLE `brz`.`bronze_pdc_consolide`
COMMENT 'Auto Loader ingestion from Dataiku source PDC_consolide'
AS
SELECT
  *,
  _metadata.file_path AS `_source_path`
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/pdc_consolide/',
  format => 'csv',
  pathGlobFilter => '*.csv',
  sep => ';',
  header => true,
  encoding => 'UTF-8'
);

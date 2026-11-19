CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_organisation_staffing_france`
COMMENT 'Auto Loader ingestion from Dataiku source Organisation_Staffing_France'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/organisation_staffing_france/',
  format => 'csv',
  sep => ';',
  header => true,
  encoding => 'UTF-8',
  pathGlobFilter => '*.csv'
);

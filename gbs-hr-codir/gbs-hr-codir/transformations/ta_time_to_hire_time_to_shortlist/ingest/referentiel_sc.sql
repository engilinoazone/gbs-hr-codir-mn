CREATE OR REFRESH STREAMING TABLE `brz`.`bronze_referentiel_sc`
COMMENT 'Auto Loader ingestion from Dataiku source Referentiel_SC'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/referentiel_sc/',
  format => 'csv',
  sep => ';',
  header => true,
  encoding => 'UTF-8',
  pathGlobFilter => '*.csv'
);

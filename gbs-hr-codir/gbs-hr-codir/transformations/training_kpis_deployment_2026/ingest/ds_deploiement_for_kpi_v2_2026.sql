CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_ds_deploiement_for_KPI_V2_2026`
COMMENT 'Auto Loader ingestion from Dataiku source ds_deploiement_for_KPI_V2_2026'
AS
SELECT
  * EXCEPT (
    `Sezame ID`,
    `Class Cancellation Reason​`
  ),
  `Sezame ID` AS `Sezame ID`,
  `Class Cancellation Reason​` AS `Class Cancellation Reason`,
  _metadata.file_path AS `_source_path`
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/ds_deploiement_for_kpi_v2/',
  format => 'csv',
  pathGlobFilter => '*.csv',
  header => true,
  sep => ',',
  encoding => 'UTF-8',
  multiLine => true,
  quote => '"',
  escape => '"'
);
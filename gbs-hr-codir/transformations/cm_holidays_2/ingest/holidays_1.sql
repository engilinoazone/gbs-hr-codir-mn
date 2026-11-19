-- Auto Loader ingestion of the Dataiku source `holidays_1`
-- The Dataiku dataset was an uploaded EXCEL file (sheet 'holidays'); the file is expected
-- on the volume already converted to UTF-8 CSV. The Excel-only `dataAddress` option has been
-- removed: it is not a read_files CSV option (ignored at best, pipeline failure at worst).
-- Types are NOT inferred: the Dataiku contract declares all 8 columns as STRING, and the
-- downstream to_date(Date, 'MM/dd/yy') / Global = 'True' comparisons require real strings.
CREATE OR REFRESH STREAMING TABLE `brz`.`bronze_holidays_1`
COMMENT 'Auto Loader ingestion from Dataiku source holidays_1'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/holidays_1/',
  format => 'csv',
  sep => ',',
  header => true,
  encoding => 'UTF-8',
  inferColumnTypes => false,
  schemaHints => '`Date` STRING, `LocalName` STRING, `Name` STRING, `CountryCode` STRING, `Fixed` STRING, `Global` STRING, `LaunchYear` STRING, `Type` STRING'
);

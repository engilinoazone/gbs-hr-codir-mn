CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_ds_payroll_compliance_rate`
COMMENT 'Auto Loader ingestion from Dataiku source ds_Payroll_compliance_rate'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/source_payroll/',
  format => 'csv',
  sep => ';',
  header => true,
  encoding => 'UTF-8',
  pathGlobFilter => '*.csv'
);

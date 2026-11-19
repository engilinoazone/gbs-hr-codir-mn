-- NOTE: S3 bucket set on Dataiku connection `GBSHRCODIR`: set its root (s3://bucket/prefix) in Migration > Sources tab.
CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_gbs_employee`
COMMENT 'Auto Loader ingestion from Dataiku source GBS_Employee'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  's3://<GBSHRCODIR>/gbs_employee/managed/',
  format => 'parquet'
);

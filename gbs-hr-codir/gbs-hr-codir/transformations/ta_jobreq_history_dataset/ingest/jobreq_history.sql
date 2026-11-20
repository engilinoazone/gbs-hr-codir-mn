CREATE OR REFRESH STREAMING TABLE `gbshr_ta_dev`.`brz`.`fr_jobreq_history`
COMMENT 'Auto Loader ingestion from Dataiku source JOBREQ-HISTORY'
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/jobreq_history/',
  format => 'csv',
  sep => ',',
  header => true
);

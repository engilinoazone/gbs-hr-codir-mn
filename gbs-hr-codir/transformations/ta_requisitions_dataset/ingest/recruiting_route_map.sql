CREATE OR REFRESH STREAMING TABLE `raw_data`.`bronze_recruiting_route_map`
COMMENT 'Auto Loader ingestion from Dataiku source Recruiting_Route_Map'
AS SELECT
  *,
  _metadata.file_path AS _source_path
FROM STREAM read_files(
  '/Volumes/hr_gbs_dev/raw_data/sources_ta/recruiting_route_map/',
  format => 'csv',
  header => false,
  sep => ','
);

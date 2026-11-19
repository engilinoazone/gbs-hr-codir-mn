-- Migrated from Dataiku: compute_REF_POS_prepared2
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_ref_pos_prepared2`
COMMENT 'Migrated from Dataiku (REF_POS_prepared2)'
AS
-- Dataiku shaker `compute_REF_POS_prepared2`: 0 Prepare steps
SELECT
  CAST(`POSITION_CODE` AS STRING) AS `POSITION_CODE`,
  `POSITION_LABEL`,
  `POSITION_PARENT`,
  `POSITION_STATUS`,
  `POSITION_DEPARTMENT`,
  `POSITION_SECOND_AXIS`,
  `POSITION_VACANT`
FROM `raw_data`.`bronze_ref_pos`;

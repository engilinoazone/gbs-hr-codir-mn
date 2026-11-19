-- Migrated from Dataiku: compute_REF_POS_prepared2
CREATE OR REFRESH STREAMING TABLE `raw_data`.`silver_ref_pos_prepared2`
COMMENT 'Migrated from Dataiku (REF_POS_prepared2)'
AS
-- Dataiku shaker `compute_REF_POS_prepared2`: Preparation in 0 steps; project the declared output schema.
SELECT
  CAST(`POSITION_CODE` AS STRING) AS `POSITION_CODE`,
  `POSITION_LABEL`,
  `POSITION_PARENT`,
  `POSITION_STATUS`,
  `POSITION_DEPARTMENT`,
  `POSITION_SECOND_AXIS`,
  `POSITION_VACANT`
FROM STREAM(`raw_data`.`bronze_ref_pos`);

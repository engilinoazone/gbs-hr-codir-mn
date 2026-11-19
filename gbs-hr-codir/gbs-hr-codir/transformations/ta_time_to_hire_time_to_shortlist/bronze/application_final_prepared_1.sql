-- Migrated from Dataiku: compute_APPLICATION_FINAL_prepared_1
-- Target realigned on the registered output of this step (slv.bronze_application_final_prepared_1).
-- The "bronze_" prefix is knowingly not the ideal medallion layer for a Prepare output; the user accepts it
-- and will rename it later directly in the pipelines, so that code and plan metadata stay consistent.
-- Kept from the previous fix (independent of naming): the input is read with the 2-part reference
-- `raw_data`.`silver_application_final` — never a 3-part reference, the catalog comes from ${var.catalog}.
CREATE OR REFRESH MATERIALIZED VIEW `slv`.`bronze_application_final_prepared_1`
COMMENT 'Migrated from Dataiku (APPLICATION_FINAL_prepared_1)'
AS
-- Dataiku shaker `compute_APPLICATION_FINAL_prepared_1`: filter statuses, select and reorder columns, then rename the status date
-- Step 0 [FilterOnValue]: keep Shortlist and Hireable application statuses
-- Step 1 [ColumnsSelector]: remove 18 unused columns
-- Step 2 [ColumnReorder]: move Req Posting Start Date before Application Created Date
-- Step 3 [ColumnsSelector]: remove Application Created Date and the original Application Status Date (Timestamp)
-- Step 4 [ColumnRenamer]: rename Application Status Date to Application Status Date (Timestamp)
SELECT
  `Job Req ID`,
  `Application ID`,
  `Req Posting Start Date`,
  `Application Status`,
  CAST(`Application Status Date` AS DATE) AS `Application Status Date (Timestamp)`
FROM `raw_data`.`silver_application_final`
WHERE `Application Status` IN ('Shortlist', 'Hireable');

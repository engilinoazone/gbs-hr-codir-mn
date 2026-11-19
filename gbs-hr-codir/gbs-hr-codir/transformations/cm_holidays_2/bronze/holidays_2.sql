-- Migrated from Dataiku: compute_holidays_prepared_1
-- Target realigned on the registered output of this step (slv.bronze_holidays_2).
-- The "bronze_" prefix is knowingly not the ideal medallion layer for a filtered dataset; the user accepts it
-- and will rename it later directly in the pipelines, so that code and plan metadata stay consistent.
-- Input stays STREAM(brz.bronze_holidays_1) (ingested append-only source => streaming table).
CREATE OR REFRESH STREAMING TABLE `slv`.`bronze_holidays_2`
COMMENT 'Migrated from Dataiku (holidays_2)'
AS
-- Dataiku shaker `compute_holidays_prepared_1`: parse Date, filter global public holidays, select and rename output columns
-- Step 0 [DateParser]: Parse Date as date using MM/dd/yy
-- Step 1 [ColumnsSelector]: Remove LocalName
-- Step 2 [FilterOnValue]: Keep rows where Global = True
-- Step 3 [FilterOnValue]: Keep rows where Type = Public
-- Step 4 [ColumnsSelector]: Remove Type, LaunchYear, Global, Fixed, and Name
-- Step 5 [ColumnRenamer]: Rename CountryCode to Country
-- Step 6 [ColumnReorder]: Move Country to the start
SELECT
  `CountryCode` AS `Country`,
  to_date(`Date`, 'MM/dd/yy') AS `Date`
FROM STREAM(`brz`.`bronze_holidays_1`)
WHERE `Global` = 'True'
  AND `Type` = 'Public';

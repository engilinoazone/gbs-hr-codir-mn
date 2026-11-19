-- Migrated from Dataiku: compute_holidays_prepared_1
CREATE OR REFRESH STREAMING TABLE `slv`.`silver_holidays_2`
COMMENT 'Migrated from Dataiku (holidays_2)'
AS
-- Dataiku shaker `compute_holidays_prepared_1`: parse Date, filter global public holidays, select and rename output columns
-- Step 0 [DateParser]: Parse Date using MM/dd/yy
-- Step 1 [ColumnsSelector]: Remove LocalName
-- Step 2 [FilterOnValue]: Keep Global = True
-- Step 3 [FilterOnValue]: Keep Type = Public
-- Step 4 [ColumnsSelector]: Remove Type, LaunchYear, Global, Fixed, and Name
-- Step 5 [ColumnRenamer]: Rename CountryCode to Country
-- Step 6 [ColumnReorder]: Move Country to the start
SELECT
  `CountryCode` AS `Country`,
  to_date(`Date`, 'M/d/yy') AS `Date`
FROM STREAM(`brz`.`bronze_holidays_1`)
WHERE `Global` = 'True'
  AND `Type` = 'Public';

-- Migrated from Dataiku: compute_applications_gbs_distinct2, compute_applications_gbs_distinct2_filtered2, compute_applications_gbs_distinct2_prepared2
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_applications_gbs_distinct2_prepared2` (
  CONSTRAINT keep_compute_applications_gbs_distinct2_filtered2
    EXPECT (`Application ID` IS NOT NULL AND trim(`Application ID`) <> '')
    ON VIOLATION DROP ROW
)
COMMENT 'Migrated from Dataiku (applications_gbs_distinct2_prepared2)'
AS
WITH
-- Dataiku distinct `compute_applications_gbs_distinct2`: deduplicate on all 26 declared columns
_compute_applications_gbs_distinct2 AS (
  SELECT DISTINCT
    `Job Req ID`,
    `Application ID`,
    `Application Status Category`,
    `Application Status`,
    `Application Date`,
    `Created Date`,
    `Created By`,
    `Created Date (Timestamp)`,
    `Days In Status`,
    `Time In Status (days:hours:minutes)`,
    `Is Current Status`,
    `Skipped Status`,
    `Status Comment`,
    `Is Internal`,
    `GID`,
    `Employee ID`,
    `User Sys ID`,
    `Candidate ID`,
    `External Candidate User ID`,
    `First Name`,
    `Last Name`,
    `Hired On`,
    `Expected Start Date`,
    `Job Start Date`,
    `Source`,
    `Source Details`
  FROM `raw_data`.`bronze_applications_gbs`
)
-- Dataiku sampling `compute_applications_gbs_distinct2_filtered2`: keep rows where Application ID is not empty
-- Dataiku shaker `compute_applications_gbs_distinct2_prepared2`: parse dates, derive statuses, rename columns, reorder output
SELECT
  -- Step 5 [ColumnReorder]: place Application Status Category after Application Status 2
  `Job Req ID`,
  `Application ID`,
  `Application Status`,

  -- Step 1 [VisualIfRule]: group Interview 1 through Interview 4 as Interviews
  CASE
    WHEN instr(`Application Status`, 'Interview 1') > 0
      OR instr(`Application Status`, 'Interview 2') > 0
      OR instr(`Application Status`, 'Interview 3') > 0
      OR instr(`Application Status`, 'Interview 4') > 0
    THEN 'Interviews'
    ELSE `Application Status`
  END AS `Application Status 2`,

  -- Step 4 [VisualIfRule]: derive Application Status Category from Application Status
  CASE
    WHEN `Application Status` = 'Default'
      THEN '02 - Submission'
    WHEN `Application Status` = 'Pre-screening'
      THEN '03 - Resume Qualification'
    WHEN `Application Status` = 'Longlist'
      THEN '04 - Longlist'
    WHEN `Application Status` = 'Phone Qualifications'
      THEN '05 - Phone Qualifications'
    ELSE 'else'
  END AS `Application Status Category`,

  -- Step 0 [DateParser]: parse Application Date and Created Date as MM/dd/yyyy
  -- Step 3 [ColumnRenamer]: rename Application Date and Created Date
  CAST(try_to_timestamp(`Application Date`, 'MM/dd/yyyy') AS DATE)
    AS `Application Created Date`,
  CAST(try_to_timestamp(`Created Date`, 'MM/dd/yyyy') AS DATE)
    AS `Application Status Date`,

  `Created By`,

  -- Step 2 [DateParser]: parse Created Date (Timestamp) as MM/dd/yyyy hh:mm:ss a
  -- Step 3 [ColumnRenamer]: rename Created Date (Timestamp)
  CAST(
    try_to_timestamp(`Created Date (Timestamp)`, 'MM/dd/yyyy hh:mm:ss a')
    AS DATE
  ) AS `Application Status Date (Timestamp)`,

  `Days In Status`,
  `Time In Status (days:hours:minutes)`,
  `Is Current Status`,
  `Skipped Status`,
  `Status Comment`,
  `Is Internal`,
  `GID`,
  `Employee ID`,
  `User Sys ID`,
  `Candidate ID`,
  `External Candidate User ID`,
  `First Name`,
  `Last Name`,
  `Hired On`,
  `Expected Start Date`,

  -- Step 0 [DateParser]: parse Job Start Date while retaining the declared string output type
  CAST(
    CAST(try_to_timestamp(`Job Start Date`, 'MM/dd/yyyy') AS DATE)
    AS STRING
  ) AS `Job Start Date`,

  `Source`,
  `Source Details`
FROM _compute_applications_gbs_distinct2
WHERE `Application ID` IS NOT NULL
  AND trim(`Application ID`) <> '';

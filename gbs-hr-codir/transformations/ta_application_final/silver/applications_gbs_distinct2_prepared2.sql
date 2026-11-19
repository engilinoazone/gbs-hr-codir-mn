-- Migrated from Dataiku: compute_applications_gbs_distinct2, compute_applications_gbs_distinct2_filtered2, compute_applications_gbs_distinct2_prepared2
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_applications_gbs_distinct2_prepared2` (
  CONSTRAINT keep_compute_applications_gbs_distinct2_filtered2 EXPECT (
    `Application ID` IS NOT NULL AND length(`Application ID`) > 0
  ) ON VIOLATION DROP ROW
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
),
-- Dataiku sampling `compute_applications_gbs_distinct2_filtered2`: keep rows whose Application ID is not empty
_compute_applications_gbs_distinct2_filtered2 AS (
  SELECT
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
  FROM _compute_applications_gbs_distinct2
  WHERE `Application ID` IS NOT NULL
    AND length(`Application ID`) > 0
),
-- Dataiku shaker `compute_applications_gbs_distinct2_prepared2`: parse dates, derive statuses, rename columns, and reorder output
_compute_applications_gbs_distinct2_prepared2 AS (
  SELECT
    `Job Req ID`,
    `Application ID`,
    `Application Status`,

    -- Prepare step 1: consolidate Interview 1 through Interview 4 as Interviews
    CASE
      WHEN instr(`Application Status`, 'Interview 1') > 0
        OR instr(`Application Status`, 'Interview 2') > 0
        OR instr(`Application Status`, 'Interview 3') > 0
        OR instr(`Application Status`, 'Interview 4') > 0
      THEN 'Interviews'
      ELSE `Application Status`
    END AS `Application Status 2`,

    -- Prepare step 4: assign the status category from the application status rules
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

    -- Prepare step 0: parse Application Date, Created Date, and Job Start Date using MM/dd/yyyy
    -- Prepare step 3: rename Application Date to Application Created Date
    to_date(`Application Date`, 'MM/dd/yyyy') AS `Application Created Date`,

    -- Prepare step 3: rename Created Date to Application Status Date
    to_date(`Created Date`, 'MM/dd/yyyy') AS `Application Status Date`,

    `Created By`,

    -- Prepare step 2: parse Created Date (Timestamp) using MM/dd/yyyy hh:mm:ss a
    -- Prepare step 3: rename it to Application Status Date (Timestamp)
    to_date(
      to_timestamp(`Created Date (Timestamp)`, 'MM/dd/yyyy hh:mm:ss a')
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
    CAST(to_date(`Job Start Date`, 'MM/dd/yyyy') AS STRING) AS `Job Start Date`,
    `Source`,
    `Source Details`
    -- Prepare step 5: output columns reordered with Application Status Category after Application Status 2
  FROM _compute_applications_gbs_distinct2_filtered2
)
SELECT * FROM _compute_applications_gbs_distinct2_prepared2;

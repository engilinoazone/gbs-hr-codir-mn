-- Migrated from Dataiku: compute_application_renamed, compute_application, compute_app_req-v2
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_application_final`
COMMENT 'Migrated from Dataiku (APPLICATION_FINAL)'
AS
WITH
-- Dataiku shaker `compute_application_renamed`: create and retain Arrival records, fold Arrival, remove columns, and update status fields
_compute_application_renamed AS (
  SELECT
    f.`Job Req ID`,
    TRY_CAST(f.`Application ID` AS BIGINT) AS `Application ID`,
    f.`Application Created Date`,
    -- Prepare step 5: classify Application IDs containing 'Arrival' as skipped/closed
    CASE
      WHEN CONTAINS(f.`Application ID`, 'Arrival')
        THEN '99 - Skipped - Closed'
      ELSE f.`Application Status Category`
    END AS `Application Status Category`,
    f.`Application Status`,
    f.`Application Status Date`,
    -- Prepare step 4: copy the folded status date when Application ID is not empty
    CASE
      WHEN f.`Application ID` IS NOT NULL AND f.`Application ID` <> ''
        THEN CAST(f.`Application Status Date` AS DATE)
      ELSE f.`Application Status Date (Timestamp)`
    END AS `Application Status Date (Timestamp)`,
    f.`GID`,
    TRY_CAST(f.`Employee ID` AS BIGINT) AS `Employee ID`,
    f.`User Sys ID`,
    f.`Candidate ID`,
    TRY_CAST(f.`External Candidate User ID` AS BIGINT) AS `External Candidate User ID`,
    f.`Hired On`,
    f.`Expected Start Date`,
    f.`Source`,
    f.`Source Details`,
    f.`Is Internal`,
    f.`GENDER`,
    f.`EMPLOYEE_CLASS`,
    TRY_CAST(f.`POSITION_ID` AS BIGINT) AS `POSITION_ID`,
    TRY_CAST(f.`SEZAME_ID` AS BIGINT) AS `SEZAME_ID`,
    TRY_CAST(f.`USER_ID` AS BIGINT) AS `USER_ID`
  FROM (
    -- Prepare step 2: fold Arrival into Application Status and Application Status Date
    SELECT
      p.`Job Req ID`,
      p.`Application ID`,
      p.`Application Created Date`,
      p.`Application Status Category`,
      'Arrival' AS `Application Status`,
      CAST(p.`Arrival` AS STRING) AS `Application Status Date`,
      p.`Application Status Date (Timestamp)`,
      p.`GID`,
      p.`Employee ID`,
      p.`User Sys ID`,
      p.`Candidate ID`,
      p.`External Candidate User ID`,
      p.`Hired On`,
      p.`Expected Start Date`,
      p.`Source`,
      p.`Source Details`,
      p.`Is Internal`,
      p.`GENDER`,
      p.`EMPLOYEE_CLASS`,
      p.`POSITION_ID`,
      p.`SEZAME_ID`,
      p.`USER_ID`
    FROM (
      SELECT
        s.`Job Req ID`,
        s.`Application ID`,
        s.`Application Created Date`,
        s.`Application Status Category`,
        s.`Application Status Date (Timestamp)`,
        s.`GID`,
        s.`Employee ID`,
        s.`User Sys ID`,
        s.`Candidate ID`,
        s.`External Candidate User ID`,
        s.`Hired On`,
        s.`Expected Start Date`,
        s.`Source`,
        s.`Source Details`,
        s.`Is Internal`,
        s.`GENDER`,
        s.`EMPLOYEE_CLASS`,
        s.`POSITION_ID`,
        s.`SEZAME_ID`,
        s.`USER_ID`,
        -- Prepare step 0: set Arrival from HIRE_DATE for matching hired applications
        CASE
          WHEN s.`Application Status Date` >= s.`HIRE_DATE`
            AND s.`Application ID` = 'Hired'
          THEN s.`HIRE_DATE`
        END AS `Arrival`
      FROM `raw_data`.`silver_applications_gbs_distinct2_filtered_joined` AS s
    ) AS p
    -- Prepare step 1: remove rows where Arrival is empty
    WHERE p.`Arrival` IS NOT NULL
  ) AS f
  -- Prepare step 3: omit Arrival, EVENT_REASON, EVENT_REASON_NAME, STATUS_NAME, Job Start Date, First Name, Last Name, and HIRE_DATE
),
-- Dataiku vstack `compute_application`: stack the shared application columns from Arrival and the original application dataset
_compute_application AS (
  SELECT
    `Job Req ID`,
    CAST(`Application ID` AS STRING) AS `Application ID`,
    `Application Created Date`,
    `Application Status Category`,
    `Application Status`,
    `Application Status Date`,
    `Application Status Date (Timestamp)`,
    `GID`,
    CAST(`Employee ID` AS STRING) AS `Employee ID`,
    `User Sys ID`,
    `Candidate ID`,
    CAST(`External Candidate User ID` AS STRING) AS `External Candidate User ID`,
    `Hired On`,
    `Expected Start Date`,
    `Source`,
    `Source Details`,
    `Is Internal`,
    `GENDER`,
    `EMPLOYEE_CLASS`,
    CAST(`POSITION_ID` AS STRING) AS `POSITION_ID`,
    CAST(`SEZAME_ID` AS STRING) AS `SEZAME_ID`,
    CAST(`USER_ID` AS STRING) AS `USER_ID`
  FROM _compute_application_renamed

  UNION ALL

  SELECT
    `Job Req ID`,
    `Application ID`,
    `Application Created Date`,
    `Application Status Category`,
    `Application Status`,
    CAST(`Application Status Date` AS STRING) AS `Application Status Date`,
    `Application Status Date (Timestamp)`,
    `GID`,
    `Employee ID`,
    `User Sys ID`,
    `Candidate ID`,
    `External Candidate User ID`,
    `Hired On`,
    `Expected Start Date`,
    `Source`,
    `Source Details`,
    `Is Internal`,
    `GENDER`,
    `EMPLOYEE_CLASS`,
    `POSITION_ID`,
    `SEZAME_ID`,
    `USER_ID`
  FROM `raw_data`.`silver_applications_gbs_distinct2_filtered_joined`
),
-- Dataiku join `compute_app_req-v2`: left join applications to requisitions on Job Req ID
_compute_app_req_v2 AS (
  SELECT
    a.`Job Req ID`,
    a.`Application ID`,
    a.`Application Created Date`,
    a.`Application Status Category`,
    a.`Application Status`,
    a.`Application Status Date`,
    a.`Application Status Date (Timestamp)`,
    a.`GID`,
    a.`Employee ID`,
    a.`User Sys ID`,
    a.`Candidate ID`,
    a.`External Candidate User ID`,
    a.`Hired On`,
    a.`Expected Start Date`,
    a.`Source`,
    a.`Source Details`,
    a.`Is Internal`,
    a.`GENDER`,
    a.`EMPLOYEE_CLASS`,
    a.`POSITION_ID`,
    a.`SEZAME_ID`,
    a.`USER_ID`,
    r.`Req Created Date`,
    r.`Req Posting Start Date`,
    r.`Req Assignment Date`
  FROM _compute_application AS a
  LEFT JOIN `raw_data`.`silver_req_final` AS r
    ON a.`Job Req ID` = r.`Job Req ID`
)
SELECT * FROM _compute_app_req_v2;

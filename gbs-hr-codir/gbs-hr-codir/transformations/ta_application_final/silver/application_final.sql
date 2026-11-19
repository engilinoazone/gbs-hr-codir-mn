-- Migrated from Dataiku: compute_application_renamed, compute_application, compute_app_req-v2
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_application_final`
COMMENT 'Migrated from Dataiku (APPLICATION_FINAL)'
AS
WITH
-- Dataiku shaker `compute_application_renamed`: Apply six enabled Prepare steps and retain the declared application-arrival columns
_compute_application_renamed AS (
  -- Step 0 [VisualIfRule]: Set Arrival from HIRE_DATE when Application Status Date >= HIRE_DATE and Application ID = 'Hired'
  -- Step 1 [RemoveRowsOnEmpty]: Remove rows with an empty Arrival
  -- Step 2 [MultiColumnFold]: Fold Arrival into Application Status / Application Status Date
  -- Step 3 [ColumnsSelector]: Remove Arrival and the seven excluded source columns
  -- Step 4 [VisualIfRule]: Set Application Status Date (Timestamp) from the folded status date when Application ID is not empty
  -- Step 5 [VisualIfRule]: Set the skipped/closed category when Application ID contains 'Arrival'
  SELECT
    s.`Job Req ID`,
    s.`Application ID`,
    s.`Application Created Date`,
    CASE
      WHEN instr(s.`Application ID`, 'Arrival') > 0
        THEN '99 - Skipped - Closed'
      ELSE s.`Application Status Category`
    END AS `Application Status Category`,
    'Arrival' AS `Application Status`,
    CAST(s.`HIRE_DATE` AS STRING) AS `Application Status Date`,
    CASE
      WHEN s.`Application ID` IS NOT NULL
       AND s.`Application ID` <> ''
        THEN s.`HIRE_DATE`
      ELSE s.`Application Status Date (Timestamp)`
    END AS `Application Status Date (Timestamp)`,
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
    s.`USER_ID`
  FROM `raw_data`.`silver_applications_gbs_distinct2_filtered_joined` AS s
  WHERE s.`Application Status Date` >= s.`HIRE_DATE`
    AND s.`Application ID` = 'Hired'
    AND s.`HIRE_DATE` IS NOT NULL
),
-- Dataiku vstack `compute_application`: Stack (INTERSECT) the 22 common application columns from both inputs
_compute_application AS (
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
    a.`USER_ID`
  FROM _compute_application_renamed AS a

  UNION ALL

  SELECT
    s.`Job Req ID`,
    s.`Application ID`,
    s.`Application Created Date`,
    s.`Application Status Category`,
    s.`Application Status`,
    CAST(s.`Application Status Date` AS STRING) AS `Application Status Date`,
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
    s.`USER_ID`
  FROM `raw_data`.`silver_applications_gbs_distinct2_filtered_joined` AS s
)
-- Dataiku join `compute_app_req-v2`: Left join applications to REQ_FINAL on Job Req ID and add the three requisition dates
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
  ON a.`Job Req ID` = r.`Job Req ID`;

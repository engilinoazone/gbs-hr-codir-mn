-- Migrated from Dataiku: compute_GBS_Employee_prepared, compute_applications_gbs_distinct2_prepared2_by_Application_ID, compute_applications_gbs_distinct2_prepared2_by_Application_ID2, compute_applications_gbs_distinct2_prepared2_by_Application_ID2_prepared, compute_applications_gbs_distinct2_prepared2_by_Application_ID_prepared, compute_applications_gbs_distinct2_prepared2_by_Application_ID_stacked, compute_applications_gbs_distinct2_filtered_joined
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_applications_gbs_distinct2_filtered_joined`
COMMENT 'Migrated from Dataiku (applications_gbs_distinct2_filtered_joined)'
AS
WITH
-- Dataiku shaker `compute_GBS_Employee_prepared`: preparation with no enabled transformation steps.
_compute_gbs_employee_prepared AS (
  SELECT
    `GID`,
    `GENDER`,
    `HIRE_DATE`,
    `EMPLOYEE_CLASS`,
    CAST(`POSITION_ID` AS STRING) AS `POSITION_ID`,
    `EVENT_REASON`,
    `STATUS_NAME`,
    `EVENT_REASON_NAME`,
    `SEZAME_ID`,
    `USER_ID`
  FROM `raw_data`.`bronze_gbs_employee`
),

-- Dataiku grouping `compute_applications_gbs_distinct2_prepared2_by_Application_ID`: group by application attributes and calculate minimum status dates and row count.
_compute_applications_gbs_distinct2_prepared2_by_application_id AS (
  SELECT
    `Application ID`,
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
    `Source Details`,
    `Job Req ID`,
    `Application Status Category`,
    `Application Status 2`,
    `Application Created Date`,
    `Is Internal`,
    MIN(`Application Status Date`) AS `Application Status Date_min`,
    MIN(`Application Status Date (Timestamp)`) AS `Application Status Date (Timestamp)_min`,
    COUNT(*) AS `count`
  FROM `raw_data`.`silver_applications_gbs_distinct2_prepared2`
  GROUP BY
    `Application ID`,
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
    `Source Details`,
    `Job Req ID`,
    `Application Status Category`,
    `Application Status 2`,
    `Application Created Date`,
    `Is Internal`
),

-- Dataiku grouping `compute_applications_gbs_distinct2_prepared2_by_Application_ID2`: group by application attributes and calculate maximum application and status dates and row count.
_compute_applications_gbs_distinct2_prepared2_by_application_id2 AS (
  SELECT
    `Application ID`,
    `Job Req ID`,
    `Application Status Category`,
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
    `Source Details`,
    `Application Status 2`,
    `Is Internal`,
    MAX(`Application Created Date`) AS `Application Created Date_max`,
    MAX(`Application Status Date`) AS `Application Status Date_max`,
    MAX(`Application Status Date (Timestamp)`) AS `Application Status Date (Timestamp)_max`,
    COUNT(*) AS `count`
  FROM `raw_data`.`silver_applications_gbs_distinct2_prepared2`
  GROUP BY
    `Application ID`,
    `Job Req ID`,
    `Application Status Category`,
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
    `Source Details`,
    `Application Status 2`,
    `Is Internal`
),

-- Dataiku shaker `compute_applications_gbs_distinct2_prepared2_by_Application_ID2_prepared`: rename maximum-date columns, derive status, reorder columns, and remove count and source status.
_compute_applications_gbs_distinct2_prepared2_by_application_id2_prepared AS (
  -- Prepare step 0: rename the three maximum-date columns.
  -- Prepare step 1: remove `count`.
  -- Prepare step 2: assign `Interviews max` when `Application Status 2` is `Interviews`; otherwise retain `Application Status 2`.
  -- Prepare steps 3-5: reorder status, date, and job requisition columns.
  -- Prepare step 6: remove `Application Status 2`.
  SELECT
    CAST(`Job Req ID` AS BIGINT) AS `Job Req ID`,
    `Application ID`,
    `Application Created Date_max` AS `Application Created Date`,
    `Application Status Category`,
    CASE
      WHEN `Application Status 2` = 'Interviews' THEN 'Interviews max'
      ELSE `Application Status 2`
    END AS `Application Status`,
    `Application Status Date_max` AS `Application Status Date`,
    `Application Status Date (Timestamp)_max` AS `Application Status Date (Timestamp)`,
    `GID`,
    `Employee ID`,
    `User Sys ID`,
    CAST(`Candidate ID` AS BIGINT) AS `Candidate ID`,
    `External Candidate User ID`,
    `First Name`,
    `Last Name`,
    `Hired On`,
    `Expected Start Date`,
    `Job Start Date`,
    `Source`,
    `Source Details`,
    CAST(`Is Internal` AS BOOLEAN) AS `Is Internal`
  FROM _compute_applications_gbs_distinct2_prepared2_by_application_id2
),

-- Dataiku shaker `compute_applications_gbs_distinct2_prepared2_by_Application_ID_prepared`: rename minimum-date columns, derive status, reorder columns, and remove count and source status.
_compute_applications_gbs_distinct2_prepared2_by_application_id_prepared AS (
  -- Prepare step 0: rename the two minimum-date columns.
  -- Prepare step 1: remove `count`.
  -- Prepare step 2: assign `Interviews min` when `Application ID` is `Interviews`; otherwise retain `Application Status 2`.
  -- Prepare step 3: move category, status, and status-date columns before `GID`.
  -- Prepare step 4: remove `Application Status 2`.
  SELECT
    `Application ID`,
    `Application Status Category`,
    CASE
      WHEN `Application ID` = 'Interviews' THEN 'Interviews min'
      ELSE `Application Status 2`
    END AS `Application Status`,
    `Application Status Date_min` AS `Application Status Date`,
    `Application Status Date (Timestamp)_min` AS `Application Status Date (Timestamp)`,
    `GID`,
    CAST(`Employee ID` AS BIGINT) AS `Employee ID`,
    `User Sys ID`,
    CAST(`Candidate ID` AS BIGINT) AS `Candidate ID`,
    CAST(`External Candidate User ID` AS BIGINT) AS `External Candidate User ID`,
    `First Name`,
    `Last Name`,
    `Hired On`,
    `Expected Start Date`,
    `Job Start Date`,
    `Source`,
    `Source Details`,
    CAST(`Job Req ID` AS BIGINT) AS `Job Req ID`,
    `Application Created Date`,
    CAST(`Is Internal` AS BOOLEAN) AS `Is Internal`
  FROM _compute_applications_gbs_distinct2_prepared2_by_application_id
),

-- Dataiku vstack `compute_applications_gbs_distinct2_prepared2_by_Application_ID_stacked`: append maximum- and minimum-status datasets using the declared output column order and types.
_compute_applications_gbs_distinct2_prepared2_by_application_id_stacked AS (
  SELECT
    `Job Req ID`,
    `Application ID`,
    `Application Created Date`,
    `Application Status Category`,
    `Application Status`,
    `Application Status Date`,
    `Application Status Date (Timestamp)`,
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
    `Source Details`,
    `Is Internal`
  FROM _compute_applications_gbs_distinct2_prepared2_by_application_id2_prepared

  UNION ALL

  SELECT
    `Job Req ID`,
    `Application ID`,
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
    `First Name`,
    `Last Name`,
    `Hired On`,
    `Expected Start Date`,
    `Job Start Date`,
    `Source`,
    `Source Details`,
    `Is Internal`
  FROM _compute_applications_gbs_distinct2_prepared2_by_application_id_prepared
),

-- Dataiku join `compute_applications_gbs_distinct2_filtered_joined`: left join applications to employees on employee and user identifiers.
_compute_applications_gbs_distinct2_filtered_joined AS (
  SELECT
    applications.`Job Req ID`,
    applications.`Application ID`,
    applications.`Application Created Date`,
    applications.`Application Status Category`,
    applications.`Application Status`,
    applications.`Application Status Date`,
    applications.`Application Status Date (Timestamp)`,
    applications.`GID`,
    applications.`Employee ID`,
    applications.`User Sys ID`,
    applications.`Candidate ID`,
    applications.`External Candidate User ID`,
    applications.`First Name`,
    applications.`Last Name`,
    applications.`Hired On`,
    applications.`Expected Start Date`,
    applications.`Job Start Date`,
    applications.`Source`,
    applications.`Source Details`,
    applications.`Is Internal`,
    employees.`GENDER`,
    employees.`HIRE_DATE`,
    employees.`EMPLOYEE_CLASS`,
    employees.`POSITION_ID`,
    employees.`EVENT_REASON`,
    employees.`STATUS_NAME`,
    employees.`EVENT_REASON_NAME`,
    employees.`SEZAME_ID`,
    employees.`USER_ID`
  FROM _compute_applications_gbs_distinct2_prepared2_by_application_id_stacked AS applications
  LEFT JOIN _compute_gbs_employee_prepared AS employees
    ON applications.`Employee ID` = employees.`SEZAME_ID`
   AND applications.`User Sys ID` = employees.`USER_ID`
)
SELECT * FROM _compute_applications_gbs_distinct2_filtered_joined;

-- Migrated from Dataiku: compute_Job_Requisition_assignment, compute_REF_POS_filtered, compute_Job_Requisition_TA_assigned, compute_req_sans_app, compute_req_sans_app_prepared, compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_1, compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_prepared_1, compute_REQ_DISTINCT_joined, compute_REQ_DISTINCT_w_Position, compute_REQ_DISTINCT_w_Position_joined, compute_REQ_DISTINCT_w_Position_joined_prepared
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_req_distinct_w_position_joined_prepared`
COMMENT 'Migrated from Dataiku (REQ_DISTINCT_w_Position_joined_prepared)'
AS
WITH
-- Dataiku shaker `compute_Job_Requisition_assignment`: parse routing date and retain routed assignment rows
_compute_job_requisition_assignment AS (
  -- Prepare 0: parse Step Last Routed with format MMM dd, yyyy hh:mm:ss a (unparseable -> NULL, as in Dataiku)
  -- Prepare 1: keep rows where Step Sub Type equals R
  SELECT
    TRY_CAST(`Job Requisition ID` AS BIGINT) AS `Job Requisition ID`,
    TRY_CAST(`Route Entry ID` AS BIGINT) AS `Route Entry ID`,
    `Step Description`,
    `Step Last Routed`,
    TO_DATE(TRY_TO_TIMESTAMP(`Step Last Routed`, 'MMM dd, yyyy hh:mm:ss a')) AS `Step Last Routed_parsed`,
    `Step Status`,
    `Step Sub Status`,
    `Step Sub Type`,
    `Step Type`,
    `User ID`
  FROM `raw_data`.`bronze_recruiting_route_map`
  WHERE `Step Sub Type` = 'R'
),

-- Dataiku sampling `compute_REF_POS_filtered`: retain rows whose POSITION_LABEL is numerically at least zero
_compute_ref_pos_filtered AS (
  SELECT
    `POSITION_CODE`,
    `POSITION_LABEL`,
    `POSITION_PARENT`,
    `POSITION_STATUS`,
    `POSITION_DEPARTMENT`,
    `POSITION_SECOND_AXIS`,
    `POSITION_VACANT`
  FROM `raw_data`.`bronze_ref_pos`
  WHERE TRY_CAST(`POSITION_LABEL` AS DOUBLE) >= 0
),

-- Dataiku grouping `compute_Job_Requisition_TA_assigned`: aggregate assignment attributes by Job Requisition ID
_compute_job_requisition_ta_assigned AS (
  SELECT
    `Job Requisition ID`,
    MAX(`Step Last Routed_parsed`) AS `Step Last Routed_parsed_max`,
    MAX(`Step Status`) AS `Step Status_max`,
    MAX(`User ID`) AS `User ID_max`
  FROM _compute_job_requisition_assignment
  GROUP BY `Job Requisition ID`
),

-- Dataiku join `compute_req_sans_app`: inner join requisitions to application rows with an empty Application ID
_compute_req_sans_app AS (
  SELECT
    requisitions.`Job Req ID`
  FROM (
    SELECT
      `Job Req ID`
    FROM `raw_data`.`bronze_applications_gbs`
    WHERE `Application ID` IS NULL OR `Application ID` = ''
  ) AS applications
  INNER JOIN (
    SELECT
      `Job Req ID`
    FROM `raw_data`.`silver_req_gbs_jobreqid_type`
  ) AS requisitions
    ON applications.`Job Req ID` = requisitions.`Job Req ID`
),

-- Dataiku shaker `compute_req_sans_app_prepared`: pass through the recipe output unchanged
_compute_req_sans_app_prepared AS (
  SELECT
    `Job Req ID`
  FROM _compute_req_sans_app
),

-- Dataiku pivot `compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_1`: count static Board ID modalities and take minima for requisition attributes
_compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_1 AS (
  SELECT
    `Job Req ID`,
    COUNT_IF(`Board ID` IS NULL) AS `null_Board ID_count`,
    COUNT_IF(`Board ID` = 'Agency') AS `Agency_count`,
    COUNT_IF(`Board ID` = 'External') AS `External_count`,
    COUNT_IF(`Board ID` = 'Internal') AS `Internal_count`,
    COUNT_IF(`Board ID` = '_private_external') AS `_private_external_count`,
    COUNT_IF(`Board ID` = '_private_internal') AS `_private_internal_count`,
    MIN(`Job Title`) AS `Job Title_min`,
    MIN(`Template ID`) AS `Template ID_min`,
    MIN(`Template Name`) AS `Template Name_min`,
    MIN(`Requisition Status`) AS `Requisition Status_min`,
    MIN(`Requisition Status_2`) AS `Requisition Status_2_min`,
    MIN(`Date Created`) AS `Date Created_min`,
    MIN(`Global Leader Position`) AS `Global Leader Position_min`,
    MIN(`Requisition Type`) AS `Requisition Type_min`,
    MIN(`Number of Openings`) AS `Number of Openings_min`,
    MIN(`Openings Filled`) AS `Openings Filled_min`,
    MIN(`Business Unit`) AS `Business Unit_min`,
    MIN(`Division`) AS `Division_min`,
    MIN(`Department`) AS `Department_min`,
    MIN(`Legal Entity`) AS `Legal Entity_min`,
    MIN(`Country`) AS `Country_min`,
    MIN(`Work Location`) AS `Work Location_min`,
    MIN(`HR Business Partner User Sys ID`) AS `HR Business Partner User Sys ID_min`,
    MIN(`HR Business Partner First name`) AS `HR Business Partner First name_min`,
    MIN(`HR Business Partner Last Name`) AS `HR Business Partner Last Name_min`,
    MIN(`Recruiter User Sys ID`) AS `Recruiter User Sys ID_min`,
    MIN(`Recruiter First Name`) AS `Recruiter First Name_min`,
    MIN(`Recruiter Last Name`) AS `Recruiter Last Name_min`,
    MIN(`Hiring Manager User Sys ID`) AS `Hiring Manager User Sys ID_min`,
    MIN(`Hiring Manager First Name`) AS `Hiring Manager First Name_min`,
    MIN(`Hiring Manager Last Name`) AS `Hiring Manager Last Name_min`,
    MIN(`Job Family`) AS `Job Family_min`,
    MIN(`Cost Center`) AS `Cost Center_min`,
    MIN(`Posting Start Date`) AS `Posting Start Date_min`,
    MIN(`Group Employee Level`) AS `Group Employee Level_min`,
    MIN(`Job Type`) AS `Job Type_min`,
    MIN(`Contract Type`) AS `Contract Type_min`,
    MIN(`Hay Level`) AS `Hay Level_min`,
    MIN(`Justification`) AS `Justification_min`,
    MIN(`REQ_EDU_LEVEL`) AS `REQ_EDU_LEVEL_min`,
    MIN(`JobRequisition_std_position_objlist`) AS `JobRequisition_std_position_objlist_min`,
    MIN(`JobRequisition_evergreen`) AS `JobRequisition_evergreen_min`,
    MIN(`Build_Date`) AS `Build_Date_min`
  FROM `raw_data`.`silver_req_date_parsed`
  GROUP BY `Job Req ID`
),

-- Dataiku shaker `compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_prepared_1`: label pivot counts, rename attributes, convert declared types, and apply posting-date fallback
_compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_prepared_1 AS (
  -- Prepare 0: replace External_count values 0–10 with the configured labels
  -- Prepare 1: replace _private_external_count values 0–10 with the configured labels
  -- Prepare 2: replace Internal_count values 0–10 with the configured labels
  -- Prepare 3: replace _private_internal_count values 0–10 with the configured labels
  -- Prepare 4: replace Agency_count values 0–10 with the configured labels
  -- Prepare 5: replace null_Board ID_count values 0–10 with the configured labels
  -- Prepare 6: concatenate Board ID labels into Board ID. (subsequently removed)
  -- Prepare 7: rename the Board ID count columns
  -- Prepare 8: remove the _min suffix from requisition attributes
  -- Prepare 9: disabled ColumnsSelector ignored
  -- Prepare 10: place Board ID indicator columns at the end
  -- Prepare 11: remove the temporary Board ID. concatenation
  -- Prepare 12: place Posting Start Date before Global Leader Position
  -- Prepare 13: rename Date Created and Posting Start Date
  -- Prepare 14: use Req Created Date when Job Title is empty
  -- Prepare 15: place Req Posting Start Date before Global Leader Position
  -- Prepare 16: complete the configured attribute renames
  SELECT
    `Job Req ID`,
    `Job Title_min` AS `Job Title`,
    CAST(`Template ID_min` AS BIGINT) AS `Template ID`,
    `Template Name_min` AS `Template Name`,
    `Requisition Status_min` AS `Requisition Status`,
    `Requisition Status_2_min` AS `Requisition Status_2`,
    `Date Created_min` AS `Req Created Date`,
    CASE
      WHEN `Job Title_min` IS NULL OR `Job Title_min` = '' THEN `Date Created_min`
      ELSE `Posting Start Date_min`
    END AS `Req Posting Start Date`,
    `Global Leader Position_min` AS `Global Leader Position`,
    `Requisition Type_min` AS `Requisition Type`,
    TRY_CAST(`Number of Openings_min` AS BIGINT) AS `Number of Openings`,
    TRY_CAST(`Openings Filled_min` AS BIGINT) AS `Openings Filled`,
    `Business Unit_min` AS `Business Unit`,
    `Division_min` AS `Division`,
    `Department_min` AS `Department`,
    `Legal Entity_min` AS `Legal Entity`,
    `Country_min` AS `Country`,
    `Work Location_min` AS `Work Location`,
    `HR Business Partner User Sys ID_min` AS `HR Business Partner User Sys ID`,
    `HR Business Partner First name_min` AS `HR Business Partner First name`,
    `HR Business Partner Last Name_min` AS `HR Business Partner Last Name`,
    `Recruiter User Sys ID_min` AS `Recruiter User Sys ID`,
    `Recruiter First Name_min` AS `Recruiter First Name`,
    `Recruiter Last Name_min` AS `Recruiter Last Name`,
    `Hiring Manager User Sys ID_min` AS `Hiring Manager User Sys ID`,
    `Hiring Manager First Name_min` AS `Hiring Manager First Name`,
    `Hiring Manager Last Name_min` AS `Hiring Manager Last Name`,
    `Job Family_min` AS `Job Family`,
    `Cost Center_min` AS `Cost Center`,
    `Group Employee Level_min` AS `Group Employee Level`,
    `Job Type_min` AS `Job Type`,
    `Contract Type_min` AS `Contract Type`,
    `Hay Level_min` AS `Hay Level`,
    `Justification_min` AS `Justification`,
    `REQ_EDU_LEVEL_min` AS `REQ_EDU_LEVEL`,
    `JobRequisition_std_position_objlist_min` AS `JobRequisition_std_position_objlist`,
    TRY_CAST(`JobRequisition_evergreen_min` AS BOOLEAN) AS `JobRequisition_evergreen`,
    `Build_Date_min` AS `req_build_Date`,
    CASE
      WHEN `null_Board ID_count` = 0 THEN ''
      WHEN `null_Board ID_count` BETWEEN 1 AND 10 THEN 'null'
      ELSE CAST(`null_Board ID_count` AS STRING)
    END AS `null_Board ID`,
    CASE
      WHEN `Agency_count` = 0 THEN ''
      WHEN `Agency_count` BETWEEN 1 AND 10 THEN 'Agency'
      ELSE CAST(`Agency_count` AS STRING)
    END AS `Agency`,
    CASE
      WHEN `External_count` = 0 THEN ''
      WHEN `External_count` BETWEEN 1 AND 10 THEN 'External'
      ELSE CAST(`External_count` AS STRING)
    END AS `External`,
    CASE
      WHEN `_private_external_count` = 0 THEN ''
      WHEN `_private_external_count` BETWEEN 1 AND 10 THEN 'Private_external'
      ELSE CAST(`_private_external_count` AS STRING)
    END AS `_private_external`,
    CASE
      WHEN `Internal_count` = 0 THEN ''
      WHEN `Internal_count` BETWEEN 1 AND 10 THEN 'Internal'
      ELSE CAST(`Internal_count` AS STRING)
    END AS `Internal`,
    CASE
      WHEN `_private_internal_count` = 0 THEN ''
      WHEN `_private_internal_count` BETWEEN 1 AND 10 THEN 'Private_internal'
      ELSE CAST(`_private_internal_count` AS STRING)
    END AS `_private_internal`
  FROM _compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_1
),

-- Dataiku join `compute_REQ_DISTINCT_joined`: left join assignment date by requisition ID
_compute_req_distinct_joined AS (
  SELECT
    requisitions.*,
    assignments.`Step Last Routed_parsed_max` AS `Req Assignment Date`
  FROM _compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_prepared_1 AS requisitions
  LEFT JOIN _compute_job_requisition_ta_assigned AS assignments
    ON requisitions.`Job Req ID` = assignments.`Job Requisition ID`
),

-- Dataiku join `compute_REQ_DISTINCT_w_Position`: left join position attributes, filter nonempty requisition IDs, and remove duplicates
_compute_req_distinct_w_position AS (
  SELECT DISTINCT
    requisitions.*,
    positions.`POSITION_CODE`,
    positions.`POSITION_VACANT`
  FROM _compute_req_distinct_joined AS requisitions
  LEFT JOIN _compute_ref_pos_filtered AS positions
    ON requisitions.`JobRequisition_std_position_objlist` = positions.`POSITION_CODE`
  WHERE requisitions.`Job Req ID` IS NOT NULL
    AND CAST(requisitions.`Job Req ID` AS STRING) <> ''
),

-- Dataiku join `compute_REQ_DISTINCT_w_Position_joined`: left join the requisition-without-application marker
_compute_req_distinct_w_position_joined AS (
  SELECT DISTINCT
    requisitions.*,
    without_application.`Job Req ID` AS `Req Without Application`
  FROM _compute_req_distinct_w_position AS requisitions
  LEFT JOIN _compute_req_sans_app_prepared AS without_application
    ON requisitions.`Job Req ID` = without_application.`Job Req ID`
),

-- Dataiku shaker `compute_REQ_DISTINCT_w_Position_joined_prepared`: extract and rename Work Location Code
_compute_req_distinct_w_position_joined_prepared AS (
  -- Prepare 0: extract Work Location code1 with /([a-zA-Z0-9_]+)\pP$/
  -- Prepare 1: rename Work Location code1 to Work Location Code
  SELECT
    `Job Req ID`,
    `Job Title`,
    `Template ID`,
    `Template Name`,
    `Requisition Status`,
    `Requisition Status_2`,
    `Req Created Date`,
    `Req Posting Start Date`,
    `Global Leader Position`,
    `Requisition Type`,
    `Number of Openings`,
    `Openings Filled`,
    `Business Unit`,
    `Division`,
    `Department`,
    `Legal Entity`,
    `Country`,
    `Work Location`,
    NULLIF(
      REGEXP_EXTRACT(
        `Work Location`,
        r'([a-zA-Z0-9_]+)\pP$',
        1
      ),
      ''
    ) AS `Work Location Code`,
    `HR Business Partner User Sys ID`,
    `HR Business Partner First name`,
    `HR Business Partner Last Name`,
    `Recruiter User Sys ID`,
    `Recruiter First Name`,
    `Recruiter Last Name`,
    `Hiring Manager User Sys ID`,
    `Hiring Manager First Name`,
    `Hiring Manager Last Name`,
    `Job Family`,
    `Cost Center`,
    `Group Employee Level`,
    `Job Type`,
    `Contract Type`,
    `Hay Level`,
    `Justification`,
    `REQ_EDU_LEVEL`,
    `JobRequisition_std_position_objlist`,
    `JobRequisition_evergreen`,
    `req_build_Date`,
    `null_Board ID`,
    `Agency`,
    `External`,
    `_private_external`,
    `Internal`,
    `_private_internal`,
    `Req Assignment Date`,
    TRY_CAST(`POSITION_CODE` AS INT) AS `POSITION_CODE`,
    `POSITION_VACANT`,
    CAST(`Req Without Application` AS BIGINT) AS `Req Without Application`
  FROM _compute_req_distinct_w_position_joined
)

SELECT * FROM _compute_req_distinct_w_position_joined_prepared;

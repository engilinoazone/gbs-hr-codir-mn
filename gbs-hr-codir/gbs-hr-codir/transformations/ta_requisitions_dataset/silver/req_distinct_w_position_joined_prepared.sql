-- Migrated from Dataiku: compute_Job_Requisition_assignment, compute_REF_POS_filtered, compute_Job_Requisition_TA_assigned, compute_req_sans_app, compute_req_sans_app_prepared, compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_1, compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_prepared_1, compute_REQ_DISTINCT_joined, compute_REQ_DISTINCT_w_Position, compute_REQ_DISTINCT_w_Position_joined, compute_REQ_DISTINCT_w_Position_joined_prepared
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_req_distinct_w_position_joined_prepared`
COMMENT 'Migrated from Dataiku (REQ_DISTINCT_w_Position_joined_prepared)'
AS
WITH
-- Dataiku shaker `compute_Job_Requisition_assignment`: parse Step Last Routed and retain routed rows.
_compute_job_requisition_assignment AS (
  -- Prepare 0: parse Step Last Routed using MMM dd, yyyy hh:mm:ss a.
  -- Prepare 1: keep rows where Step Sub Type equals R.
  SELECT
    CAST(`Job Requisition ID` AS BIGINT) AS `Job Requisition ID`,
    CAST(`Route Entry ID` AS BIGINT) AS `Route Entry ID`,
    `Step Description`,
    `Step Last Routed`,
    TO_DATE(TO_TIMESTAMP(`Step Last Routed`, 'MMM dd, yyyy hh:mm:ss a')) AS `Step Last Routed_parsed`,
    `Step Status`,
    `Step Sub Status`,
    `Step Sub Type`,
    `Step Type`,
    `User ID`
  FROM `hr_gbs_dev`.`raw_data`.`bronze_recruiting_route_map`
  WHERE `Step Sub Type` = 'R'
),

-- Dataiku sampling `compute_REF_POS_filtered`: retain rows whose POSITION_LABEL is numerically at least zero.
_compute_ref_pos_filtered AS (
  SELECT
    `POSITION_CODE`,
    `POSITION_LABEL`,
    `POSITION_PARENT`,
    `POSITION_STATUS`,
    `POSITION_DEPARTMENT`,
    `POSITION_SECOND_AXIS`,
    `POSITION_VACANT`
  FROM `hr_gbs_dev`.`raw_data`.`bronze_ref_pos`
  WHERE TRY_CAST(`POSITION_LABEL` AS DOUBLE) >= 0
),

-- Dataiku grouping `compute_Job_Requisition_TA_assigned`: aggregate assignment attributes by requisition.
_compute_job_requisition_ta_assigned AS (
  SELECT
    `Job Requisition ID`,
    MAX(`Step Last Routed_parsed`) AS `Step Last Routed_parsed_max`,
    MAX(`Step Status`) AS `Step Status_max`,
    MAX(`User ID`) AS `User ID_max`
  FROM _compute_job_requisition_assignment
  GROUP BY `Job Requisition ID`
),

-- Dataiku join `compute_req_sans_app`: select requisitions joined to empty-application rows.
_compute_req_sans_app AS (
  SELECT
    r.`Job Req ID` AS `Job Req ID`
  FROM (
    SELECT
      `Job Req ID`,
      `Application ID`
    FROM `hr_gbs_dev`.`raw_data`.`bronze_applications_gbs`
    WHERE `Application ID` IS NULL OR `Application ID` = ''
  ) AS a
  INNER JOIN (
    SELECT `Job Req ID`
    FROM `raw_data`.`silver_req_gbs_jobreqid_type`
  ) AS r
    ON a.`Job Req ID` = r.`Job Req ID`
),

-- Dataiku shaker `compute_req_sans_app_prepared`: pass through the single requisition identifier.
_compute_req_sans_app_prepared AS (
  SELECT
    `Job Req ID`
  FROM _compute_req_sans_app
),

-- Dataiku pivot `compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_1`: pivot Board ID counts and retain minimum requisition attributes.
_compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_1 AS (
  SELECT
    `Job Req ID`,
    COUNT(CASE WHEN `Board ID` IS NULL THEN 1 END) AS `null_Board ID_count`,
    COUNT(CASE WHEN `Board ID` = 'Agency' THEN 1 END) AS `Agency_count`,
    COUNT(CASE WHEN `Board ID` = 'External' THEN 1 END) AS `External_count`,
    COUNT(CASE WHEN `Board ID` = 'Internal' THEN 1 END) AS `Internal_count`,
    COUNT(CASE WHEN `Board ID` = '_private_external' THEN 1 END) AS `_private_external_count`,
    COUNT(CASE WHEN `Board ID` = '_private_internal' THEN 1 END) AS `_private_internal_count`,
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

-- Dataiku shaker `compute_dataset_REQ_GBS_PBI_w_HASH_by_Job_Req_ID_prepared_1`: convert pivot counts to labels, rename attributes and apply posting-date fallback.
_compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_prepared_1 AS (
  -- Prepare 0: replace External_count digits with the External label.
  -- Prepare 1: replace _private_external_count digits with the Private_external label.
  -- Prepare 2: replace Internal_count digits with the Internal label.
  -- Prepare 3: replace _private_internal_count digits with the Private_internal label.
  -- Prepare 4: replace Agency_count digits with the Agency label.
  -- Prepare 5: replace null_Board ID_count digits with the null label.
  -- Prepare 6: concatenate the transient Board ID. column; it is removed by Prepare 11.
  -- Prepare 7: rename the six pivot-count columns.
  -- Prepare 8: remove the aggregate suffix from requisition attributes.
  -- Prepare 10: move the six Board ID label columns to the end.
  -- Prepare 11: remove the transient Board ID. column.
  -- Prepare 12: move Posting Start Date before Global Leader Position.
  -- Prepare 13: rename Date Created and Posting Start Date.
  -- Prepare 14: when Job Title is empty, use Req Created Date as Req Posting Start Date.
  -- Prepare 15: keep Req Posting Start Date before Global Leader Position.
  -- Prepare 16: complete the Work Location, HRBP and hiring-manager renames.
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
    CAST(`Number of Openings_min` AS BIGINT) AS `Number of Openings`,
    CAST(`Openings Filled_min` AS BIGINT) AS `Openings Filled`,
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
    CAST(`JobRequisition_evergreen_min` AS BOOLEAN) AS `JobRequisition_evergreen`,
    `Build_Date_min` AS `req_build_Date`,
    REGEXP_REPLACE(
      REPLACE(CAST(`null_Board ID_count` AS STRING), '0', ''),
      '[1-9]',
      'null'
    ) AS `null_Board ID`,
    REGEXP_REPLACE(
      REPLACE(CAST(`Agency_count` AS STRING), '0', ''),
      '[1-9]',
      'Agency'
    ) AS `Agency`,
    REGEXP_REPLACE(
      REPLACE(CAST(`External_count` AS STRING), '0', ''),
      '[1-9]',
      'External'
    ) AS `External`,
    REGEXP_REPLACE(
      REPLACE(CAST(`_private_external_count` AS STRING), '0', ''),
      '[1-9]',
      'Private_external'
    ) AS `_private_external`,
    REGEXP_REPLACE(
      REPLACE(CAST(`Internal_count` AS STRING), '0', ''),
      '[1-9]',
      'Internal'
    ) AS `Internal`,
    REGEXP_REPLACE(
      REPLACE(CAST(`_private_internal_count` AS STRING), '0', ''),
      '[1-9]',
      'Private_internal'
    ) AS `_private_internal`
  FROM _compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_1
),

-- Dataiku join `compute_REQ_DISTINCT_joined`: left join the assignment date to each requisition.
_compute_req_distinct_joined AS (
  SELECT
    d.*,
    a.`Step Last Routed_parsed_max` AS `Req Assignment Date`
  FROM _compute_dataset_req_gbs_pbi_w_hash_by_job_req_id_prepared_1 AS d
  LEFT JOIN _compute_job_requisition_ta_assigned AS a
    ON d.`Job Req ID` = a.`Job Requisition ID`
),

-- Dataiku join `compute_REQ_DISTINCT_w_Position`: left join position data, filter non-null requisition IDs and deduplicate.
_compute_req_distinct_w_position AS (
  SELECT DISTINCT
    r.*,
    p.`POSITION_CODE`,
    p.`POSITION_VACANT`
  FROM _compute_req_distinct_joined AS r
  LEFT JOIN _compute_ref_pos_filtered AS p
    ON r.`JobRequisition_std_position_objlist` = p.`POSITION_CODE`
  WHERE r.`Job Req ID` IS NOT NULL
),

-- Dataiku join `compute_REQ_DISTINCT_w_Position_joined`: left join the requisitions identified without an application.
_compute_req_distinct_w_position_joined AS (
  SELECT
    r.*,
    a.`Job Req ID` AS `Req Without Application`
  FROM _compute_req_distinct_w_position AS r
  LEFT JOIN _compute_req_sans_app_prepared AS a
    ON r.`Job Req ID` = a.`Job Req ID`
),

-- Dataiku shaker `compute_REQ_DISTINCT_w_Position_joined_prepared`: extract and rename the work-location code.
_compute_req_distinct_w_position_joined_prepared AS (
  -- Prepare 0: extract the final alphanumeric token followed by punctuation from Work Location.
  -- Prepare 1: rename Work Location code1 to Work Location Code.
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
    `POSITION_CODE`,
    `POSITION_VACANT`,
    `Req Without Application`
  FROM _compute_req_distinct_w_position_joined
)
SELECT * FROM _compute_req_distinct_w_position_joined_prepared;

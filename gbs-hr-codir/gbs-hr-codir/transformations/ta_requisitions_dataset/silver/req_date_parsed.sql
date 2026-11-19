-- Migrated from Dataiku: compute_REQ_GBS_distinct_1, compute_dataset_REQ_GBS_PBI_prepared_1
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_req_date_parsed`
COMMENT 'Migrated from Dataiku (REQ_date_parsed)'
AS
WITH
-- Dataiku distinct `compute_REQ_GBS_distinct_1`: deduplicate on all 39 declared output columns
_compute_req_gbs_distinct_1 AS (
  SELECT DISTINCT
    `Job Req ID`,
    `Job Title`,
    `Template ID`,
    `Template Name`,
    `Requisition Status`,
    `Requisition Status_2`,
    `Date Created`,
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
    `Posting Start Date`,
    `Group Employee Level`,
    `Job Type`,
    `Contract Type`,
    `Board ID`,
    `Hay Level`,
    `Justification`,
    `REQ_EDU_LEVEL`,
    `JobRequisition_std_position_objlist`,
    `JobRequisition_evergreen`,
    `Build_Date`
  FROM `raw_data`.`silver_req_gbs_jobreqid_type`
),
-- Dataiku shaker `compute_dataset_REQ_GBS_PBI_prepared_1`: parse Date Created and Posting Start Date as dates
_compute_dataset_req_gbs_pbi_prepared_1 AS (
  SELECT
    `Job Req ID`,
    `Job Title`,
    `Template ID`,
    `Template Name`,
    `Requisition Status`,
    `Requisition Status_2`,
    -- Prepare step 0: parse Date Created as MM/dd/yyyy in place
    to_date(`Date Created`, 'MM/dd/yyyy') AS `Date Created`,
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
    -- Prepare step 1: parse Posting Start Date as MM/dd/yyyy in place
    to_date(`Posting Start Date`, 'MM/dd/yyyy') AS `Posting Start Date`,
    `Group Employee Level`,
    `Job Type`,
    `Contract Type`,
    `Board ID`,
    `Hay Level`,
    `Justification`,
    `REQ_EDU_LEVEL`,
    `JobRequisition_std_position_objlist`,
    `JobRequisition_evergreen`,
    `Build_Date`
  FROM _compute_req_gbs_distinct_1
)
SELECT * FROM _compute_dataset_req_gbs_pbi_prepared_1;

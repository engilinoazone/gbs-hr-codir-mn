-- Migrated from Dataiku: compute_REQ_FINAL_prepared_1
-- Target realigned on the registered output of this step (slv.bronze_req_final_prepared_1).
-- The "bronze_" prefix is knowingly not the ideal medallion layer for a Prepare output; the user accepts it
-- and will rename it later directly in the pipelines, so that code and plan metadata stay consistent.
CREATE OR REFRESH MATERIALIZED VIEW `slv`.`bronze_req_final_prepared_1`
COMMENT 'Migrated from Dataiku (REQ_FINAL_prepared_1)'
AS
-- Dataiku shaker `compute_REQ_FINAL_prepared_1`: extract and normalize Department ID, tokenize Division for Division ID, and select declared columns
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
  `Business Unit`,
  `Division`,
  -- Step 3 [Tokenizer]: tokenize Division without normalization into the transient div value
  -- Step 4 [JSONPathExtractor]: extract the last token from div as Division ID ($[-1], singleValue)
  -- try_element_at so an empty/token-less Division yields NULL instead of failing under ANSI mode
  try_element_at(
    regexp_extract_all(`Division`, r'[\p{L}\p{N}_]+', 0),
    -1
  ) AS `Division ID`,
  `Department`,
  -- Step 0 [RegexpExtractor]: extract the first punctuation-delimited numeric value from Department
  -- Step 1 [TextSimplifierProcessor]: normalize the extracted value
  -- Step 2 [ColumnRenamer]: rename the extracted column from 1 to Department ID
  nullif(
    regexp_replace(
      regexp_extract(`Department`, r'(\pP[0-9]+\pP)', 1),
      r'\pP',
      ''
    ),
    ''
  ) AS `Department ID`,
  `Legal Entity`,
  `Country`,
  `HR Business Partner User Sys ID`,
  `Recruiter User Sys ID`,
  `Recruiter First Name`,
  `Recruiter Last Name`,
  `Hiring Manager User Sys ID`,
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
  `Time_to_KPI_GRP_scope`,
  `Req Without Application`,
  CAST(`build_req_status` AS DATE) AS `build_req_status`
  -- Step 5 [ColumnsSelector]: omit the transient div column
FROM `raw_data`.`silver_req_final`;

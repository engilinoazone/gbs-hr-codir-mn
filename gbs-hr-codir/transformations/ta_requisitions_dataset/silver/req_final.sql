-- Migrated from Dataiku: compute_REQ_DISTINCT_w_Position_joined_GID_Recruteur, compute_Jointure_GID_Recruteur_PBI_Op_TA, compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared, compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined, compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined_joined, compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined_joined_by_Job_Req_ID, compute_REQ_FLAG_FILTER_GRP
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_req_final` (
  CONSTRAINT req_created_date_present EXPECT (`Req Created Date` IS NOT NULL),
  CONSTRAINT job_req_id_present EXPECT (`Job Req ID` IS NOT NULL),
  CONSTRAINT requisition_status_2_present EXPECT (`Requisition Status_2` IS NOT NULL),
  CONSTRAINT requisition_status_present EXPECT (`Requisition Status` IS NOT NULL),
  CONSTRAINT req_posting_start_date_present EXPECT (`Req Posting Start Date` IS NOT NULL),
  CONSTRAINT division_present EXPECT (`Division` IS NOT NULL),
  CONSTRAINT department_present EXPECT (`Department` IS NOT NULL),
  CONSTRAINT legal_entity_present EXPECT (`Legal Entity` IS NOT NULL),
  CONSTRAINT country_present EXPECT (`Country` IS NOT NULL),
  CONSTRAINT recruiter_user_sys_id_present EXPECT (`Recruiter User Sys ID` IS NOT NULL),
  CONSTRAINT recruiter_first_name_present EXPECT (`Recruiter First Name` IS NOT NULL),
  CONSTRAINT recruiter_last_name_present EXPECT (`Recruiter Last Name` IS NOT NULL)
)
COMMENT 'Migrated from Dataiku (REQ_FINAL)'
AS
WITH
-- Dataiku join `compute_REQ_DISTINCT_w_Position_joined_GID_Recruteur`: left join on Job Req ID, selecting the requisition close date and recruiter GID, then distinct.
_compute_req_distinct_w_position_joined_gid_recruteur AS (
  SELECT DISTINCT
    req.`Job Req ID`,
    req.`Job Title`,
    req.`Template ID`,
    req.`Template Name`,
    req.`Requisition Status`,
    req.`Requisition Status_2`,
    req.`Req Created Date`,
    req.`Req Posting Start Date`,
    req.`Global Leader Position`,
    req.`Requisition Type`,
    req.`Number of Openings`,
    req.`Openings Filled`,
    req.`Business Unit`,
    req.`Division`,
    req.`Department`,
    req.`Legal Entity`,
    req.`Country`,
    req.`Work Location`,
    req.`Work Location Code`,
    req.`HR Business Partner User Sys ID`,
    req.`HR Business Partner First name`,
    req.`HR Business Partner Last Name`,
    req.`Recruiter User Sys ID`,
    req.`Recruiter First Name`,
    req.`Recruiter Last Name`,
    req.`Hiring Manager User Sys ID`,
    req.`Hiring Manager First Name`,
    req.`Hiring Manager Last Name`,
    req.`Job Family`,
    req.`Cost Center`,
    req.`Group Employee Level`,
    req.`Job Type`,
    req.`Contract Type`,
    req.`Hay Level`,
    req.`Justification`,
    req.`REQ_EDU_LEVEL`,
    req.`JobRequisition_std_position_objlist`,
    req.`JobRequisition_evergreen`,
    req.`req_build_Date`,
    req.`null_Board ID`,
    req.`Agency`,
    req.`External`,
    req.`_private_external`,
    req.`Internal`,
    req.`_private_internal`,
    req.`Req Assignment Date`,
    req.`POSITION_CODE`,
    req.`POSITION_VACANT`,
    req.`Req Without Application`,
    req.`CITY`,
    gbs.`JobRequisition_closedDateTime`,
    gbs.`Recruiter GID` AS `Recruiter GID`
  FROM `raw_data`.`silver_req_distinct_w_position_joined_prepared_joined` AS req
  LEFT JOIN `raw_data`.`silver_req_gbs_jobreqid_type` AS gbs
    ON req.`Job Req ID` = gbs.`Job Req ID`
),

-- Dataiku join `compute_Jointure_GID_Recruteur_PBI_Op_TA`: left join recruiter details on Recruiter GID = GID_Recruteur.
_compute_jointure_gid_recruteur_pbi_op_ta AS (
  SELECT
    req.*,
    ta.`GID_Recruteur` AS `TA_GID_Recruteur`,
    ta.`Nom_Recruteur` AS `TA_Nom_Recruteur`,
    ta.`Prénom_Recruteur` AS `TA_Prénom_Recruteur`,
    ta.`Equipe_Recruteur` AS `TA_Equipe_Recruteur`,
    ta.`Fonction_Recruteur` AS `TA_Fonction_Recruteur`,
    ta.`Localisation_Recruteur` AS `TA_Localisation_Recruteur`,
    ta.`Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`
      AS `TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
    ta.`Nom_Manager` AS `TA_Nom_Manager`,
    ta.`Prénom_Manager` AS `TA_Prénom_Manager`,
    ta.`Commentaires` AS `TA_Commentaires`
  FROM _compute_req_distinct_w_position_joined_gid_recruteur AS req
  LEFT JOIN `raw_data`.`silver_liste_de_recruteurs_ta_pbi_operationnel_ta_prepared` AS ta
    ON req.`Recruiter GID` = ta.`GID_Recruteur`
),

-- Dataiku shaker `compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared`: replace missing TA values and remove seven unused TA columns.
_compute_jointure_gid_recruteur_pbi_op_ta_prepared AS (
  SELECT
    CAST(src.`Job Req ID` AS STRING) AS `Job Req ID`,
    src.`Job Title`,
    src.`Template ID`,
    src.`Template Name`,
    src.`Requisition Status`,
    src.`Requisition Status_2`,
    src.`Req Created Date`,
    src.`Req Posting Start Date`,
    src.`Global Leader Position`,
    src.`Requisition Type`,
    src.`Number of Openings`,
    src.`Openings Filled`,
    src.`Business Unit`,
    src.`Division`,
    src.`Department`,
    src.`Legal Entity`,
    src.`Country`,
    src.`Work Location`,
    src.`Work Location Code`,
    src.`HR Business Partner User Sys ID`,
    src.`HR Business Partner First name`,
    src.`HR Business Partner Last Name`,
    src.`Recruiter User Sys ID`,
    src.`Recruiter First Name`,
    src.`Recruiter Last Name`,
    src.`Hiring Manager User Sys ID`,
    src.`Hiring Manager First Name`,
    src.`Hiring Manager Last Name`,
    src.`Job Family`,
    src.`Cost Center`,
    src.`Group Employee Level`,
    src.`Job Type`,
    src.`Contract Type`,
    src.`Hay Level`,
    src.`Justification`,
    src.`REQ_EDU_LEVEL`,
    src.`JobRequisition_std_position_objlist`,
    src.`JobRequisition_evergreen`,
    src.`req_build_Date`,
    src.`null_Board ID`,
    src.`Agency`,
    src.`External`,
    src.`_private_external`,
    src.`Internal`,
    src.`_private_internal`,
    src.`Req Assignment Date`,
    CAST(src.`POSITION_CODE` AS STRING) AS `POSITION_CODE`,
    src.`POSITION_VACANT`,
    src.`Req Without Application`,
    src.`CITY`,
    src.`JobRequisition_closedDateTime`,
    src.`Recruiter GID`,
    -- Prepare step 0: replace missing TA-list values.
    COALESCE(
      src.`TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
      'Le recruteur n''est pas dans la liste TA fournie'
    ) AS `TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
    COALESCE(
      src.`TA_Nom_Manager`,
      'Le recruteur n''est pas dans la liste TA fournie'
    ) AS `TA_Nom_Manager`,
    COALESCE(
      src.`TA_Prénom_Manager`,
      'Le recruteur n''est pas dans la liste TA fournie'
    ) AS `TA_Prénom_Manager`
    -- Prepare step 1: omit TA_Commentaires, TA_GID_Recruteur, TA_Equipe_Recruteur,
    -- TA_Fonction_Recruteur, TA_Nom_Recruteur, TA_Prénom_Recruteur and TA_Localisation_Recruteur.
  FROM _compute_jointure_gid_recruteur_pbi_op_ta AS src
),

-- Dataiku join `compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined`: left join position reference on POSITION_CODE.
_compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined AS (
  SELECT
    req.*,
    pos.`POSITION_SECOND_AXIS`
  FROM _compute_jointure_gid_recruteur_pbi_op_ta_prepared AS req
  LEFT JOIN `raw_data`.`silver_ref_pos_prepared2` AS pos
    ON req.`POSITION_CODE` = pos.`POSITION_CODE`
),

-- Dataiku join `compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined_joined`: left join SOA reference on second-axis code, then distinct.
_compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined_joined AS (
  SELECT DISTINCT
    req.*,
    soa.`CUST_BUSINESSPLATFORM_externalName_defaultValue` AS `Second Organization Axis`
  FROM _compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined AS req
  LEFT JOIN `raw_data`.`bronze_ref_soa` AS soa
    ON req.`POSITION_SECOND_AXIS` = soa.`CUST_BUSINESSPLATFORM_externalCode`
),

-- Dataiku grouping `compute_Jointure_GID_Recruteur_PBI_Op_TA_prepared_joined_joined_by_Job_Req_ID`: group on all requisition attributes and take the first organization-axis value.
_compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined_joined_by_job_req_id AS (
  SELECT
    src.`Job Req ID`,
    src.`Job Title`,
    src.`Template ID`,
    src.`Template Name`,
    src.`Requisition Status`,
    src.`Requisition Status_2`,
    src.`Req Created Date`,
    src.`Req Posting Start Date`,
    src.`Global Leader Position`,
    src.`Requisition Type`,
    src.`Number of Openings`,
    src.`Openings Filled`,
    src.`Business Unit`,
    src.`Division`,
    src.`Department`,
    src.`Legal Entity`,
    src.`Country`,
    src.`Work Location`,
    src.`Work Location Code`,
    src.`HR Business Partner User Sys ID`,
    src.`HR Business Partner First name`,
    src.`HR Business Partner Last Name`,
    src.`Recruiter User Sys ID`,
    src.`Recruiter First Name`,
    src.`Recruiter Last Name`,
    src.`Hiring Manager User Sys ID`,
    src.`Hiring Manager First Name`,
    src.`Hiring Manager Last Name`,
    src.`Job Family`,
    src.`Cost Center`,
    src.`Group Employee Level`,
    src.`Job Type`,
    src.`Contract Type`,
    src.`Hay Level`,
    src.`Justification`,
    src.`REQ_EDU_LEVEL`,
    src.`JobRequisition_std_position_objlist`,
    src.`JobRequisition_evergreen`,
    src.`req_build_Date`,
    src.`null_Board ID`,
    src.`Agency`,
    src.`External`,
    src.`_private_external`,
    src.`Internal`,
    src.`_private_internal`,
    src.`Req Assignment Date`,
    src.`POSITION_CODE`,
    src.`POSITION_VACANT`,
    src.`Req Without Application`,
    src.`CITY`,
    src.`JobRequisition_closedDateTime`,
    src.`Recruiter GID`,
    src.`TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
    src.`TA_Nom_Manager`,
    src.`TA_Prénom_Manager`,
    first(src.`Second Organization Axis`, false) AS `Second Organization Axis_first`
  FROM _compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined_joined AS src
  GROUP BY
    src.`Job Req ID`,
    src.`Job Title`,
    src.`Template ID`,
    src.`Template Name`,
    src.`Requisition Status`,
    src.`Requisition Status_2`,
    src.`Req Created Date`,
    src.`Req Posting Start Date`,
    src.`Global Leader Position`,
    src.`Requisition Type`,
    src.`Number of Openings`,
    src.`Openings Filled`,
    src.`Business Unit`,
    src.`Division`,
    src.`Department`,
    src.`Legal Entity`,
    src.`Country`,
    src.`Work Location`,
    src.`Work Location Code`,
    src.`HR Business Partner User Sys ID`,
    src.`HR Business Partner First name`,
    src.`HR Business Partner Last Name`,
    src.`Recruiter User Sys ID`,
    src.`Recruiter First Name`,
    src.`Recruiter Last Name`,
    src.`Hiring Manager User Sys ID`,
    src.`Hiring Manager First Name`,
    src.`Hiring Manager Last Name`,
    src.`Job Family`,
    src.`Cost Center`,
    src.`Group Employee Level`,
    src.`Job Type`,
    src.`Contract Type`,
    src.`Hay Level`,
    src.`Justification`,
    src.`REQ_EDU_LEVEL`,
    src.`JobRequisition_std_position_objlist`,
    src.`JobRequisition_evergreen`,
    src.`req_build_Date`,
    src.`null_Board ID`,
    src.`Agency`,
    src.`External`,
    src.`_private_external`,
    src.`Internal`,
    src.`_private_internal`,
    src.`Req Assignment Date`,
    src.`POSITION_CODE`,
    src.`POSITION_VACANT`,
    src.`Req Without Application`,
    src.`CITY`,
    src.`JobRequisition_closedDateTime`,
    src.`Recruiter GID`,
    src.`TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
    src.`TA_Nom_Manager`,
    src.`TA_Prénom_Manager`
),

-- Dataiku shaker `compute_REQ_FLAG_FILTER_GRP`: calculate the KPI flag, remove opening metrics, add the build date, transform the application flag, and rename final columns.
_compute_req_flag_filter_grp AS (
  SELECT
    CAST(src.`Job Req ID` AS BIGINT) AS `Job Req ID`,
    src.`Job Title`,
    src.`Template ID`,
    src.`Template Name`,
    src.`Requisition Status`,
    src.`Requisition Status_2`,
    src.`Req Created Date`,
    src.`Req Posting Start Date`,
    CAST(src.`Global Leader Position` AS BOOLEAN) AS `Global Leader Position`,
    src.`Requisition Type`,
    src.`Business Unit`,
    src.`Division`,
    src.`Department`,
    src.`Legal Entity`,
    src.`Country`,
    src.`Work Location`,
    CAST(src.`Work Location Code` AS BIGINT) AS `Work Location Code`,
    src.`HR Business Partner User Sys ID`,
    src.`HR Business Partner First name`,
    src.`HR Business Partner Last Name`,
    src.`Recruiter User Sys ID`,
    src.`Recruiter First Name`,
    src.`Recruiter Last Name`,
    src.`Hiring Manager User Sys ID`,
    src.`Hiring Manager First Name`,
    src.`Hiring Manager Last Name`,
    src.`Job Family`,
    src.`Cost Center`,
    src.`Group Employee Level`,
    src.`Job Type`,
    src.`Contract Type`,
    src.`Hay Level`,
    src.`Justification`,
    src.`REQ_EDU_LEVEL`,
    src.`JobRequisition_std_position_objlist`,
    CAST(src.`JobRequisition_evergreen` AS STRING) AS `JobRequisition_evergreen`,
    src.`req_build_Date`,
    src.`null_Board ID`,
    src.`Agency`,
    src.`External`,
    src.`_private_external`,
    src.`Internal`,
    src.`_private_internal`,
    src.`Req Assignment Date`,
    CAST(src.`POSITION_CODE` AS BIGINT) AS `POSITION_CODE`,
    CAST(src.`POSITION_VACANT` AS BOOLEAN) AS `POSITION_VACANT`,

    -- Prepare steps 1-2: VisualIfRule followed by FlagOnValue; the latter defines the retained flag.
    CAST(
      CASE
        WHEN src.`Requisition Status_2` = 'Filled'
         AND src.`JobRequisition_evergreen` = false
         AND src.`Contract Type` IN (
           'Permanent',
           'Trainee',
           'Fixed-Term',
           'Apprenticeship',
           'Internship'
         )
         AND src.`POSITION_VACANT` = 'false'
        THEN 1
        ELSE 0
      END
      AS BIGINT
    ) AS `Time_to_KPI_GRP_scope`,

    -- Prepare step 7: GREL isNumeric on the bigint source yields true for non-null values.
    CASE
      WHEN src.`Req Without Application` IS NOT NULL THEN true
      ELSE CAST(NULL AS BOOLEAN)
    END AS `Req Without Application`,

    src.`CITY`,

    -- Prepare step 9: rename JobRequisition_closedDateTime.
    src.`JobRequisition_closedDateTime` AS `Req Closing Date`,
    src.`Recruiter GID` AS `Recruiter GID`,
    src.`TA_Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
    src.`TA_Nom_Manager`,
    src.`TA_Prénom_Manager`,

    -- Prepare step 9: rename Second Organization Axis_first.
    src.`Second Organization Axis_first` AS `Second Organization Axis`,

    -- Prepare steps 5-6: add the execution date and format it in UTC as yyyy/MM/dd.
    date_format(
      to_utc_timestamp(current_timestamp(), current_timezone()),
      'yyyy/MM/dd'
    ) AS `build_req_status`

    -- Prepare step 0 is disabled.
    -- Prepare step 3 creates Time_To_Hire_Grp_flag, which prepare step 8 subsequently removes.
    -- Prepare step 4 removes Openings Filled and Number of Openings.
  FROM _compute_jointure_gid_recruteur_pbi_op_ta_prepared_joined_joined_by_job_req_id AS src
)
SELECT * FROM _compute_req_flag_filter_grp;

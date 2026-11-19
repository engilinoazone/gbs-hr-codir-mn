-- Migrated from Dataiku: compute_APP_HASH_format, compute_GBS_RECRUITMENT_FUNNEL_distinct, compute_REQ_HASH_distinct, compute_RECRUITMENT_FUNNEL_HASHED, compute_RECRUITMENT_FUNNEL_FILLED
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_recruitment_funnel_filled_onhold`
COMMENT 'Migrated from Dataiku (RECRUITMENT_FUNNEL_Filled_OnHold)'
AS
WITH
-- Dataiku shaker `compute_APP_HASH_format`: convert Application ID from EN numerical format to RAW integer
_compute_app_hash_format AS (
  SELECT
    -- Prepare step 0: NumericalFormatConverter (EN to RAW) on Application ID
    CAST(regexp_replace(`Application ID`, ',', '') AS INT) AS `Application ID`,
    `Application ID_hashed`
  FROM `raw_data`.`bronze_app_hash`
),

-- Dataiku distinct `compute_GBS_RECRUITMENT_FUNNEL_distinct`: deduplicate on all 30 declared key columns
_compute_gbs_recruitment_funnel_distinct AS (
  SELECT DISTINCT
    `JobRequisitionID`,
    `TemplateID`,
    `RequisitionType`,
    `RequisitionDateCreated_formatted`,
    `Application Date_parsed`,
    `ApplicationID`,
    `PostingStartDate_formatted`,
    `FunnelStatusCategory`,
    `FunnelCurrentStatus`,
    `SkippedStatus`,
    `IsInternal`,
    `AppClosed`,
    `AppSomebodyArrived`,
    `App_SomebodyHired?`,
    `JobSomebodyHired`,
    `JobSomebodyRelevantArrived`,
    `RelevantStepArrival`,
    `EmploymentDetailsMostRecentHireDate_formatted`,
    `GenderPrediction`,
    `GroupEmployeeLevel`,
    `GlobalLeaderPosition`,
    `JobFamilyID`,
    `DepartmentID`,
    `CostCenterID`,
    `LegalEntityID`,
    `SmartCodeID`,
    `DaysInStatus`,
    `Arrivals`,
    `DivisionLvl2ID`,
    `Build_Date`
  FROM `raw_data`.`bronze_gbs_recruitment_funnel`
),

-- Dataiku distinct `compute_REQ_HASH_distinct`: deduplicate requisition IDs and their hashed values
_compute_req_hash_distinct AS (
  SELECT DISTINCT
    `JobRequisition_jobReqId`,
    `JobRequisition_jobReqId_Hashed`
  FROM `raw_data`.`bronze_req_hash`
),

-- Dataiku join `compute_RECRUITMENT_FUNNEL_HASHED`: left join application and requisition hash mappings
_compute_recruitment_funnel_hashed AS (
  SELECT
    funnel.`RequisitionType`,
    funnel.`RequisitionDateCreated_formatted`,
    funnel.`Application Date_parsed`,
    funnel.`PostingStartDate_formatted`,
    funnel.`FunnelStatusCategory`,
    funnel.`FunnelCurrentStatus`,
    funnel.`SkippedStatus`,
    funnel.`IsInternal`,
    funnel.`AppClosed`,
    funnel.`AppSomebodyArrived`,
    funnel.`App_SomebodyHired?`,
    funnel.`JobSomebodyHired`,
    funnel.`JobSomebodyRelevantArrived`,
    funnel.`RelevantStepArrival`,
    funnel.`EmploymentDetailsMostRecentHireDate_formatted`,
    funnel.`GenderPrediction`,
    funnel.`GroupEmployeeLevel`,
    funnel.`GlobalLeaderPosition`,
    funnel.`JobFamilyID`,
    funnel.`DepartmentID`,
    funnel.`CostCenterID`,
    funnel.`LegalEntityID`,
    funnel.`SmartCodeID`,
    funnel.`DaysInStatus`,
    funnel.`Arrivals`,
    funnel.`DivisionLvl2ID`,
    funnel.`Build_Date`,
    app_hash.`Application ID`,
    req_hash.`JobRequisition_jobReqId`
  FROM _compute_gbs_recruitment_funnel_distinct AS funnel
  LEFT JOIN _compute_app_hash_format AS app_hash
    ON funnel.`ApplicationID` = app_hash.`Application ID_hashed`
  LEFT JOIN _compute_req_hash_distinct AS req_hash
    ON funnel.`JobRequisitionID` = req_hash.`JobRequisition_jobReqId_Hashed`
),

-- Dataiku join `compute_RECRUITMENT_FUNNEL_FILLED`: left join requisition details and apply output distinct
_compute_recruitment_funnel_filled AS (
  SELECT DISTINCT
    funnel.`RequisitionType`,
    funnel.`RequisitionDateCreated_formatted`,
    funnel.`Application Date_parsed`,
    funnel.`PostingStartDate_formatted`,
    funnel.`FunnelStatusCategory`,
    funnel.`FunnelCurrentStatus`,
    funnel.`SkippedStatus`,
    funnel.`IsInternal`,
    funnel.`AppClosed`,
    funnel.`AppSomebodyArrived`,
    funnel.`App_SomebodyHired?`,
    funnel.`JobSomebodyHired`,
    funnel.`JobSomebodyRelevantArrived`,
    funnel.`RelevantStepArrival`,
    funnel.`EmploymentDetailsMostRecentHireDate_formatted`,
    funnel.`GroupEmployeeLevel`,
    funnel.`GlobalLeaderPosition`,
    funnel.`JobFamilyID`,
    funnel.`DepartmentID`,
    funnel.`CostCenterID`,
    funnel.`LegalEntityID`,
    funnel.`SmartCodeID`,
    funnel.`DaysInStatus`,
    funnel.`Arrivals`,
    funnel.`DivisionLvl2ID`,
    funnel.`Build_Date` AS `Funnel_build_Date`,
    funnel.`Application ID`,
    funnel.`JobRequisition_jobReqId` AS `Requisition Id`,
    requisition.`Requisition Status_2`,
    requisition.`Contract Type`,
    requisition.`JobRequisition_evergreen`
  FROM _compute_recruitment_funnel_hashed AS funnel
  LEFT JOIN `raw_data`.`silver_req_date_parsed` AS requisition
    ON funnel.`JobRequisition_jobReqId` = requisition.`Job Req ID`
)

SELECT * FROM _compute_recruitment_funnel_filled;

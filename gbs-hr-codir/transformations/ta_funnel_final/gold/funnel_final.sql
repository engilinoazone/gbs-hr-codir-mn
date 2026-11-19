-- Migrated from Dataiku: compute_RECRUITMENT_FUNNEL_Time_to_Staff, compute_RECRUITMENT_FUNNEL_Time_to_Staff_prepared, compute_FUNNEL_FINAL
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`gold_funnel_final`
COMMENT 'Migrated from Dataiku (FUNNEL_FINAL)'
AS
WITH
-- Dataiku window `compute_RECRUITMENT_FUNNEL_Time_to_Staff`: partition by Application ID and sum DaysInStatus across the partition
_compute_recruitment_funnel_time_to_staff AS (
  SELECT
    RequisitionType,
    RequisitionDateCreated_formatted,
    `Application Date_parsed`,
    PostingStartDate_formatted,
    FunnelStatusCategory,
    FunnelCurrentStatus,
    SkippedStatus,
    IsInternal,
    AppClosed,
    AppSomebodyArrived,
    `App_SomebodyHired?`,
    JobSomebodyHired,
    JobSomebodyRelevantArrived,
    RelevantStepArrival,
    EmploymentDetailsMostRecentHireDate_formatted,
    GroupEmployeeLevel,
    GlobalLeaderPosition,
    JobFamilyID,
    DepartmentID,
    CostCenterID,
    LegalEntityID,
    SmartCodeID,
    DaysInStatus,
    Arrivals,
    DivisionLvl2ID,
    `Application ID`,
    `Requisition Status_2`,
    `Contract Type`,
    JobRequisition_evergreen,
    SUM(DaysInStatus) OVER (
      PARTITION BY `Application ID`
      ORDER BY FunnelStatusCategory ASC
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS DaysInStatus_sum
  FROM `raw_data`.`silver_recruitment_funnel_filled_onhold`
),

-- Dataiku shaker `compute_RECRUITMENT_FUNNEL_Time_to_Staff_prepared`: remove DaysInStatus, parse the hire date, rename the sum, and move Application ID first
_compute_recruitment_funnel_time_to_staff_prepared AS (
  SELECT
    -- Step 9 [ColumnReorder]: move Application ID to the start
    `Application ID`,
    RequisitionType,
    RequisitionDateCreated_formatted,
    `Application Date_parsed`,
    PostingStartDate_formatted,
    FunnelStatusCategory,
    FunnelCurrentStatus,
    SkippedStatus,
    IsInternal,
    AppClosed,
    AppSomebodyArrived,
    `App_SomebodyHired?`,
    JobSomebodyHired,
    JobSomebodyRelevantArrived,
    RelevantStepArrival,
    EmploymentDetailsMostRecentHireDate_formatted,
    -- Step 1 [DateParser]: parse yyyy/MM/dd as a date
    TO_DATE(
      EmploymentDetailsMostRecentHireDate_formatted,
      'yyyy/MM/dd'
    ) AS EmploymentDetailsMostRecentHireDate_formatted_parsed,
    GroupEmployeeLevel,
    GlobalLeaderPosition,
    JobFamilyID,
    DepartmentID,
    CostCenterID,
    LegalEntityID,
    SmartCodeID,
    Arrivals,
    DivisionLvl2ID,
    `Requisition Status_2`,
    `Contract Type`,
    JobRequisition_evergreen,
    -- Step 4 [ColumnRenamer]: rename DaysInStatus_sum
    DaysInStatus_sum AS `Time To Staff- sum days`
    -- Step 0 [ColumnsSelector]: DaysInStatus is omitted
  FROM _compute_recruitment_funnel_time_to_staff
),

-- Dataiku join `compute_FUNNEL_FINAL`: right join on Application ID and FunnelStatusCategory, then select distinct output rows
_compute_funnel_final AS (
  SELECT DISTINCT
    time_to_staff.`Time To Staff- sum days` AS `Time To Staff`,
    funnel.RequisitionType,
    funnel.RequisitionDateCreated_formatted,
    funnel.`Application Date_parsed`,
    funnel.PostingStartDate_formatted,
    funnel.FunnelStatusCategory,
    funnel.FunnelCurrentStatus,
    funnel.SkippedStatus,
    funnel.IsInternal,
    funnel.AppClosed,
    funnel.AppSomebodyArrived,
    funnel.`App_SomebodyHired?`,
    funnel.JobSomebodyHired,
    funnel.JobSomebodyRelevantArrived,
    funnel.RelevantStepArrival,
    funnel.EmploymentDetailsMostRecentHireDate_formatted,
    funnel.GroupEmployeeLevel,
    funnel.GlobalLeaderPosition,
    funnel.JobFamilyID,
    funnel.DepartmentID,
    funnel.CostCenterID,
    funnel.LegalEntityID,
    funnel.SmartCodeID,
    funnel.DaysInStatus,
    funnel.Arrivals,
    funnel.DivisionLvl2ID,
    funnel.Funnel_build_Date,
    funnel.`Application ID`,
    funnel.`Requisition Id`,
    funnel.`Requisition Status_2`,
    funnel.`Contract Type`,
    funnel.JobRequisition_evergreen
  FROM _compute_recruitment_funnel_time_to_staff_prepared AS time_to_staff
  RIGHT JOIN `raw_data`.`silver_recruitment_funnel_filled_onhold` AS funnel
    ON time_to_staff.`Application ID` = funnel.`Application ID`
   AND time_to_staff.FunnelStatusCategory = funnel.FunnelStatusCategory
)
SELECT * FROM _compute_funnel_final;

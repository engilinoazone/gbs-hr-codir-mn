-- Migrated from Dataiku: compute_JOBREQ-HISTORY_scope, compute_DS_Req_History
CREATE OR REFRESH MATERIALIZED VIEW `gbshr_ta_dev`.`slv`.`fr_req_history`
(
  CONSTRAINT `requisition_status_not_empty`
    EXPECT (`requisition status` IS NOT NULL AND `requisition status` <> '')
    ON VIOLATION DROP ROW
)
COMMENT 'Migrated from Dataiku (DS_Req_History)'
TBLPROPERTIES (
  'delta.columnMapping.mode' = 'name'
)
AS
WITH
-- Dataiku join `compute_JOBREQ-HISTORY_scope`: left join on Job Req ID (distinct scope keys), keep rows whose scope key is present and with non-empty Requisition Status
_compute_jobreq_history_scope AS (
  SELECT
    history.`Job Req ID`,
    history.`Requisition Status`,
    history.`Created By`,
    history.`Created Date`,
    history.`Business Unit`,
    scope.`Job Req ID` AS `Job Req ID_scope`
  FROM `gbshr_ta_dev`.`brz`.`fr_jobreq_history` AS history
  LEFT JOIN (SELECT DISTINCT `Job Req ID` FROM `raw_data`.`silver_req_final`) AS scope
    ON history.`Job Req ID` = scope.`Job Req ID`
  WHERE scope.`Job Req ID` IS NOT NULL
    AND history.`Requisition Status` IS NOT NULL
    AND history.`Requisition Status` <> ''
),
-- Dataiku shaker `compute_DS_Req_History`: select columns, remove empty statuses, rename columns, and parse created date
_compute_ds_req_history AS (
  -- Step 0 [ColumnsSelector]: remove Business Unit and Job Req ID_scope
  -- Step 1 [RemoveRowsOnEmpty]: remove empty Requisition Status rows via the dataset expectation
  -- Step 2 [ColumnRenamer]: rename the four retained columns
  -- Step 3 [DateParser]: parse created date using M/d/yyyy h:mm:ss a
  SELECT
    `Job Req ID` AS `job requisition id`,
    `Requisition Status` AS `requisition status`,
    `Created By` AS `created by`,
    TO_DATE(
      TO_TIMESTAMP(`Created Date`, 'M/d/yyyy h:mm:ss a')
    ) AS `created date`
  FROM _compute_jobreq_history_scope
)
SELECT * FROM _compute_ds_req_history;

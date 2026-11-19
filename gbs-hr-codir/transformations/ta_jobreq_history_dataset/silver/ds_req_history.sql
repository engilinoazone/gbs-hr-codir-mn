-- Migrated from Dataiku: compute_JOBREQ-HISTORY_scope, compute_DS_Req_History
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`silver_ds_req_history`
COMMENT 'Migrated from Dataiku (DS_Req_History)'
AS
-- Dataiku join `compute_JOBREQ-HISTORY_scope`: LEFT JOIN on Job Req ID, then the enabled
-- post-filter (Job Req ID_scope "not empty string" -> scope key present).
-- Dataiku shaker `compute_DS_Req_History`: 0 ColumnsSelector (drop Business Unit, Job Req ID_scope),
-- 1 RemoveRowsOnEmpty (Requisition Status), 2 ColumnRenamer, 3 DateParser (MM/dd/yyyy hh:mm:ss a, in place).
SELECT
  history.`Job Req ID`                                     AS `job requisition id`,
  history.`Requisition Status`                             AS `requisition status`,
  history.`Created By`                                     AS `created by`,
  to_date(history.`Created Date`, 'MM/dd/yyyy hh:mm:ss a') AS `created date`
FROM `raw_data`.`bronze_jobreq_history` AS history
LEFT JOIN `raw_data`.`silver_req_final` AS scope
  ON history.`Job Req ID` = scope.`Job Req ID`
WHERE scope.`Job Req ID` IS NOT NULL
  AND history.`Requisition Status` IS NOT NULL
  AND history.`Requisition Status` <> '';

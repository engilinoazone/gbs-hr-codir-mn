-- Migrated from Dataiku: compute_ds_Payroll_compliance_rate_prepared
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`gold_ds_payroll_compliance_rate_prepared_`
COMMENT 'Migrated from Dataiku (ds_Payroll_compliance_rate_prepared_)'
AS
-- Dataiku shaker `compute_ds_Payroll_compliance_rate_prepared`: select required columns and normalize percentage-form compliance rates
-- Prepare step 0: Remove col_9, col_10, col_11, col_12, and col_13
-- Prepare step 1: Convert percentage-form Compliance rate values to decimal strings
SELECT
  `Country`,
  CAST(`Month` AS BIGINT) AS `Month`,
  CAST(`Year` AS BIGINT) AS `Year`,
  CAST(`Number of employee` AS BIGINT) AS `Number of employee`,
  CAST(`Number of payslips` AS BIGINT) AS `Number of payslips`,
  CASE
    WHEN contains(`Compliance rate`, '%') THEN
      CAST(
        try_cast(replace(replace(`Compliance rate`, '%', ''), ',', '.') AS DOUBLE) / 100
        AS STRING
      )
    ELSE `Compliance rate`
  END AS `Compliance rate`,
  `% of employees paid in time`,
  CAST(`New hire` AS BIGINT) AS `New hire`,
  CAST(`Off-boarding` AS BIGINT) AS `Off-boarding`
FROM `raw_data`.`bronze_ds_payroll_compliance_rate`;

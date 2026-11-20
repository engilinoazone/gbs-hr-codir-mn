-- Migrated from Dataiku: compute_ds_deploiement_for_KPI_V2_2026_prepared1, compute_ds_deploiement_for_KPI_V2_2026_prepared1_distinct, compute_ds_deploiement_for_KPI_V2_2026_prepared, compute_ds_deploiement_for_KPI_V2_2026_prepared_joined, compute_ds_deploiement_for_KPI_V2_final_2026
CREATE OR REFRESH MATERIALIZED VIEW `gbshr_training_dev`.`gld`.`fr_deploiement_for_kpi_v2_final_2026`
COMMENT 'Migrated from Dataiku (ds_deploiement_for_KPI_V2_final_2026)'
TBLPROPERTIES ('delta.columnMapping.mode' = 'name')
AS
WITH
-- Dataiku shaker `compute_ds_deploiement_for_KPI_V2_2026_prepared1`: record-context column `Date Extraction`
-- (sourced from the bronze table's own `Date Extraction` column) plus the recipe type conversions.
_compute_ds_deploiement_for_kpi_v2_2026_prepared1 AS (
  SELECT
    `ID.1`,
    CAST(`User ID` AS BIGINT) AS `User ID`,
    CAST(`Item ID` AS BIGINT) AS `Item ID`,
    CAST(`Class ID` AS BIGINT) AS `Class ID`,
    `Statut Inscription`,
    `Registration Status`,
    CAST(`Registration Date` AS DATE) AS `Registration Date`,
    CAST(`Registration Date_lead` AS DATE) AS `Registration Date_lead`,
    `Withdrawal Reason ID`,
    `Attended`,
    CAST(`Enrollment Seat ID` AS BIGINT) AS `Enrollment Seat ID`,
    `Assigned By`,
    `Cancelled Date (Classes)`,
    `Cancelled Date (Enrollment Seat)`,
    `Class is Cancelled`,
    CAST(`Active` AS BOOLEAN) AS `Active`,
    `Group ID`,
    CAST(`Sezame ID` AS BIGINT) AS `Sezame ID`,
    `Country/Region`,
    `Employee Type ID`,
    `Job Location ID`,
    `Security Domain`,
    `Region ID`,
    `Organization ID`,
    CAST(`HRBP_GID` AS DOUBLE) AS `HRBP_GID`,
    `HRBP First Name`,
    `HRBP Last Name`,
    `HRBP Email`,
    `GID`,
    `First Name`,
    `Last Name`,
    CAST(`SIRET` AS DOUBLE) AS `SIRET`,
    `Contract Type`,
    `Email Address`,
    `Postal Code`,
    `City`,
    `Management Entity`,
    `Division ID`,
    CAST(`Manager ID` AS BIGINT) AS `Manager ID`,
    `Global Leader`,
    CAST(`Termination Date` AS DATE) AS `Termination Date`,
    CAST(`Hire Date` AS DATE) AS `Hire Date`,
    CAST(`Position ID` AS BIGINT) AS `Position ID`,
    `Business Unit`,
    CAST(`Legal Entity ID` AS BIGINT) AS `Legal Entity ID`,
    `Global Employee Level`,
    `Learning Entity`,
    `Division Name`,
    `Position Name`,
    `Manager First Name`,
    `Manager Last Name`,
    `Manager Email`,
    `Short Description`,
    `Class Description`,
    `Closed Date`,
    `Class Cancellation Reason`,
    CAST(`Class Hours` AS DOUBLE) AS `Class Hours`,
    CAST(`Class Hours brute` AS DOUBLE) AS `Class Hours brute`,
    `Class Milestone Status`,
    `Comments (Class)`,
    `Start Date Classe`,
    `End Date Classe`,
    `Instructor ID`,
    `PO Number for class level`,
    `Cancelled Date`,
    CAST(`Approval required to withdraw` AS BOOLEAN) AS `Approval required to withdraw`,
    `Class Organisation`,
    `Facility ID`,
    `Location ID`,
    `Last Date to Withdraw`,
    CAST(`Maximum Registration (Class)` AS BIGINT) AS `Maximum Registration (Class)`,
    CAST(`Minimum Registration (Class)` AS BIGINT) AS `Minimum Registration (Class)`,
    `Registration Close Date`,
    CAST(`Virtual Class` AS BOOLEAN) AS `Virtual Class`,
    `Withdraw Approval Process`,
    CAST(`Require Withdrawal Reason` AS BOOLEAN) AS `Require Withdrawal Reason`,
    CAST(`Approval Required (Class)` AS BOOLEAN) AS `Approval Required (Class)`,
    `Instructor First Name`,
    `Instructor Last Name`,
    `Instructor Email Address`,
    `Referential Type`,
    `Owner Organisation`,
    `Approval Process (Class)`,
    `Currency Code`,
    CAST(`Class Price` AS DOUBLE) AS `Class Price`,
    `Item Type`,
    `Assignment Type (Item)`,
    CAST(`Category ID` AS BIGINT) AS `Category ID`,
    `Item Title`,
    CAST(`Credit Hours (Item)` AS DOUBLE) AS `Credit Hours (Item)`,
    CAST(`Duration` AS DOUBLE) AS `Duration`,
    `Category Description`,
    `Item Description`,
    CAST(`Item Price` AS DOUBLE) AS `Item Price`,
    `Currency Code (Item Price)`,
    `Completion Status ID`,
    `Completion Date`,
    CAST(`Exercice MEOTO` AS BIGINT) AS `Exercice MEOTO`,
    `Entite Gestion migrée de TO`,
    `Plan/Hors-Plan`,
    `Status`,
    CAST(`Request Date` AS DATE) AS `Request Date`,
    CAST(`Required Date` AS DATE) AS `Required Date`,
    `Comments`,
    `Date Extraction`,
    `Security Domain Item`,
    `Exercice MEO`,
    `Entité de gestion TO`,
    `Domaine demandé`,
    `Code stage validé`,
    `Territoire TO`,
    `Domaine Parent TO`,
    `Type Organisation TO`,
    `Validation L&D Manager (Oui/Non)`,
    `Priority (Haute/Moyenne/Basse)`,
    CAST(`Validation Date` AS DATE) AS `Validation Date`,
    `Type de gestion`,
    `Entité de regroupement`,
    `Territoire`,
    `Domaine parent`,
    `Domaine`
 FROM gbshr_training_dev.brz.fr_deploiement_for_kpi_v2_2026
),

-- Dataiku distinct `compute_ds_deploiement_for_KPI_V2_2026_prepared1_distinct`: dedup across all recipe key columns.
_compute_ds_deploiement_for_kpi_v2_2026_prepared1_distinct AS (
  SELECT DISTINCT *
  FROM _compute_ds_deploiement_for_kpi_v2_2026_prepared1
),

-- Dataiku shaker `compute_ds_deploiement_for_KPI_V2_2026_prepared` steps 0,1,2,4:
-- keep the nine selected columns, drop null Entité de regroupement, parse Start Date Classe,
-- then override Entité de regroupement from Registration Status.
_compute_ds_deploiement_for_kpi_v2_2026_prepared_parsed AS (
  SELECT
    `ID.1`,
    `Registration Status`,
    `Management Entity`,
    `Business Unit`,
    `Division Name`,
    TRY_TO_DATE(`Start Date Classe`, 'MMM dd, yyyy hh:mm:ss a') AS `Start Date Classe`,
    `Completion Status ID`,
    `Date Extraction`,
    CASE
      WHEN CONTAINS(`Registration Status`, 'France retail') THEN 'France Retail'
      WHEN CONTAINS(`Registration Status`, 'ESF') THEN 'LEI'
      ELSE `Entité de regroupement`
    END AS `Entité de regroupement`
  FROM _compute_ds_deploiement_for_kpi_v2_2026_prepared1_distinct
  WHERE `Entité de regroupement` IS NOT NULL
),

-- Prepare step 3: keep Start Date Classe within calendar year 2026.
_compute_ds_deploiement_for_kpi_v2_2026_prepared AS (
  SELECT *
  FROM _compute_ds_deploiement_for_kpi_v2_2026_prepared_parsed
  WHERE `Start Date Classe` BETWEEN DATE '2026-01-01' AND DATE '2026-12-31'
)

-- Dataiku join `compute_ds_deploiement_for_KPI_V2_2026_prepared_joined` (LEFT JOIN on Entité de regroupement)
-- plus shaker `compute_ds_deploiement_for_KPI_V2_final_2026` step 0 (constant Country = 'France').
SELECT
  deployment.`ID.1`,
  deployment.`Registration Status`,
  deployment.`Management Entity`,
  deployment.`Business Unit`,
  deployment.`Division Name`,
  deployment.`Start Date Classe`,
  deployment.`Completion Status ID`,
  deployment.`Date Extraction`,
  deployment.`Entité de regroupement`,
  pdc.`Nombre de bénéficiaires prévus`,
  pdc.`Heures prévisionnelles`,
  pdc.`Montant prévisionnelles`,
  'France' AS `Country`
FROM _compute_ds_deploiement_for_kpi_v2_2026_prepared AS deployment

LEFT JOIN gbshr_training_dev.slv.fr_pdc_consolide_prepared_by_entit_de_regroupement AS pdc
  ON deployment.`Entité de regroupement`
   = pdc.`Entité de regroupement`;

-- Migrated from Dataiku: compute_PDC_consolide_prepared, compute_PDC_consolide_prepared_by_Entit_de_regroupement
CREATE OR REFRESH MATERIALIZED VIEW `gbshr_training_dev`.`slv`.`fr_pdc_consolide_prepared_by_entit_de_regroupement` (
  CONSTRAINT entit_de_regroupement_present EXPECT (`Entité de regroupement` IS NOT NULL)
)
COMMENT 'Migrated from Dataiku (PDC_consolide_prepared_by_Entit_de_regroupement)'
TBLPROPERTIES ('delta.columnMapping.mode' = 'name')
AS
WITH
-- Dataiku shaker `compute_PDC_consolide_prepared`: select required columns and replace the ERES entity value
_compute_pdc_consolide_prepared AS (
  SELECT
    -- Prepare step 0 [ColumnsSelector]: remove `Catalogue`
    -- Prepare step 1 [FindReplace]: replace exact value ERES with ERES et Corp FR
    CASE
      WHEN `Entité de regroupement` = 'ERES' THEN 'ERES et Corp FR'
      ELSE `Entité de regroupement`
    END AS `Entité de regroupement`,
    CAST(`Nombre de bénéficiaires prévus` AS BIGINT) AS `Nombre de bénéficiaires prévus`,
    CAST(`Heures prévisionnelles` AS DOUBLE) AS `Heures prévisionnelles`,
    CAST(`Montant prévisionnelles` AS BIGINT) AS `Montant prévisionnelles`
  FROM `brz`.`bronze_pdc_consolide`
),
-- Dataiku grouping `compute_PDC_consolide_prepared_by_Entit_de_regroupement`: group by entity and sum the three measures
_compute_pdc_consolide_prepared_by_entit_de_regroupement AS (
  SELECT
    `Entité de regroupement`,
    SUM(`Nombre de bénéficiaires prévus`) AS `Nombre de bénéficiaires prévus`,
    SUM(`Heures prévisionnelles`) AS `Heures prévisionnelles`,
    SUM(`Montant prévisionnelles`) AS `Montant prévisionnelles`
  FROM _compute_pdc_consolide_prepared
  GROUP BY `Entité de regroupement`
)
SELECT * FROM _compute_pdc_consolide_prepared_by_entit_de_regroupement;

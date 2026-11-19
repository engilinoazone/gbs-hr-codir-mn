-- Migrated from Dataiku: compute_ds_Touchless_prepared
CREATE OR REFRESH MATERIALIZED VIEW `raw_data`.`gold_ds_touchless_kpi`
(
  CONSTRAINT `exclude_mt202512_france`
    EXPECT (
      coalesce(
        concat(`Cycle`, '_', `Country`) <> 'MT202512_France',
        true
      )
    )
    ON VIOLATION DROP ROW
)
COMMENT 'Migrated from Dataiku (ds_touchless_kpi)'
AS
-- Dataiku shaker `compute_ds_Touchless_prepared`: normalize Country and BU Name, derive ID, filter one ID, then remove ID
-- Step 0: Normalize FRANCE and BELGIUM country values
-- Step 1: Apply all substring replacements to BU Name
-- Step 2: Derive ID as concat(Cycle, "_", Country)
-- Step 3: Remove rows whose ID is MT202512_France via the drop-row expectation
-- Step 4: Omit the temporary ID column from the output
SELECT
  `Cycle`,
  CASE
    WHEN `Country` = 'FRANCE' THEN 'France'
    WHEN `Country` = 'BELGIUM' THEN 'Belgium'
    ELSE `Country`
  END AS `Country`,
  `Code BU`,
  replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                replace(
                  replace(
                    replace(
                      replace(
                        `BU Name`,
                        'BU Global Energy Management',
                        'Supply & Energy Management'
                      ),
                      'BU ENGIE IMPACT',
                      'LEI RoW'
                    ),
                    'BU NewCorp',
                    'Corporate'
                  ),
                  'RENEWABLE & FLEX POWER GBU',
                  'GBU Renewables & Flexible Power'
                ),
                'BU France BtoB',
                'Supply & Energy Management'
              ),
              concat('BU France BtoC', chr(9)),
              'Supply & Energy Management'
            ),
            'BU Global Business Support',
            'GBS'
          ),
          'BU Storengy',
          'GBU Networks'
        ),
        'BU Elengy',
        'GBU Networks'
      ),
      'BU Génération Europe',
      'GBU Renewables & Flexible Power'
    ),
    'BU France Réseaux',
    'LEI RoW'
  ) AS `BU Name`,
  `Society Code`,
  `Society Name`,
  `Code Smart`,
  CAST(`Touch Less Pay Slips (Qty)` AS BIGINT) AS `Touch Less Pay Slips (Qty)`,
  CAST(`Total Pay Slips (Qty)` AS BIGINT) AS `Total Pay Slips (Qty)`,
  CAST(`Touch Less Pay Slips Weight` AS DOUBLE) AS `Touch Less Pay Slips Weight`
FROM `raw_data`.`bronze_ds_touchless`;

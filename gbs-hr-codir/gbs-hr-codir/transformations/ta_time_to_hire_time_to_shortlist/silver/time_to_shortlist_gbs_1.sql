-- Migrated from Dataiku:
--   compute_Time_to_Hire_DS_1
--   compute_Time_to_Hire_2
--   compute_Time_to_hire_GBS_prepared2_filtered_1
--   compute_Time_to_Hire_w_blank_joined_1
--
-- Target:
--   gbshr_ta_dev.slv.fr_time_to_shortlist
--
-- Principales règles reproduites:
--   1. Déduplication des réquisitions avant la jointure.
--   2. Jointure des candidatures avec les réquisitions sur Job Req ID.
--   3. Filtrage sur le périmètre pays Dataiku.
--   4. Extraction du nom et de l'identifiant de l'entité légale.
--   5. Harmonisation des codes pays avec les libellés Dataiku.
--   6. Enrichissement par le référentiel Smart Code.
--
-- Périmètre pays:
--   France, Belgium, Germany, United States, Canada.
--
-- Corrections appliquées:
--   - Application ID reste un identifiant numérique.
--   - Business Unit et Division sont alignés sur le format Dataiku.
--   - Les caractères mal décodés sont réparés dans Division,
--     Department et Legal Entity.
--   - Les clés de jointure sont sécurisées avec TRIM et CAST.
--   - Les réquisitions strictement équivalentes sont dédupliquées
--     avant la jointure avec les candidatures.

CREATE OR REFRESH MATERIALIZED VIEW
`gbshr_ta_dev`.`slv`.`fr_time_to_shortlist`

COMMENT 'Migrated from Dataiku (Time_to_Shortlist_GBS_1)'

AS

WITH requisition_deduplicated AS (

  -- Certains Job Req ID apparaissent plusieurs fois avec les mêmes
  -- attributs organisationnels dans la source Réquisition.
  --
  -- La déduplication évite de multiplier les candidatures
  -- lors de la jointure suivante.

  SELECT DISTINCT
    `Job Req ID`,
    `Business Unit`,
    `Division`,
    `Division ID`,
    `Department`,
    `Department ID`,
    `Legal Entity`,
    `Country`

  FROM `slv`.`bronze_req_final_prepared_1`
),

application_deduplicated AS (

  -- Plusieurs événements Application sont présents plusieurs fois
  -- à l'identique dans la source préparée.
  --
  -- Une seule occurrence est conservée avant la jointure afin de ne pas
  -- propager les doublons Shortlist et Hireable dans le dataset final.
  SELECT DISTINCT
    `Job Req ID`,
    `Application ID`,
    `Req Posting Start Date`,
    `Application Status`,
    `Application Status Date (Timestamp)`

  FROM `slv`.`bronze_application_final_prepared_1`
),

source_prepared AS (

  SELECT
    application.`Job Req ID`,
    application.`Application ID`,
    application.`Req Posting Start Date`,
    application.`Application Status`,
    application.`Application Status Date (Timestamp)`,

    -- Suppression du code organisationnel situé entre parenthèses
    -- à la fin du libellé Business Unit.
    --
    -- Exemple:
    -- "GBS (GB000)" devient "GBS".

    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          CAST(requisition.`Business Unit` AS STRING),
          '\\s*\\([^()]+\\)\\s*$',
          ''
        )
      ),
      ''
    ) AS `Business Unit`,

    -- Réparation des caractères mal décodés dans Division.
    --
    -- La valeur est conservée telle quelle lorsqu'aucun marqueur
    -- d'encodage incorrect n'est détecté.

    CASE
      WHEN CAST(requisition.`Division` AS STRING)
           RLIKE 'Ã|Â|â€|â€“|â€™|â€œ|â€'

      THEN DECODE(
        ENCODE(
          CAST(requisition.`Division` AS STRING),
          'windows-1252'
        ),
        'UTF-8'
      )

      ELSE CAST(requisition.`Division` AS STRING)
    END AS `Division repaired`,

    requisition.`Division ID`,

    -- Réparation des caractères mal décodés dans Department.

    CASE
      WHEN CAST(requisition.`Department` AS STRING)
           RLIKE 'Ã|Â|â€|â€“|â€™|â€œ|â€'

      THEN DECODE(
        ENCODE(
          CAST(requisition.`Department` AS STRING),
          'windows-1252'
        ),
        'UTF-8'
      )

      ELSE CAST(requisition.`Department` AS STRING)
    END AS `Department`,

    CAST(
      requisition.`Department ID`
      AS BIGINT
    ) AS `Department ID`,

    -- Réparation des caractères mal décodés dans Legal Entity.

    CASE
      WHEN CAST(requisition.`Legal Entity` AS STRING)
           RLIKE 'Ã|Â|â€|â€“|â€™|â€œ|â€'

      THEN DECODE(
        ENCODE(
          CAST(requisition.`Legal Entity` AS STRING),
          'windows-1252'
        ),
        'UTF-8'
      )

      ELSE CAST(requisition.`Legal Entity` AS STRING)
    END AS `Legal Entity repaired`,

    -- Harmonisation des codes pays avec les libellés Dataiku.

    CASE UPPER(
      TRIM(
        CAST(requisition.`Country` AS STRING)
      )
    )
      WHEN 'FR' THEN 'France'
      WHEN 'FRANCE' THEN 'France'

      WHEN 'BE' THEN 'Belgium'
      WHEN 'BELGIUM' THEN 'Belgium'

      WHEN 'DE' THEN 'Germany'
      WHEN 'GERMANY' THEN 'Germany'

      WHEN 'US' THEN 'United States'
      WHEN 'UNITED STATES' THEN 'United States'

      WHEN 'CA' THEN 'Canada'
      WHEN 'CANADA' THEN 'Canada'
      
      WHEN 'MX' THEN 'Mexico'
      WHEN 'MEXICO' THEN 'Mexico'

      ELSE NULLIF(
        TRIM(
          CAST(requisition.`Country` AS STRING)
        ),
        ''
      )
    END AS `Country`

FROM application_deduplicated AS application

  LEFT JOIN requisition_deduplicated
       AS requisition

    ON TRIM(
         CAST(application.`Job Req ID` AS STRING)
       )
     = TRIM(
         CAST(requisition.`Job Req ID` AS STRING)
       )

  -- Reproduction du périmètre pays appliqué dans Dataiku.
  --
  -- Le filtre accepte aussi bien les codes que les libellés complets.
  -- Les lignes sans réquisition correspondante ou sans pays sont exclues,
  -- conformément au périmètre défini.

WHERE UPPER(
  TRIM(
    CAST(requisition.`Country` AS STRING)
  )
) IN (
  'FR',
  'FRANCE',
  'BE',
  'BELGIUM',
  'DE',
  'GERMANY',
  'US',
  'UNITED STATES',
  'CA',
  'CANADA',
  'MX',
  'MEXICO'
)
),

prepared AS (

  SELECT
    `Job Req ID`,
    `Application ID`,
    `Req Posting Start Date`,
    `Application Status`,
    `Application Status Date (Timestamp)`,
    `Business Unit`,

    -- Réparation effectuée dans source_prepared,
    -- puis suppression du code final entre parenthèses.
    --
    -- Exemple:
    -- "LEI RoW - Northam (ES0601)"
    -- devient "LEI RoW - Northam".

    NULLIF(
      TRIM(
        REGEXP_REPLACE(
          `Division repaired`,
          '\\s*\\([^()]+\\)\\s*$',
          ''
        )
      ),
      ''
    ) AS `Division`,

    `Division ID`,
    `Department`,
    `Department ID`,

    NULLIF(
      TRIM(`Legal Entity repaired`),
      ''
    ) AS `Legal Entity`,

    -- Extraction du nom de l'entité légale depuis la valeur réparée.
    --
    -- Exemple:
    -- "ENGIE North America Inc. (42775)"
    -- devient "ENGIE North America Inc.".

    NULLIF(
      TRIM(
        REGEXP_EXTRACT(
          `Legal Entity repaired`,
          r'(.+?) \((\d+)\)',
          1
        )
      ),
      ''
    ) AS `LE Name`,

    -- Extraction de l'identifiant numérique de l'entité légale.
    --
    -- Exemple:
    -- "ENGIE North America Inc. (42775)"
    -- devient "42775".

    NULLIF(
      REGEXP_EXTRACT(
        `Legal Entity repaired`,
        r'(.+?) \((\d+)\)',
        2
      ),
      ''
    ) AS `LE ID`,

    `Country`

  FROM source_prepared
)

SELECT
  source.`Job Req ID`,
  source.`Application ID`,
  source.`Req Posting Start Date`,
  source.`Application Status`,
  source.`Application Status Date (Timestamp)`,
  source.`Business Unit`,
  source.`Division`,
  source.`Division ID`,
  source.`Department`,
  source.`Department ID`,
  source.`Legal Entity`,
  source.`LE Name`,
  source.`LE ID`,
  source.`Country`,
  smart_code.`Smart Code ID 1.0`,
  smart_code.`Smart Code Name 1.0`

FROM prepared AS source

LEFT JOIN `brz`.`bronze_referentiel_sc`
          AS smart_code

  ON TRIM(
       CAST(source.`LE ID` AS STRING)
     )
   = TRIM(
       CAST(smart_code.`Legal Entity ID` AS STRING)
     )

 AND TRIM(
       CAST(source.`Division ID` AS STRING)
     )
   = TRIM(
       CAST(smart_code.`divisionlvl2id` AS STRING)
     );
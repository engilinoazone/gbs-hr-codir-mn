-- Migrated from Dataiku:
--   compute_non_shortlist
--   compute_shortlist_only_
--   compute_shortlist_ranked
--   compute_shortlist_oldest
--   compute_Final_dataset_TTH_and_TTS
--
-- Target:
--   gbshr_ta_dev.gld.tth_and_tts
--
-- La vue source gbshr_ta_dev.slv.fr_time_to_shortlist contient les candidatures,
-- les réquisitions et les données organisationnelles enrichies.
--
-- Correction appliquée:
--   Les valeurs "Shortlist" et "Hireable" correspondent à Application Status.
--   Application ID est un identifiant numérique et ne doit pas être utilisé
--   pour filtrer les statuts.
--
-- Règle Dataiku reproduite:
--   1. Sélectionner les lignes au statut Shortlist.
--   2. Classer les candidatures Shortlist par date croissante pour chaque Job Req ID.
--   3. Conserver la première ligne Shortlist de chaque Job Req ID.
--   4. Ajouter toutes les lignes dont le statut contient Hireable.
--
-- L'ancienne expectation Application ID = 1 n'est pas reproduite:
--   la règle fonctionnelle attendue est rownumber = 1 dans la branche Shortlist.

CREATE OR REFRESH MATERIALIZED VIEW `gbshr_ta_dev`.`gld`.`tth_and_tts`

COMMENT 'Migrated from Dataiku (Final_dataset_TTH_and_TTS)'

AS

WITH _compute_shortlist_ranked AS (

  -- Dataiku sampling compute_shortlist_only_:
  -- conserver uniquement les candidatures dont le statut contient "Shortlist",
  -- sans tenir compte des majuscules/minuscules.

  -- Dataiku window compute_shortlist_ranked:
  -- attribuer un numéro à chaque candidature Shortlist au sein d'un Job Req ID,
  -- en commençant par la date de statut la plus ancienne.

  SELECT
    `Job Req ID`,
    `Application ID`,
    `Req Posting Start Date`,
    `Application Status`,
    `Application Status Date (Timestamp)`,
    `Business Unit`,
    `Division`,
    `Division ID`,
    `Department`,
    `Department ID`,
    `Legal Entity`,
    `LE Name`,
    `LE ID`,
    `Country`,
    `Smart Code ID 1.0`,
    `Smart Code Name 1.0`,

-- Classement des candidatures Shortlist par réquisition.
--
-- La première date Shortlist reste le critère métier principal.
-- Application ID est utilisé uniquement comme critère secondaire
-- pour rendre le choix stable lorsque plusieurs candidatures
-- ont exactement la même première date Shortlist.
CAST(
  ROW_NUMBER() OVER (
    PARTITION BY `Job Req ID`
    ORDER BY
      `Application Status Date (Timestamp)` ASC,
      CAST(`Application ID` AS BIGINT) ASC
  ) AS BIGINT
) AS `rownumber`

  FROM `gbshr_ta_dev`.`slv`.`fr_time_to_shortlist`

  -- Correction:
  -- le statut est recherché dans Application Status,
  -- et non dans Application ID.
  WHERE LOWER(
          TRIM(
            CAST(`Application Status` AS STRING)
          )
        ) LIKE '%shortlist%'
)


-- Dataiku sampling compute_shortlist_oldest:
-- conserver la première candidature Shortlist par Job Req ID,
-- c'est-à-dire celle ayant la date de statut la plus ancienne.

SELECT
  `Job Req ID`,
  `Application ID`,
  `Req Posting Start Date`,
  `Application Status`,
  `Application Status Date (Timestamp)`,
  `Business Unit`,
  `Division`,
  `Division ID`,
  `Department`,
  `Department ID`,
  `Legal Entity`,
  `LE Name`,
  `LE ID`,
  `Country`,
  `Smart Code ID 1.0`,
  `Smart Code Name 1.0`

FROM _compute_shortlist_ranked

WHERE `rownumber` = 1


UNION ALL


-- Dataiku sampling compute_non_shortlist:
-- conserver toutes les candidatures dont le statut contient "Hireable",
-- sans tenir compte des majuscules/minuscules.
--
-- Ces lignes sont empilées avec la première candidature Shortlist
-- de chaque Job Req ID afin de constituer le dataset final.

SELECT
  `Job Req ID`,
  `Application ID`,
  `Req Posting Start Date`,
  `Application Status`,
  `Application Status Date (Timestamp)`,
  `Business Unit`,
  `Division`,
  `Division ID`,
  `Department`,
  `Department ID`,
  `Legal Entity`,
  `LE Name`,
  `LE ID`,
  `Country`,
  `Smart Code ID 1.0`,
  `Smart Code Name 1.0`

FROM `gbshr_ta_dev`.`slv`.`fr_time_to_shortlist`

-- Correction:
-- le statut est recherché dans Application Status,
-- et non dans Application ID.
WHERE LOWER(
        TRIM(
          CAST(`Application Status` AS STRING)
        )
      ) LIKE '%hireable%';
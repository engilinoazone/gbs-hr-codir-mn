-- Migrated from Dataiku: compute_Liste_de_recruteurs_TA_PBI_Operationnel_TA_prepared
CREATE OR REFRESH STREAMING TABLE `raw_data`.`silver_liste_de_recruteurs_ta_pbi_operationnel_ta_prepared`
COMMENT 'Migrated from Dataiku (Liste_de_recruteurs_TA_PBI_Operationnel_TA_prepared)'
AS
-- Dataiku shaker `compute_Liste_de_recruteurs_TA_PBI_Operationnel_TA_prepared`: normalize accents and case, then uppercase recruiter names
SELECT
  `GID_Recruteur`,
  -- Prepare step 0: Normalize accents and case; step 1: uppercase
  upper(regexp_replace(normalize(lower(`Nom_Recruteur`), 'NFD'), r'\p{M}', '')) AS `Nom_Recruteur`,
  upper(regexp_replace(normalize(lower(`Prénom_Recruteur`), 'NFD'), r'\p{M}', '')) AS `Prénom_Recruteur`,
  `Equipe_Recruteur`,
  `Fonction_Recruteur`,
  `Localisation_Recruteur`,
  `Recruteur est actuellement dans les effectifs TA ? (Oui/Non-Ancien recruteur TA)`,
  `Nom_Manager`,
  `Prénom_Manager`,
  `Commentaires`
FROM STREAM(`raw_data`.`bronze_organisation_staffing_france`);

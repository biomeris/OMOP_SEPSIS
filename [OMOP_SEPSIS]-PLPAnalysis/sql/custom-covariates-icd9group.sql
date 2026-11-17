---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#RicoveriRowMap', 'U') IS NOT NULL DROP TABLE #RicoveriRowMap;
IF OBJECT_ID('#diagnosis_groups', 'U') IS NOT NULL DROP TABLE #diagnosis_groups;
IF OBJECT_ID('#PriorDiag', 'U') IS NOT NULL DROP TABLE #PriorDiag;
IF OBJECT_ID('#ICD9CMGroup', 'U') IS NOT NULL DROP TABLE #ICD9CMGroup;

---------------------------------------------------------
-- Aggancio row_id corrente (stesso pattern di Delta/Baseline/ICD9Chapter)
---------------------------------------------------------
SELECT row_id, person_id, visit_occurrence_id, visit_start_date, visit_end_date
INTO #RicoveriRowMap
FROM (
    SELECT
        ct.@row_id_field AS row_id,
        rt.person_id,
        rt.visit_occurrence_id,
        rt.visit_start_date,
        rt.visit_end_date,
        ROW_NUMBER() OVER (
            PARTITION BY ct.@row_id_field
            ORDER BY rt.visit_occurrence_id
        ) AS rn
    FROM @cohort_table ct
    JOIN @results_schema.ricoveri_tmp rt
        ON rt.person_id = ct.subject_id
       AND rt.visit_start_date = ct.cohort_start_date
) x
WHERE rn = 1;

---------------------------------------------------------
-- Standard concept -> ICD9CM 3-digit group
-- (V/E codes excluded: covariate_id needs a numeric group)
---------------------------------------------------------
SELECT DISTINCT
    anc.concept_code AS icd9_group,
    anc.concept_name AS icd9_group_name,
    cr.concept_id_2  AS std_concept_id
INTO #diagnosis_groups
FROM @cdm_schema.concept c
JOIN @cdm_schema.concept anc
    ON anc.vocabulary_id = 'ICD9CM'
   AND anc.concept_class_id = '3-dig nonbill code'
   AND c.concept_code LIKE anc.concept_code + '%'
JOIN @cdm_schema.concept_relationship cr
    ON cr.concept_id_1 = c.concept_id
   AND cr.relationship_id = 'Maps to'
WHERE c.vocabulary_id = 'ICD9CM'
  AND anc.concept_code NOT LIKE 'V%'
  AND anc.concept_code NOT LIKE 'E%';

CREATE INDEX idx_diagnosis_groups ON #diagnosis_groups(std_concept_id);

---------------------------------------------------------
-- Diagnoses in the 180 days before admission.
-- Current stay excluded: SDO diagnoses are dated at discharge.
---------------------------------------------------------
SELECT
    r.row_id,
    dg.icd9_group,
    dg.icd9_group_name,
    COUNT(DISTINCT co.condition_occurrence_id) AS n_diagnosi
INTO #PriorDiag
FROM #RicoveriRowMap r
JOIN @cdm_schema.condition_occurrence co
    ON co.person_id = r.person_id
   AND co.condition_start_date >= DATEADD(day, -180, r.visit_start_date)
   AND co.condition_start_date <  r.visit_start_date
JOIN #diagnosis_groups dg
    ON dg.std_concept_id = co.condition_concept_id
GROUP BY r.row_id, dg.icd9_group, dg.icd9_group_name;

---------------------------------------------------------
-- ICD9CM Groups (3 cifre)
---------------------------------------------------------
SELECT *
INTO #ICD9CMGroup
FROM (
    SELECT
        d.row_id,
        (11000 * 1000 + CAST(d.icd9_group AS INTEGER)) AS covariate_id,
        d.n_diagnosi AS covariate_value,
        d.icd9_group,
        d.icd9_group_name,
        c.concept_id
    FROM #PriorDiag d
    LEFT JOIN @cdm_schema.concept c
        ON c.vocabulary_id = 'ICD9CM'
       AND c.concept_class_id = '3-dig nonbill code'
       AND c.concept_code = CAST(d.icd9_group AS VARCHAR)
       AND c.invalid_reason IS NULL
) y;

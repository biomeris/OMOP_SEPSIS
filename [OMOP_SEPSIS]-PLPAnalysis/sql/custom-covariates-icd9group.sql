---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#RicoveriRowMap', 'U') IS NOT NULL DROP TABLE #RicoveriRowMap;
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
-- ICD9CM Groups (3 cifre)
---------------------------------------------------------
SELECT *
INTO #ICD9CMGroup
FROM (
    SELECT
        r.row_id,
        (11000 * 1000 + CAST(d.icd9_group AS INTEGER)) AS covariate_id,
        d.n_diagnosi AS covariate_value,
        d.icd9_group,
        d.icd9_group_name,
        c.concept_id
    FROM #RicoveriRowMap r
    JOIN @results_schema.omop_sepsis_icd9_diagnosis d
        ON r.person_id = d.person_id
       AND r.visit_occurrence_id = d.visit_occurrence_id
    LEFT JOIN @cdm_schema.concept c
        ON c.vocabulary_id = 'ICD9CM'
       AND c.concept_class_id = '3-dig nonbill code'
       AND c.concept_code = CAST(d.icd9_group AS VARCHAR)
       AND c.invalid_reason IS NULL
) y;

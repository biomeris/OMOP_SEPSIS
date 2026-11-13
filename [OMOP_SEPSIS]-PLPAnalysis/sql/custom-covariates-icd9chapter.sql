---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#RicoveriRowMap', 'U') IS NOT NULL DROP TABLE #RicoveriRowMap;
IF OBJECT_ID('#ICD9CMChapter', 'U') IS NOT NULL DROP TABLE #ICD9CMChapter;

---------------------------------------------------------
-- Aggancio row_id corrente (stesso pattern di Delta/Baseline)
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
-- ICD9CM Chapters
---------------------------------------------------------
SELECT *
INTO #ICD9CMChapter
FROM (
    SELECT 
        r.row_id,
        d.n_diagnosi AS covariate_value,
        c.concept_id,
        CASE
        WHEN CAST(d.icd9_group AS INT) BETWEEN 1   AND 139 THEN 'Chapter 1: Infectious and parasitic diseases'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 140 AND 239 THEN 'Chapter 2: Neoplasms'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 240 AND 279 THEN 'Chapter 3: Endocrine, nutritional and metabolic diseases'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 280 AND 289 THEN 'Chapter 4: Diseases of the blood and blood-forming organs'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 290 AND 319 THEN 'Chapter 5: Mental disorders'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 320 AND 389 THEN 'Chapter 6: Diseases of the nervous system and sense organs'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 390 AND 459 THEN 'Chapter 7: Diseases of the circulatory system'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 460 AND 519 THEN 'Chapter 8: Diseases of the respiratory system'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 520 AND 579 THEN 'Chapter 9: Diseases of the digestive system'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 580 AND 629 THEN 'Chapter 10: Diseases of the genitourinary system'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 630 AND 679 THEN 'Chapter 11: Complications of pregnancy, childbirth, and the puerperium'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 680 AND 709 THEN 'Chapter 12: Diseases of the skin and subcutaneous tissue'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 710 AND 739 THEN 'Chapter 13: Diseases of the musculoskeletal system and connective tissue'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 740 AND 759 THEN 'Chapter 14: Congenital anomalies'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 760 AND 779 THEN 'Chapter 15: Certain conditions originating in the perinatal period'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 780 AND 799 THEN 'Chapter 16: Symptoms, signs and ill-defined conditions'
        WHEN CAST(d.icd9_group AS INT) BETWEEN 800 AND 999 THEN 'Chapter 17: Injury and poisoning'
        ELSE 'Other/Unknown'
        END AS icd9_chapter,
        CASE
        WHEN CAST(d.icd9_group AS INT) BETWEEN 1   AND 139 THEN 1
        WHEN CAST(d.icd9_group AS INT) BETWEEN 140 AND 239 THEN 2
        WHEN CAST(d.icd9_group AS INT) BETWEEN 240 AND 279 THEN 3
        WHEN CAST(d.icd9_group AS INT) BETWEEN 280 AND 289 THEN 4
        WHEN CAST(d.icd9_group AS INT) BETWEEN 290 AND 319 THEN 5
        WHEN CAST(d.icd9_group AS INT) BETWEEN 320 AND 389 THEN 6
        WHEN CAST(d.icd9_group AS INT) BETWEEN 390 AND 459 THEN 7
        WHEN CAST(d.icd9_group AS INT) BETWEEN 460 AND 519 THEN 8
        WHEN CAST(d.icd9_group AS INT) BETWEEN 520 AND 579 THEN 9
        WHEN CAST(d.icd9_group AS INT) BETWEEN 580 AND 629 THEN 10
        WHEN CAST(d.icd9_group AS INT) BETWEEN 630 AND 679 THEN 11
        WHEN CAST(d.icd9_group AS INT) BETWEEN 680 AND 709 THEN 12
        WHEN CAST(d.icd9_group AS INT) BETWEEN 710 AND 739 THEN 13
        WHEN CAST(d.icd9_group AS INT) BETWEEN 740 AND 759 THEN 14
        WHEN CAST(d.icd9_group AS INT) BETWEEN 760 AND 779 THEN 15
        WHEN CAST(d.icd9_group AS INT) BETWEEN 780 AND 799 THEN 16
        WHEN CAST(d.icd9_group AS INT) BETWEEN 800 AND 999 THEN 17
        ELSE 0
        END AS icd9_chapter_num
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
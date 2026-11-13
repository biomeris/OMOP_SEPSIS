---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#RicoveriRowMap', 'U') IS NOT NULL DROP TABLE #RicoveriRowMap;
IF OBJECT_ID('#InvProc', 'U') IS NOT NULL DROP TABLE #InvProc;

---------------------------------------------------------
-- Aggancio row_id corrente 
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
-- InvProc
---------------------------------------------------------
SELECT DISTINCT
    r.row_id, 
    r.visit_occurrence_id,
    r.person_id,
    r.visit_start_date,
    r.visit_end_date,
    po.procedure_concept_id,
    po.procedure_date
INTO #InvProc
FROM #RicoveriRowMap r
JOIN @cdm_schema.procedure_occurrence po
    ON r.person_id = po.person_id
   AND po.procedure_date BETWEEN r.visit_start_date AND r.visit_end_date
WHERE po.procedure_concept_id IN (
    SELECT c2.concept_id
    FROM @vocabulary_database_schema.concept c2
    JOIN @vocabulary_database_schema.concept_ancestor ca 
      ON c2.concept_id = ca.descendant_concept_id
    WHERE ca.ancestor_concept_id IN (4301351, 4179713)  -- Surgical, Endoscopic
      AND c2.invalid_reason IS NULL
      AND c2.domain_id = 'Procedure'
);

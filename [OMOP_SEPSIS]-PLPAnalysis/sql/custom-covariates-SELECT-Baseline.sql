SELECT 
    b.visit_occurrence_id as row_id,
    b.person_id, 
    (cs.codeset_id + 20000000) as covariate_id,
    b.measurement_concept_id,
    b.baseline_value AS covariate_value,
    cs.codeset_name,
    c.concept_name
FROM #Baseline b    
JOIN (
    SELECT DISTINCT codeset_id, codeset_name
    FROM #Codesets
) cs 
ON b.codeset_id = cs.codeset_id
join @cdm_schema.concept c
on b.measurement_concept_id = c.concept_id
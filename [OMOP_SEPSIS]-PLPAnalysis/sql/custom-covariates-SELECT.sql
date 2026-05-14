SELECT 
    b.person_id as row_id, 
    (cs.codeset_id + 10000000) as covariate_id,
    b.measurement_concept_id,
    p.post_value - b.baseline_value AS covariate_value,
    cs.codeset_name,
    c.concept_name
FROM #Baseline b
LEFT JOIN #Post p
    ON b.visit_occurrence_id = p.visit_occurrence_id
   AND b.codeset_id = p.codeset_id
   AND b.unit_concept_id = p.unit_concept_id
LEFT JOIN (
    SELECT DISTINCT codeset_id, codeset_name
    FROM #Codesets
) cs 
ON b.codeset_id = cs.codeset_id
LEFT join @cdm_schema.concept c
on b.measurement_concept_id = c.concept_id
ORDER BY b.person_id, b.measurement_date;

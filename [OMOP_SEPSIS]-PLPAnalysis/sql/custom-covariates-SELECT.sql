SELECT 
    b.row_id as row_id, 
    (cs.codeset_id + 10000000) as covariate_id,
    p.post_value - b.baseline_value AS covariate_value,
    cs.codeset_name,
    cs.codeset_id,
    p.rn
FROM #Baseline b
LEFT JOIN #Post p
    ON b.visit_occurrence_id = p.visit_occurrence_id
   AND b.codeset_id = p.codeset_id
   AND b.unit_concept_id = p.unit_concept_id
   AND p.rn = 1
LEFT JOIN (
    SELECT DISTINCT codeset_id, codeset_name
    FROM #Codesets
) cs 
ON b.codeset_id = cs.codeset_id
   WHERE p.post_value IS NOT NULL
   AND b.baseline_value IS NOT NULL
   AND b.rn = 1;
-- Baseline lab value (day 0). Independent of later measurements:
-- the value is kept even if the test is not repeated on days 1-3.
SELECT
    b.row_id AS row_id,
    (cs.codeset_id + 20000000) AS covariate_id,
    b.baseline_value AS covariate_value,
    cs.codeset_name,
    cs.codeset_id
FROM #Baseline b
LEFT JOIN (
    SELECT DISTINCT codeset_id, codeset_name
    FROM #Codesets
) cs
    ON b.codeset_id = cs.codeset_id
WHERE b.baseline_value IS NOT NULL
  AND b.rn = 1;
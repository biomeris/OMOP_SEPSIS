---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#RicoveriRowMap', 'U') IS NOT NULL DROP TABLE #RicoveriRowMap;
IF OBJECT_ID('#Codesets', 'U') IS NOT NULL DROP TABLE #Codesets;
IF OBJECT_ID('#measurement_filt', 'U') IS NOT NULL DROP TABLE #measurement_filt;
IF OBJECT_ID('#Baseline', 'U') IS NOT NULL DROP TABLE #Baseline;
IF OBJECT_ID('#Post', 'U') IS NOT NULL DROP TABLE #Post;

---------------------------------------------------------
-- Aggancio row_id corrente alla tabella fisica ricoveri_tmp
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

CREATE INDEX idx_ricoveri_rowmap ON #RicoveriRowMap(row_id);
CREATE INDEX idx_ricoveri_rowmap_person ON #RicoveriRowMap(person_id);

---------------------------------------------------------
-- Codesets
---------------------------------------------------------
CREATE TABLE #Codesets (
  codeset_id int NOT NULL,
  concept_id bigint NOT NULL,
  codeset_name VARCHAR(100) NOT NULL
)
;

INSERT INTO #Codesets (codeset_id, concept_id, codeset_name)
 -- Hemoglobin
SELECT 0 as codeset_id, c.concept_id, 'Hemoglobin' as codeset_name FROM (select distinct I.concept_id FROM
( 
 select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4153000,37029074,37072252) -- Hemoglobin
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4153000,37029074,37072252) -- Hemoglobin
  and c.invalid_reason is null
) I
) C UNION ALL 
-- RBC (Eritrociti)
SELECT 1 as codeset_id, c.concept_id, 'RBC' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (1450296,4030871) -- Red blood cell count, Red blood cell count in blood
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (1450296) -- Red blood cell count in blood
  and c.invalid_reason is null
) I
) C UNION ALL
-- HCT (Ematocrito)
SELECT 2 as codeset_id, c.concept_id, 'HCT' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4151358,3023314,2212642,3009542) -- Hematocrit determination
) I
) C UNION ALL
-- Eritroblasti (valore assoluto)
SELECT 3 as codeset_id, c.concept_id, 'Normoblasts (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3021589,4012826) -- Normoblasts [#/volume] in Blood, -- Nucleated red blood cell count procedure
) I
) C UNION ALL
-- Eritroblasti (percentuale)
SELECT 4 as codeset_id, c.concept_id, 'Normoblasts (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3046588,3029160,4012826) -- Normoblasts/100 blasts in Blood, -- Nucleated red blood cell count procedure
) I
) C UNION ALL
--  MCV (Volume Corpuscolare Medio)
SELECT 5 as codeset_id, c.concept_id, 'MCV' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4016239,3024731) -- Erythrocyte mean corpuscular volume determination
) I 
) C UNION ALL
-- MCH (Contenuto HGB medio)
SELECT 6 as codeset_id, c.concept_id, 'MCH' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4182871,37398674,3035941) -- Mean corpuscular hemoglobin determination
) I 
) C UNION ALL
-- MCHC (Conc. HGB Globulare Media)
SELECT 7 as codeset_id, c.concept_id, 'MCHC' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4290193,37393850,3003338) -- Mean corpuscular hemoglobin concentration determination
) I
) C UNION ALL
-- RDW
SELECT 8 as codeset_id, c.concept_id, 'RDW' as codeset_name FROM (select distinct I.concept_id FROM
( 
   SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (3002385,3002888,4281085,37397924) -- Red cell distribution width
) I
) C UNION ALL
-- WBC
SELECT 9 as codeset_id, c.concept_id, 'WBC' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4298431, 37208925) -- White blood cell count
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (40654026) -- Leukocytes|Number Concentration (count/vol)|Moment in time|Blood
  and c.invalid_reason is null
) I
) C UNION ALL
-- Neutrofili (valore assoluto)
SELECT 10 as codeset_id, c.concept_id, 'Neutrophils (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4148615,37208699,3017732) -- Neutrophil count
) I 
) C UNION ALL
-- Neutrofili (percentuale)
SELECT 11 as codeset_id, c.concept_id, 'Neutrophils (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3018010, 37398605) -- Neutrophils/100 leukocytes in Blood, Percentage neutrophils
) I
) C UNION ALL
-- Linfociti (valore assoluto)
SELECT 12 as codeset_id, c.concept_id, 'Lymphocytes (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4254663,3019198,37208689) -- Lymphocytes count
) I 
) C UNION ALL
-- Linfociti (percentuale)
SELECT 13 as codeset_id, c.concept_id, 'Lymphocytes (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3002030, 37399254) -- Lymphocytes/100 leukocytes in Blood, Percentage lymphocytes
) I
) C UNION ALL
-- Monociti (valore assoluto)
SELECT 14 as codeset_id, c.concept_id, 'Monocytes (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4194332, 37208691,3001604) -- Monocytes count
) I 
) C UNION ALL
-- Monociti (percentuale)
SELECT 15 as codeset_id, c.concept_id, 'Monocytes (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3019069, 37393321) -- Monocytes/100 leukocytes in Blood, Percentage monocytes
) I
) C UNION ALL
-- Eosinofili (valore assoluto)
SELECT 16 as codeset_id, c.concept_id, 'Eosinophil (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4216098, 37208633,3013115) -- Eosinophil count
) I 
) C UNION ALL
-- Eosinofili (percentuale)
SELECT 17 as codeset_id, c.concept_id, 'Eosinophil (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3006504, 37399255) -- Eosinophils/100 leukocytes in Blood
) I
) C UNION ALL
-- Basofili (valore assoluto)
SELECT 18 as codeset_id, c.concept_id, 'Basophil (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4172647,37208514,3006315) -- Basophil count
) I 
) C UNION ALL
-- Basofili (percentuale)
SELECT 19 as codeset_id, c.concept_id, 'Basophil (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3022096, 37398606) -- Basophils/100 leukocytes in Blood, Percentage basophils
) I
) C UNION ALL
-- PDW (Anisocitosi PLT)
SELECT 20 as codeset_id, c.concept_id, 'PDW' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4097620, 3040227, 3002736, 3039417) -- Platelet distribution width measurement
) I
) C UNION ALL
-- MPV (Volume Piastrinico Medio)
SELECT 21 as codeset_id, c.concept_id, 'MPV' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4192368,37397923,3001123) -- Platelet mean volume determination
) I
) C UNION ALL
-- Piastrine
SELECT 22 as codeset_id, c.concept_id, 'Platelet (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM @vocabulary_database_schema.concept c
				JOIN @vocabulary_database_schema.concept_relationship cr 
				ON c.concept_id = cr.concept_id_2 
					AND cr.relationship_id = 'Maps to' 
					AND cr.invalid_reason IS NULL 
				WHERE concept_id IN (4267147,37208696,3007461) -- Platelet count
) I 
) C UNION ALL
-- INR International normalized ratio 
SELECT 23 as codeset_id, c.concept_id, 'INR' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4306239, 46285118) -- International normalized ratio 
) I
) C UNION ALL
-- Bilirubina TOTALE (sangue / siero / plasma)
SELECT 24 as codeset_id, c.concept_id, 'Bilirubin total' as codeset_name FROM (
select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (
   4118986,   -- Bilirubin measurement 
   3024128,   -- Bilirubin.total [Mass/volume] in Serum or Plasma
   3028833,   -- Bilirubin.total [Mass/volume] in Blood
   40757494   -- Bilirubin.total [Moles/volume] in Blood 
)
) I
) C UNION ALL
-- Creatinina 
SELECT 25 as codeset_id, c.concept_id, 'Creatinin' as codeset_name FROM (select distinct I.concept_id FROM
( 
select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4324383,2212294) -- Creatinine
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (37029387,37074896,40652870,37056619)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (314958,1094424,3029545,3033962,3032720,3033837)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (314958,1094424)
  and c.invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) I
) C UNION ALL
-- Azotemia
SELECT 26 as codeset_id, c.concept_id, 'Urea' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4020121,4094594) -- Urea measurement
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4094594) -- Blood urea measurement
  and c.invalid_reason is null
) I
) C UNION ALL
-- PCR - Proteina C Reattiva
SELECT 27 as codeset_id, c.concept_id, 'PCR' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4208414) -- C-reactive protein measurement
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4208414) -- C-reactive protein measurement
  and c.invalid_reason is null
) I
) C;

CREATE INDEX idx_codesets_concept
ON #Codesets(concept_id);

---------------------------------------------------------
-- Measurement filtrati
---------------------------------------------------------
-- Conversione unita' di misura (regole in lab_units/*.csv, passate da R):
--   unita' = codice UCUM del concept; se unit_concept_id e' NULL/0 si usa unit_source_value
--   confronto senza distinzione maiuscole/minuscole
--   unita' assente o non prevista nel CSV -> misura scartata
--   esclusioni specifiche del centro in lab_exclusions.csv
SELECT 
    r.row_id,
    r.visit_occurrence_id,
    r.person_id,
    cs.codeset_id,
    m.measurement_concept_id,
    m.measurement_date,
    m.value_as_number * uc.factor AS value_as_number,
    tu.concept_id                 AS unit_concept_id,
    r.visit_start_date,
    r.visit_end_date
INTO #measurement_filt
FROM #RicoveriRowMap r
JOIN @cdm_schema.measurement m 
    ON r.person_id = m.person_id
   AND m.measurement_date BETWEEN r.visit_start_date AND DATEADD(day,3,r.visit_start_date)
JOIN #Codesets cs
    ON m.measurement_concept_id = cs.concept_id
LEFT JOIN @vocabulary_database_schema.concept su
    ON su.concept_id = m.unit_concept_id
   AND m.unit_concept_id <> 0
JOIN (VALUES
@unit_conversion_values
) AS uc(codeset_id, source_unit_ucum, target_unit_ucum, factor)
    ON uc.codeset_id = cs.codeset_id
   AND UPPER(uc.source_unit_ucum) = UPPER(COALESCE(su.concept_code, TRIM(m.unit_source_value)))
JOIN @vocabulary_database_schema.concept tu
    ON tu.vocabulary_id = 'UCUM'
   AND tu.concept_code  = uc.target_unit_ucum
WHERE m.value_as_number IS NOT NULL
  AND NOT EXISTS (
        SELECT 1
        FROM (VALUES
@unit_exclusion_values
        ) AS ex(codeset_id, measurement_concept_id, unit_ucum)
        WHERE ex.codeset_id = cs.codeset_id
          AND ex.measurement_concept_id = m.measurement_concept_id
          AND UPPER(ex.unit_ucum) = UPPER(COALESCE(su.concept_code, TRIM(m.unit_source_value)))
  );

CREATE INDEX idx_measurement_visit_codeset
ON #measurement_filt(visit_occurrence_id, codeset_id, measurement_date);

---------------------------------------------------------
-- Baseline (primo measurement del ricovero, se più visite fai avg per = unit)
---------------------------------------------------------
SELECT *
INTO #Baseline
FROM (
    SELECT 
        mf.row_id,
        mf.visit_occurrence_id,
        mf.person_id,
        mf.codeset_id,
        mf.measurement_concept_id, 
        mf.measurement_date,
        AVG(mf.value_as_number) AS baseline_value,
        mf.unit_concept_id,
        ROW_NUMBER() OVER (
            PARTITION BY mf.row_id, mf.codeset_id
            ORDER BY mf.measurement_concept_id, mf.unit_concept_id  
        ) AS rn
    FROM #measurement_filt mf
    WHERE mf.measurement_date = mf.visit_start_date
      AND (
            (mf.codeset_id = 3 AND mf.unit_concept_id IN (8848, 8815))
         OR (mf.codeset_id = 4 AND mf.unit_concept_id IN (8554))
         OR (mf.codeset_id NOT IN (3, 4))
      )
    GROUP BY
        mf.row_id, mf.visit_occurrence_id, mf.person_id, mf.codeset_id,
        mf.measurement_concept_id, mf.measurement_date, mf.unit_concept_id
) X;
---------------------------------------------------------
-- POst Measurement 48h ± 24h
---------------------------------------------------------
SELECT *
INTO #Post
FROM (
    SELECT
        mf.row_id,
        mf.visit_occurrence_id,
        mf.person_id,
        mf.codeset_id,
        mf.measurement_concept_id,
        mf.measurement_date,
        AVG(mf.value_as_number) AS post_value,
        mf.unit_concept_id,
        ROW_NUMBER() OVER (
            PARTITION BY mf.visit_occurrence_id, mf.codeset_id
            ORDER BY
                CASE
                    WHEN mf.measurement_date = DATEADD(day, 2, mf.visit_start_date) THEN 0
                    WHEN mf.measurement_date = DATEADD(day, 3, mf.visit_start_date) THEN 1
                    WHEN mf.measurement_date = DATEADD(day, 1, mf.visit_start_date) THEN 2
                    ELSE 3
                END,
                mf.measurement_date
        ) AS rn
    FROM #measurement_filt mf
     WHERE mf.measurement_date BETWEEN DATEADD(day, 1, mf.visit_start_date)
     AND DATEADD(day, 3, mf.visit_start_date)
         AND (
            -- Normoblasts (#)
            (mf.codeset_id = 3 AND mf.unit_concept_id IN (8848, 8815)) -- -- 10*3/uL, 10*6/uL

            OR -- Normoblasts (%)
            (mf.codeset_id = 4 AND mf.unit_concept_id IN (8554)) -- %

            OR -- Altri codeset → nessun filtro
            (mf.codeset_id NOT IN (3,4))
        )
        GROUP BY
           mf.visit_occurrence_id,
           mf.person_id,
           mf.measurement_concept_id,
           mf.measurement_date,
           mf.unit_concept_id,
           mf.visit_start_date,
           mf.row_id,
           mf.codeset_id

) X;
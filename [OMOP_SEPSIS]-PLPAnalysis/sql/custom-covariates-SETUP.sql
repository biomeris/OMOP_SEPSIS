---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#ricoveri_tmp', 'U') IS NOT NULL DROP TABLE #ricoveri_tmp;
IF OBJECT_ID('#Codesets', 'U') IS NOT NULL DROP TABLE #Codesets;
IF OBJECT_ID('#measurement_filt', 'U') IS NOT NULL DROP TABLE #measurement_filt;
IF OBJECT_ID('#Baseline', 'U') IS NOT NULL DROP TABLE #Baseline;
IF OBJECT_ID('#Post', 'U') IS NOT NULL DROP TABLE #Post;

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
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4151358,3023314,2212642,3009542)-- Hematocrit determination
) I
) C UNION ALL
-- Eritroblasti (valore assoluto)
SELECT 3 as codeset_id, c.concept_id, 'Normoblasts (#)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3021589,4012826)-- Normoblasts [#/volume] in Blood, -- Nucleated red blood cell count procedure
) I
) C UNION ALL
-- Eritroblasti (percentuale)
SELECT 4 as codeset_id, c.concept_id, 'Normoblasts (%)' as codeset_name FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (3046588,3029160,4012826)-- Normoblasts/100 blasts in Blood, -- Nucleated red blood cell count procedure
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
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4298431, 37208925)-- White blood cell count
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
-- Esoinofili (valore assoluto)
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
-- Esoinofili (percentuale)
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
-- Bilirubin measurement
SELECT 24 as codeset_id, c.concept_id, 'bilirubin' as codeset_name FROM (select distinct I.concept_id FROM
( 
select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4118986,3024128,40757494,3007242,4216632,3028833,3027597,3021194,3007359) -- Bilirubin measurement
) I
) C UNION ALL
-- Creatinina 
SELECT 25 as codeset_id, c.concept_id, 'Creatinin' as codeset_name FROM (select distinct I.concept_id FROM
( 
SELECT concept_id FROM @vocabulary_database_schema.CONCEPT WHERE concept_id IN (4324383) -- Creatinine measurement
				UNION  
				SELECT c.concept_id
				FROM @vocabulary_database_schema.CONCEPT c
				JOIN @vocabulary_database_schema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
				AND ca.ancestor_concept_id IN (4324383) -- Creatinine measurement
				AND c.invalid_reason IS NULL
				UNION
				SELECT DISTINCT cr.concept_id_1 AS concept_id
				FROM
				(
					SELECT concept_id FROM @vocabulary_database_schema.CONCEPT WHERE concept_id IN (4324383) -- Creatinine measurement 
					UNION  SELECT c.concept_id
					FROM @vocabulary_database_schema.CONCEPT c
					JOIN @vocabulary_database_schema.CONCEPT_ANCESTOR ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4324383) -- Creatinine measurement
					AND c.invalid_reason IS NULL) C
				JOIN @vocabulary_database_schema.concept_relationship cr ON C.concept_id = cr.concept_id_2 AND cr.relationship_id = 'Maps to' AND cr.invalid_reason IS NULL
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
-- Cohort: Ricoveri
---------------------------------------------------------
SELECT 
  ROW_NUMBER() OVER (ORDER BY vo.person_id, vo.visit_start_date) as row_id,
  vo.visit_occurrence_id,
	vo.person_id,
	vo.visit_concept_id,
	vo.visit_start_date,
	vo.visit_end_date,
	vo.visit_end_date - vo.visit_start_date AS visit_length
INTO #ricoveri_tmp
FROM
	@cdm_schema.visit_occurrence vo
	JOIN @cohort_table c 
	ON c.subject_id = vo.person_id
	AND c.cohort_start_date = vo.visit_start_date
WHERE
	vo.visit_concept_id IN (
		SELECT
			c.concept_id
		FROM
			@vocabulary_database_schema.concept c
			JOIN @vocabulary_database_schema.concept_ancestor ca 
			ON c.concept_id = ca.descendant_concept_id
			AND ca.ancestor_concept_id IN (9201, 262)
			AND c.invalid_reason IS NULL
			AND c.domain_id = 'Visit'
	)
	AND (vo.visit_end_date - vo.visit_start_date) > 1 
	AND c.cohort_definition_id = @cohort_id_ricoveri
	ORDER BY vo.person_id, vo.visit_start_date;

CREATE INDEX idx_ricoveri_person ON #ricoveri_tmp(person_id);

---------------------------------------------------------
-- Measurement filtrati
---------------------------------------------------------
SELECT 
    r.row_id,
    r.visit_occurrence_id,
    r.person_id,
    cs.codeset_id,
    m.measurement_concept_id,
    m.measurement_date,
    m.value_as_number,
    m.unit_concept_id,
    r.visit_start_date,
    r.visit_end_date
INTO #measurement_filt
FROM #ricoveri_tmp r 
LEFT JOIN @cdm_schema.measurement m 
ON r.person_id = m.person_id
JOIN #Codesets cs
ON m.measurement_concept_id = cs.concept_id
WHERE m.value_as_number IS NOT NULL
AND m.measurement_date BETWEEN r.visit_start_date AND DATEADD(day,3,r.visit_start_date);

CREATE INDEX idx_measurement_visit_codeset
ON #measurement_filt(visit_occurrence_id, codeset_id, measurement_date);

---------------------------------------------------------
-- Baseline (primo measurement del ricovero)
---------------------------------------------------------
SELECT 
    *
INTO #Baseline
FROM (
    SELECT 
        mf.row_id,
        mf.visit_occurrence_id,
        mf.person_id,
        mf.codeset_id,
        mf.measurement_concept_id, 
        mf.measurement_date,
        mf.value_as_number as baseline_value,
        mf.unit_concept_id,
        ROW_NUMBER() OVER(
            PARTITION BY mf.visit_occurrence_id, mf.codeset_id
            ORDER BY mf.measurement_date
        ) AS rn
    FROM #measurement_filt mf
    WHERE mf.measurement_date = mf.visit_start_date
    AND (
            -- Normoblasts (#)
            (mf.codeset_id = 3 AND mf.unit_concept_id IN (8848, 8815)) -- -- 10*3/uL, 10*6/uL

            OR -- Normoblasts (%)
            (mf.codeset_id = 4 AND mf.unit_concept_id IN (8554)) -- %

            OR -- Altri codeset → nessun filtro
            (mf.codeset_id NOT IN (3,4))
        )

) X
WHERE X.rn = 1;

---------------------------------------------------------
-- Measurement 48h ± 24h
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
        mf.value_as_number AS post_value,
        mf.unit_concept_id,
        ROW_NUMBER() OVER (
            PARTITION BY mf.visit_occurrence_id, mf.codeset_id
            ORDER BY
                CASE
                    WHEN mf.measurement_date = DATEADD(day, 2, mf.visit_start_date) THEN 0
                    WHEN mf.measurement_date = DATEADD(day, 1, mf.visit_start_date) THEN 1
                    ELSE 2
                END,
                mf.measurement_date
        ) AS rn
    FROM #measurement_filt mf
     WHERE mf.measurement_date BETWEEN
         DATEADD(day, 1, mf.visit_start_date)
         AND DATEADD(day, 3, mf.visit_start_date)
         AND (
            -- Normoblasts (#)
            (mf.codeset_id = 3 AND mf.unit_concept_id IN (8848, 8815)) -- -- 10*3/uL, 10*6/uL

            OR -- Normoblasts (%)
            (mf.codeset_id = 4 AND mf.unit_concept_id IN (8554)) -- %

            OR -- Altri codeset → nessun filtro
            (mf.codeset_id NOT IN (3,4))
        )

) X
WHERE rn = 1;
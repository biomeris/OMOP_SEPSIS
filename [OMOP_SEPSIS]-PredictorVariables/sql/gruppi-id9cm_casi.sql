---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#ricoveri_all', 'U') IS NOT NULL DROP TABLE #ricoveri_all;
IF OBJECT_ID('#ricoveri', 'U') IS NOT NULL DROP TABLE #ricoveri;
IF OBJECT_ID('#diagnosis_groups', 'U') IS NOT NULL DROP TABLE #diagnosis_groups;

---------------------------------------------------------
-- Cohort: Ricoveri
---------------------------------------------------------
-- Tutti i ricoveri
SELECT
		vo.visit_occurrence_id,
		vo.person_id,
		vo.visit_concept_id,
		vo.visit_start_date,
		vo.visit_end_date,
		vo.admitted_from_concept_id,
		c.cohort_start_date,
		vo.visit_end_date - vo.visit_start_date AS visit_length
INTO #ricoveri_all
FROM
	@cdm_schema.visit_occurrence vo
	JOIN @results_schema.@cohort_table c ON c.subject_id = vo.person_id
	AND c.cohort_start_date = vo.visit_start_date
WHERE
	vo.visit_concept_id IN (
		SELECT
			c.concept_id
		FROM
			@vocabulary_schema.concept c
			JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
			AND ca.ancestor_concept_id IN (9201, 262)
			AND c.invalid_reason IS NULL
			AND c.domain_id = 'Visit'
	)
	AND (vo.visit_end_date - vo.visit_start_date) > 1
	AND c.cohort_definition_id = @cohort_id_ricoveri;

CREATE INDEX idx_ricoveri_all_person ON #ricoveri_all(person_id);

-- Ricoveri con sepsi
SELECT 
    ra.*
INTO #ricoveri
FROM @results_schema.@cohort_table c2 
INNER JOIN #ricoveri_all ra
    ON c2.subject_id = ra.person_id 
	AND c2.cohort_start_date >= ra.visit_start_date 
	AND c2.cohort_start_date <= ra.visit_end_date 
	WHERE c2.cohort_definition_id = @cohort_id_sepsi;

CREATE INDEX idx_ricoveri_person ON #ricoveri(person_id);

---------------------------------------------------------
-- Gruppi diagnosi
---------------------------------------------------------

SELECT
	c.concept_id,
	c.concept_name,
	c.concept_code AS icd9_code,
	ancestor.concept_code AS icd9_group,
	ancestor.concept_name as icd9_group_name,
	cr.concept_id_2 AS std_concept_id,
	c3.concept_name AS std_concept_name
INTO #diagnosis_groups
FROM
	@vocabulary_schema.concept c
	JOIN (
		SELECT
			c2.concept_code,
			c2.concept_name
		FROM
			@vocabulary_schema.concept c2
		WHERE
			c2.vocabulary_id = 'ICD9CM'
			AND c2.concept_class_id = '3-dig nonbill code'
	) ancestor ON c.concept_code LIKE ancestor.concept_code + '%'
	JOIN @vocabulary_schema.concept_relationship cr ON c.concept_id = cr.concept_id_1
	AND cr.relationship_id = 'Maps to'
	JOIN @vocabulary_schema.concept c3 ON cr.concept_id_2 = c3.concept_id
WHERE
	c.vocabulary_id = 'ICD9CM'
ORDER BY
	ancestor.concept_code;

CREATE INDEX idx_diagnosis_id ON #diagnosis_groups(std_concept_id);

---------------------------------------------------------
-- Tabella finale delle diagnosi
---------------------------------------------------------

IF OBJECT_ID('@results_schema.omop_sepsis_icd9_diagnosis_cases', 'U') IS NOT NULL DROP TABLE @results_schema.omop_sepsis_icd9_diagnosis_cases;

SELECT
	all_diag.visit_occurrence_id,
	all_diag.person_id,
	all_diag.icd9_group,
	all_diag.icd9_group_name,
	count(*) INTO @results_schema.omop_sepsis_icd9_diagnosis
FROM
	(
		SELECT
			co.condition_occurrence_id,
			co.person_id,
			co.condition_concept_id,
			co.condition_start_date,
			dg.icd9_code,
			dg.icd9_group,
			dg.icd9_group_name,
			dg.std_concept_id,
			r.visit_occurrence_id
		FROM
			@cdm_schema.condition_occurrence co
			JOIN #diagnosis_groups dg ON co.condition_concept_id = dg.std_concept_id
			JOIN #ricoveri r ON r.person_id = co.person_id
			AND co.condition_start_date >= (r.visit_start_date - 180)
			AND co.condition_start_date < r.visit_start_date
	) all_diag
GROUP BY
	all_diag.visit_occurrence_id,
	all_diag.person_id,
	all_diag.icd9_group,
	all_diag.icd9_group_name;

---------------------------------------------------------
-- Cleanup finale
---------------------------------------------------------
DROP TABLE #ricoveri_all;
DROP TABLE #ricoveri;
DROP TABLE #diagnosis_groups;

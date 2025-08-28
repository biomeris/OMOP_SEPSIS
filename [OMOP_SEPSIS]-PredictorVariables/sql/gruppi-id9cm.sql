IF OBJECT_ID(
	'@results_schema.omop_sepsis_icd9_diagnosis',
	'U'
) IS NOT NULL DROP TABLE @results_schema.omop_sepsis_icd9_diagnosis;

--- Conteggio condition_occurrence raggruppate per ricovero, person_id e gruppo ICD9CM	
WITH --- Ricoveri
ricoveri AS (
	SELECT
		vo.visit_occurrence_id,
		vo.person_id,
		vo.visit_concept_id,
		vo.visit_start_date,
		vo.visit_end_date,
		vo.admitted_from_concept_id,
		c.cohort_start_date,
		(vo.visit_end_date - vo.visit_start_date) AS visit_length
	FROM
		@cdm_schema.visit_occurrence vo
		JOIN @results_schema. @cohort_table c ON c.subject_id = vo.person_id
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
		AND c.cohort_definition_id = @cohort_id_ricoveri
),
diagnosis_groups AS (
	SELECT
		c.concept_id,
		c.concept_name,
		c.concept_code AS icd9_code,
		ancestor.concept_code AS icd9_group,
		ancestor.concept_name as icd9_group_name,
		cr.concept_id_2 AS std_concept_id,
		c3.concept_name AS std_concept_name
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
		ancestor.concept_code
)
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
			ricoveri.visit_occurrence_id
		FROM
			@cdm_schema.condition_occurrence co
			JOIN diagnosis_groups dg ON co.condition_concept_id = dg.std_concept_id
			JOIN ricoveri ON ricoveri.person_id = co.person_id
			AND co.condition_start_date >= (ricoveri.visit_start_date - 180)
			AND co.condition_start_date < ricoveri.visit_start_date
	) all_diag
GROUP BY
	all_diag.visit_occurrence_id,
	all_diag.person_id,
	all_diag.icd9_group,
	all_diag.icd9_group_name
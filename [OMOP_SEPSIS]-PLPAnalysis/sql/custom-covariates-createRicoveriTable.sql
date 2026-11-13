---------------------------------------------------------
-- Cohort: Ricoveri
---------------------------------------------------------
SELECT 
  vo.visit_occurrence_id,
	vo.person_id,
	vo.visit_concept_id,
	vo.visit_start_date,
	vo.visit_end_date,
	vo.visit_end_date - vo.visit_start_date AS visit_length
INTO @results_schema.ricoveri_tmp
FROM
	@cdm_schema.visit_occurrence vo
	JOIN @results_schema.@cohort_table c 
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
	AND c.cohort_definition_id = @cohort_id_ricoveri;

CREATE INDEX idx_ricoveri_person ON @results_schema.ricoveri_tmp(person_id);

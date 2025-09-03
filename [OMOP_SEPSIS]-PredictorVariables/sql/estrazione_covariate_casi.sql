---------------------------------------------------------
-- Cleanup iniziale
---------------------------------------------------------
IF OBJECT_ID('#ricoveri_all', 'U') IS NOT NULL DROP TABLE #ricoveri_all;
IF OBJECT_ID('#ricoveri_tmp', 'U') IS NOT NULL DROP TABLE #ricoveri_tmp;
IF OBJECT_ID('#anagrafica_tmp', 'U') IS NOT NULL DROP TABLE #anagrafica_tmp;
IF OBJECT_ID('#reparto_tmp', 'U') IS NOT NULL DROP TABLE #reparto_tmp;
IF OBJECT_ID('#emocultura', 'U') IS NOT NULL DROP TABLE #emocultura;
IF OBJECT_ID('#urinocultura', 'U') IS NOT NULL DROP TABLE #urinocultura;
IF OBJECT_ID('#procedure_inv', 'U') IS NOT NULL DROP TABLE #procedure_inv;
IF OBJECT_ID('#hgb_base', 'U') IS NOT NULL DROP TABLE #hgb_base;
IF OBJECT_ID('#hgb_post', 'U') IS NOT NULL DROP TABLE #hgb_post;
IF OBJECT_ID('#rbc_base', 'U') IS NOT NULL DROP TABLE #rbc_base;
IF OBJECT_ID('#rbc_post', 'U') IS NOT NULL DROP TABLE #rbc_post;
IF OBJECT_ID('#hct_base', 'U') IS NOT NULL DROP TABLE #hct_base;
IF OBJECT_ID('#hct_post', 'U') IS NOT NULL DROP TABLE #hct_post;
IF OBJECT_ID('#mcv_base', 'U') IS NOT NULL DROP TABLE #mcv_base;
IF OBJECT_ID('#mcv_post', 'U') IS NOT NULL DROP TABLE #mcv_post;
IF OBJECT_ID('#mch_base', 'U') IS NOT NULL DROP TABLE #mch_base;
IF OBJECT_ID('#mch_post', 'U') IS NOT NULL DROP TABLE #mch_post;
IF OBJECT_ID('#mchc_base', 'U') IS NOT NULL DROP TABLE #mchc_base;
IF OBJECT_ID('#mchc_post', 'U') IS NOT NULL DROP TABLE #mchc_post;
IF OBJECT_ID('#rdw_base', 'U') IS NOT NULL DROP TABLE #rdw_base;
IF OBJECT_ID('#rdw_post', 'U') IS NOT NULL DROP TABLE #rdw_post;
IF OBJECT_ID('#wbc_base', 'U') IS NOT NULL DROP TABLE #wbc_base;
IF OBJECT_ID('#wbc_post', 'U') IS NOT NULL DROP TABLE #wbc_post;
IF OBJECT_ID('#neutro_cont_base', 'U') IS NOT NULL DROP TABLE #neutro_cont_base;
IF OBJECT_ID('#neutro_cont_post', 'U') IS NOT NULL DROP TABLE #neutro_cont_post;
IF OBJECT_ID('#neutro_perc_base', 'U') IS NOT NULL DROP TABLE #neutro_perc_base;
IF OBJECT_ID('#neutro_perc_post', 'U') IS NOT NULL DROP TABLE #neutro_perc_post;
IF OBJECT_ID('#linfo_cont_base', 'U') IS NOT NULL DROP TABLE #linfo_cont_base;
IF OBJECT_ID('#linfo_cont_post', 'U') IS NOT NULL DROP TABLE #linfo_cont_post;
IF OBJECT_ID('#linfo_perc_base', 'U') IS NOT NULL DROP TABLE #linfo_perc_base;
IF OBJECT_ID('#linfo_perc_post', 'U') IS NOT NULL DROP TABLE #linfo_perc_post;
IF OBJECT_ID('#mono_cont_base', 'U') IS NOT NULL DROP TABLE #mono_cont_base;
IF OBJECT_ID('#mono_cont_post', 'U') IS NOT NULL DROP TABLE #mono_cont_post;
IF OBJECT_ID('#mono_perc_base', 'U') IS NOT NULL DROP TABLE #mono_perc_base;
IF OBJECT_ID('#mono_perc_post', 'U') IS NOT NULL DROP TABLE #mono_perc_post;
IF OBJECT_ID('#eosi_cont_base', 'U') IS NOT NULL DROP TABLE #eosi_cont_base;
IF OBJECT_ID('#eosi_cont_post', 'U') IS NOT NULL DROP TABLE #eosi_cont_post;
IF OBJECT_ID('#eosi_perc_base', 'U') IS NOT NULL DROP TABLE #eosi_perc_base;
IF OBJECT_ID('#eosi_perc_post', 'U') IS NOT NULL DROP TABLE #eosi_perc_post;
IF OBJECT_ID('#baso_cont_base', 'U') IS NOT NULL DROP TABLE #baso_cont_base;
IF OBJECT_ID('#baso_cont_post', 'U') IS NOT NULL DROP TABLE #baso_cont_post;
IF OBJECT_ID('#baso_perc_base', 'U') IS NOT NULL DROP TABLE #baso_perc_base;
IF OBJECT_ID('#baso_perc_post', 'U') IS NOT NULL DROP TABLE #baso_perc_post;
IF OBJECT_ID('#eritro_cont_base', 'U') IS NOT NULL DROP TABLE #eritro_cont_base;
IF OBJECT_ID('#eritro_cont_post', 'U') IS NOT NULL DROP TABLE #eritro_cont_post;
IF OBJECT_ID('#eritro_perc_base', 'U') IS NOT NULL DROP TABLE #eritro_perc_base;
IF OBJECT_ID('#eritro_perc_post', 'U') IS NOT NULL DROP TABLE #eritro_perc_post;
IF OBJECT_ID('#pdw_base', 'U') IS NOT NULL DROP TABLE #pdw_base;
IF OBJECT_ID('#pdw_post', 'U') IS NOT NULL DROP TABLE #pdw_post;
IF OBJECT_ID('#mpv_base', 'U') IS NOT NULL DROP TABLE #mpv_base;
IF OBJECT_ID('#mpv_post', 'U') IS NOT NULL DROP TABLE #mpv_post;
IF OBJECT_ID('#ega_base', 'U') IS NOT NULL DROP TABLE #ega_base;
IF OBJECT_ID('#ega_post', 'U') IS NOT NULL DROP TABLE #ega_post;
IF OBJECT_ID('#plt_base', 'U') IS NOT NULL DROP TABLE #plt_base;
IF OBJECT_ID('#plt_post', 'U') IS NOT NULL DROP TABLE #plt_post;
IF OBJECT_ID('#pt_base', 'U') IS NOT NULL DROP TABLE #pt_base;
IF OBJECT_ID('#pt_post', 'U') IS NOT NULL DROP TABLE #pt_post;
IF OBJECT_ID('#ptt_base', 'U') IS NOT NULL DROP TABLE #ptt_base;
IF OBJECT_ID('#ptt_post', 'U') IS NOT NULL DROP TABLE #ptt_post;
IF OBJECT_ID('#inr_base', 'U') IS NOT NULL DROP TABLE #inr_base;
IF OBJECT_ID('#inr_post', 'U') IS NOT NULL DROP TABLE #inr_post;
IF OBJECT_ID('#transaminasi_base', 'U') IS NOT NULL DROP TABLE #transaminasi_base;
IF OBJECT_ID('#transaminasi_post', 'U') IS NOT NULL DROP TABLE #transaminasi_post;
IF OBJECT_ID('#bilirubina_base', 'U') IS NOT NULL DROP TABLE #bilirubina_base;
IF OBJECT_ID('#bilirubina_post', 'U') IS NOT NULL DROP TABLE #bilirubina_post;
IF OBJECT_ID('#creatinina_base', 'U') IS NOT NULL DROP TABLE #creatinina_base;
IF OBJECT_ID('#creatinina_post', 'U') IS NOT NULL DROP TABLE #creatinina_post;
IF OBJECT_ID('#azotemia_base', 'U') IS NOT NULL DROP TABLE #azotemia_base;
IF OBJECT_ID('#azotemia_post', 'U') IS NOT NULL DROP TABLE #azotemia_post;
IF OBJECT_ID('#glicemia_base', 'U') IS NOT NULL DROP TABLE #glicemia_base;
IF OBJECT_ID('#glicemia_post', 'U') IS NOT NULL DROP TABLE #glicemia_post;
IF OBJECT_ID('#sodium_base', 'U') IS NOT NULL DROP TABLE #sodium_base;
IF OBJECT_ID('#sodium_post', 'U') IS NOT NULL DROP TABLE #sodium_post;
IF OBJECT_ID('#chloride_base', 'U') IS NOT NULL DROP TABLE #chloride_base;
IF OBJECT_ID('#chloride_post', 'U') IS NOT NULL DROP TABLE #chloride_post;
IF OBJECT_ID('#potassium_base', 'U') IS NOT NULL DROP TABLE #potassium_base;
IF OBJECT_ID('#potassium_post', 'U') IS NOT NULL DROP TABLE #potassium_post;
IF OBJECT_ID('#pct_base', 'U') IS NOT NULL DROP TABLE #pct_base;
IF OBJECT_ID('#pct_post', 'U') IS NOT NULL DROP TABLE #pct_post;
IF OBJECT_ID('#pcr_base', 'U') IS NOT NULL DROP TABLE #pcr_base;
IF OBJECT_ID('#pcr_post', 'U') IS NOT NULL DROP TABLE #pcr_post;

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
INTO #ricoveri_tmp
FROM @results_schema.@cohort_table c2 
INNER JOIN #ricoveri_all ra
    ON c2.subject_id = ra.person_id 
	AND c2.cohort_start_date >= ra.visit_start_date 
	AND c2.cohort_start_date <= ra.visit_end_date 
	WHERE c2.cohort_definition_id = @cohort_id_sepsi;

CREATE INDEX idx_ricoveri_person ON #ricoveri_tmp(person_id);

---------------------------------------------------------
-- Anagrafica
---------------------------------------------------------
SELECT
	r.visit_occurrence_id,
	r.person_id,
	p.gender_concept_id,
	DATEPART(YEAR, r.visit_start_date) - p.year_of_birth AS age
INTO #anagrafica_tmp
FROM #ricoveri_tmp r
LEFT JOIN @cdm_schema.person p ON r.person_id = p.person_id;

CREATE INDEX idx_anagrafica_person ON #anagrafica_tmp(person_id);

---------------------------------------------------------
-- Reparto ricovero
---------------------------------------------------------
SELECT
	*
INTO #reparto_tmp
FROM
	(
		SELECT
			vd.visit_detail_id,
			vd.person_id,
			vd.visit_detail_concept_id,
			vd.visit_detail_start_date,
			vd.care_site_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY vd.visit_occurrence_id
				ORDER BY
					vd.visit_detail_start_date
			) AS rank
		FROM
			@cdm_schema.visit_detail vd
			JOIN #ricoveri_tmp r ON vd.visit_occurrence_id = r.visit_occurrence_id
	) AS all_visit_detail
WHERE
	all_visit_detail.rank = 1;

CREATE INDEX idx_reparto_person ON #reparto_tmp(person_id);

---------------------------------------------------------
-- Emocultura
---------------------------------------------------------
SELECT
	*
INTO #emocultura
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date >= r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4107893) -- Blood culture 
					AND c.invalid_reason IS NULL
			    	AND c.domain_id = 'Measurement'
			)
	) AS all_emo
WHERE
	all_emo.rank = 1;

CREATE INDEX idx_emocultura_person ON #emocultura(person_id);

---------------------------------------------------------
-- Urinocultura
---------------------------------------------------------
SELECT
	*
INTO #urinocultura
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date >= r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4024509) -- Urine culture 
					AND c.invalid_reason IS NULL
			    	AND c.domain_id = 'Measurement'
			)
	) AS all_uro
WHERE
	all_uro.rank = 1;

CREATE INDEX idx_urinocultura_person ON #urinocultura(person_id);

---------------------------------------------------------
-- Procedure invasive
---------------------------------------------------------
SELECT
	*
INTO #procedure_inv
FROM
	(
		SELECT
			po.procedure_occurrence_id,
			po.person_id,
			po.procedure_concept_id,
			po.procedure_date,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					po.procedure_date DESC
			) AS rank
		FROM
			@cdm_schema.procedure_occurrence po
			JOIN #ricoveri_tmp r ON po.person_id = r.person_id
			AND po.procedure_date >= r.visit_start_date
			AND po.procedure_date <= r.visit_end_date
		WHERE
			po.procedure_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4301351,4179713) -- Surgical procedure, Endoscopic procedure
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Procedure'
			)
	) AS all_procedure
WHERE
	all_procedure.rank = 1;

CREATE INDEX idx_procedure_person ON #procedure_inv(person_id);

---------------------------------------------------------
-- HGB (Emoglobina)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #hgb_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4153000, 37029074, 37072252) -- Hemoglobin
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			)
	) AS all_hgb_base
WHERE
	all_hgb_base.rank = 1;

CREATE INDEX idx_hgb_base_person ON #hgb_base(person_id);

-- 72h
SELECT
	*
INTO #hgb_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4153000, 37029074, 37072252) -- Hemoglobin
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			)
	) AS all_hgb_base
WHERE
	all_hgb_base.rank = 1;

CREATE INDEX idx_hgb_post_person ON #hgb_post(person_id);

---------------------------------------------------------
-- RBC (Eritrociti)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #rbc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4030871) -- Red blood cell count
	) AS all_rbc_base
WHERE
	all_rbc_base.rank = 1;

CREATE INDEX idx_rbc_base_person ON #rbc_base(person_id);

-- 72h
SELECT
	*
INTO #rbc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4030871) -- Red blood cell count
	) AS all_rbc_base
WHERE
	all_rbc_base.rank = 1;

CREATE INDEX idx_rbc_post_person ON #rbc_post(person_id);

---------------------------------------------------------
-- HCT (Ematocrito)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #hct_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4151358) -- Hematocrit determination
	) AS all_hct_base
WHERE
	all_hct_base.rank = 1;

CREATE INDEX idx_hct_base_person ON #hct_base(person_id);

-- 72h
SELECT
	*
INTO #hct_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4151358) -- Hematocrit determination
	) AS all_hct_base
WHERE
	all_hct_base.rank = 1;

CREATE INDEX idx_hct_post_person ON #hct_post(person_id);

---------------------------------------------------------
-- MCV (Volume Corpuscolare Medio)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mcv_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4016239) -- Erythrocyte mean corpuscular volume determination
	) AS all_mcv_base
WHERE
	all_mcv_base.rank = 1;

CREATE INDEX idx_mcv_base_person ON #mcv_base(person_id);

-- 72h
SELECT
	*
INTO #mcv_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4016239) -- Erythrocyte mean corpuscular volume determination
	) AS all_mcv_base
WHERE
	all_mcv_base.rank = 1;

CREATE INDEX idx_mcv_post_person ON #mcv_post(person_id);

---------------------------------------------------------
-- MCH (Contenuto HGB medio)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mch_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4182871) -- Mean corpuscular hemoglobin determination
	) AS all_mch_base
WHERE
	all_mch_base.rank = 1;

CREATE INDEX idx_mch_base_person ON #mch_base(person_id);

-- 72h
SELECT
	*
INTO #mch_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4182871) -- Mean corpuscular hemoglobin determination
	) AS all_mch_base
WHERE
	all_mch_base.rank = 1;

CREATE INDEX idx_mch_post_person ON #mch_post(person_id);

---------------------------------------------------------
-- MCHC (Conc. HGB Globulare Media)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mchc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4290193) -- Mean corpuscular hemoglobin concentration determination
	) AS all_mchc_base
WHERE
	all_mchc_base.rank = 1;

CREATE INDEX idx_mchc_base_person ON #mchc_base(person_id);

-- 72h
SELECT
	*
INTO #mchc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4290193) -- Mean corpuscular hemoglobin concentration determination
	) AS all_mchc_base
WHERE
	all_mchc_base.rank = 1;

CREATE INDEX idx_mchc_post_person ON #mchc_post(person_id);

---------------------------------------------------------
-- RDW
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #rdw_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4281085) -- Red cell distribution width determination
	) AS all_rdw_base
WHERE
	all_rdw_base.rank = 1;

CREATE INDEX idx_rdw_base_person ON #rdw_base(person_id);

-- 72h
SELECT
	*
INTO #rdw_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4281085) -- Red cell distribution width determination
	) AS all_rdw_base
WHERE
	all_rdw_base.rank = 1;

CREATE INDEX idx_rdw_post_person ON #rdw_post(person_id);

---------------------------------------------------------
-- WBC (Leucociti)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #wbc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4298431) -- White blood cell count
	) AS all_wbc_base
WHERE
	all_wbc_base.rank = 1;

CREATE INDEX idx_wbc_base_person ON #wbc_base(person_id);

-- 72h
SELECT
	*
INTO #wbc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4298431) -- White blood cell count
	) AS all_wbc_base
WHERE
	all_wbc_base.rank = 1;

CREATE INDEX idx_wbc_post_person ON #wbc_post(person_id);

---------------------------------------------------------
-- Neutrofili (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #neutro_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4148615) -- Neutrophil count
	) AS all_neutro_cont_base
WHERE
	all_neutro_cont_base.rank = 1;

CREATE INDEX idx_neutro_cont_base_person ON #neutro_cont_base(person_id);

-- 72h
SELECT
	*
INTO #neutro_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4148615) -- Neutrophil count
	) AS all_neutro_cont_base
WHERE
	all_neutro_cont_base.rank = 1;

CREATE INDEX idx_neutro_cont_post_person ON #neutro_cont_post(person_id);

---------------------------------------------------------
-- Neutrofili (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #neutro_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (3018010, 37398605) -- Neutrophils/100 leukocytes in Blood, Percentage neutrophils
	) AS all_neutro_perc_base
WHERE
	all_neutro_perc_base.rank = 1;

CREATE INDEX idx_neutro_perc_base_person ON #neutro_perc_base(person_id);

-- 72h
SELECT
	*
INTO #neutro_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id (3018010, 37398605) -- Neutrophils/100 leukocytes in Blood, Percentage neutrophils
	) AS all_neutro_perc_base
WHERE
	all_neutro_perc_base.rank = 1;

CREATE INDEX idx_neutro_perc_post_person ON #neutro_perc_post(person_id);

---------------------------------------------------------
-- Linfociti (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #linfo_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4254663) -- Lymphocyte count
	) AS all_linfo_cont_base
WHERE
	all_linfo_cont_base.rank = 1;

CREATE INDEX idx_linfo_cont_base_person ON #linfo_cont_base(person_id);

-- 72h
SELECT
	*
INTO #linfo_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4254663) -- Lymphocyte count
	) AS all_linfo_cont_base
WHERE
	all_linfo_cont_base.rank = 1;

CREATE INDEX idx_linfo_cont_post_person ON #linfo_cont_post(person_id);

---------------------------------------------------------
-- Linfociti (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #linfo_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (3002030, 37399254) -- Lymphocytes/100 leukocytes in Blood, Percentage lymphocytes
	) AS all_linfo_perc_base
WHERE
	all_linfo_perc_base.rank = 1;

CREATE INDEX idx_linfo_perc_base_person ON #linfo_perc_base(person_id);

-- 72h
SELECT
	*
INTO #linfo_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (3002030, 37399254) -- Lymphocytes/100 leukocytes in Blood, Percentage lymphocytes
	) AS all_linfo_perc_base
WHERE
	all_linfo_perc_base.rank = 1;

CREATE INDEX idx_linfo_perc_post_person ON #linfo_perc_post(person_id);

---------------------------------------------------------
-- Monociti (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mono_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4194332) -- Monocyte count
	) AS all_mono_cont_base
WHERE
	all_mono_cont_base.rank = 1;

CREATE INDEX idx_mono_cont_base_person ON #mono_cont_base(person_id);

-- 72h
SELECT
	*
INTO #mono_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4194332) -- Monocyte count
	) AS all_mono_cont_base
WHERE
	all_mono_cont_base.rank = 1;

CREATE INDEX idx_mono_cont_post_person ON #mono_cont_post(person_id);

---------------------------------------------------------
-- Monociti (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mono_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (3019069, 37393321) -- Monocytes/100 leukocytes in Blood, Percentage monocytes
	) AS all_mono_perc_base
WHERE
	all_mono_perc_base.rank = 1;

CREATE INDEX idx_mono_perc_base_person ON #mono_perc_base(person_id);

-- 72h
SELECT
	*
INTO #mono_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (3019069, 37393321) -- Monocytes/100 leukocytes in Blood, Percentage monocytes
	) AS all_mono_perc_base
WHERE
	all_mono_perc_base.rank = 1;

CREATE INDEX idx_mono_perc_post_person ON #mono_perc_post(person_id);

---------------------------------------------------------
-- Eosinofili (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #eosi_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4216098) -- Eosinophil count
	) AS all_eosi_cont_base
WHERE
	all_eosi_cont_base.rank = 1;

CREATE INDEX idx_eosi_cont_base_person ON #eosi_cont_base(person_id);

-- 72h
SELECT
	*
INTO #eosi_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4216098) -- Eosinophil count
	) AS all_eosi_cont_base
WHERE
	all_eosi_cont_base.rank = 1;

CREATE INDEX idx_eosi_cont_post_person ON #eosi_cont_post(person_id);

---------------------------------------------------------
-- Eosinofili (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #eosi_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (3006504) -- Eosinophils/100 leukocytes in Blood
	) AS all_eosi_perc_base
WHERE
	all_eosi_perc_base.rank = 1;

CREATE INDEX idx_eosi_perc_base_person ON #eosi_perc_base(person_id);

-- 72h
SELECT
	*
INTO #eosi_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (3006504) -- Eosinophils/100 leukocytes in Blood
	) AS all_eosi_perc_base
WHERE
	all_eosi_perc_base.rank = 1;

CREATE INDEX idx_eosi_perc_post_person ON #eosi_perc_post(person_id);

---------------------------------------------------------
-- Basofili (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #baso_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4172647) -- Basophil count
	) AS all_baso_cont_base
WHERE
	all_baso_cont_base.rank = 1;

CREATE INDEX idx_baso_cont_base_person ON #baso_cont_base(person_id);

-- 72h
SELECT
	*
INTO #baso_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4172647) -- Basophil count
	) AS all_baso_cont_base
WHERE
	all_baso_cont_base.rank = 1;

CREATE INDEX idx_baso_cont_post_person ON #baso_cont_post(person_id);

---------------------------------------------------------
-- Basofili (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #baso_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (3022096, 37398606) -- Basophils/100 leukocytes in Blood, Percentage basophils
	) AS all_baso_perc_base
WHERE
	all_baso_perc_base.rank = 1;

CREATE INDEX idx_baso_perc_base_person ON #baso_perc_base(person_id);

-- 72h
SELECT
	*
INTO #baso_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (3022096, 37398606) -- Basophils/100 leukocytes in Blood, Percentage basophils
	) AS all_baso_perc_base
WHERE
	all_baso_perc_base.rank = 1;

CREATE INDEX idx_baso_perc_post_person ON #baso_perc_post(person_id);

---------------------------------------------------------
-- Eritroblasti (valore assoluto)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #eritro_cont_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			(
					(m.measurement_concept_id = 3021589) -- Normoblasts [#/volume] in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8848, 8815) -- 10*3/uL, 10*6/uL
					)
				)
	) AS all_eritro_cont_base
WHERE
	all_eritro_cont_base.rank = 1;

CREATE INDEX idx_eritro_cont_base_person ON #eritro_cont_base(person_id);

-- 72h
SELECT
	*
INTO #eritro_cont_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			(
					(m.measurement_concept_id = 3021589) -- Normoblasts [#/volume] in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8848, 8815) -- 10*3/uL, 10*6/uL
					)
				)
	) AS all_eritro_cont_base
WHERE
	all_eritro_cont_base.rank = 1;

CREATE INDEX idx_eritro_cont_post_person ON #eritro_cont_post(person_id);

---------------------------------------------------------
-- Eritroblasti (percentuale)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #eritro_perc_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			(
					(m.measurement_concept_id = 3046588) -- Normoblasts/100 blasts in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8554) -- %
					)
				)
	) AS all_eritro_perc_base
WHERE
	all_eritro_perc_base.rank = 1;

CREATE INDEX idx_eritro_perc_base_person ON #eritro_perc_base(person_id);

-- 72h
SELECT
	*
INTO #eritro_perc_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			(
					(m.measurement_concept_id = 3046588) -- Normoblasts/100 blasts in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8554) -- %
					)
				)
	) AS all_eritro_perc_base
WHERE
	all_eritro_perc_base.rank = 1;

CREATE INDEX idx_eritro_perc_post_person ON #eritro_perc_post(person_id);

---------------------------------------------------------
-- PDW (Anisocitosi PLT)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #pdw_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4097620, 3040227) -- Platelet distribution width measurement
	) AS all_pdw_base
WHERE
	all_pdw_base.rank = 1;

CREATE INDEX idx_pdw_base_person ON #pdw_base(person_id);

-- 72h
SELECT
	*
INTO #pdw_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4097620, 3040227) -- Platelet distribution width measurement
	) AS all_pdw_base
WHERE
	all_pdw_base.rank = 1;

CREATE INDEX idx_pdw_post_person ON #pdw_post(person_id);

---------------------------------------------------------
-- MPV (Volume Piastrinico Medio)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #mpv_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4192368) -- Platelet mean volume determination
	) AS all_mpv_base
WHERE
	all_mpv_base.rank = 1;

CREATE INDEX idx_mpv_base_person ON #mpv_base(person_id);

-- 72h
SELECT
	*
INTO #mpv_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4192368) -- Platelet mean volume determination
	) AS all_mpv_base
WHERE
	all_mpv_base.rank = 1;

CREATE INDEX idx_mpv_post_person ON #mpv_post(person_id);

---------------------------------------------------------
-- EGA-EAB con lattati
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #ega_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4239236) -- Blood gases, arterial measurement
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			)
	) AS all_ega_base
WHERE
	all_ega_base.rank = 1;

CREATE INDEX idx_ega_base_person ON #ega_base(person_id);

-- 72h
SELECT
	*
INTO #ega_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4239236) -- Blood gases, arterial measurement
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			)
	) AS all_ega_base
WHERE
	all_ega_base.rank = 1;

CREATE INDEX idx_ega_post_person ON #ega_post(person_id);

---------------------------------------------------------
-- Piastrine
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #plt_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4267147) -- Platelet count
	) AS all_plt_base
WHERE
	all_plt_base.rank = 1;

CREATE INDEX idx_plt_base_person ON #plt_base(person_id);

-- 72h
SELECT
	*
INTO #plt_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4267147) -- Platelet count
	) AS all_plt_base
WHERE
	all_plt_base.rank = 1;

CREATE INDEX idx_plt_post_person ON #plt_post(person_id);

---------------------------------------------------------
-- PT
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #pt_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4245261) -- Prothrombin time
	) AS all_pt_base
WHERE
	all_pt_base.rank = 1;

CREATE INDEX idx_pt_base_person ON #pt_base(person_id);

-- 72h
SELECT
	*
INTO #pt_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4245261) -- Prothrombin time
	) AS all_pt_base
WHERE
	all_pt_base.rank = 1;

CREATE INDEX idx_pt_post_person ON #pt_post(person_id);

---------------------------------------------------------
-- PTT
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #ptt_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (2212742) -- Thromboplastin time, partial (PTT); plasma or whole blood 
	) AS all_ptt_base
WHERE
	all_ptt_base.rank = 1;

CREATE INDEX idx_ptt_base_person ON #ptt_base(person_id);

-- 72h
SELECT
	*
INTO #ptt_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (2212742) -- Thromboplastin time, partial (PTT); plasma or whole blood 
	) AS all_ptt_base
WHERE
	all_ptt_base.rank = 1;

CREATE INDEX idx_ptt_post_person ON #ptt_post(person_id);

---------------------------------------------------------
-- INR
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #inr_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4306239, 46285118) -- International normalized ratio 
	) AS all_inr_base
WHERE
	all_inr_base.rank = 1;

CREATE INDEX idx_inr_base_person ON #inr_base(person_id);

-- 72h
SELECT
	*
INTO #inr_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4306239, 46285118) -- International normalized ratio 
	) AS all_inr_base
WHERE
	all_inr_base.rank = 1;

CREATE INDEX idx_inr_post_person ON #inr_post(person_id);

---------------------------------------------------------
-- Transaminasi
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #transaminasi_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4146380, 4263457) -- ALT - blood measurement, Aspartate aminotransferase measurement
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			)
	) AS all_transaminasi_base
WHERE
	all_transaminasi_base.rank = 1;

CREATE INDEX idx_transaminasi_base_person ON #transaminasi_base(person_id);

-- 72h
SELECT
	*
INTO #transaminasi_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (
				SELECT
					c.concept_id
				FROM
					@vocabulary_schema.concept c
					JOIN @vocabulary_schema.concept_ancestor ca ON c.concept_id = ca.descendant_concept_id
					AND ca.ancestor_concept_id IN (4146380, 4263457) -- ALT - blood measurement, Aspartate aminotransferase measurement
					AND c.invalid_reason IS NULL
					AND c.domain_id = 'Measurement'
			) 
	) AS all_transaminasi_base
WHERE
	all_transaminasi_base.rank = 1;

CREATE INDEX idx_transaminasi_post_person ON #transaminasi_post(person_id);

---------------------------------------------------------
-- Bilirubina
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #bilirubina_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4118986) -- Bilirubin measurement
	) AS all_bilirubina_base
WHERE
	all_bilirubina_base.rank = 1;

CREATE INDEX idx_bilirubina_base_person ON #bilirubina_base(person_id);

-- 72h
SELECT
	*
INTO #bilirubina_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4118986) -- Bilirubin measurement
	) AS all_bilirubina_base
WHERE
	all_bilirubina_base.rank = 1;

CREATE INDEX idx_bilirubina_post_person ON #bilirubina_post(person_id);

---------------------------------------------------------
-- Creatinina
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #creatinina_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4324383) -- Creatinine measurement
	) AS all_creatinina_base
WHERE
	all_creatinina_base.rank = 1;

CREATE INDEX idx_creatinina_base_person ON #creatinina_base(person_id);

-- 72h
SELECT
	*
INTO #creatinina_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4324383) -- Creatinine measurement
	) AS all_creatinina_base
WHERE
	all_creatinina_base.rank = 1;

CREATE INDEX idx_creatinina_post_person ON #creatinina_post(person_id);

---------------------------------------------------------
-- Azotemia
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #azotemia_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4020121, 4094594) -- Urea measurement
	) AS all_azotemia_base
WHERE
	all_azotemia_base.rank = 1;

CREATE INDEX idx_azotemia_base_person ON #azotemia_base(person_id);

-- 72h
SELECT
	*
INTO #azotemia_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4020121, 4094594) -- Urea measurement
	) AS all_azotemia_base
WHERE
	all_azotemia_base.rank = 1;

CREATE INDEX idx_azotemia_post_person ON #azotemia_post(person_id);

---------------------------------------------------------
-- Glicemia
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #glicemia_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4202143, 4149519, 4144235) -- Blood glucose concentration
	) AS all_glicemia_base
WHERE
	all_glicemia_base.rank = 1;

CREATE INDEX idx_glicemia_base_person ON #glicemia_base(person_id);

-- 72h
SELECT
	*
INTO #glicemia_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4202143, 4149519, 4144235) -- Blood glucose concentration
	) AS all_glicemia_base
WHERE
	all_glicemia_base.rank = 1;

CREATE INDEX idx_glicemia_post_person ON #glicemia_post(person_id);

---------------------------------------------------------
-- Sodio (Na)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #sodium_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4208938) -- Sodium measurement, blood
	) AS all_sodium_base
WHERE
	all_sodium_base.rank = 1;

CREATE INDEX idx_sodium_base_person ON #sodium_base(person_id);

-- 72h
SELECT
	*
INTO #sodium_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4208938) -- Sodium measurement, blood
	) AS all_sodium_base
WHERE
	all_sodium_base.rank = 1;

CREATE INDEX idx_sodium_post_person ON #sodium_post(person_id);

---------------------------------------------------------
-- Cloro (Cl)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #chloride_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4019545, 4008116) -- Chloride measurement, blood
	) AS all_chloride_base
WHERE
	all_chloride_base.rank = 1;

CREATE INDEX idx_chloride_base_person ON #chloride_base(person_id);

-- 72h
SELECT
	*
INTO #chloride_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4019545, 4008116) -- Chloride measurement, blood
	) AS all_chloride_base
WHERE
	all_chloride_base.rank = 1;

CREATE INDEX idx_chloride_post_person ON #chloride_post(person_id);

---------------------------------------------------------
-- Potassio (K)
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #potassium_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4207483) -- Blood potassium measurement
	) AS all_potassium_base
WHERE
	all_potassium_base.rank = 1;

CREATE INDEX idx_potassium_base_person ON #potassium_base(person_id);

-- 72h
SELECT
	*
INTO #potassium_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4207483) -- Blood potassium measurement
	) AS all_potassium_base
WHERE
	all_potassium_base.rank = 1;

CREATE INDEX idx_potassium_post_person ON #potassium_post(person_id);

---------------------------------------------------------
-- PCT
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #pct_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (44791466) -- Procalcitonin measurement
	) AS all_pct_base
WHERE
	all_pct_base.rank = 1;

CREATE INDEX idx_pct_base_person ON #pct_base(person_id);

-- 72h
SELECT
	*
INTO #pct_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (44791466) -- Procalcitonin measurement
	) AS all_pct_base
WHERE
	all_pct_base.rank = 1;

CREATE INDEX idx_pct_post_person ON #pct_post(person_id);

---------------------------------------------------------
-- PCR
---------------------------------------------------------
-- Baseline
SELECT
	*
INTO #pcr_base
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date = r.visit_start_date
		WHERE
			m.measurement_concept_id IN (4208414) -- C-reactive protein measurement
	) AS all_pcr_base
WHERE
	all_pcr_base.rank = 1;

CREATE INDEX idx_pcr_base_person ON #pcr_base(person_id);

-- 72h
SELECT
	*
INTO #pcr_post
FROM
	(
		SELECT
			m.measurement_id,
			m.person_id,
			m.measurement_concept_id,
			m.measurement_date,
			m.value_as_number,
			m.unit_concept_id,
			r.visit_occurrence_id,
			ROW_NUMBER() OVER (
				PARTITION BY r.visit_occurrence_id
				ORDER BY
					m.measurement_date DESC
			) AS rank
		FROM
			@cdm_schema.measurement m
			JOIN #ricoveri_tmp r ON m.person_id = r.person_id
			AND m.measurement_date > r.visit_start_date
			AND m.measurement_date <= r.visit_end_date
			AND m.measurement_date <= (r.visit_start_date + 3)
		WHERE
			m.measurement_concept_id IN (4208414) -- C-reactive protein measurement
	) AS all_pcr_base
WHERE
	all_pcr_base.rank = 1;

CREATE INDEX idx_pcr_post_person ON #pcr_post(person_id);

---------------------------------------------------------
-- Tabella finale delle covariate
---------------------------------------------------------
IF OBJECT_ID('@results_schema.omop_sepsis_covariates_cases', 'U') IS NOT NULL DROP TABLE @results_schema.omop_sepsis_covariates_cases;

SELECT r.visit_occurrence_id,
	r.person_id,
	r.visit_start_date,
	r.visit_end_date,
	r.admitted_from_concept_id AS provenienza,
    a.gender_concept_id AS sex,
	a.age AS age,
    rep.care_site_id AS reparto_ricovero,
	IIF(emo.measurement_concept_id IS NOT NULL,1,0) AS emocultura,
    IIF(uri.measurement_concept_id IS NOT NULL,1,0) AS urinocultura,
    IIF(pinv.procedure_concept_id IS NOT NULL,1,0) AS procedure_invasive,
    IIF(hgbb.measurement_concept_id IS NOT NULL,1,0) AS hgb_base,
	IIF(hgbp.measurement_concept_id IS NOT NULL,1,0) AS hgb_post,
    IIF(rbcb.measurement_concept_id IS NOT NULL,1,0) AS rbc_base,
	IIF(rbcp.measurement_concept_id IS NOT NULL,1,0) AS rbc_post,
    IIF(hctb.measurement_concept_id IS NOT NULL,1,0) AS hct_base,
	IIF(hctp.measurement_concept_id IS NOT NULL,1,0) AS hct_post,
    IIF(mcvb.measurement_concept_id IS NOT NULL,1,0) AS mcv_base,
	IIF(mcvp.measurement_concept_id IS NOT NULL,1,0) AS mcv_post,
    IIF(mchb.measurement_concept_id IS NOT NULL,1,0) AS mch_base,
	IIF(mchp.measurement_concept_id IS NOT NULL,1,0) AS mch_post,
    IIF(mchcb.measurement_concept_id IS NOT NULL,1,0) AS mchc_base,
	IIF(mchcp.measurement_concept_id IS NOT NULL,1,0) AS mchc_post,
    IIF(rdwb.measurement_concept_id IS NOT NULL,1,0) AS rdw_base,
	IIF(rdwp.measurement_concept_id IS NOT NULL,1,0) AS rdw_post,
    IIF(wbcb.measurement_concept_id IS NOT NULL,1,0) AS wbc_base,
	IIF(wbcp.measurement_concept_id IS NOT NULL,1,0) AS wbc_post,
    IIF(neutro_contb.measurement_concept_id IS NOT NULL,1,0) AS neutro_cont_base,
	IIF(neutro_contp.measurement_concept_id IS NOT NULL,1,0) AS neutro_cont_post,
    IIF(neutro_percb.measurement_concept_id IS NOT NULL,1,0) AS neutro_perc_base,
	IIF(neutro_percp.measurement_concept_id IS NOT NULL,1,0) AS neutro_perc_post,
    IIF(linfo_contb.measurement_concept_id IS NOT NULL,1,0) AS linfo_cont_base,
	IIF(linfo_contp.measurement_concept_id IS NOT NULL,1,0) AS linfo_cont_post,
    IIF(linfo_percb.measurement_concept_id IS NOT NULL,1,0) AS linfo_perc_base,
	IIF(linfo_percp.measurement_concept_id IS NOT NULL,1,0) AS linfo_perc_post,
    IIF(mono_contb.measurement_concept_id IS NOT NULL,1,0) AS mono_cont_base,
	IIF(mono_contp.measurement_concept_id IS NOT NULL,1,0) AS mono_cont_post,
    IIF(mono_percb.measurement_concept_id IS NOT NULL,1,0) AS mono_perc_base,
	IIF(mono_percp.measurement_concept_id IS NOT NULL,1,0) AS mono_perc_post,
    IIF(eosi_contb.measurement_concept_id IS NOT NULL,1,0) AS eosi_cont_base,
	IIF(eosi_contp.measurement_concept_id IS NOT NULL,1,0) AS eosi_cont_post,
    IIF(eosi_percb.measurement_concept_id IS NOT NULL,1,0) AS eosi_perc_base,
	IIF(eosi_percp.measurement_concept_id IS NOT NULL,1,0) AS eosi_perc_post,
    IIF(baso_contb.measurement_concept_id IS NOT NULL,1,0) AS baso_cont_base,
	IIF(baso_contp.measurement_concept_id IS NOT NULL,1,0) AS baso_cont_post,
    IIF(baso_percb.measurement_concept_id IS NOT NULL,1,0) AS baso_perc_base,
	IIF(baso_percp.measurement_concept_id IS NOT NULL,1,0) AS baso_perc_post,
    IIF(eritro_contb.measurement_concept_id IS NOT NULL,1,0) AS eritro_cont_base,
	IIF(eritro_contp.measurement_concept_id IS NOT NULL,1,0) AS eritro_cont_post,
    IIF(eritro_percb.measurement_concept_id IS NOT NULL,1,0) AS eritro_perc_base,
	IIF(eritro_percp.measurement_concept_id IS NOT NULL,1,0) AS eritro_perc_post,
    IIF(pdwb.measurement_concept_id IS NOT NULL,1,0) AS pdw_base,
	IIF(pdwp.measurement_concept_id IS NOT NULL,1,0) AS pdw_post,
    IIF(mpvb.measurement_concept_id IS NOT NULL,1,0) AS mpv_base,
	IIF(mpvp.measurement_concept_id IS NOT NULL,1,0) AS mpv_post,
    IIF(egab.measurement_concept_id IS NOT NULL,1,0) AS ega_base,
	IIF(egap.measurement_concept_id IS NOT NULL,1,0) AS ega_post,
    IIF(pltb.measurement_concept_id IS NOT NULL,1,0) AS plt_base,
	IIF(pltp.measurement_concept_id IS NOT NULL,1,0) AS plt_post,
    IIF(ptb.measurement_concept_id IS NOT NULL,1,0) AS pt_base,
	IIF(ptp.measurement_concept_id IS NOT NULL,1,0) AS pt_post,
    IIF(pttb.measurement_concept_id IS NOT NULL,1,0) AS ptt_base,
	IIF(pttp.measurement_concept_id IS NOT NULL,1,0) AS ptt_post,
    IIF(inrb.measurement_concept_id IS NOT NULL,1,0) AS inr_base,
	IIF(inrp.measurement_concept_id IS NOT NULL,1,0) AS inr_post,
    IIF(transaminasib.measurement_concept_id IS NOT NULL,1,0) AS transaminasi_base,
	IIF(transaminasip.measurement_concept_id IS NOT NULL,1,0) AS transaminasi_post,
    IIF(bilirubinab.measurement_concept_id IS NOT NULL,1,0) AS bilirubina_base,
	IIF(bilirubinap.measurement_concept_id IS NOT NULL,1,0) AS bilirubina_post,
    IIF(creatininab.measurement_concept_id IS NOT NULL,1,0) AS creatinina_base,
	IIF(creatininap.measurement_concept_id IS NOT NULL,1,0) AS creatinina_post,
    IIF(azotemiab.measurement_concept_id IS NOT NULL,1,0) AS azotemia_base,
	IIF(azotemiap.measurement_concept_id IS NOT NULL,1,0) AS azotemia_post,
    IIF(glicemiab.measurement_concept_id IS NOT NULL,1,0) AS glicemia_base,
	IIF(glicemiap.measurement_concept_id IS NOT NULL,1,0) AS glicemia_post,
    IIF(sodiumb.measurement_concept_id IS NOT NULL,1,0) AS sodium_base,
	IIF(sodiump.measurement_concept_id IS NOT NULL,1,0) AS sodium_post,
    IIF(chlorideb.measurement_concept_id IS NOT NULL,1,0) AS chloride_base,
	IIF(chloridep.measurement_concept_id IS NOT NULL,1,0) AS chloride_post,
    IIF(potassiumb.measurement_concept_id IS NOT NULL,1,0) AS potassium_base,
	IIF(potassiump.measurement_concept_id IS NOT NULL,1,0) AS potassium_post,
    IIF(pctb.measurement_concept_id IS NOT NULL,1,0) AS pct_base,
	IIF(pctp.measurement_concept_id IS NOT NULL,1,0) AS pct_post,
    IIF(pcrb.measurement_concept_id IS NOT NULL,1,0) AS pcr_base,
	IIF(pcrp.measurement_concept_id IS NOT NULL,1,0) AS pcr_post
INTO @results_schema.omop_sepsis_covariates_cases
FROM #ricoveri_tmp r 
LEFT JOIN #anagrafica_tmp a ON a.person_id = r.person_id
	AND a.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #reparto_tmp rep ON rep.person_id = r.person_id
	AND rep.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #emocultura emo ON emo.person_id = r.person_id
	AND emo.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #urinocultura uri ON uri.person_id = r.person_id
	AND uri.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #procedure_inv pinv ON pinv.person_id = r.person_id
	AND pinv.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #hgb_base hgbb ON hgbb.person_id = r.person_id
	AND hgbb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #hgb_post hgbp ON hgbp.person_id = r.person_id
	AND hgbp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #rbc_base rbcb ON rbcb.person_id = r.person_id
	AND rbcb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #rbc_post rbcp ON rbcp.person_id = r.person_id
	AND rbcp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #hct_base hctb ON hctb.person_id = r.person_id
	AND hctb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #hct_post hctp ON hctp.person_id = r.person_id
	AND hctp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mcv_base mcvb ON mcvb.person_id = r.person_id
	AND mcvb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mcv_post mcvp ON mcvp.person_id = r.person_id
	AND mcvp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mch_base mchb ON mchb.person_id = r.person_id
	AND mchb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mch_post mchp ON mchp.person_id = r.person_id
	AND mchp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mchc_base mchcb ON mchcb.person_id = r.person_id
	AND mchcb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mchc_post mchcp ON mchcp.person_id = r.person_id
	AND mchcp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #rdw_base rdwb ON rdwb.person_id = r.person_id
	AND rdwb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #rdw_post rdwp ON rdwp.person_id = r.person_id
	AND rdwp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #wbc_base wbcb ON wbcb.person_id = r.person_id
	AND wbcb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #wbc_post wbcp ON wbcp.person_id = r.person_id
	AND wbcp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #neutro_cont_base neutro_contb ON neutro_contb.person_id = r.person_id
	AND neutro_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #neutro_cont_post neutro_contp ON neutro_contp.person_id = r.person_id
	AND neutro_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #neutro_perc_base neutro_percb ON neutro_percb.person_id = r.person_id
	AND neutro_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #neutro_perc_post neutro_percp ON neutro_percp.person_id = r.person_id
	AND neutro_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #linfo_cont_base linfo_contb ON linfo_contb.person_id = r.person_id
	AND linfo_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #linfo_cont_post linfo_contp ON linfo_contp.person_id = r.person_id
	AND linfo_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #linfo_perc_base linfo_percb ON linfo_percb.person_id = r.person_id
	AND linfo_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #linfo_perc_post linfo_percp ON linfo_percp.person_id = r.person_id
	AND linfo_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mono_cont_base mono_contb ON mono_contb.person_id = r.person_id
	AND mono_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mono_cont_post mono_contp ON mono_contp.person_id = r.person_id
	AND mono_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mono_perc_base mono_percb ON mono_percb.person_id = r.person_id
	AND mono_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mono_perc_post mono_percp ON mono_percp.person_id = r.person_id
	AND mono_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eosi_cont_base eosi_contb ON eosi_contb.person_id = r.person_id
	AND eosi_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eosi_cont_post eosi_contp ON eosi_contp.person_id = r.person_id
	AND eosi_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eosi_perc_base eosi_percb ON eosi_percb.person_id = r.person_id
	AND eosi_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eosi_perc_post eosi_percp ON eosi_percp.person_id = r.person_id
	AND eosi_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #baso_cont_base baso_contb ON baso_contb.person_id = r.person_id
	AND baso_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #baso_cont_post baso_contp ON baso_contp.person_id = r.person_id
	AND baso_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #baso_perc_base baso_percb ON baso_percb.person_id = r.person_id
	AND baso_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #baso_perc_post baso_percp ON baso_percp.person_id = r.person_id
	AND baso_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eritro_cont_base eritro_contb ON eritro_contb.person_id = r.person_id
	AND eritro_contb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eritro_cont_post eritro_contp ON eritro_contp.person_id = r.person_id
	AND eritro_contp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eritro_perc_base eritro_percb ON eritro_percb.person_id = r.person_id
	AND eritro_percb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #eritro_perc_post eritro_percp ON eritro_percp.person_id = r.person_id
	AND eritro_percp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pdw_base pdwb ON pdwb.person_id = r.person_id
	AND pdwb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pdw_post pdwp ON pdwp.person_id = r.person_id
	AND pdwp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mpv_base mpvb ON mpvb.person_id = r.person_id
	AND mpvb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #mpv_post mpvp ON mpvp.person_id = r.person_id
	AND mpvp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #ega_base egab ON egab.person_id = r.person_id
	AND egab.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #ega_post egap ON egap.person_id = r.person_id
	AND egap.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #plt_base pltb ON pltb.person_id = r.person_id
	AND pltb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #plt_post pltp ON pltp.person_id = r.person_id
	AND pltp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pt_base ptb ON ptb.person_id = r.person_id
	AND ptb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pt_post ptp ON ptp.person_id = r.person_id
	AND ptp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #ptt_base pttb ON pttb.person_id = r.person_id
	AND pttb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #ptt_post pttp ON pttp.person_id = r.person_id
	AND pttp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #inr_base inrb ON inrb.person_id = r.person_id
	AND inrb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #inr_post inrp ON inrp.person_id = r.person_id
	AND inrp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #transaminasi_base transaminasib ON transaminasib.person_id = r.person_id
	AND transaminasib.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #transaminasi_post transaminasip ON transaminasip.person_id = r.person_id
	AND transaminasip.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #bilirubina_base bilirubinab ON bilirubinab.person_id = r.person_id
	AND bilirubinab.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #bilirubina_post bilirubinap ON bilirubinap.person_id = r.person_id
	AND bilirubinap.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #creatinina_base creatininab ON creatininab.person_id = r.person_id
	AND creatininab.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #creatinina_post creatininap ON creatininap.person_id = r.person_id
	AND creatininap.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #azotemia_base azotemiab ON azotemiab.person_id = r.person_id
	AND azotemiab.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #azotemia_post azotemiap ON azotemiap.person_id = r.person_id
	AND azotemiap.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #glicemia_base glicemiab ON glicemiab.person_id = r.person_id
	AND glicemiab.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #glicemia_post glicemiap ON glicemiap.person_id = r.person_id
	AND glicemiap.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #sodium_base sodiumb ON sodiumb.person_id = r.person_id
	AND sodiumb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #sodium_post sodiump ON sodiump.person_id = r.person_id
	AND sodiump.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #chloride_base chlorideb ON chlorideb.person_id = r.person_id
	AND chlorideb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #chloride_post chloridep ON chloridep.person_id = r.person_id
	AND chloridep.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #potassium_base potassiumb ON potassiumb.person_id = r.person_id
	AND potassiumb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #potassium_post potassiump ON potassiump.person_id = r.person_id
	AND potassiump.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pct_base pctb ON pctb.person_id = r.person_id
	AND pctb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pct_post pctp ON pctp.person_id = r.person_id
	AND pctp.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pcr_base pcrb ON pcrb.person_id = r.person_id
	AND pcrb.visit_occurrence_id = r.visit_occurrence_id
LEFT JOIN #pcr_post pcrp ON pcrp.person_id = r.person_id
	AND pcrp.visit_occurrence_id = r.visit_occurrence_id;

---------------------------------------------------------
-- Cleanup finale
---------------------------------------------------------
DROP TABLE #ricoveri_all;
DROP TABLE #ricoveri_tmp;
DROP TABLE #anagrafica_tmp;
DROP TABLE #reparto_tmp;
DROP TABLE #emocultura;
DROP TABLE #urinocultura;
DROP TABLE #procedure_inv;
DROP TABLE #hgb_base;
DROP TABLE #hgb_post;
DROP TABLE #rbc_base;
DROP TABLE #rbc_post;
DROP TABLE #hct_base;
DROP TABLE #hct_post;
DROP TABLE #mcv_base;
DROP TABLE #mcv_post;
DROP TABLE #mch_base;
DROP TABLE #mch_post;
DROP TABLE #mchc_base;
DROP TABLE #mchc_post;
DROP TABLE #rdw_base;
DROP TABLE #rdw_post;
DROP TABLE #wbc_base;
DROP TABLE #wbc_post;
DROP TABLE #neutro_cont_base;
DROP TABLE #neutro_cont_post;
DROP TABLE #neutro_perc_base;
DROP TABLE #neutro_perc_post;
DROP TABLE #linfo_cont_base;
DROP TABLE #linfo_cont_post;
DROP TABLE #linfo_perc_base;
DROP TABLE #linfo_perc_post;
DROP TABLE #mono_cont_base;
DROP TABLE #mono_cont_post;
DROP TABLE #mono_perc_base;
DROP TABLE #mono_perc_post;
DROP TABLE #eosi_cont_base;
DROP TABLE #eosi_cont_post;
DROP TABLE #eosi_perc_base;
DROP TABLE #eosi_perc_post;
DROP TABLE #baso_cont_base;
DROP TABLE #baso_cont_post;
DROP TABLE #baso_perc_base;
DROP TABLE #baso_perc_post;
DROP TABLE #eritro_cont_base;
DROP TABLE #eritro_cont_post;
DROP TABLE #eritro_perc_base;
DROP TABLE #eritro_perc_post;
DROP TABLE #pdw_base;
DROP TABLE #pdw_post;
DROP TABLE #mpv_base;
DROP TABLE #mpv_post;
DROP TABLE #ega_base;
DROP TABLE #ega_post;
DROP TABLE #plt_base;
DROP TABLE #plt_post;
DROP TABLE #pt_base;
DROP TABLE #pt_post;
DROP TABLE #ptt_base;
DROP TABLE #ptt_post;
DROP TABLE #inr_base;
DROP TABLE #inr_post;
DROP TABLE #transaminasi_base;
DROP TABLE #transaminasi_post;
DROP TABLE #bilirubina_base;
DROP TABLE #bilirubina_post;
DROP TABLE #creatinina_base;
DROP TABLE #creatinina_post;
DROP TABLE #azotemia_base;
DROP TABLE #azotemia_post;
DROP TABLE #glicemia_base;
DROP TABLE #glicemia_post;
DROP TABLE #sodium_base;
DROP TABLE #sodium_post;
DROP TABLE #chloride_base;
DROP TABLE #chloride_post;
DROP TABLE #potassium_base;
DROP TABLE #potassium_post;
DROP TABLE #pct_base;
DROP TABLE #pct_post;
DROP TABLE #pcr_base;
DROP TABLE #pcr_post;

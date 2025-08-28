IF OBJECT_ID('@results_schema.omop_sepsis_covariates_cases', 'U') IS NOT NULL DROP TABLE @results_schema.omop_sepsis_covariates_cases;

WITH --- Ricoveri con sepsi
ricoveri_all AS (
	SELECT
		vo.visit_occurrence_id,
		vo.person_id,
		vo.visit_concept_id,
		vo.visit_start_date,
		vo.visit_end_date,
		vo.admitted_from_concept_id,
		c.cohort_start_date,
		vo.visit_end_date - vo.visit_start_date AS visit_length
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
		AND c.cohort_definition_id = @cohort_id_ricoveri
),
ricoveri AS (
	SELECT ricoveri_all.*
	FROM @results_schema.@cohort_table c2 
	INNER JOIN ricoveri_all ON c2.subject_id = ricoveri_all.person_id 
	AND c2.cohort_start_date >= ricoveri_all.visit_start_date 
	AND c2.cohort_start_date <= ricoveri_all.visit_end_date 
	WHERE c2.cohort_definition_id = @cohort_id_sepsi
),
--- Anagrafica
anagrafica AS (
	SELECT
		ricoveri.visit_occurrence_id,
		ricoveri.person_id,
		p.gender_concept_id,
		DATEPART(YEAR, ricoveri.visit_start_date) - p.year_of_birth AS age
	FROM
		ricoveri
		LEFT JOIN @cdm_schema.person p ON ricoveri.person_id = p.person_id
),
--- Reparto ricovero
reparto AS (
	SELECT
		*
	FROM
		(
			SELECT
				vd.visit_detail_id,
				vd.person_id,
				vd.visit_detail_concept_id,
				vd.visit_detail_start_date,
				vd.care_site_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY vd.visit_occurrence_id
					ORDER BY
						vd.visit_detail_start_date
				) AS rank
			FROM
				@cdm_schema.visit_detail vd
				JOIN ricoveri ON vd.visit_occurrence_id = ricoveri.visit_occurrence_id
		) AS all_visit_detail
	WHERE
		all_visit_detail.rank = 1
),
--- Emocultura
emocultura AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date >= ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
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
		all_emo.rank = 1
),
--- Urinocultura
urinocultura AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date >= ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
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
		all_uro.rank = 1
),
--- Procedure invasive
procedure_inv AS (
	SELECT
		*
	FROM
		(
			SELECT
				po.procedure_occurrence_id,
				po.person_id,
				po.procedure_concept_id,
				po.procedure_date,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						po.procedure_date DESC
				) AS rank
			FROM
				@cdm_schema.procedure_occurrence po
				JOIN ricoveri ON po.person_id = ricoveri.person_id
				AND po.procedure_date >= ricoveri.visit_start_date
				AND po.procedure_date <= ricoveri.visit_end_date
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
		all_procedure.rank = 1
),
--- HGB (Emoglobina) baseline
hgb_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
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
		all_hgb_base.rank = 1
),
--- HGB (Emoglobina) 72h
hgb_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
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
		) AS all_hgb_post
	WHERE
		all_hgb_post.rank = 1
),
--- RBC (Eritrociti) baseline
rbc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4030871) -- Red blood cell count
		) AS all_rbc_base
	WHERE
		all_rbc_base.rank = 1
),
--- RBC (Eritrociti) 72h
rbc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4030871) -- Red blood cell count
		) AS all_rbc_post
	WHERE
		all_rbc_post.rank = 1
),
--- HCT (Ematocrito) baseline
hct_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4151358) -- Hematocrit determination
		) AS all_hct_base
	WHERE
		all_hct_base.rank = 1
),
--- HCT (Ematocrito) 72h
hct_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4151358) -- Hematocrit determination
		) AS all_hct_post
	WHERE
		all_hct_post.rank = 1
),
--- MCV (Volume Corpuscolare Medio) baseline
mcv_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4016239) -- Erythrocyte mean corpuscular volume determination
		) AS all_mcv_base
	WHERE
		all_mcv_base.rank = 1
),
--- MCV (Volume Corpuscolare Medio) 72h
mcv_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4016239) -- Erythrocyte mean corpuscular volume determination
		) AS all_mcv_post
	WHERE
		all_mcv_post.rank = 1
),
--- MCH (Contenuto HGB medio) baseline
mch_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4182871) -- Mean corpuscular hemoglobin determination
		) AS all_mch_base
	WHERE
		all_mch_base.rank = 1
),
--- MCH (Contenuto HGB medio) 72h
mch_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4182871) -- Mean corpuscular hemoglobin determination
		) AS all_mch_post
	WHERE
		all_mch_post.rank = 1
),
--- MCHC (Conc. HGB Globulare Media) baseline
mchc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4290193) -- Mean corpuscular hemoglobin concentration determination
		) AS all_mchc_base
	WHERE
		all_mchc_base.rank = 1
),
--- MCHC (Conc. HGB Globulare Media) 72h
mchc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4290193) -- Mean corpuscular hemoglobin concentration determination
		) AS all_mchc_post
	WHERE
		all_mchc_post.rank = 1
),
--- RDW baseline
rdw_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4281085) -- Red cell distribution width determination
		) AS all_rdw_base
	WHERE
		all_rdw_base.rank = 1
),
--- RDW 72h
rdw_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4281085) -- Red cell distribution width determination
		) AS all_rdw_post
	WHERE
		all_rdw_post.rank = 1
),
--- WBC (Leucociti) baseline
wbc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4298431) -- White blood cell count
		) AS all_wbc_base
	WHERE
		all_wbc_base.rank = 1
),
--- WBC (Leucociti) 72h
wbc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4298431) -- White blood cell count
		) AS all_wbc_post
	WHERE
		all_wbc_post.rank = 1
),
--- Neutrofili (valore assoluto) baseline
neutro_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4148615) -- Neutrophil count
		) AS all_neutro_cont_base
	WHERE
		all_neutro_cont_base.rank = 1
),
--- Neutrofili (valore assoluto) 72h
neutro_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4148615) -- Neutrophil count
		) AS all_neutro_cont_post
	WHERE
		all_neutro_cont_post.rank = 1
),
--- Neutrofili (percentuale) baseline
neutro_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (3018010) -- Neutrophils/100 leukocytes in Blood
		) AS all_neutro_perc_base
	WHERE
		all_neutro_perc_base.rank = 1
),
--- Neutrofili (percentuale) 72h
neutro_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (3018010) -- Neutrophils/100 leukocytes in Blood
		) AS all_neutro_perc_post
	WHERE
		all_neutro_perc_post.rank = 1
),
--- Linfociti (valore assoluto) baseline
linfo_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4148615) -- Lymphocyte count
		) AS all_linfo_cont_base
	WHERE
		all_linfo_cont_base.rank = 1
),
--- Linfociti (valore assoluto) 72h
linfo_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4148615) -- Lymphocyte count
		) AS all_linfo_cont_post
	WHERE
		all_linfo_cont_post.rank = 1
),
--- Linfociti (percentuale) baseline
linfo_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (3002030) -- Lymphocytes/100 leukocytes in Blood
		) AS all_linfo_perc_base
	WHERE
		all_linfo_perc_base.rank = 1
),
--- Linfociti (percentuale) 72h
linfo_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (3002030) -- Lymphocytes/100 leukocytes in Blood
		) AS all_linfo_perc_post
	WHERE
		all_linfo_perc_post.rank = 1
),
--- Monociti (valore assoluto) baseline
mono_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4194332) -- Monocyte count
		) AS all_mono_cont_base
	WHERE
		all_mono_cont_base.rank = 1
),
--- Monociti (valore assoluto) 72h
mono_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4194332) -- Monocyte count
		) AS all_mono_cont_post
	WHERE
		all_mono_cont_post.rank = 1
),
--- Monociti (percentuale) baseline
mono_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (3019069) -- Monocytes/100 leukocytes in Blood
		) AS all_mono_perc_base
	WHERE
		all_mono_perc_base.rank = 1
),
--- Monociti (percentuale) 72h
mono_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (3019069) -- Monocytes/100 leukocytes in Blood
		) AS all_mono_perc_post
	WHERE
		all_mono_perc_post.rank = 1
),
--- Eosinofili (valore assoluto) baseline
eosi_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4216098) -- Eosinophil count
		) AS all_eosi_cont_base
	WHERE
		all_eosi_cont_base.rank = 1
),
--- Eosinofili (valore assoluto) 72h
eosi_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4216098) -- Eosinophil count
		) AS all_eosi_cont_post
	WHERE
		all_eosi_cont_post.rank = 1
),
--- Eosinofili (percentuale) baseline
eosi_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (3006504) -- Eosinophils/100 leukocytes in Blood
		) AS all_eosi_perc_base
	WHERE
		all_eosi_perc_base.rank = 1
),
--- Eosinofili (percentuale) 72h
eosi_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (3006504) -- Eosinophils/100 leukocytes in Blood
		) AS all_eosi_perc_post
	WHERE
		all_eosi_perc_post.rank = 1
),
--- Basofili (valore assoluto) baseline
baso_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4172647) -- Basophil count
		) AS all_baso_cont_base
	WHERE
		all_baso_cont_base.rank = 1
),
--- Basofili (valore assoluto) 72h
baso_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4172647) -- Basophil count
		) AS all_baso_cont_post
	WHERE
		all_baso_cont_post.rank = 1
),
--- Basofili (percentuale) baseline
baso_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (3022096) -- Basophils/100 leukocytes in Blood
		) AS all_baso_perc_base
	WHERE
		all_baso_perc_base.rank = 1
),
--- Basofili (percentuale) 72h
baso_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (3022096) -- Basophils/100 leukocytes in Blood
		) AS all_baso_perc_post
	WHERE
		all_baso_perc_post.rank = 1
),
--- Eritroblasti (valore assoluto) baseline
eritro_cont_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
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
		all_eritro_cont_base.rank = 1
),
--- Eritroblasti (valore assoluto) 72h
eritro_cont_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				(
					(m.measurement_concept_id = 3021589) -- Normoblasts [#/volume] in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8848, 8815) -- 10*3/uL, 10*6/uL
					)
				)
		) AS all_eritro_cont_post
	WHERE
		all_eritro_cont_post.rank = 1
),
--- Eritroblasti (percentuale) baseline
eritro_perc_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
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
		all_eritro_perc_base.rank = 1
),
--- Eritroblasti (percentuale) 72h
eritro_perc_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				(
					(m.measurement_concept_id = 3046588) -- Normoblasts/100 blasts in Blood
					OR (
						m.measurement_concept_id = 4012826 -- Nucleated red blood cell count procedure
						AND m.unit_concept_id IN (8554) -- %
					)
				)
		) AS all_eritro_perc_post
	WHERE
		all_eritro_perc_post.rank = 1
),
--- PDW (Anisocitosi PLT) baseline
pdw_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4097620, 3040227) -- Platelet distribution width measurement
		) AS all_pdw_base
	WHERE
		all_pdw_base.rank = 1
),
--- PDW (Anisocitosi PLT) 72h
pdw_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4097620, 3040227) -- Platelet distribution width measurement
		) AS all_pdw_post
	WHERE
		all_pdw_post.rank = 1
),
--- MPV (Volume Piastrinico Medio) baseline
mpv_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4192368) -- Platelet mean volume determination
		) AS all_mpv_base
	WHERE
		all_mpv_base.rank = 1
),
--- MPV (Volume Piastrinico Medio) 72h
mpv_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4192368) -- Platelet mean volume determination
		) AS all_mpv_post
	WHERE
		all_mpv_post.rank = 1
),
--- EGA-EAB con lattati baseline
ega_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
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
		all_ega_base.rank = 1
),
--- EGA-EAB con lattati 72h
ega_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
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
		) AS all_ega_post
	WHERE
		all_ega_post.rank = 1
),
--- Piastrine baseline
piastrine_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4267147) -- Platelet count
		) AS all_plt_base
	WHERE
		all_plt_base.rank = 1
),
--- Piastrine 72h
piastrine_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4267147) -- Platelet count
		) AS all_plt_post
	WHERE
		all_plt_post.rank = 1
),
--- PT baseline
pt_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4245261) -- Prothrombin time
		) AS all_pt_base
	WHERE
		all_pt_base.rank = 1
),
--- PT 72h
pt_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4245261) -- Prothrombin time
		) AS all_pt_post
	WHERE
		all_pt_post.rank = 1
),
--- PTT baseline
ptt_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (2212742) -- Thromboplastin time, partial (PTT); plasma or whole blood 
		) AS all_ptt_base
	WHERE
		all_ptt_base.rank = 1
),
--- PTT 72h
ptt_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (2212742) -- Thromboplastin time, partial (PTT); plasma or whole blood 
		) AS all_ptt_post
	WHERE
		all_ptt_post.rank = 1
),
--- INR baseline
inr_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4306239, 46285118) -- International normalized ratio 
		) AS all_inr_base
	WHERE
		all_inr_base.rank = 1
),
--- INR 72h
inr_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4306239, 46285118) -- International normalized ratio
		) AS all_inr_post
	WHERE
		all_inr_post.rank = 1
),
--- Transaminasi baseline
transaminasi_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
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
		all_transaminasi_base.rank = 1
),
--- Transaminasi 72h
transaminasi_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
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
		) AS all_transaminasi_post
	WHERE
		all_transaminasi_post.rank = 1
),
--- Bilirubina baseline
bilirubina_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4118986) -- Bilirubin measurement
		) AS all_bilirubina_base
	WHERE
		all_bilirubina_base.rank = 1
),
--- Bilirubina 72h
bilirubina_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4118986) -- Bilirubin measurement
		) AS all_bilirubina_post
	WHERE
		all_bilirubina_post.rank = 1
),
--- Creatinina baseline
creatinina_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4324383) -- Creatinine measurement
		) AS all_creatinina_base
	WHERE
		all_creatinina_base.rank = 1
),
--- Creatinina 72h
creatinina_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4324383) -- Creatinine measurement
		) AS all_creatinina_post
	WHERE
		all_creatinina_post.rank = 1
),
--- Azotemia baseline
azotemia_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4020121, 4094594) -- Urea measurement
		) AS all_azotemia_base
	WHERE
		all_azotemia_base.rank = 1
),
--- Azotemia 72h
azotemia_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4020121, 4094594) -- Urea measurement
		) AS all_azotemia_post
	WHERE
		all_azotemia_post.rank = 1
),
--- Glicemia baseline
glicemia_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4202143, 4149519, 4144235) -- Blood glucose concentration
		) AS all_glicemia_base
	WHERE
		all_glicemia_base.rank = 1
),
--- Glicemia 72h
glicemia_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4202143, 4149519, 4144235) -- Blood glucose concentration
		) AS all_glicemia_post
	WHERE
		all_glicemia_post.rank = 1
),
--- Sodio (Na) baseline
sodium_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4208938) -- Sodium measurement, blood
		) AS all_sodium_base
	WHERE
		all_sodium_base.rank = 1
),
--- Sodio (Na) 72h
sodium_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4208938) -- Sodium measurement, blood
		) AS all_sodium_post
	WHERE
		all_sodium_post.rank = 1
),
--- Cloro (Cl) baseline
chloride_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4019545, 4008116) -- Chloride measurement, blood
		) AS all_chloride_base
	WHERE
		all_chloride_base.rank = 1
),
--- Cloro (Cl) 72h
chloride_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4019545, 4008116) -- Chloride measurement, blood
		) AS all_chloride_post
	WHERE
		all_chloride_post.rank = 1
),
--- Potassio (K) baseline
potassium_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4207483) -- Blood potassium measurement
		) AS all_potassium_base
	WHERE
		all_potassium_base.rank = 1
),
--- Potassio (K) 72h
potassium_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4207483) -- Blood potassium measurement
		) AS all_potassium_post
	WHERE
		all_potassium_post.rank = 1
),
--- PCT baseline
pct_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (44791466) -- Procalcitonin measurement
		) AS all_pct_base
	WHERE
		all_pct_base.rank = 1
),
--- PCT 72h
pct_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (44791466) -- Procalcitonin measurement
		) AS all_pct_post
	WHERE
		all_pct_post.rank = 1
),
--- PCR baseline
pcr_base AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE
				m.measurement_concept_id IN (4208414) -- C-reactive protein measurement
		) AS all_pcr_base
	WHERE
		all_pcr_base.rank = 1
),
--- PCR 72h
pcr_post AS (
	SELECT
		*
	FROM
		(
			SELECT
				m.measurement_id,
				m.person_id,
				m.measurement_concept_id,
				m.measurement_date,
				m.value_as_number,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (
					PARTITION BY ricoveri.visit_occurrence_id
					ORDER BY
						m.measurement_date DESC
				) AS rank
			FROM
				@cdm_schema.measurement m
				JOIN ricoveri ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE
				m.measurement_concept_id IN (4208414) -- C-reactive protein measurement
		) AS all_pcr_post
	WHERE
		all_pcr_post.rank = 1
)
SELECT
	ricoveri.visit_occurrence_id,
	ricoveri.person_id,
	ricoveri.visit_start_date,
	ricoveri.visit_end_date,
	ricoveri.admitted_from_concept_id AS provenienza,
	anagrafica.gender_concept_id AS sex,
	anagrafica.age AS age,
	reparto.care_site_id AS reparto_ricovero,
	IIF(
		emocultura.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS emocultura,
	IIF(
		urinocultura.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS urinocultura,
	IIF(
		procedure_inv.procedure_concept_id IS NOT NULL,
		1,
		0
	) AS procedure_invasive,
	IIF(
		hgb_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS hgb_base,
	IIF(
		hgb_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS hgb_post,
	IIF(
		rbc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS rbc_base,
	IIF(
		rbc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS rbc_post,
	IIF(
		hct_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS hct_base,
	IIF(
		hct_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS hct_post,
	IIF(
		mcv_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mcv_base,
	IIF(
		mcv_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mcv_post,
	IIF(
		mch_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mch_base,
	IIF(
		mch_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mch_post,
	IIF(
		mchc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mchc_base,
	IIF(
		mchc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mchc_post,
	IIF(
		rdw_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS rdw_base,
	IIF(
		rdw_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS rdw_post,
	IIF(
		wbc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS wbc_base,
	IIF(
		wbc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS wbc_post,
	IIF(
		neutro_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS neutro_cont_base,
	IIF(
		neutro_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS neutro_cont_post,
	IIF(
		neutro_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS neutro_perc_base,
	IIF(
		neutro_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS neutro_perc_post,
	IIF(
		linfo_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS linfo_cont_base,
	IIF(
		linfo_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS linfo_cont_post,
	IIF(
		linfo_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS linfo_perc_base,
	IIF(
		linfo_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS linfo_perc_post,
	IIF(
		mono_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mono_cont_base,
	IIF(
		mono_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mono_cont_post,
	IIF(
		mono_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mono_perc_base,
	IIF(
		mono_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mono_perc_post,
	IIF(
		eosi_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eosi_cont_base,
	IIF(
		eosi_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eosi_cont_post,
	IIF(
		eosi_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eosi_perc_base,
	IIF(
		eosi_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eosi_perc_post,
	IIF(
		baso_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS baso_cont_base,
	IIF(
		baso_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS baso_cont_post,
	IIF(
		baso_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS baso_perc_base,
	IIF(
		baso_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS baso_perc_post,
	IIF(
		eritro_cont_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eritro_cont_base,
	IIF(
		eritro_cont_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eritro_cont_post,
	IIF(
		eritro_perc_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eritro_perc_base,
	IIF(
		eritro_perc_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS eritro_perc_post,
	IIF(
		pdw_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pdw_base,
	IIF(
		pdw_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pdw_post,
	IIF(
		mpv_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mpv_base,
	IIF(
		mpv_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS mpv_post,
	IIF(
		ega_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS ega_base,
	IIF(
		ega_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS ega_post,
	IIF(
		piastrine_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS plt_base,
	IIF(
		piastrine_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS plt_post,
	IIF(pt_base.measurement_concept_id IS NOT NULL, 1, 0) AS pt_base,
	IIF(pt_post.measurement_concept_id IS NOT NULL, 1, 0) AS pt_post,
	IIF(
		ptt_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS ptt_base,
	IIF(
		ptt_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS ptt_post,
	IIF(
		inr_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS inr_base,
	IIF(
		inr_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS inr_post,
	IIF(
		transaminasi_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS transaminasi_base,
	IIF(
		transaminasi_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS transaminasi_post,
	IIF(
		bilirubina_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS bilirubina_base,
	IIF(
		bilirubina_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS bilirubina_post,
	IIF(
		creatinina_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS creatinina_base,
	IIF(
		creatinina_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS creatinina_post,
	IIF(
		azotemia_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS azotemia_base,
	IIF(
		azotemia_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS azotemia_post,
	IIF(
		glicemia_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS glicemia_base,
	IIF(
		glicemia_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS glicemia_post,
	IIF(
		sodium_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS sodium_base,
	IIF(
		sodium_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS sodium_post,
	IIF(
		chloride_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS chloride_base,
	IIF(
		chloride_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS chloride_post,
	IIF(
		potassium_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS potassium_base,
	IIF(
		potassium_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS potassium_post,
	IIF(
		pct_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pct_base,
	IIF(
		pct_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pct_post,
	IIF(
		pcr_base.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pcr_base,
	IIF(
		pcr_post.measurement_concept_id IS NOT NULL,
		1,
		0
	) AS pcr_post INTO @results_schema.omop_sepsis_covariates_cases
FROM
	ricoveri
	LEFT JOIN anagrafica ON anagrafica.person_id = ricoveri.person_id
	AND anagrafica.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN reparto ON reparto.person_id = ricoveri.person_id
	AND reparto.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN emocultura ON emocultura.person_id = ricoveri.person_id
	AND emocultura.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN urinocultura ON urinocultura.person_id = ricoveri.person_id
	AND urinocultura.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN procedure_inv ON procedure_inv.person_id = ricoveri.person_id
	AND procedure_inv.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN hgb_base ON hgb_base.person_id = ricoveri.person_id
	AND hgb_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN hgb_post ON hgb_post.person_id = ricoveri.person_id
	AND hgb_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN rbc_base ON rbc_base.person_id = ricoveri.person_id
	AND rbc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN rbc_post ON rbc_post.person_id = ricoveri.person_id
	AND rbc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN hct_base ON hct_base.person_id = ricoveri.person_id
	AND hct_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN hct_post ON hct_post.person_id = ricoveri.person_id
	AND hct_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mcv_base ON mcv_base.person_id = ricoveri.person_id
	AND mcv_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mcv_post ON mcv_post.person_id = ricoveri.person_id
	AND mcv_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mch_base ON mch_base.person_id = ricoveri.person_id
	AND mch_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mch_post ON mch_post.person_id = ricoveri.person_id
	AND mch_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mchc_base ON mchc_base.person_id = ricoveri.person_id
	AND mchc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mchc_post ON mchc_post.person_id = ricoveri.person_id
	AND mchc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN rdw_base ON rdw_base.person_id = ricoveri.person_id
	AND rdw_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN rdw_post ON rdw_post.person_id = ricoveri.person_id
	AND rdw_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN wbc_base ON wbc_base.person_id = ricoveri.person_id
	AND wbc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN wbc_post ON wbc_post.person_id = ricoveri.person_id
	AND wbc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN neutro_cont_base ON neutro_cont_base.person_id = ricoveri.person_id
	AND neutro_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN neutro_cont_post ON neutro_cont_post.person_id = ricoveri.person_id
	AND neutro_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN neutro_perc_base ON neutro_perc_base.person_id = ricoveri.person_id
	AND neutro_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN neutro_perc_post ON neutro_perc_post.person_id = ricoveri.person_id
	AND neutro_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN linfo_cont_base ON linfo_cont_base.person_id = ricoveri.person_id
	AND linfo_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN linfo_cont_post ON linfo_cont_post.person_id = ricoveri.person_id
	AND linfo_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN linfo_perc_base ON linfo_perc_base.person_id = ricoveri.person_id
	AND linfo_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN linfo_perc_post ON linfo_perc_post.person_id = ricoveri.person_id
	AND linfo_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mono_cont_base ON mono_cont_base.person_id = ricoveri.person_id
	AND mono_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mono_cont_post ON mono_cont_post.person_id = ricoveri.person_id
	AND mono_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mono_perc_base ON mono_perc_base.person_id = ricoveri.person_id
	AND mono_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mono_perc_post ON mono_perc_post.person_id = ricoveri.person_id
	AND mono_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eosi_cont_base ON eosi_cont_base.person_id = ricoveri.person_id
	AND eosi_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eosi_cont_post ON eosi_cont_post.person_id = ricoveri.person_id
	AND eosi_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eosi_perc_base ON eosi_perc_base.person_id = ricoveri.person_id
	AND eosi_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eosi_perc_post ON eosi_perc_post.person_id = ricoveri.person_id
	AND eosi_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN baso_cont_base ON baso_cont_base.person_id = ricoveri.person_id
	AND baso_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN baso_cont_post ON baso_cont_post.person_id = ricoveri.person_id
	AND baso_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN baso_perc_base ON baso_perc_base.person_id = ricoveri.person_id
	AND baso_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN baso_perc_post ON baso_perc_post.person_id = ricoveri.person_id
	AND baso_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eritro_cont_base ON eritro_cont_base.person_id = ricoveri.person_id
	AND eritro_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eritro_cont_post ON eritro_cont_post.person_id = ricoveri.person_id
	AND eritro_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eritro_perc_base ON eritro_perc_base.person_id = ricoveri.person_id
	AND eritro_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN eritro_perc_post ON eritro_perc_post.person_id = ricoveri.person_id
	AND eritro_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pdw_base ON pdw_base.person_id = ricoveri.person_id
	AND pdw_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pdw_post ON pdw_post.person_id = ricoveri.person_id
	AND pdw_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mpv_base ON mpv_base.person_id = ricoveri.person_id
	AND mpv_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN mpv_post ON mpv_post.person_id = ricoveri.person_id
	AND mpv_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN ega_base ON ega_base.person_id = ricoveri.person_id
	AND ega_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN ega_post ON ega_post.person_id = ricoveri.person_id
	AND ega_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN piastrine_base ON piastrine_base.person_id = ricoveri.person_id
	AND piastrine_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN piastrine_post ON piastrine_post.person_id = ricoveri.person_id
	AND piastrine_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pt_base ON pt_base.person_id = ricoveri.person_id
	AND pt_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pt_post ON pt_post.person_id = ricoveri.person_id
	AND pt_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN ptt_base ON ptt_base.person_id = ricoveri.person_id
	AND ptt_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN ptt_post ON ptt_post.person_id = ricoveri.person_id
	AND ptt_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN inr_base ON inr_base.person_id = ricoveri.person_id
	AND inr_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN inr_post ON inr_post.person_id = ricoveri.person_id
	AND inr_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN transaminasi_base ON transaminasi_base.person_id = ricoveri.person_id
	AND transaminasi_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN transaminasi_post ON transaminasi_post.person_id = ricoveri.person_id
	AND transaminasi_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN bilirubina_base ON bilirubina_base.person_id = ricoveri.person_id
	AND bilirubina_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN bilirubina_post ON bilirubina_post.person_id = ricoveri.person_id
	AND bilirubina_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN creatinina_base ON creatinina_base.person_id = ricoveri.person_id
	AND creatinina_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN creatinina_post ON creatinina_post.person_id = ricoveri.person_id
	AND creatinina_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN azotemia_base ON azotemia_base.person_id = ricoveri.person_id
	AND azotemia_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN azotemia_post ON azotemia_post.person_id = ricoveri.person_id
	AND azotemia_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN glicemia_base ON glicemia_base.person_id = ricoveri.person_id
	AND glicemia_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN glicemia_post ON glicemia_post.person_id = ricoveri.person_id
	AND glicemia_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN sodium_base ON sodium_base.person_id = ricoveri.person_id
	AND sodium_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN sodium_post ON sodium_post.person_id = ricoveri.person_id
	AND sodium_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN chloride_base ON chloride_base.person_id = ricoveri.person_id
	AND chloride_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN chloride_post ON chloride_post.person_id = ricoveri.person_id
	AND chloride_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN potassium_base ON potassium_base.person_id = ricoveri.person_id
	AND potassium_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN potassium_post ON potassium_post.person_id = ricoveri.person_id
	AND potassium_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pct_base ON pct_base.person_id = ricoveri.person_id
	AND pct_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pct_post ON pct_post.person_id = ricoveri.person_id
	AND pct_post.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pcr_base ON pcr_base.person_id = ricoveri.person_id
	AND pcr_base.visit_occurrence_id = ricoveri.visit_occurrence_id
	LEFT JOIN pcr_post ON pcr_post.person_id = ricoveri.person_id
	AND pcr_post.visit_occurrence_id = ricoveri.visit_occurrence_id
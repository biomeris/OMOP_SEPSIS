IF OBJECT_ID('@results_schema.omop_sepsis_covariates', 'U') IS NOT NULL DROP TABLE @results_schema.omop_sepsis_covariates;
WITH 
	--- Ricoveri
	ricoveri AS (
		SELECT 
			vo.visit_occurrence_id ,
			vo.person_id ,
			vo.visit_concept_id , 
			vo.visit_start_date ,
			vo.visit_end_date ,
			vo.admitted_from_concept_id, 
			c.cohort_start_date ,
			vo.visit_end_date - vo.visit_start_date AS visit_length
		FROM 
			@cdm_schema.visit_occurrence vo 
		JOIN
			@results_schema.@cohort_table c 
			ON c.subject_id = vo.person_id 
			AND c.cohort_start_date = vo.visit_start_date 
		WHERE 
			vo.visit_concept_id IN (9201,262) 
			AND (vo.visit_end_date - vo.visit_start_date) > 1
			{@cohort_id != -1} ? {AND c.cohort_definition_id = @cohort_id}
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
		LEFT JOIN 
			@cdm_schema.person p 
			ON ricoveri.person_id = p.person_id
	),
	--- Reparto ricovero
	reparto AS (
		SELECT 
			*
		FROM
			(SELECT 
				vd.visit_detail_id ,
				vd.person_id,
				vd.visit_detail_concept_id ,
				vd.visit_detail_start_date ,
				vd.care_site_id ,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY vd.visit_occurrence_id ORDER BY vd.visit_detail_start_date) AS rank
			FROM 
				@cdm_schema.visit_detail vd 
			JOIN
				ricoveri
				ON vd.visit_occurrence_id = ricoveri.visit_occurrence_id
			) AS all_visit_detail
		WHERE 
			all_visit_detail.rank = 1
	),
	--- Emocultura
	emocultura AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_concept_id , 
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date >= ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (
					SELECT 
                        c.concept_id
                    FROM 
                        @vocabulary_schema.concept c
                    JOIN 
                        @vocabulary_schema.concept_ancestor ca 
                        ON c.concept_id = ca.descendant_concept_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_concept_id , 
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date >= ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (
					SELECT 
                        c.concept_id
                    FROM 
                        @vocabulary_schema.concept c
                    JOIN 
                        @vocabulary_schema.concept_ancestor ca 
                        ON c.concept_id = ca.descendant_concept_id
                        AND ca.ancestor_concept_id IN (4024509) -- Urine culture
                        AND c.invalid_reason IS NULL
						AND c.domain_id = 'Measurement'
				)
			) AS all_uro
		WHERE 
			all_uro.rank = 1
	),
	--- Lista procedure invasive
	proc_inv_icd9 AS (
		SELECT 
			*
		FROM 
			@vocabulary_schema.concept c 
		WHERE 
			c.vocabulary_id = 'ICD9Proc' 
			AND c.concept_class_id IN ('3-dig billing code', '4-dig billing code')
			AND c.concept_code IN ('00.50','00.51','00.52','00.53','00.54','00.56','00.57','00.61','00.62','00.66','00.70','00.71','00.72','00.73','00.80','00.81','00.82','00.83','00.84','00.85','00.86','00.87','01.21','01.22','01.23','01.24','01.25','01.28','01.31','01.32','01.39','01.41','01.42','01.51','01.52','01.53','01.59','01.6','02.01','02.02','02.03','02.04','02.05','02.06','02.07','02.11','02.12','02.13','02.14','02.2','02.31','02.32','02.33','02.34','02.35','02.39','02.42','02.43','02.91','02.92','02.93','02.94','02.99','03.01','03.02','03.09','03.1','03.21','03.29','03.4','03.51','03.52','03.53','03.59','03.6','03.71','03.72','03.79','03.93','03.94','03.97','03.98','03.99','04.01','04.02','04.03','04.04','04.05','04.06','04.07','04.3','04.41','04.42','04.43','04.44','04.49','04.5','04.6','04.71','04.72','04.73','04.74','04.75','04.76','04.79','04.91','04.92','04.93','04.99','05.0','05.21','05.22','05.23','05.24','05.25','05.29','05.81','05.89','05.9','06.02','06.09','06.2','06.31','06.39','06.4','06.50','06.51','06.52','06.6','06.7','06.81','06.89','06.91','06.92','06.93','06.94','06.95','06.98','06.99','07.00','07.01','07.02','07.21','07.22','07.29','07.3','07.41','07.42','07.43','07.44','07.45','07.49','07.51','07.52','07.53','07.54','07.59','07.61','07.62','07.63','07.64','07.65','07.68','07.69','07.71','07.72','07.79','07.80','07.81','07.82','07.91','07.92','07.93','07.94','07.99','08.20','08.21','08.22','08.23','08.24','08.25','08.31','08.32','08.33','08.34','08.35','08.36','08.37','08.38','08.41','08.42','08.43','08.44','08.49','08.51','08.52','08.59','08.61','08.62','08.63','08.64','08.69','08.70','08.71','08.72','08.73','08.74','08.91','08.92','08.93','08.99','09.0','09.20','09.21','09.22','09.23','09.3','09.41','09.42','09.43','09.44','09.49','09.51','09.52','09.53','09.59','09.6','09.71','09.72','09.73','09.81','09.82','09.83','09.91','09.99','10.0','10.1','10.31','10.32','10.33','10.41','10.42','10.43','10.44','10.49','10.5','10.6','10.91','10.99','11.0','11.1','11.31','11.32','11.39','11.41','11.42','11.43','11.49','11.51','11.52','11.53','11.59','11.60','11.61','11.62','11.63','11.64','11.69','11.71','11.72','11.73','11.74','11.75','11.76','11.79','11.91','11.92','11.99','12.00','12.01','12.02','12.11','12.12','12.13','12.14','12.31','12.32','12.33','12.34','12.35','12.39','12.40','12.41','12.42','12.43','12.44','12.51','12.52','12.53','12.54','12.55','12.59','12.61','12.62','12.63','12.64','12.65','12.66','12.69','12.71','12.72','12.73','12.74','12.79','12.81','12.82','12.83','12.84','12.85','12.86','12.87','12.88','12.89','12.91','12.92','12.93','12.97','12.98','12.99','13.00','13.01','13.02','13.11','13.19','13.2','13.3','13.41','13.42','13.43','13.51','13.59','13.64','13.65','13.66','13.69','13.70','13.71','13.72','13.8','13.90','13.91','14.00','14.01','14.02','14.21','14.22','14.26','14.27','14.29','14.31','14.32','14.39','14.41','14.49','14.51','14.52','14.53','14.54','14.55','14.59','14.6','14.71','14.72','14.73','14.74','14.75','14.79','14.9','15.11','15.12','15.13','15.19','15.21','15.22','15.29','15.3','15.4','15.5','15.6','15.7','15.9','16.01','16.02','16.09','16.1','16.31','16.39','16.41','16.42','16.49','16.51','16.52','16.59','16.61','16.62','16.63','16.64','16.65','16.66','16.69','16.71','16.72','16.81','16.82','16.89','16.92','16.93','16.98','16.99','18.21','18.31','18.39','18.5','18.6','18.71','18.72','18.79','18.9','19.0','19.11','19.19','19.21','19.29','19.3','19.4','19.52','19.53','19.54','19.55','19.6','19.9','20.01','20.21','20.22','20.23','20.41','20.42','20.49','20.51','20.59','20.61','20.62','20.71','20.72','20.79','20.91','20.92','20.93','20.95','20.96','20.97','20.98','20.99','21.04','21.05','21.06','21.07','21.09','21.4','21.5','21.61','21.62','21.69','21.72','21.82','21.83','21.84','21.85','21.86','21.87','21.88','21.89','21.99','22.31','22.39','22.41','22.42','22.50','22.51','22.52','22.53','22.60','22.61','22.62','22.63','22.64','22.71','22.79','22.9','24.2','24.4','24.5','25.1','25.2','25.3','25.4','25.59','25.94','25.99','26.21','26.29','26.30','26.31','26.32','26.41','26.42','26.49','26.99','27.0','27.1','27.31','27.32','27.42','27.43','27.49','27.53','27.54','27.55','27.56','27.57','27.59','27.61','27.62','27.63','27.69','27.71','27.72','27.73','27.79','27.92','27.99','28.0','28.2','28.3','28.4','28.5','28.6','28.7','28.91','28.92','28.99','29.0','29.2','29.31','29.32','29.33','29.39','29.4','29.51','29.52','29.53','29.54','29.59','29.92','29.99','30.01','30.09','30.1','30.21','30.22','30.29','30.3','30.4','31.21','31.29','31.3','31.5','31.61','31.62','31.63','31.64','31.69','31.71','31.72','31.73','31.74','31.75','31.79','31.91','31.92','31.98','31.99','32.09','32.1','32.21','32.22','32.23','32.24','32.25','32.26','32.29','32.3','32.4','32.5','32.6','32.9','33.0','33.1','33.34','33.39','33.41','33.42','33.43','33.48','33.49','33.50','33.51','33.52','33.6','33.92','33.93','33.98','33.99','34.02','34.03','34.1','34.3','34.4','34.51','34.59','34.6','34.73','34.74','34.79','34.81','34.82','34.83','34.84','34.85','34.89','34.93','34.99','35.00','35.01','35.02','35.03','35.04','35.10','35.11','35.12','35.13','35.14','35.20','35.21','35.22','35.23','35.24','35.25','35.26','35.27','35.28','35.31','35.32','35.33','35.34','35.35','35.39','35.42','35.50','35.51','35.52','35.53','35.54','35.55','35.60','35.61','35.62','35.63','35.70','35.71','35.72','35.73','35.81','35.82','35.83','35.84','35.91','35.92','35.93','35.94','35.95','35.96','35.98','35.99','36.03','36.09','36.10','36.11','36.12','36.13','36.14','36.15','36.16','36.17','36.19','36.2','36.31','36.32','36.33','36.34','36.39','36.91','36.99','37.10','37.11','37.12','37.31','37.32','37.33','37.34','37.35','37.41','37.49','37.51','37.52','37.53','37.54','37.61','37.62','37.63','37.64','37.65','37.66','37.67','37.68','37.74','37.75','37.76','37.77','37.79','37.80','37.85','37.86','37.87','37.89','37.91','37.94','37.95','37.96','37.97','37.98','37.99','38.00','38.01','38.02','38.03','38.04','38.05','38.06','38.07','38.08','38.09','38.10','38.11','38.12','38.13','38.14','38.15','38.16','38.18','38.30','38.31','38.32','38.33','38.34','38.35','38.36','38.37','38.38','38.39','38.40','38.41','38.42','38.43','38.44','38.45','38.46','38.47','38.48','38.49','38.50','38.51','38.52','38.53','38.55','38.57','38.59','38.60','38.61','38.62','38.63','38.64','38.65','38.66','38.67','38.68','38.69','38.7','38.80','38.81','38.82','38.83','38.84','38.85','38.86','38.87','38.88','38.89','39.0','39.1','39.21','39.22','39.23','39.24','39.25','39.26','39.27','39.28','39.29','39.30','39.31','39.32','39.41','39.42','39.43','39.49','39.50','39.51','39.52','39.53','39.54','39.55','39.56','39.57','39.58','39.59','39.65','39.71','39.72','39.73','39.74','39.79','39.8','39.91','39.92','39.93','39.94','39.98','39.99','40.0','40.21','40.22','40.23','40.24','40.29','40.3','40.40','40.41','40.42','40.50','40.51','40.52','40.53','40.54','40.59','40.61','40.62','40.63','40.64','40.69','40.9','41.00','41.01','41.02','41.03','41.04','41.05','41.06','41.07','41.08','41.09','41.2','41.41','41.42','41.43','41.5','41.93','41.94','41.95','41.99','42.01','42.09','42.10','42.11','42.12','42.19','42.31','42.32','42.39','42.40','42.41','42.42','42.51','42.52','42.53','42.54','42.55','42.56','42.58','42.59','42.61','42.62','42.63','42.64','42.65','42.66','42.68','42.69','42.7','42.82','42.83','42.84','42.85','42.86','42.87','42.89','42.91','43.0','43.3','43.42','43.49','43.5','43.6','43.7','43.81','43.89','43.91','43.99','44.00','44.01','44.02','44.03','44.21','44.29','44.31','44.32','44.38','44.39','44.40','44.41','44.42','44.5','44.61','44.63','44.64','44.65','44.66','44.67','44.68','44.69','44.91','44.92','44.95','44.96','44.97','44.98','44.99','45.00','45.01','45.02','45.03','45.31','45.32','45.33','45.34','45.41','45.49','45.50','45.51','45.52','45.61','45.62','45.63','45.71','45.72','45.73','45.74','45.75','45.76','45.79','45.8','45.90','45.91','45.92','45.93','45.94','45.95','46.01','46.02','46.03','46.04','46.10','46.11','46.13','46.20','46.21','46.22','46.23','46.40','46.41','46.42','46.43','46.50','46.51','46.52','46.60','46.61','46.62','46.63','46.64','46.71','46.72','46.73','46.74','46.75','46.76','46.79','46.80','46.81','46.82','46.91','46.92','46.93','46.94','46.97','46.99','47.01','47.09','47.11','47.19','47.2','47.91','47.92','47.99','48.0','48.1','48.35','48.41','48.49','48.5','48.61','48.62','48.63','48.64','48.65','48.69','48.71','48.72','48.73','48.74','48.75','48.76','48.79','48.81','48.82','48.91','48.92','48.93','48.99','49.01','49.02','49.04','49.11','49.12','49.39','49.44','49.45','49.46','49.49','49.51','49.52','49.59','49.6','49.71','49.72','49.73','49.74','49.75','49.76','49.79','49.91','49.92','49.93','49.94','49.95','49.99','50.0','50.21','50.22','50.23','50.24','50.25','50.26','50.29','50.3','50.4','50.51','50.59','50.61','50.69','51.02','51.03','51.04','51.21','51.22','51.23','51.24','51.31','51.32','51.33','51.34','51.35','51.36','51.37','51.39','51.41','51.42','51.43','51.49','51.51','51.59','51.61','51.62','51.63','51.69','51.71','51.72','51.79','51.81','51.82','51.83','51.89','51.91','51.92','51.93','51.94','51.95','51.99','52.01','52.09','52.22','52.3','52.4','52.51','52.52','52.53','52.59','52.6','52.7','52.80','52.81','52.82','52.83','52.92','52.95','52.96','52.99','53.00','53.01','53.02','53.03','53.04','53.05','53.10','53.11','53.12','53.13','53.14','53.15','53.16','53.17','53.21','53.29','53.31','53.39','53.41','53.49','53.51','53.59','53.61','53.69','53.7','53.80','53.81','53.82','53.9','54.0','54.11','54.12','54.19','54.3','54.4','54.51','54.59','54.61','54.62','54.63','54.64','54.71','54.72','54.73','54.74','54.75','54.92','54.93','54.94','54.95','55.01','55.02','55.03','55.04','55.11','55.12','55.31','55.32','55.33','55.34','55.35','55.39','55.4','55.51','55.52','55.53','55.54','55.61','55.69','55.7','55.81','55.82','55.83','55.84','55.85','55.86','55.87','55.89','55.91','55.97','55.98','55.99','56.0','56.1','56.2','56.40','56.41','56.42','56.51','56.52','56.61','56.62','56.71','56.72','56.73','56.74','56.75','56.79','56.81','56.82','56.83','56.84','56.85','56.86','56.89','56.92','56.93','56.94','56.95','56.99','57.12','57.18','57.19','57.21','57.22','57.41','57.49','57.51','57.59','57.6','57.71','57.79','57.81','57.82','57.83','57.84','57.85','57.86','57.87','57.88','57.89','57.91','57.93','57.96','57.97','57.98','57.99','58.0','58.1','58.41','58.42','58.43','58.44','58.45','58.46','58.47','58.49','58.5','58.91','58.92','58.93','58.99','59.00','59.02','59.03','59.09','59.11','59.12','59.19','59.3','59.4','59.5','59.6','59.71','59.79','59.91','59.92','60.0','60.21','60.29','60.3','60.4','60.5','60.61','60.62','60.69','60.72','60.73','60.79','60.81','60.82','60.93','60.94','60.95','60.96','60.97','60.99','61.2','61.42','61.49','61.92','61.99','62.0','62.2','62.3','62.41','62.42','62.5','62.61','62.69','62.7','62.99','63.1','63.2','63.3','63.4','63.51','63.53','63.59','63.81','63.82','63.83','63.85','63.89','63.92','63.93','63.94','63.95','63.99','64.0','64.2','64.3','64.41','64.42','64.43','64.44','64.45','64.49','64.5','64.92','64.93','64.95','64.96','64.97','64.98','64.99','65.01','65.09','65.21','65.22','65.23','65.24','65.25','65.29','65.31','65.39','65.41','65.49','65.51','65.52','65.53','65.54','65.61','65.62','65.63','65.64','65.71','65.72','65.73','65.74','65.75','65.76','65.79','65.81','65.89','65.91','65.92','65.93','65.94','65.95','65.99','66.01','66.02','66.21','66.22','66.29','66.31','66.32','66.39','66.4','66.51','66.52','66.61','66.62','66.63','66.69','66.71','66.72','66.73','66.74','66.79','66.92','66.93','66.94','66.95','66.96','66.97','66.99','67.2','67.31','67.32','67.33','67.39','67.4','67.51','67.59','67.61','67.62','67.69','68.0','68.21','68.22','68.23','68.29','68.31','68.39','68.41','68.49','68.51','68.59','68.61','68.69','68.71','68.79','68.8','68.9','69.01','69.02','69.19','69.21','69.22','69.23','69.29','69.3','69.41','69.42','69.49','69.51','69.52','69.95','69.97','69.98','69.99','70.12','70.13','70.14','70.31','70.32','70.33','70.4','70.50','70.51','70.52','70.61','70.62','70.71','70.72','70.73','70.74','70.75','70.76','70.77','70.79','70.8','70.91','70.92','71.01','71.09','71.22','71.23','71.24','71.29','71.3','71.4','71.5','71.61','71.62','71.71','71.72','71.79','71.8','71.9','73.94','73.99','74.0','74.1','74.2','74.3','74.4','74.91','74.99','75.36','75.50','75.51','75.52','75.61','75.93','75.99','76.01','76.09','76.2','76.31','76.39','76.41','76.42','76.43','76.44','76.45','76.46','76.5','76.61','76.62','76.63','76.64','76.65','76.66','76.67','76.68','76.69','76.70','76.72','76.74','76.76','76.77','76.79','76.91','76.92','76.94','76.97','76.99','77.00','77.01','77.02','77.03','77.04','77.05','77.06','77.07','77.08','77.09','77.10','77.11','77.12','77.13','77.14','77.15','77.16','77.17','77.18','77.19','77.20','77.21','77.22','77.23','77.24','77.25','77.26','77.27','77.28','77.29','77.30','77.31','77.32','77.33','77.34','77.35','77.36','77.37','77.38','77.39','77.51','77.52','77.53','77.54','77.56','77.57','77.58','77.59','77.60','77.61','77.62','77.63','77.64','77.65','77.66','77.67','77.68','77.69','77.70','77.71','77.72','77.73','77.74','77.75','77.76','77.77','77.78','77.79','77.80','77.81','77.82','77.83','77.84','77.85','77.86','77.87','77.88','77.89','77.90','77.91','77.92','77.93','77.94','77.95','77.96','77.97','77.98','77.99','78.00','78.01','78.02','78.03','78.04','78.05','78.06','78.07','78.08','78.09','78.10','78.11','78.12','78.13','78.14','78.15','78.16','78.17','78.18','78.19','78.20','78.22','78.23','78.24','78.25','78.27','78.28','78.29','78.30','78.32','78.33','78.34','78.35','78.37','78.38','78.39','78.40','78.41','78.42','78.43','78.44','78.45','78.46','78.47','78.48','78.49','78.50','78.51','78.52','78.53','78.54','78.55','78.56','78.57','78.58','78.59','78.60','78.61','78.62','78.63','78.64','78.65','78.66','78.67','78.68','78.69','78.70','78.71','78.72','78.73','78.74','78.75','78.76','78.77','78.78','78.79','78.90','78.91','78.92','78.93','78.94','78.95','78.96','78.97','78.98','78.99','79.10','79.11','79.12','79.13','79.14','79.15','79.16','79.17','79.18','79.19','79.20','79.21','79.22','79.23','79.24','79.25','79.26','79.27','79.28','79.29','79.30','79.31','79.32','79.33','79.34','79.35','79.36','79.37','79.38','79.39','79.40','79.41','79.42','79.45','79.46','79.49','79.50','79.51','79.52','79.55','79.56','79.59','79.60','79.61','79.62','79.63','79.64','79.65','79.66','79.67','79.68','79.69','79.80','79.81','79.82','79.83','79.84','79.85','79.86','79.87','79.88','79.89','79.90','79.91','79.92','79.93','79.94','79.95','79.96','79.97','79.98','79.99','80.00','80.01','80.02','80.03','80.04','80.05','80.06','80.07','80.08','80.09','80.10','80.11','80.12','80.13','80.14','80.15','80.16','80.17','80.18','80.19','80.40','80.41','80.42','80.43','80.44','80.45','80.46','80.47','80.48','80.49','80.50','80.51','80.59','80.6','80.70','80.71','80.72','80.73','80.74','80.75','80.76','80.77','80.78','80.79','80.80','80.81','80.82','80.83','80.84','80.85','80.86','80.87','80.88','80.89','80.90','80.91','80.92','80.93','80.94','80.95','80.96','80.97','80.98','80.99','81.00','81.01','81.02','81.03','81.04','81.05','81.06','81.07','81.08','81.11','81.12','81.13','81.14','81.15','81.16','81.17','81.18','81.20','81.21','81.22','81.23','81.24','81.25','81.26','81.27','81.28','81.29','81.30','81.31','81.32','81.33','81.34','81.35','81.36','81.37','81.38','81.39','81.40','81.42','81.43','81.44','81.45','81.46','81.47','81.49','81.51','81.52','81.53','81.54','81.55','81.56','81.57','81.59','81.62','81.63','81.64','81.65','81.66','81.71','81.72','81.73','81.74','81.75','81.79','81.80','81.81','81.82','81.83','81.84','81.85','81.93','81.94','81.95','81.96','81.97','81.99','82.01','82.02','82.03','82.09','82.11','82.12','82.19','82.21','82.22','82.29','82.31','82.32','82.33','82.34','82.35','82.36','82.39','82.41','82.42','82.43','82.44','82.45','82.46','82.51','82.52','82.53','82.54','82.55','82.56','82.57','82.58','82.59','82.61','82.69','82.71','82.72','82.79','82.81','82.82','82.83','82.84','82.85','82.86','82.89','82.91','82.99','83.01','83.02','83.03','83.09','83.11','83.12','83.13','83.14','83.19','83.31','83.32','83.39','83.41','83.42','83.43','83.44','83.45','83.49','83.5','83.61','83.62','83.63','83.64','83.65','83.71','83.72','83.73','83.74','83.75','83.76','83.77','83.79','83.81','83.82','83.83','83.84','83.85','83.86','83.87','83.88','83.89','83.91','83.92','83.93','83.99','84.00','84.01','84.02','84.03','84.04','84.05','84.06','84.07','84.08','84.09','84.10','84.11','84.12','84.13','84.14','84.15','84.16','84.17','84.18','84.19','84.21','84.22','84.23','84.24','84.25','84.26','84.27','84.28','84.29','84.3','84.40','84.44','84.48','84.58','84.59','84.60','84.61','84.62','84.63','84.64','84.65','84.66','84.67','84.68','84.69','84.91','84.92','84.93','84.99','85.20','85.21','85.22','85.23','85.24','85.25','85.31','85.32','85.33','85.34','85.35','85.36','85.41','85.42','85.43','85.44','85.45','85.46','85.47','85.48','85.50','85.53','85.54','85.6','85.7','85.82','85.83','85.84','85.85','85.86','85.87','85.89','85.93','85.94','85.95','85.96','85.99','86.06','86.21','86.22','86.25','86.4','86.60','86.61','86.62','86.63','86.65','86.66','86.67','86.69','86.70','86.71','86.72','86.73','86.74','86.75','86.81','86.82','86.83','86.84','86.85','86.86','86.89','86.91','86.93','86.94','86.95','86.96','86.97','86.98','92.27')
	),
	proc_inv_omop AS (
		SELECT
			proc_inv_icd9.concept_id,
			proc_inv_icd9.concept_name,
			proc_inv_icd9.concept_code,
			proc_inv_icd9.vocabulary_id,
			cr.concept_id_2,
			c.concept_name,
			c.concept_code,
			c.vocabulary_id
		FROM 
			proc_inv_icd9 
		JOIN
			@vocabulary_schema.concept_relationship cr
			ON proc_inv_icd9.concept_id = cr.concept_id_1 
			AND cr.relationship_id = 'Maps to'
		JOIN 
			@vocabulary_schema.concept c
			ON cr.concept_id_2 = c.concept_id 
	),
	--- Procedure invasive
	procedure_inv AS (
		SELECT 
			*
		FROM 
			(SELECT 
				po.procedure_occurrence_id ,
				po.person_id ,
				po.procedure_concept_id ,
				po.procedure_date ,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY po.procedure_date DESC) AS rank
			FROM
				@cdm_schema.procedure_occurrence po 
			JOIN 
				ricoveri
				ON po.person_id = ricoveri.person_id
				AND po.procedure_date >= ricoveri.visit_start_date
				AND po.procedure_date <= ricoveri.visit_end_date
			WHERE 
				po.procedure_concept_id IN (SELECT proc_inv_omop.concept_id_2 FROM proc_inv_omop)
			) AS all_procedure
		WHERE 
			all_procedure.rank = 1
	),
	--- HGB (Emoglobina) baseline
	hgb_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4153000) -- Hemoglobin level estimation
			) AS all_hgb_base
		WHERE 
			all_hgb_base.rank = 1
	),
	--- HGB (Emoglobina) 72h
	hgb_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4153000) -- Hemoglobin level estimation
			) AS all_hgb_post
		WHERE 
			all_hgb_post.rank = 1
	),
	--- RBC (Eritrociti) baseline
	rbc_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (3021589) -- Normoblasts [#/volume] in Blood
			) AS all_eritro_cont_base
		WHERE 
			all_eritro_cont_base.rank = 1
	),
	--- Eritroblasti (valore assoluto) 72h
	eritro_cont_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (3021589) -- Normoblasts [#/volume] in Blood
			) AS all_eritro_cont_post
		WHERE 
			all_eritro_cont_post.rank = 1
	),
	--- Eritroblasti (percentuale) baseline
	eritro_perc_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (3046588) -- Normoblasts/100 blasts in Blood
			) AS all_eritro_perc_base
		WHERE 
			all_eritro_perc_base.rank = 1
	),
	--- Eritroblasti (percentuale) 72h
	eritro_perc_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (3046588) -- Normoblasts/100 blasts in Blood
			) AS all_eritro_perc_post
		WHERE 
			all_eritro_perc_post.rank = 1
	),
	--- PDW (Anisocitosi PLT) baseline
	pdw_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4097620) -- Platelet distribution width measurement
			) AS all_pdw_base
		WHERE 
			all_pdw_base.rank = 1
	),
	--- PDW (Anisocitosi PLT) 72h
	pdw_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4097620) -- Platelet distribution width measurement
			) AS all_pdw_post
		WHERE 
			all_pdw_post.rank = 1
	),
	--- MPV (Volume Piastrinico Medio) baseline
	mpv_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4243951) -- Analysis of arterial blood gases and pH
			) AS all_ega_base
		WHERE 
			all_ega_base.rank = 1
	),
	--- EGA-EAB con lattati 72h
	ega_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4243951) -- Analysis of arterial blood gases and pH 
			) AS all_ega_post
		WHERE 
			all_ega_post.rank = 1
	),
	--- Piastrine baseline
	piastrine_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4306239) -- International normalized ratio 
			) AS all_inr_base
		WHERE 
			all_inr_base.rank = 1
	),
	--- INR 72h
	inr_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4306239) -- International normalized ratio
			) AS all_inr_post
		WHERE 
			all_inr_post.rank = 1
	),
    --- Transaminasi baseline
	transaminasi_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4095055,4263457) -- ALT - blood measurement, Aspartate aminotransferase measurement
			) AS all_transaminasi_base
		WHERE 
			all_transaminasi_base.rank = 1
	),
	--- Transaminasi 72h
	transaminasi_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4095055,4263457) -- ALT - blood measurement, Aspartate aminotransferase measurement
			) AS all_transaminasi_post
		WHERE 
			all_transaminasi_post.rank = 1
	),
    --- Bilirubina baseline
	bilirubina_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4094594) -- Blood urea measurement
			) AS all_azotemia_base
		WHERE 
			all_azotemia_base.rank = 1
	),
	--- Azotemia 72h
	azotemia_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4094594) -- Blood urea measurement
			) AS all_azotemia_post
		WHERE 
			all_azotemia_post.rank = 1
	),
    --- Glicemia baseline
	glicemia_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4202143) -- Blood glucose concentration
			) AS all_glicemia_base
		WHERE 
			all_glicemia_base.rank = 1
	),
	--- Glicemia 72h
	glicemia_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4202143) -- Blood glucose concentration
			) AS all_glicemia_post
		WHERE 
			all_glicemia_post.rank = 1
	),
    --- Sodio (Na) baseline
	sodium_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date = ricoveri.visit_start_date
			WHERE 
				m.measurement_concept_id IN (4019545) -- Chloride measurement, blood
			) AS all_chloride_base
		WHERE 
			all_chloride_base.rank = 1
	),
	--- Cloro (Cl) 72h
	chloride_post AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
				AND m.measurement_date > ricoveri.visit_start_date
				AND m.measurement_date <= ricoveri.visit_end_date
				AND m.measurement_date <= (ricoveri.visit_start_date + 3)
			WHERE 
				m.measurement_concept_id IN (4019545) -- Chloride measurement, blood
			) AS all_chloride_post
		WHERE 
			all_chloride_post.rank = 1
	),
    --- Potassio (K) baseline
	potassium_base AS (
		SELECT 
			*
		FROM 
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
			(SELECT 
				m.measurement_id ,
				m.person_id,
				m.measurement_concept_id ,
				m.measurement_date ,
				m.value_as_number ,
				m.unit_concept_id,
				ricoveri.visit_occurrence_id,
				ROW_NUMBER() OVER (PARTITION BY ricoveri.visit_occurrence_id ORDER BY m.measurement_date DESC) AS rank
			FROM
				@cdm_schema.measurement m 
			JOIN 
				ricoveri
				ON m.person_id = ricoveri.person_id
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
	IIF(emocultura.measurement_concept_id IS NOT NULL, 1, 0) AS emocultura,
	IIF(urinocultura.measurement_concept_id IS NOT NULL, 1, 0) AS urinocultura,
	IIF(procedure_inv.procedure_concept_id IS NOT NULL, 1, 0) AS procedure_invasive,
	IIF(hgb_base.measurement_concept_id IS NOT NULL, 1, 0) AS hgb_base,
	IIF(hgb_post.measurement_concept_id IS NOT NULL, 1, 0) AS hgb_post,
	IIF(rbc_base.measurement_concept_id IS NOT NULL, 1, 0) AS rbc_base,
	IIF(rbc_post.measurement_concept_id IS NOT NULL, 1, 0) AS rbc_post,
	IIF(hct_base.measurement_concept_id IS NOT NULL, 1, 0) AS hct_base,
	IIF(hct_post.measurement_concept_id IS NOT NULL, 1, 0) AS hct_post,
	IIF(mcv_base.measurement_concept_id IS NOT NULL, 1, 0) AS mcv_base,
	IIF(mcv_post.measurement_concept_id IS NOT NULL, 1, 0) AS mcv_post,
	IIF(mch_base.measurement_concept_id IS NOT NULL, 1, 0) AS mch_base,
	IIF(mch_post.measurement_concept_id IS NOT NULL, 1, 0) AS mch_post,
	IIF(mchc_base.measurement_concept_id IS NOT NULL, 1, 0) AS mchc_base,
	IIF(mchc_post.measurement_concept_id IS NOT NULL, 1, 0) AS mchc_post,
	IIF(rdw_base.measurement_concept_id IS NOT NULL, 1, 0) AS rdw_base,
	IIF(rdw_post.measurement_concept_id IS NOT NULL, 1, 0) AS rdw_post,
	IIF(wbc_base.measurement_concept_id IS NOT NULL, 1, 0) AS wbc_base,
	IIF(wbc_post.measurement_concept_id IS NOT NULL, 1, 0) AS wbc_post,
	IIF(neutro_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS neutro_cont_base,
	IIF(neutro_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS neutro_cont_post,
	IIF(neutro_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS neutro_perc_base,
	IIF(neutro_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS neutro_perc_post,
	IIF(linfo_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS linfo_cont_base,
	IIF(linfo_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS linfo_cont_post,
	IIF(linfo_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS linfo_perc_base,
	IIF(linfo_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS linfo_perc_post,
	IIF(mono_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS mono_cont_base,
	IIF(mono_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS mono_cont_post,
	IIF(mono_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS mono_perc_base,
	IIF(mono_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS mono_perc_post,
	IIF(eosi_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS eosi_cont_base,
	IIF(eosi_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS eosi_cont_post,
	IIF(eosi_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS eosi_perc_base,
	IIF(eosi_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS eosi_perc_post,
	IIF(baso_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS baso_cont_base,
	IIF(baso_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS baso_cont_post,
	IIF(baso_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS baso_perc_base,
	IIF(baso_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS baso_perc_post,
	IIF(eritro_cont_base.measurement_concept_id IS NOT NULL, 1, 0) AS eritro_cont_base,
	IIF(eritro_cont_post.measurement_concept_id IS NOT NULL, 1, 0) AS eritro_cont_post,
	IIF(eritro_perc_base.measurement_concept_id IS NOT NULL, 1, 0) AS eritro_perc_base,
	IIF(eritro_perc_post.measurement_concept_id IS NOT NULL, 1, 0) AS eritro_perc_post,
	IIF(pdw_base.measurement_concept_id IS NOT NULL, 1, 0) AS pdw_base,
	IIF(pdw_post.measurement_concept_id IS NOT NULL, 1, 0) AS pdw_post,
	IIF(mpv_base.measurement_concept_id IS NOT NULL, 1, 0) AS mpv_base,
	IIF(mpv_post.measurement_concept_id IS NOT NULL, 1, 0) AS mpv_post,
	IIF(ega_base.measurement_concept_id IS NOT NULL, 1, 0) AS ega_base,
	IIF(ega_post.measurement_concept_id IS NOT NULL, 1, 0) AS ega_post,
	IIF(piastrine_base.measurement_concept_id IS NOT NULL, 1, 0) AS plt_base,
	IIF(piastrine_post.measurement_concept_id IS NOT NULL, 1, 0) AS plt_post,
	IIF(pt_base.measurement_concept_id IS NOT NULL, 1, 0) AS pt_base,
	IIF(pt_post.measurement_concept_id IS NOT NULL, 1, 0) AS pt_post,
	IIF(ptt_base.measurement_concept_id IS NOT NULL, 1, 0) AS ptt_base,
	IIF(ptt_post.measurement_concept_id IS NOT NULL, 1, 0) AS ptt_post,
    IIF(inr_base.measurement_concept_id IS NOT NULL, 1, 0) AS inr_base,
	IIF(inr_post.measurement_concept_id IS NOT NULL, 1, 0) AS inr_post,
    IIF(transaminasi_base.measurement_concept_id IS NOT NULL, 1, 0) AS transaminasi_base,
	IIF(transaminasi_post.measurement_concept_id IS NOT NULL, 1, 0) AS transaminasi_post,
    IIF(bilirubina_base.measurement_concept_id IS NOT NULL, 1, 0) AS bilirubina_base,
	IIF(bilirubina_post.measurement_concept_id IS NOT NULL, 1, 0) AS bilirubina_post,
    IIF(creatinina_base.measurement_concept_id IS NOT NULL, 1, 0) AS creatinina_base,
	IIF(creatinina_post.measurement_concept_id IS NOT NULL, 1, 0) AS creatinina_post,
    IIF(azotemia_base.measurement_concept_id IS NOT NULL, 1, 0) AS azotemia_base,
	IIF(azotemia_post.measurement_concept_id IS NOT NULL, 1, 0) AS azotemia_post,
    IIF(glicemia_base.measurement_concept_id IS NOT NULL, 1, 0) AS glicemia_base,
	IIF(glicemia_post.measurement_concept_id IS NOT NULL, 1, 0) AS glicemia_post,
    IIF(sodium_base.measurement_concept_id IS NOT NULL, 1, 0) AS sodium_base,
	IIF(sodium_post.measurement_concept_id IS NOT NULL, 1, 0) AS sodium_post,
    IIF(chloride_base.measurement_concept_id IS NOT NULL, 1, 0) AS chloride_base,
	IIF(chloride_post.measurement_concept_id IS NOT NULL, 1, 0) AS chloride_post,
    IIF(potassium_base.measurement_concept_id IS NOT NULL, 1, 0) AS potassium_base,
	IIF(potassium_post.measurement_concept_id IS NOT NULL, 1, 0) AS potassium_post,
    IIF(pct_base.measurement_concept_id IS NOT NULL, 1, 0) AS pct_base,
	IIF(pct_post.measurement_concept_id IS NOT NULL, 1, 0) AS pct_post,
    IIF(pcr_base.measurement_concept_id IS NOT NULL, 1, 0) AS pcr_base,
	IIF(pcr_post.measurement_concept_id IS NOT NULL, 1, 0) AS pcr_post
INTO 
	@results_schema.omop_sepsis_covariates
FROM 
	ricoveri
LEFT JOIN 
	anagrafica
	ON anagrafica.person_id = ricoveri.person_id
	AND anagrafica.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	reparto
	ON reparto.person_id = ricoveri.person_id
	AND reparto.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	emocultura
	ON emocultura.person_id = ricoveri.person_id
	AND emocultura.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	urinocultura
	ON urinocultura.person_id = ricoveri.person_id
	AND urinocultura.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	procedure_inv
	ON procedure_inv.person_id = ricoveri.person_id
	AND procedure_inv.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	hgb_base
	ON hgb_base.person_id = ricoveri.person_id
	AND hgb_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	hgb_post
	ON hgb_post.person_id = ricoveri.person_id
	AND hgb_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	rbc_base
	ON rbc_base.person_id = ricoveri.person_id
	AND rbc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	rbc_post
	ON rbc_post.person_id = ricoveri.person_id
	AND rbc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	hct_base
	ON hct_base.person_id = ricoveri.person_id
	AND hct_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	hct_post
	ON hct_post.person_id = ricoveri.person_id
	AND hct_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mcv_base
	ON mcv_base.person_id = ricoveri.person_id
	AND mcv_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mcv_post
	ON mcv_post.person_id = ricoveri.person_id
	AND mcv_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mch_base
	ON mch_base.person_id = ricoveri.person_id
	AND mch_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mch_post
	ON mch_post.person_id = ricoveri.person_id
	AND mch_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mchc_base
	ON mchc_base.person_id = ricoveri.person_id
	AND mchc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mchc_post
	ON mchc_post.person_id = ricoveri.person_id
	AND mchc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	rdw_base
	ON rdw_base.person_id = ricoveri.person_id
	AND rdw_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	rdw_post
	ON rdw_post.person_id = ricoveri.person_id
	AND rdw_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	wbc_base
	ON wbc_base.person_id = ricoveri.person_id
	AND wbc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	wbc_post
	ON wbc_post.person_id = ricoveri.person_id
	AND wbc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	neutro_cont_base
	ON neutro_cont_base.person_id = ricoveri.person_id
	AND neutro_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	neutro_cont_post
	ON neutro_cont_post.person_id = ricoveri.person_id
	AND neutro_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	neutro_perc_base
	ON neutro_perc_base.person_id = ricoveri.person_id
	AND neutro_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	neutro_perc_post
	ON neutro_perc_post.person_id = ricoveri.person_id
	AND neutro_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	linfo_cont_base
	ON linfo_cont_base.person_id = ricoveri.person_id
	AND linfo_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	linfo_cont_post
	ON linfo_cont_post.person_id = ricoveri.person_id
	AND linfo_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	linfo_perc_base
	ON linfo_perc_base.person_id = ricoveri.person_id
	AND linfo_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	linfo_perc_post
	ON linfo_perc_post.person_id = ricoveri.person_id
	AND linfo_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mono_cont_base
	ON mono_cont_base.person_id = ricoveri.person_id
	AND mono_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mono_cont_post
	ON mono_cont_post.person_id = ricoveri.person_id
	AND mono_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mono_perc_base
	ON mono_perc_base.person_id = ricoveri.person_id
	AND mono_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mono_perc_post
	ON mono_perc_post.person_id = ricoveri.person_id
	AND mono_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eosi_cont_base
	ON eosi_cont_base.person_id = ricoveri.person_id
	AND eosi_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eosi_cont_post
	ON eosi_cont_post.person_id = ricoveri.person_id
	AND eosi_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eosi_perc_base
	ON eosi_perc_base.person_id = ricoveri.person_id
	AND eosi_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eosi_perc_post
	ON eosi_perc_post.person_id = ricoveri.person_id
	AND eosi_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	baso_cont_base
	ON baso_cont_base.person_id = ricoveri.person_id
	AND baso_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	baso_cont_post
	ON baso_cont_post.person_id = ricoveri.person_id
	AND baso_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	baso_perc_base
	ON baso_perc_base.person_id = ricoveri.person_id
	AND baso_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	baso_perc_post
	ON baso_perc_post.person_id = ricoveri.person_id
	AND baso_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eritro_cont_base
	ON eritro_cont_base.person_id = ricoveri.person_id
	AND eritro_cont_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eritro_cont_post
	ON eritro_cont_post.person_id = ricoveri.person_id
	AND eritro_cont_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eritro_perc_base
	ON eritro_perc_base.person_id = ricoveri.person_id
	AND eritro_perc_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	eritro_perc_post
	ON eritro_perc_post.person_id = ricoveri.person_id
	AND eritro_perc_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pdw_base
	ON pdw_base.person_id = ricoveri.person_id
	AND pdw_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pdw_post
	ON pdw_post.person_id = ricoveri.person_id
	AND pdw_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mpv_base
	ON mpv_base.person_id = ricoveri.person_id
	AND mpv_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	mpv_post
	ON mpv_post.person_id = ricoveri.person_id
	AND mpv_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	ega_base
	ON ega_base.person_id = ricoveri.person_id
	AND ega_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	ega_post
	ON ega_post.person_id = ricoveri.person_id
	AND ega_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	piastrine_base
	ON piastrine_base.person_id = ricoveri.person_id
	AND piastrine_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	piastrine_post
	ON piastrine_post.person_id = ricoveri.person_id
	AND piastrine_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pt_base
	ON pt_base.person_id = ricoveri.person_id
	AND pt_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pt_post
	ON pt_post.person_id = ricoveri.person_id
	AND pt_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	ptt_base
	ON ptt_base.person_id = ricoveri.person_id
	AND ptt_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	ptt_post
	ON ptt_post.person_id = ricoveri.person_id
	AND ptt_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	inr_base
	ON inr_base.person_id = ricoveri.person_id
	AND inr_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	inr_post
	ON inr_post.person_id = ricoveri.person_id
	AND inr_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	transaminasi_base
	ON transaminasi_base.person_id = ricoveri.person_id
	AND transaminasi_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	transaminasi_post
	ON transaminasi_post.person_id = ricoveri.person_id
	AND transaminasi_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	bilirubina_base
	ON bilirubina_base.person_id = ricoveri.person_id
	AND bilirubina_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	bilirubina_post
	ON bilirubina_post.person_id = ricoveri.person_id
	AND bilirubina_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	creatinina_base
	ON creatinina_base.person_id = ricoveri.person_id
	AND creatinina_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	creatinina_post
	ON creatinina_post.person_id = ricoveri.person_id
	AND creatinina_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	azotemia_base
	ON azotemia_base.person_id = ricoveri.person_id
	AND azotemia_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	azotemia_post
	ON azotemia_post.person_id = ricoveri.person_id
	AND azotemia_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	glicemia_base
	ON glicemia_base.person_id = ricoveri.person_id
	AND glicemia_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	glicemia_post
	ON glicemia_post.person_id = ricoveri.person_id
	AND glicemia_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	sodium_base
	ON sodium_base.person_id = ricoveri.person_id
	AND sodium_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	sodium_post
	ON sodium_post.person_id = ricoveri.person_id
	AND sodium_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	chloride_base
	ON chloride_base.person_id = ricoveri.person_id
	AND chloride_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	chloride_post
	ON chloride_post.person_id = ricoveri.person_id
	AND chloride_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	potassium_base
	ON potassium_base.person_id = ricoveri.person_id
	AND potassium_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	potassium_post
	ON potassium_post.person_id = ricoveri.person_id
	AND potassium_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pct_base
	ON pct_base.person_id = ricoveri.person_id
	AND pct_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pct_post
	ON pct_post.person_id = ricoveri.person_id
	AND pct_post.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pcr_base
	ON pcr_base.person_id = ricoveri.person_id
	AND pcr_base.visit_occurrence_id = ricoveri.visit_occurrence_id
LEFT JOIN 
	pcr_post
	ON pcr_post.person_id = ricoveri.person_id
	AND pcr_post.visit_occurrence_id = ricoveri.visit_occurrence_id
# Custom Function for comorbidities at 6 months, icd9cm chapter
getConditionIcd9ChapterCovariateData <- function(connection,
                                                tempEmulationSchema  = NULL,
                                               cdmDatabaseSchema,
                                               cohortTable = "#cohort_person",
                                               cohortIds = -1,
                                               cdmVersion = "5",
                                               rowIdField = "visit_occurrence_id",
                                               covariateSettings,
                                               aggregated = FALSE,
                                               minCharacterizationMean = 0.001) {
  
  writeLines("Building custom ICD9 chapter (conditions) covariates...")
  
  sql <- "SELECT 
          d.visit_occurrence_id AS row_id,
          (12000 * 1000 + CAST(d.icd9_group AS INTEGER)) AS covariate_id,
          d.n_diagnosi AS covariate_value,
          c.concept_id,
          CASE 
            WHEN CAST(d.icd9_group AS INT) BETWEEN 1 AND 139 THEN 'Chapter 1: Infectious and parasitic diseases'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 140 AND 239 THEN 'Chapter 2: Neoplasms'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 240 AND 279 THEN 'Chapter 3: Endocrine, nutritional and metabolic diseases'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 280 AND 289 THEN 'Chapter 4: Diseases of the blood and blood-forming organs'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 290 AND 319 THEN 'Chapter 5: Mental disorders'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 320 AND 389 THEN 'Chapter 6: Diseases of the nervous system and sense organs'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 390 AND 459 THEN 'Chapter 7: Diseases of the circulatory system'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 460 AND 519 THEN 'Chapter 8: Diseases of the respiratory system'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 520 AND 579 THEN 'Chapter 9: Diseases of the digestive system'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 580 AND 629 THEN 'Chapter 10: Diseases of the genitourinary system'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 630 AND 679 THEN 'Chapter 11: Complications of pregnancy, childbirth, and the puerperium'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 680 AND 709 THEN 'Chapter 12: Diseases of the skin and subcutaneous tissue'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 710 AND 739 THEN 'Chapter 13: Diseases of the musculoskeletal system and connective tissue'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 740 AND 759 THEN 'Chapter 14: Congenital anomalies'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 760 AND 779 THEN 'Chapter 15: Certain conditions originating in the perinatal period'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 780 AND 799 THEN 'Chapter 16: Symptoms, signs and ill-defined conditions'
            WHEN CAST(d.icd9_group AS INT) BETWEEN 800 AND 999 THEN 'Chapter 17: Injury and poisoning'
              ELSE 'Other/Unknown'
          END AS icd9_chapter
      FROM @results_schema.omop_sepsis_icd9_diagnosis d
      LEFT JOIN @cdm_database_schema.concept c
          ON c.vocabulary_id = 'ICD9CM'
          AND c.concept_class_id = '3-dig nonbill code'
          AND c.concept_code = CAST(d.icd9_group AS VARCHAR)
          AND c.invalid_reason IS NULL;
  "
  
  sql <- SqlRender::render(
    sql,
    results_schema = resultsDatabaseSchema,
    cdm_database_schema = cdmDatabaseSchema
  )
  
  sql <- SqlRender::translate(
    sql,
    targetDialect = attr(connection, "dbms")
  )
  
  covariates <- DatabaseConnector::querySql(
    connection,
    sql,
    snakeCaseToCamelCase = TRUE
  )
  
  unique_ids <- unique(
    covariates[, c("covariateId", "icd9Chapter", 'conceptId')]
  )
  
  covariateRef <- data.frame(
    covariateId   = unique_ids$covariateId,
    covariateName = unique_ids$icd9Chapter,
    analysisId    = 12000,
    conceptId     = unique_ids$conceptId
  )
  
  analysisRef <- data.frame(
    analysisId = 12000,
    analysisName = "ICD9 chapter counts prior 180d (pre-admission)",
    domainId = "Condition",
    startDay = -180,
    endDay = 0,
    isBinary = "N",
    missingMeansZero = "N"
  )
  
  covariates <- covariates[, c("rowId", "covariateId", "covariateValue")]
  
  result <- Andromeda::andromeda(
    covariates   = covariates,
    covariateRef = covariateRef,
    analysisRef  = analysisRef
  )
  
  attr(result, "metaData") <- list(
    populationSize = length(unique(covariates$rowId))
  )
  class(result) <- "CovariateData"
  
  return(result)
}

createConditionIcd9ChapterSettings <- function() {
  settings <- list(useConditionIcd9Chapter = TRUE)
  attr(settings, "fun") <- "getConditionIcd9ChapterCovariateData"
  class(settings) <- "covariateSettings"
  settings
}
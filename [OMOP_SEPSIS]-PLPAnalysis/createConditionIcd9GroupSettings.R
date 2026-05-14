# Custom Function for comorbidities at 6 months, 3 dig icd9cm
getConditionIcd9GroupCovariateData <- function(connection,
                                               tempEmulationSchema  = NULL,
                                               cdmDatabaseSchema,
                                               cohortTable = "#cohort_person",
                                               cohortIds = -1,
                                               cdmVersion = "5",
                                               rowIdField = "visit_occurrence_id",
                                               covariateSettings,
                                               aggregated = FALSE,
                                               minCharacterizationMean = 0.001) {
  
  writeLines("Building custom ICD9 group (conditions) covariates...")
  
  sql <- "
  SELECT
      d.visit_occurrence_id AS row_id,
      (11000 * 1000 + CAST(d.icd9_group AS INTEGER)) AS covariate_id,
      d.n_diagnosi AS covariate_value,
      d.icd9_group,
      d.icd9_group_name,
      c.concept_id
  FROM
      @results_schema.omop_sepsis_icd9_diagnosis d
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
    targetDialect = attr(connection, "dbms"))
  
  covariates <- DatabaseConnector::querySql(
    connection,
    sql,
    snakeCaseToCamelCase = TRUE
  )
  
  unique_ids <- unique(
    covariates[, c("covariateId", "icd9Group", "icd9GroupName", 'conceptId')]
  )

  covariateRef <- data.frame(
    covariateId   = unique_ids$covariateId,
    covariateName = paste0(
      "ICD9 group count: ",
      unique_ids$icd9Group, " - ",
      unique_ids$icd9GroupName
    ),
    analysisId    = 11000,
    conceptId     = unique_ids$conceptId
  )
  
  analysisRef <- data.frame(
    analysisId = 11000,
    analysisName = "ICD9 group counts prior 180d (pre-admission)",
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


createConditionIcd9GroupSettings <- function() {
  settings <- list(useConditionIcd9Group = TRUE)
  attr(settings, "fun") <- "getConditionIcd9GroupCovariateData"
  class(settings) <- "covariateSettings"
  settings
}
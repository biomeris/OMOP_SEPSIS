getConditionIcd9GroupCovariateData <- function(connection,
                                               cdmDatabaseSchema,
                                               tempEmulationSchema = NULL,
                                               cohortTable = "#cohort_person",
                                               cohortIds = NULL,
                                               cdmVersion = "5",
                                               rowIdField = "row_id",
                                               covariateSettings,
                                               aggregated = FALSE,
                                               minCharacterizationMean = 0.001,
                                               ...) {
  
  writeLines("Building custom ICD9 group (conditions) covariates...")
  if (aggregated) stop("Aggregated non supportato")
  
  
  renderTranslateExecuteSql(connection,
                            sql = readSql(here::here("sql", "custom-covariates-icd9group.sql")),
                            cdm_schema = cdmDatabaseSchema,
                            results_schema = covariateSettings$resultsDatabaseSchema,
                            cohort_table = cohortTable,
                            row_id_field = rowIdField,
                            tempEmulationSchema = tempEmulationSchema
  )
  
  covariates <- renderTranslateQuerySql(
    connection,
    sql = "SELECT * FROM #ICD9CMGroup",
    snakeCaseToCamelCase = TRUE,
    tempEmulationSchema = tempEmulationSchema
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
    conceptId     = unique_ids$conceptId,
    valueAsConceptId = as.numeric(NA),
    collisions = 0L
  )
  
  analysisRef <- data.frame(
    analysisId = 11000,
    analysisName = "ICD9 group (3-digit): n. diagnoses in prior 180d (pre-admission)",
    domainId = "Condition",
    startDay = -180,
    endDay = 0,
    isBinary = "N",
    missingMeansZero = "Y"
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

createConditionIcd9GroupSettings <- function(resultsDatabaseSchema) {
  settings <- list(
    useConditionIcd9Group = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )
  attr(settings, "fun") <- "getConditionIcd9GroupCovariateData"
  class(settings) <- "covariateSettings"
  settings
}
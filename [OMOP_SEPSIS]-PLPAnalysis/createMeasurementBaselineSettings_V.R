# Create a custom function to establish baseline values for laboratory test results 
# for each hospital admission
getMeasurementBaselineCovariateData <- function(connection,
                                             tempEmulationSchema = NULL,
                                             cdmDatabaseSchema,
                                             cohortTable = "#cohort_person",
                                             cohortIds = -1,
                                             cdmVersion = "5",
                                             rowIdField = "visit_occurrence_id",
                                             covariateSettings,
                                             aggregated = FALSE,
                                             minCharacterizationMean = 0.001) {
  
  writeLines("Building custom baseline measurement covariates...")
  
  if (aggregated) {
    stop("Aggregated not supported")
  }
  
  renderTranslateExecuteSql(connection,
                            sql = readSql(here("sql", "custom-covariates-SETUP.sql")),
                            vocabulary_database_schema = cdmDatabaseSchema,
                            cohort_table = cohortTable,
                            cohort_id_ricoveri = 2,
                            cdm_schema = cdmDatabaseSchema
  )
  
  covariates <- renderTranslateQuerySql(
    connection,
    sql = readSql(here("sql", "custom-covariates-SELECT-Baseline.sql")),
    snakeCaseToCamelCase = TRUE,
    cdm_schema = cdmDatabaseSchema
  )
  
  covariateNames <- unique(
    covariates[, c("covariateId", "conceptName", "measurementConceptId")]
  )
  
  # Remove conceptName 
  covariates <- covariates[, c("rowId", "covariateId", "covariateValue")]
  
  # Create covariateRef
  covariateRef <- data.frame(
    covariateId   = covariateNames$covariateId,
    covariateName = paste0(
      "Baseline measurement: ",
      covariateNames$conceptName
    ),
    analysisId    = 10001,
    conceptId     = covariateNames$measurementConceptId
  )
  analysisRef <- data.frame(
    analysisId = 10001,
    analysisName = "Measurement at Baseline (Hospitalization)",
    domainId = "Measurement",
    startDay = -3,
    endDay = 0,
    isBinary = "N",
    missingMeansZero = "N"
  )
  
  # Create Andromeda object
  result <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateRef,
    analysisRef = analysisRef
  )
  
  attr(result, "metaData") <- list(populationSize = length(unique(covariates$rowId)))
  class(result) <- "CovariateData"
  
  return(result)
}

# Create settings
createMeasurementBaselineSettings <- function() {
  covariateSettings <- list(useMeasurementBaseline = TRUE)
  attr(covariateSettings, "fun") <- "getMeasurementBaselineCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

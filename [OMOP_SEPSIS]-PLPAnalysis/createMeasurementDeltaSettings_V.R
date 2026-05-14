# Create a custom function to calculate the changes in laboratory test results 
# for each hospital admission
getMeasurementDeltaCovariateData <- function(connection,
                                             tempEmulationSchema = NULL,
                                             cdmDatabaseSchema,
                                             cohortTable = "#cohort_person",
                                             cohortIds = -1,
                                             cdmVersion = "5",
                                             rowIdField = "visit_occurrence_id",
                                             covariateSettings,
                                             aggregated = FALSE,
                                             minCharacterizationMean = 0.001) {
  
  writeLines("Building custom delta measurement covariates...")
  
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
    sql = readSql(here("sql", "custom-covariates-SELECT.sql")),
    snakeCaseToCamelCase = TRUE,
    cdm_schema = cdmDatabaseSchema
  )
  
  print(colnames(covariates))
  
  covariateNames <- unique(
    covariates[, c("covariateId", "conceptName", "measurementConceptId")]
  )
  
  # Remove conceptName 
  covariates <- covariates[, c("rowId", "covariateId", "covariateValue")]
  
  # Create covariateRef
  covariateRef <- data.frame(
    covariateId   = covariateNames$covariateId,
    covariateName = paste0(
      "Delta within 48h ±12h from baseline: ",
      covariateNames$conceptName
    ),
    analysisId    = 10000,
    conceptId     = covariateNames$measurementConceptId
  )
  analysisRef <- data.frame(
    analysisId = 10000,
    analysisName = "Measurement Delta 48h ±12h",
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
createMeasurementDeltaSettings <- function() {
  covariateSettings <- list(useMeasurementDelta = TRUE)
  attr(covariateSettings, "fun") <- "getMeasurementDeltaCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

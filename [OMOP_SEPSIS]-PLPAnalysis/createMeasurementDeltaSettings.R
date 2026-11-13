source(here::here("createLabUnitSql.R"))
# Crea una funzione custom per calcolare i delta delle misurazioni di laboratorio 
# per ogni ricovero
getMeasurementDeltaCovariateData <- function(connection,
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
  
  writeLines("Building custom delta measurement covariates...")
  if (aggregated) {
    stop("Aggregated non supportato")
  }
  

  unitSql <- buildLabUnitSql()
  
  renderTranslateExecuteSql(connection,
                            sql = readSql(here::here("sql", "custom-covariates-SETUP.sql")),
                            vocabulary_database_schema = cdmDatabaseSchema,
                            cdm_schema = cdmDatabaseSchema,
                            results_schema = covariateSettings$resultsDatabaseSchema,
                            cohort_table = cohortTable,       
                            row_id_field = rowIdField,
                            unit_conversion_values = unitSql$conversion,
                            unit_exclusion_values  = unitSql$exclusion,
                            tempEmulationSchema = tempEmulationSchema
  )
  
  covariates <- renderTranslateQuerySql(
    connection,
    sql = readSql(here::here("sql", "custom-covariates-SELECT.sql")),
    snakeCaseToCamelCase = TRUE,
    tempEmulationSchema = tempEmulationSchema
  )
  
  covariateRef <- covariates %>%
    dplyr::distinct(covariateId, codesetId, codesetName) %>%
    dplyr::transmute(
      covariateId = covariateId,
      covariateName = paste0(
        "Delta within 48h ± 24h from baseline:",
        codesetName
      ),
      analysisId = 10000,
      conceptId = codesetId
      ) %>%  
    dplyr::mutate(
    valueAsConceptId = as.numeric(NA),
    collisions = 0L
    ) %>%
    as.data.frame()
  
  analysisRef <- data.frame(
    analysisId = 10000,
    analysisName = "Measurement Delta 24h-72h",
    domainId = "Measurement",
    startDay = -3,
    endDay = 0,
    isBinary = "N",
    missingMeansZero = "N"
  )
  
  result <- Andromeda::andromeda(
    covariates = covariates[, c("rowId", "covariateId", "covariateValue")],
    covariateRef = covariateRef,
    analysisRef = analysisRef
  )
  
  attr(result, "metaData") <- list(populationSize = length(unique(covariates$rowId)))
  class(result) <- "CovariateData"
  return(result)
}

createMeasurementDeltaSettings <- function(resultsDatabaseSchema) {
  covariateSettings <- list(
    useMeasurementDelta = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )
  attr(covariateSettings, "fun") <- "getMeasurementDeltaCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
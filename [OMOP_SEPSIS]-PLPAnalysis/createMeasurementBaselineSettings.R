source(here::here("createLabUnitSql.R"))
# Crea una funzione custom per prendere il baseline delle misurazioni di laboratorio 
# per ogni ricovero
getMeasurementBaselineCovariateData <- function(connection,
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
  
  writeLines("Building custom baseline measurement covariates...")
  
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
    sql = readSql(here::here("sql", "custom-covariates-SELECT-Baseline.sql")),
    snakeCaseToCamelCase = TRUE,
    tempEmulationSchema = tempEmulationSchema
  )
  
  # Creo riferimenti
  covariateRef <- covariates %>%
    dplyr::distinct(covariateId, codesetId, codesetName) %>%
    dplyr::transmute(
      covariateId = covariateId,
      covariateName = paste0("Baseline Measurement: ", codesetName),
      analysisId = 10001,
      conceptId = codesetId
    ) %>%  
    dplyr::mutate(
      valueAsConceptId = as.numeric(NA),
      collisions = 0L
    ) %>%
    as.data.frame()
  
  analysisRef <- data.frame(
    analysisId = 10001,
    analysisName = "Measurement at Baseline (Hospitalization)",
    domainId = "Measurement",
    startDay = 0,
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

# Crea settings
createMeasurementBaselineSettings <- function(resultsDatabaseSchema) {
  covariateSettings <- list(
    useMeasurementBaseline = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )
  attr(covariateSettings, "fun") <- "getMeasurementBaselineCovariateData"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}

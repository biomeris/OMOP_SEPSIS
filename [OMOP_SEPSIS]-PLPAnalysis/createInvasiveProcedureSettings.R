# Funzione custom per covariate procedure invasive
getInvasiveInpatientProcedureCovariates <- function(connection,
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
  
  writeLines("Building custom Invasive Procedure covariates...")
  if (aggregated) stop("Aggregated non supportato")
  
  renderTranslateExecuteSql(connection,
                            sql = readSql(here::here("sql", "custom-covariates-InvProc.sql")),
                            vocabulary_database_schema = cdmDatabaseSchema,
                            cdm_schema = cdmDatabaseSchema,
                            results_schema = covariateSettings$resultsDatabaseSchema,
                            cohort_table = cohortTable,
                            row_id_field = rowIdField,
                            tempEmulationSchema = tempEmulationSchema
  )
  
  covariates <- renderTranslateQuerySql(
    connection,
    sql = "SELECT DISTINCT row_id,
            1 as covariate_value,
            13000000 AS covariate_id
            FROM #InvProc pi",
    snakeCaseToCamelCase = TRUE,
    tempEmulationSchema = tempEmulationSchema
  )
  
  covariates <- covariates[, c("rowId", "covariateId", "covariateValue")]
  
  covariateRef <- data.frame(
    covariateId   = 13000000,
    covariateName = "Invasive/surgical/endoscopic procedure performed during hospitalization",
    analysisId    = 13000,
    conceptId     = 0,
    valueAsConceptId = as.numeric(NA),
    collisions = 0L
  )
  
  analysisRef <- data.frame(
    analysisId = 13000,
    analysisName = "Invasive Inpatient Procedure: performed anytime during hospital stay (admission to discharge)",
    domainId = "Procedure",
    startDay = 0,
    endDay = 0,
    isBinary = "Y",
    missingMeansZero = "Y"
  )
  
  result <- Andromeda::andromeda(
    covariates = covariates,
    covariateRef = covariateRef,
    analysisRef = analysisRef
  )
  
  attr(result, "metaData") <- list(populationSize = length(unique(covariates$rowId)))
  class(result) <- "CovariateData"
  
  return(result)
}

createInvasiveProcedureSettings <- function(resultsDatabaseSchema) {
  covariateSettings <- list(
    useInvasiveProcedure = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )
  attr(covariateSettings, "fun") <- "getInvasiveInpatientProcedureCovariates"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}
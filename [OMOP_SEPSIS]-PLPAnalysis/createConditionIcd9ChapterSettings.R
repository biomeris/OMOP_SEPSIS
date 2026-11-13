# Custom Function for comorbidities at 6 months, icd9cm chapter
getConditionIcd9ChapterCovariateData <- function(connection,
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
  
  writeLines("Building custom ICD9 chapter (conditions) covariates...")
  if (aggregated) stop("Aggregated non supportato")
  
  
  renderTranslateExecuteSql(connection,
                            sql = readSql(here::here("sql", "custom-covariates-icd9chapter.sql")),
                            cdm_schema = cdmDatabaseSchema,
                            results_schema = covariateSettings$resultsDatabaseSchema,
                            cohort_table = cohortTable,
                            row_id_field = rowIdField,
                            tempEmulationSchema = tempEmulationSchema
  )
  
  covariates <- renderTranslateQuerySql(
    connection,
    sql = 
      "SELECT
      row_id,
      (12000 * 1000 + icd9_chapter_num) AS covariate_id,
      SUM(covariate_value) AS covariate_value,
      MAX(concept_id) AS concept_id,
      icd9_chapter,
      icd9_chapter_num
      FROM #ICD9CMChapter
      GROUP BY
      row_id,
      icd9_chapter_num,
      icd9_chapter",
    snakeCaseToCamelCase = TRUE,
    tempEmulationSchema = tempEmulationSchema
  )
  
  unique_ids <- unique(
    covariates[, c("covariateId", "icd9Chapter", 'icd9ChapterNum')]
  )
  
  covariateRef <- data.frame(
    covariateId   = unique_ids$covariateId,
    covariateName = unique_ids$icd9Chapter,
    analysisId    = 12000,
    conceptId     = unique_ids$icd9ChapterNum,
    valueAsConceptId = as.numeric(NA),
    collisions = 0L
  )
  
  analysisRef <- data.frame(
    analysisId = 12000,
    analysisName = "ICD9 chapter: n. diagnoses in prior 180d (pre-admission)",
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

createConditionIcd9ChapterSettings <- function(resultsDatabaseSchema) {
  settings <- list(
    useConditionIcd9Chapter = TRUE,
    resultsDatabaseSchema = resultsDatabaseSchema
  )
  attr(settings, "fun") <- "getConditionIcd9ChapterCovariateData"
  class(settings) <- "covariateSettings"
  settings
}
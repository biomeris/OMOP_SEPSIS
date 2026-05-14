# Funzione custom per covariate procedure invasive
getInvasiveInpatientProcedureCovariates <- function(connection,
                                                    tempEmulationSchema  = NULL,
                                                    cdmDatabaseSchema,
                                                    cohortTable = "#cohort_person",
                                                    cohortIds = -1,
                                                    cdmVersion = "5",
                                                    rowIdField = "visit_occurrence_id",
                                                    covariateSettings,
                                                    aggregated = FALSE,
                                                    minCharacterizationMean = 0.001) {
  
  writeLines("Building custom Invasive Procedure covariates...")
  
  if (aggregated) {
    stop("Aggregated non supportato")
  }
  
  sql <- "WITH procedure_inv AS (
    SELECT DISTINCT
        po.visit_occurrence_id
    FROM @cdm_database_schema.procedure_occurrence po
    JOIN @cohort_table c
      ON po.person_id = c.subject_id
     AND po.procedure_date >= c.cohort_start_date
    WHERE po.procedure_concept_id IN (
        SELECT c2.concept_id
        FROM @vocabulary_schema.concept c2
        JOIN @vocabulary_schema.concept_ancestor ca 
          ON c2.concept_id = ca.descendant_concept_id
        WHERE ca.ancestor_concept_id IN (4301351, 4179713)  -- Surgical, Endoscopic
          AND c2.invalid_reason IS NULL
          AND c2.domain_id = 'Procedure'
      )
  )
  SELECT
  vo.visit_occurrence_id AS row_id,
  100001 AS covariate_id,
  CASE
      WHEN pi.visit_occurrence_id IS NOT NULL THEN 1
      ELSE 0
  END AS covariate_value
  FROM @cohort_table c
  LEFT JOIN @cdm_database_schema.visit_occurrence vo
    ON c.subject_id = vo.person_id
  LEFT JOIN procedure_inv pi
    ON vo.visit_occurrence_id = pi.visit_occurrence_id
  WHERE c.cohort_definition_id IN (@cohort_id)
  AND vo.visit_start_date = c.cohort_start_date ;
  "

  sql <- SqlRender::render(
    sql,
    cdm_database_schema = cdmDatabaseSchema,
    cohort_table = cohortTable,
    vocabulary_schema = cdmDatabaseSchema,
    cohort_id = cohortIds
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
  
  covariateRef <- data.frame(
    covariateId   = 100001,
    covariateName = "Invasive Inpatient Procedure performed",
    analysisId    = 10000,
    conceptId     = 0
  )
  
  analysisRef <- data.frame(
    analysisId = 10000,
    analysisName = "Check Invasive Inpatient Procedure",
    domainId = "Procedure",
    startDay = 0,
    endDay = 0,
    isBinary = "Y",
    missingMeansZero = "N"
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

# Funzione per creare settings
createInvasiveProcedureSettings <- function() {
  covariateSettings <- list(useInvasiveProcedure = TRUE)
  attr(covariateSettings, "fun") <- "getInvasiveInpatientProcedureCovariates"
  class(covariateSettings) <- "covariateSettings"
  return(covariateSettings)
}


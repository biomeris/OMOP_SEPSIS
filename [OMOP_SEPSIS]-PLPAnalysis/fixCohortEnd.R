fixCohortEnd <- function(plpData, connectionDetails, resultsSchema) {
  conn <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(conn))
  
  # discharge date per admission; same-day duplicates -> latest discharge
  vEnd <- DatabaseConnector::renderTranslateQuerySql(conn,
  "SELECT person_id, visit_start_date, MAX(visit_end_date) AS visit_end_date
  FROM @results_schema.ricoveri_tmp
  GROUP BY person_id, visit_start_date;",
  results_schema = resultsSchema, snakeCaseToCamelCase = TRUE)
  
  cohorts <- plpData$cohorts
  meta <- attr(cohorts, "metaData")
  idx <- match(paste(as.numeric(cohorts$subjectId), as.Date(cohorts$cohortStartDate)),
               paste(as.numeric(vEnd$personId),     as.Date(vEnd$visitStartDate)))
  stopifnot(!anyNA(idx))
 
   cohorts$daysToCohortEnd <- pmin(
    as.numeric(as.Date(vEnd$visitEndDate[idx]) - as.Date(cohorts$cohortStartDate)),
    cohorts$daysToObsEnd)
  
   attr(cohorts, "metaData") <- meta
  plpData$cohorts <- cohorts
  plpData
}
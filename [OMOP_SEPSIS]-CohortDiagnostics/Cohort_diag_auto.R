# Define output folder ----
outputFolder <- here::here("OMOP_SEPSIS_results_CohortDiagnostics")   
# Create output folder if it doesn't exist
if (!file.exists(outputFolder)){
  dir.create(outputFolder, recursive = TRUE)}

# Get cohort definitions sets
cohortDefinitionSet <- CohortGenerator::getCohortDefinitionSet(
  settingsFileName = "Cohorts.csv",
  jsonFolder = "json_cohorts",
  sqlFolder = "sql_cohorts",
  verbose = TRUE
)


# Create the output table names for the cohort
cohortTableNames <- CohortGenerator::getCohortTableNames(cohortTable = cohortTable)

# Create the tables on the database
CohortGenerator::createCohortTables(
  connectionDetails = connectionDetails,
  cohortTableNames = cohortTableNames,
  cohortDatabaseSchema = cohortDatabaseSchema,
  incremental = FALSE
)

# Generate the cohort set
CohortGenerator::generateCohortSet(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames,
  cohortDefinitionSet = cohortDefinitionSet,
  incremental = FALSE
)

# Execute cohort diagnostics
CohortDiagnostics::executeDiagnostics(cohortDefinitionSet,
                                      connectionDetails = connectionDetails,
                                      cohortTable = cohortTable,
                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                      cdmDatabaseSchema = cdmDatabaseSchema,
                                      exportFolder = outputFolder,
                                      databaseId = databaseId,
                                      minCellCount = 30
)

# Clean up temporary tables
CohortGenerator::dropCohortStatsTables(
  connectionDetails = connectionDetails,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTableNames = cohortTableNames
)

# *****************************************************
# STEP 3 (Optional): Explore CohortDiagnostics results
# *****************************************************
library(CohortDiagnostics)
library(glue)
library(here)

# input directory
data_directory <- "data"

# Define the name of the output database that is stored in the data folder
sqliteDbPath <- "OMOP_SEPSIS_CohortDiagnosticsData.sqlite"

# Create merged results
createMergedResults <- TRUE # if results have already been merged, set this to FALSE

# Overwrite the output database if it exists? 
overwrite <- TRUE

# Check if input folder exists
if (!dir.exists(data_directory)) {
  stop(glue("Please make sure the '{data_directory}' directory exists."))
}

# Merge results
if(createMergedResults) {
  createMergedResultsFile(data_directory, sqliteDbPath = file.path(data_directory, sqliteDbPath), overwrite = overwrite)
}

# Visualize the results in the shiny app
launchDiagnosticsExplorer(sqliteDbPath = file.path(data_directory, sqliteDbPath))
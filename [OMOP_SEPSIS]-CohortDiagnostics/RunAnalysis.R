# *******************************************
# STEP 2: Execute CohortDiagnostics analysis
# *******************************************

# Load packages -----
library(here)
library(DatabaseConnector)
library(CohortGenerator)
library(CohortDiagnostics)

# Connect to database
connectionDetails <- createConnectionDetails(dbms = ".....",   #Database type
                                             server = ".....",      #Server to the database
                                             port   = ".....",      #Port to the database
                                             user = ".....",
                                             password = ".....",
                                             pathToDriver = "....." #Path to jdbc driver
)

# additional parameters to connect to the CDM
cdmDatabaseSchema <- "....."    #Name of the database schema
cohortDatabaseSchema <- "....." #Schema in which results will be stored
cohortTable <- "OMOP_SEPSIS_cohort_diagn_results" #Prefix for table created by the analysis
databaseId <- "....." #Identifier for result folder

source("Cohort_diag_auto.R")
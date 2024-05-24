library(here)
library(stringi)
library(DatabaseConnector)
library(CohortGenerator)
library(CohortDiagnostics)


# Connect to database
connDetails <- createConnectionDetails(dbms = "postgresql",   #Databaase type
                                       server = ".....",      #Server to the database
                                       port   = ".....",      #Port to the database
                                       user = ".....",
                                       password = ".....",
                                       pathToDriver = "....." #Path to jdbc driver
)
connection <- connect(connDetails) # DB Connection

# additional parameters to connect to the CDM
cdmDatabaseSchema <- "....."    #Name of the database schema
cohortDatabaseSchema <- "....." #Schema in which results will be stored
cohortTable <- "OMOP_SEPSIS_cohort_diagn_results" #Prefix for table created by the analysis
databaseId <- "....." #Identifier for result folder

source("Cohort_diag_auto.R")
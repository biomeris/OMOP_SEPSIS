# *******************************************
# STEP 2: Execute PatientLevelPrediction analysis
# *******************************************

# Load packages -----
library(here)
library(stringi)
library(DatabaseConnector)
library(CohortGenerator)


# Connect to database
connectionDetails <- createConnectionDetails(dbms = "...",   #Database type
                                             server = "...",      #Server to the database
                                             user = "...",
                                             password = "...",
                                             pathToDriver = "..." #Path to jdbc driver
)

# additional parameters to connect to the CDM
cdmDatabaseSchema <- "..."    #Name of the database schema
cdmDatabaseName <- '...' #Name of the database to use in the Shiny app
cohortDatabaseSchema <- "..." #Schema in which results will be stored
cohortTable <- "..." #Prefix for table created by the analysis
databaseId <- "..." #Identifier for result folder
resultsDatabaseSchema <- cohortDatabaseSchema

#source("PLP_Core.R")
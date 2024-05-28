### Create project library and synchronize repository ----
# You need to run this code only once
# if you have not installed renv, please first install uncommenting the line below: 
# install.packages("renv")
renv::activate()
renv::restore()

# Load packages -----
library(here)
library(stringi)
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
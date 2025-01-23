# *********************************************
# STEP 2: Execute predictor variables analysis
# *********************************************

# Load packages -----
library(here)
library(DatabaseConnector)
library(dplyr)
library(dbplyr)
library(openxlsx)

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
resultsDatabaseSchema <- '.....' #Schema in which results will be stored
vocabularyDatabaseSchema <- "....." #Schema in which vocabularies are store (commonly is the same as cdmDatabaseSchema)
databaseId <- "....." #Identifier for result folder

source("PredictorVariables.R")
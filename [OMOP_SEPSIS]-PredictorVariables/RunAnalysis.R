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
# please see examples to connect here:
# https://ohdsi.github.io/DatabaseConnector/articles/Connecting.html
connectionDetails <- createConnectionDetails(dbms = ".....",
                                             server = ".....",
                                             port   = ".....",
                                             user = ".....",
                                             password = ".....",
                                             pathToDriver = "....."
)

# additional parameters to connect to the CDM
cdmDatabaseSchema <- "....." # schema where cdm tables are located
resultsDatabaseSchema <- '.....' # schema in which results will be stored (must have write permission)
vocabularyDatabaseSchema <- "....." # The fully qualified database name of the vocabulary schema (tipically is the same as cdmDatabaseSchema)
databaseId <- "....." # name of the database, use acronym in capital letters

# Performing the analysis on both cases and controls (full dataset)
source("PredictorVariables.R")
# Performing the analysis on cases only
source("PredictorVariables-CASES.R")
#Cohort definition
library(FeatureExtraction)
library(PatientLevelPrediction)
library(SqlRender)
library(dplyr)

# ------------------------------------------------------------------------------
# for RF, LightGBM, SVM models
library(reticulate)
use_virtualenv("r-reticulate", required = TRUE)
# ------------------------------------------------------------------------------

# Define output folder ----
outputFolder <- here::here("OMOP_SEPSIS_results_PLP")   
# Create output folder if it doesn't exist
if (!file.exists(outputFolder)){
  dir.create(outputFolder, recursive = TRUE)}

# ------------------------------------------------------------------------------
# Get cohort definitions sets
# ------------------------------------------------------------------------------
sql <- paste("SELECT cohort_definition_id, COUNT(*) AS count",
             "FROM @cohortsDbSchema.@cohortsDbTable",
             "GROUP BY cohort_definition_id")
conn <- connect(connectionDetails)
renderTranslateQuerySql(connection = conn,
                        sql = sql,
                        cohortsDbSchema = cohortDatabaseSchema,
                        cohortsDbTable = cohortTable)
disconnect(conn)
# ------------------------------------------------------------------------------
# Create Ricoveri Table 
# ------------------------------------------------------------------------------

# run once per site, after cohort generation
if (createRicoveriTable) {
  conn <- connect(connectionDetails)
  renderTranslateExecuteSql(connection = conn,
                            sql = readSql(here::here("sql", "custom-covariates-createRicoveriTable.sql")),
                            vocabulary_database_schema = cdmDatabaseSchema,
                            cohort_table = cohortTable,
                            cohort_id_ricoveri = 2,
                            cdm_schema = cdmDatabaseSchema,
                            results_schema = resultsDatabaseSchema)
  disconnect(conn)
}

# ------------------------------------------------------------------------------
# Data and Feature Extraction
# ------------------------------------------------------------------------------
# Demographics default variables
covariateSettingsList_def <- createCovariateSettings(useDemographicsGender = T,
                                                     useDemographicsAge = T)

# Clinical Custom variables
source("createMeasurementDeltaSettings.R")
source("createMeasurementBaselineSettings.R")
source("createConditionIcd9GroupSettings.R")
source("createConditionIcd9ChapterSettings.R")
source("createInvasiveProcedureSettings.R")

#Baseline lab variables
MeasurementBaseline <- createMeasurementBaselineSettings(resultsDatabaseSchema = resultsDatabaseSchema) 

#Delta lab variables
MeasurementDelta <- createMeasurementDeltaSettings(resultsDatabaseSchema = resultsDatabaseSchema)

#Comorbidities 3-dig bill 6 months prior
icd9Cov3dig <- createConditionIcd9GroupSettings(resultsDatabaseSchema = resultsDatabaseSchema)

#Comorbidities Chapter 6 months prior
icd9cmChapter <- createConditionIcd9ChapterSettings(resultsDatabaseSchema = resultsDatabaseSchema)

#Invasive Procedures 
invProc <- createInvasiveProcedureSettings(resultsDatabaseSchema = resultsDatabaseSchema)

covariateSettingsList <- list(covariateSettingsList_def, MeasurementBaseline, MeasurementDelta,
                              icd9cmChapter, invProc)


############################################################
# PLP analysis #
############################################################
databaseDetails <- createDatabaseDetails(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cdmDatabaseName = cdmDatabaseName,
  cohortDatabaseSchema = resultsDatabaseSchema,
  cohortTable = cohortTable,
  targetId = 2,
  outcomeDatabaseSchema = resultsDatabaseSchema,
  outcomeTable = cohortTable,
  outcomeIds = 1,
  cdmVersion = 5
)

restrictPlpDataSettings <- createRestrictPlpDataSettings()

plpData <- getPlpData(
  databaseDetails = databaseDetails,
  covariateSettings = covariateSettingsList,
  restrictPlpDataSettings = restrictPlpDataSettings
)


savePlpData(plpData, file.path(outputFolder, "plpData"))

# ------------------------------------------------------------------------------
# Model training (person split or time split)
# ------------------------------------------------------------------------------
populationSettings <- createStudyPopulationSettings(
  removeSubjectsWithPriorOutcome = F)

studySeed <- 34568

splitSettings <- createDefaultSplitSetting(
  trainFraction = 0.75,
  testFraction = 0.25,
  type = 'subject',
  nfold = 5,
  splitSeed = studySeed
)

# ---  Removing continuous covariates with more than 70% zeros ---------------------------
thr <- 0.70

pop_tmp <- createStudyPopulation(plpData = plpData, outcomeId = 1,
                                 populationSettings = populationSettings)

covs <- plpData$covariateData$covariates %>%
  dplyr::filter(rowId %in% !!pop_tmp$rowId) %>%
  dplyr::collect()                      

ref  <- plpData$covariateData$covariateRef %>% dplyr::collect()
aref <- plpData$covariateData$analysisRef  %>% dplyr::collect()

zeroStats <- covs %>%
  dplyr::group_by(covariateId) %>%
  dplyr::summarise(n_present = dplyr::n(),
                   n_zero    = sum(covariateValue == 0, na.rm = TRUE),
                   .groups = "drop") %>%
  dplyr::mutate(pct_zero  = n_zero / n_present,
                pct_avail = n_present / nrow(pop_tmp)) %>%
  dplyr::left_join(ref %>% dplyr::select(covariateId, covariateName, analysisId),
                   by = "covariateId") %>%
  dplyr::left_join(aref %>% dplyr::select(analysisId, isBinary, missingMeansZero),   
                   by = "analysisId")

idsToRemove <- zeroStats %>%
  dplyr::filter(isBinary == "N", missingMeansZero == "N", pct_zero > thr) %>%
  dplyr::pull(covariateId)

print(zeroStats %>% dplyr::filter(covariateId %in% idsToRemove) %>%
        dplyr::arrange(dplyr::desc(pct_zero)), n = Inf)

write.csv(zeroStats %>% dplyr::filter(covariateId %in% idsToRemove),
          file.path(outputFolder, "covariate_rimosse_zeri.csv"),
          row.names = FALSE)                                                          

if (length(idsToRemove) > 0) {
  plpData$covariateData$covariates <- plpData$covariateData$covariates %>%
    dplyr::filter(!covariateId %in% !!idsToRemove)
  plpData$covariateData$covariateRef <- plpData$covariateData$covariateRef %>%
    dplyr::filter(!covariateId %in% !!idsToRemove)
}

source("corr_check.R")
#-------------------
# intermediate split check
population <- createStudyPopulation(
  plpData = plpData,
  outcomeId = 1,
  populationSettings = populationSettings
)
plpData$population <- population

splitData <- splitData(plpData, population, splitSettings)

sampleSettings <- createSampleSettings()

# iterativeImputer <- createIterativeImputer(
#   missingThreshold = 0.3,
#   method = "pmm",
#   methodSettings = list(pmm = list(k = 5, iterations = 5))
# )
simpleImputer <- createSimpleImputer(method = "median", missingThreshold = 0.7)

source("createCorrelationFeatureRemover.R")
corrRemover <- createCorrelationFeatureRemover(cutoff = 0.8)

featureEngineeringSettings <- list(simpleImputer, corrRemover)

preprocessSettings <- createPreprocessSettings(
  minFraction = 0.001,
  normalize = T,
  removeRedundancy = T
)

#-------------------------------------------------------------------------------
# Train ML models 
#-------------------------------------------------------------------------------

# run date for output folders (ISO format, sorts correctly)
runDate <- format(Sys.Date(), "%Y%m%d")
runDir  <- function(model) file.path(outputFolder, paste0("singlePlp", model, "_", runDate))


# LASSO LOGISTIC REGRESSION


lrModel  <- setLassoLogisticRegression(maxIterations = 10000, seed = studySeed)

lrResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemo_LR',
  analysisName = 'OMOP_SEPSIS_LASSO_LR',
  populationSettings = populationSettings,
  splitSettings = splitSettings,
  sampleSettings = sampleSettings,
  featureEngineeringSettings = featureEngineeringSettings,
  preprocessSettings = preprocessSettings,
  modelSettings = lrModel,
  logSettings = createLogSettings(),
  executeSettings = createExecuteSettings(
    runSplitData = T,
    runSampleData = T,
    runFeatureEngineering = T,
    runPreprocessData = T,
    runModelDevelopment = T,
    runCovariateSummary = T
  ),
  saveDirectory = runDir("LR"))

#viewPlp(lrResults)

if (interactive()) { 

# check coefficients
lrResults$model$covariateImportance %>%
  dplyr::filter(covariateValue != 0) %>%
  dplyr::arrange(dplyr::desc(abs(covariateValue))) %>%
  print(n = 30)

print(plotPrecisionRecall(lrResults, typeColumn = "evaluation"))
print(plotSparseRoc(lrResults, typeColumn = "evaluation"))
print(plotSparseCalibration(lrResults, typeColumn = "evaluation"))
print(plotF1Measure(lrResults, typeColumn = "evaluation"))
}
# ______________________________________________________________________________
# RANDOM FOREST

rfModel <- setRandomForest(
  ntrees = list(100, 500),
  criterion = list("gini"),
  maxDepth = list(4, 10, 17),
  minSamplesSplit = list(2, 5),
  minSamplesLeaf = list(1, 10),
  minWeightFractionLeaf = list(0),
  mtries = list("sqrt", "log2"),
  minImpurityDecrease = list(0),
  bootstrap = list(TRUE),
  maxSamples = list(NULL, 0.9),
  oobScore = list(FALSE),
  seed = studySeed
)


rfResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemo_RF',
  analysisName = 'OMOP_SEPSIS_RF',
  populationSettings = populationSettings,
  splitSettings = splitSettings,
  sampleSettings = sampleSettings,
  featureEngineeringSettings = featureEngineeringSettings,
  preprocessSettings = preprocessSettings,
  modelSettings = rfModel,
  logSettings = createLogSettings(),
  executeSettings = createExecuteSettings(
    runSplitData = T,
    runSampleData = T,
    runFeatureEngineering = T,
    runPreprocessData = T,
    runModelDevelopment = T,
    runCovariateSummary = T
  ),
  saveDirectory = runDir("RF"))

if (interactive()) { 
# check coefficients
rfResults$model$covariateImportance %>%
  dplyr::filter(covariateValue != 0) %>%
  dplyr::arrange(dplyr::desc(abs(covariateValue))) %>%
  print(n=30)

  print(plotPrecisionRecall(rfResults, typeColumn = "evaluation"))
  print(plotSparseRoc(rfResults, typeColumn = "evaluation"))
  print(plotSparseCalibration(rfResults, typeColumn = "evaluation"))
  print(plotF1Measure(rfResults, typeColumn = "evaluation"))
}
# ______________________________________________________________________________
# Light Gradient Boosting Machine
LightGBMModel <- setGradientBoostingMachine(
  ntrees = c(100, 300),
  nthread = 20,
  earlyStopRound = 25,
  maxDepth = c(4, 6, 8),
  minChildWeight = 1,
  learnRate = c(0.05, 0.1, 0.3),
  scalePosWeight = 1,
  lambda = 1,
  alpha = 0,
  seed = studySeed
)

LightGBMResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemo_LightGBM',
  analysisName = 'OMOP_SEPSIS_LightGBM',
  populationSettings = populationSettings,
  splitSettings = splitSettings,
  sampleSettings = sampleSettings,
  featureEngineeringSettings = featureEngineeringSettings,
  preprocessSettings = preprocessSettings,
  modelSettings = LightGBMModel,
  logSettings = createLogSettings(),
  executeSettings = createExecuteSettings(
    runSplitData = T,
    runSampleData = T,
    runFeatureEngineering = T,
    runPreprocessData = T,
    runModelDevelopment = T,
    runCovariateSummary = T
  ),
  saveDirectory = runDir("LightGBM"))

# ______________________________________________________________________________
# Support vector machine

SVMModel <- setSVM(
  C = list(1, 0.9, 2, 0.1),
  kernel = list("rbf"),
  degree = list(1, 3, 5),
  gamma = list("scale", 1e-04, 3e-05, 0.001, 0.01, 0.25),
  coef0 = list(0),
  shrinking = list(TRUE),
  tol = list(0.001),
  classWeight = list(NULL),
  cacheSize = 500,
  seed = studySeed
)
SVMResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemo_SVM',
  analysisName = 'OMOP_SEPSIS_SVM',
  populationSettings = populationSettings,
  splitSettings = splitSettings,
  sampleSettings = sampleSettings,
  featureEngineeringSettings = featureEngineeringSettings,
  preprocessSettings = preprocessSettings,
  modelSettings = SVMModel,
  logSettings = createLogSettings(),
  executeSettings = createExecuteSettings(
    runSplitData = T,
    runSampleData = T,
    runFeatureEngineering = T,
    runPreprocessData = T,
    runModelDevelopment = T,
    runCovariateSummary = T
  ),
  saveDirectory = runDir("SVM")) 

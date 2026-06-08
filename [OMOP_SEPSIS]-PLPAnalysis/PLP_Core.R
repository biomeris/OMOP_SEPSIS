library(FeatureExtraction)
library(PatientLevelPrediction)
library(SqlRender)

# ------------------------------------------------------------------------------
# for GB and RF models
library(reticulate)
use_virtualenv("r-reticulate", required = TRUE)
py_config()
py_install("scikit-learn", envname = "r-reticulate")
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

renderTranslateQuerySql(connection = connect(connectionDetails),
                        sql = sql,
                        cohortsDbSchema = cohortDatabaseSchema,
                        cohortsDbTable = cohortTable)


source("createMeasurementDeltaSettings_V.R")
source("createMeasurementBaselineSettings_V.R")
source("createConditionIcd9GroupSettings.R")
source("createConditionIcd9ChapterSettings.R")
source("createInvasiveProcedureSettings.R")
# ------------------------------------------------------------------------------
# Data and Feature Extraction
# ------------------------------------------------------------------------------

#Baseline lab variables
MeasurementBaseline <- createMeasurementBaselineSettings()

#Delta lab variables
MeasurementDelta <- createMeasurementDeltaSettings()

#Comorbidities 3-dig bill 6 months prior
icd9Cov3dig <- createConditionIcd9GroupSettings()

#Comorbidities Chapter 6 months prior
icd9cmChapter <- createConditionIcd9ChapterSettings()

#Invasive Procedures 
invProc <- createInvasiveProcedureSettings()

#test only for measurement_delta
covariateSettingsList <- list(MeasurementDelta)
                      

start <- Sys.time()
covariateData <- getDbCovariateData(
  connectionDetails = connectionDetails,
  cdmDatabaseSchema = cdmDatabaseSchema,
  cohortDatabaseSchema = cohortDatabaseSchema,
  cohortTable = cohortTable,
  cohortIds = 2, #ricoveri
  rowIdField = "person_id",
  covariateSettings = covariateSettingsList
)

summary(covariateData)

covariates_overview <- merge(covariateData$covariates, covariateData$covariateRef, by = "covariateId")
stop <- Sys.time()
sprintf("Execution time: %f", stop-start)

############################################################
#Check lab range post covariate creation
# covariates_name <- unique(covariates_overview$covariateName)
# 
# vars <- grep(c("Baseline|baseline|Age"), covariates_name )
# 
# for (var in covariates_name[vars]){
#   idx <- which(covariates_overview$covariateName == var)
#   boxplot(covariates_overview[idx, "covariateValue"], xlab = var)
#   Sys.sleep(4)
# }
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

# savePlpData(plpData, 'OMOP_sepsis_data')

# ------------------------------------------------------------------------------
# Model training (person split or time split)
# ------------------------------------------------------------------------------
populationSettings <- createStudyPopulationSettings(
  removeSubjectsWithPriorOutcome = F)

splitSettings <- createDefaultSplitSetting(
  trainFraction = 0.75,
  testFraction = 0.25,
  type = 'person',
  nfold = 5,
  splitSeed = 34568
)

#-------------------
# intermediate split check
population <- createStudyPopulation(
  plpData = plpData,
  outcomeId = 1,
  populationSettings = populationSettings
)

splitData <- splitData(plpData, population, splitSettings)

sampleSettings <- createSampleSettings()

# featureEngineeringSettings <- createIterativeImputer(
#   missingThreshold = 0.7,
#   method = "pmm",
#   methodSettings = list(pmm = list(k = 5, iterations = 5))
# )
featureEngineeringSettings <- createSimpleImputer(method = "median", missingThreshold = 0.8)

preprocessSettings <- createPreprocessSettings(
  minFraction = 0,
  normalize = F,
  removeRedundancy = F
)

# Set ML models 

lrModel  <- setLassoLogisticRegression()
#gbModel  <- setGradientBoostingMachine()

lrResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemo',
  analysisName = 'Demonstration of runPlp for training single PLP models',
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
    runCovariateSummary = F
  ),
  saveDirectory = file.path(getwd(), 'singlePlp'))

# Random Forest Model
rfModel <- setRandomForest(ntrees = list(100),
                           criterion = list("gini"),
                           maxDepth = list( 17),
                           minSamplesSplit = list(2),
                           minSamplesLeaf = list(1),
                           minWeightFractionLeaf = list(0),
                           mtries = list("sqrt", "log2"))
rfResults <- runPlp(
  plpData = plpData,
  outcomeId = 1,
  analysisId = 'singleDemorf',
  analysisName = 'Demonstration of runPlp for training single PLP models',
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
    runCovariateSummary = F
  ),
  saveDirectory = file.path(getwd(), 'singlePlp'))

# ------------------------------------------------------------------------------
#Internal Validation
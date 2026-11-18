# Repeat LR and RF over 5 split seeds to estimate performance variability.
# Needs the objects built in PLP_Core.R (plpData, settings, rfModel).

library(dplyr)

seeds   <- c(studySeed, 1001, 2002, 3003, 4004)   # first seed reproduces the main run
seedDir <- file.path(outputFolder, paste0("seeds_", format(Sys.time(), "%Y%m%d_%H%M")))

# test/CV metrics + AUC on the first test admission per patient
getMetrics <- function(res, model, seed) {
  stats <- res$performanceEvaluation$evaluationStatistics %>%
    dplyr::mutate(dplyr::across(c(evaluation, metric, value), ~ unlist(.x))) %>%
    dplyr::filter(evaluation %in% c("Test", "CV"),
                  metric %in% c("AUROC", "AUPRC", "weak calibration gradient")) %>%
    dplyr::mutate(value = as.numeric(value)) %>%
    dplyr::select(evaluation, metric, value)
  
  first <- res$prediction %>%
    dplyr::filter(evaluationType == "Test") %>%
    dplyr::group_by(subjectId) %>%
    dplyr::slice_min(cohortStartDate, n = 1, with_ties = FALSE) %>%
    dplyr::ungroup()
  aucFirst <- as.numeric(pROC::auc(first$outcomeCount, first$value, quiet = TRUE))
  
  dplyr::bind_rows(
    stats,
    data.frame(evaluation = "Test", metric = "AUROC first admission", value = aucFirst)
  ) %>%
    dplyr::mutate(model = model, seed = seed)
}

seedResults <- list()

for (s in seeds) {
  splitSeed <- createDefaultSplitSetting(
    trainFraction = 0.75,
    testFraction  = 0.25,
    type          = "subject",
    nfold         = 5,
    splitSeed     = s
  )
  
  models <- list(
    LR = setLassoLogisticRegression(maxIterations = 10000, seed = s),
    RF = rfModel   # same grid as the main run
  )
  
  for (m in names(models)) {
    res <- runPlp(
      plpData = plpData,
      outcomeId = 1,
      analysisId = paste0(m, "_seed", s),
      analysisName = paste0("OMOP_SEPSIS_", m, "_seed", s),
      populationSettings = populationSettings,
      splitSettings = splitSeed,
      sampleSettings = sampleSettings,
      featureEngineeringSettings = featureEngineeringSettings,
      preprocessSettings = preprocessSettings,
      modelSettings = models[[m]],
      logSettings = createLogSettings(),
      executeSettings = createExecuteSettings(
        runSplitData = T,
        runSampleData = T,
        runFeatureEngineering = T,
        runPreprocessData = T,
        runModelDevelopment = T,
        runCovariateSummary = F
      ),
      saveDirectory = seedDir)
    
    if (is.null(res)) next
    seedResults[[paste(m, s)]] <- getMetrics(res, m, s)
    rm(res); gc()
  }
}

seedResults <- dplyr::bind_rows(seedResults)
write.csv(seedResults, file.path(seedDir, "seed_metrics.csv"), row.names = FALSE)

# mean and SD over seeds
seedSummary <- seedResults %>%
  dplyr::group_by(model, evaluation, metric) %>%
  dplyr::summarise(mean = round(mean(value), 3),
                   sd   = round(sd(value), 3),
                   min  = round(min(value), 3),
                   max  = round(max(value), 3),
                   .groups = "drop") %>%
  dplyr::arrange(metric, evaluation, model)
print(seedSummary)
write.csv(seedSummary, file.path(seedDir, "seed_summary.csv"), row.names = FALSE)

# paired RF - LR difference on the same split
seedDiff <- seedResults %>%
  dplyr::filter(evaluation == "Test", metric %in% c("AUROC", "AUROC first admission")) %>%
  dplyr::select(model, seed, metric, value) %>%
  tidyr::pivot_wider(names_from = model, values_from = value) %>%
  dplyr::mutate(diff = round(RF - LR, 3))
print(seedDiff)
write.csv(seedDiff, file.path(seedDir, "seed_diff_rf_lr.csv"), row.names = FALSE)
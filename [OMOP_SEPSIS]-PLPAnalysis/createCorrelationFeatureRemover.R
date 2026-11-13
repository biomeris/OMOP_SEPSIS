# Settings for the correlation-based feature remover
# cutoff: if |rho| between two features is above this, one of them is dropped
createCorrelationFeatureRemover <- function(cutoff = 0.8) {
  featureEngineeringSettings <- list(
    cutoff = cutoff
  )
  attr(featureEngineeringSettings, "fun") <- "implementCorrelationFeatureRemover"
  class(featureEngineeringSettings) <- "featureEngineeringSettings"
  return(featureEngineeringSettings)
}

# Removes highly correlated features
# model = NULL -> training: compute correlations and find features to drop
# model != NULL -> test/validation: drop the same features found on train
implementCorrelationFeatureRemover <- function(trainData,
                                               featureEngineeringSettings,
                                               model = NULL) {
  start <- Sys.time()
  
  if (is.null(model)) {
    ParallelLogger::logInfo(
      "Removing features correlated above cutoff: ",
      featureEngineeringSettings$cutoff, " from the data"
    )
    
    # runs after the imputer, so labs are already filled;
    # 0 fill here only affects binary/count covariates
    wide <- trainData$covariateData$covariates |>
      dplyr::collect() |>
      tidyr::pivot_wider(
        id_cols = "rowId",
        names_from = "covariateId",
        values_from = "covariateValue",
        values_fill = 0
      )
    
    # spearman: less sensitive to outliers and skewed labs
    corMatrix <- stats::cor(wide[, -1, drop = FALSE],
                            use = "pairwise.complete.obs",
                            method = "spearman")
    corMatrix[is.na(corMatrix)] <- 0
    
    # for each correlated pair caret drops the one with the highest mean |rho|
    correlatedFeatures <- caret::findCorrelation(
      corMatrix,
      cutoff = featureEngineeringSettings$cutoff,
      names = TRUE
    )
    correlatedFeatures <- as.numeric(correlatedFeatures)
    
    ParallelLogger::logInfo(
      "Found ", length(correlatedFeatures),
      " features correlated above selected cutoff."
    )
    
    # store the dropped ids, reused on test/validation
    model <- list(correlatedFeatures = correlatedFeatures)
  } else {
    ParallelLogger::logInfo(
      "Applying correlated feature removal (cutoff ",
      featureEngineeringSettings$cutoff, ") using previously identified features"
    )
  }
  
  # drop features from covariates and covariateRef
  trainData$covariateData$covariates <- trainData$covariateData$covariates |>
    dplyr::filter(!.data$covariateId %in% !!model$correlatedFeatures)
  
  trainData$covariateData$covariateRef <- trainData$covariateData$covariateRef |>
    dplyr::filter(!.data$covariateId %in% !!model$correlatedFeatures)
  
  # save settings + model in metaData so PLP can apply it to new data
  featureEngineering <- list(
    funct = "implementCorrelationFeatureRemover",
    settings = list(
      featureEngineeringSettings = featureEngineeringSettings,
      model = model
    )
  )
  
  attr(trainData$covariateData, "metaData")$featureEngineering <- listAppend(
    attr(trainData$covariateData, "metaData")$featureEngineering,
    featureEngineering
  )
  
  delta <- Sys.time() - start
  
  ParallelLogger::logInfo(paste0(
    "Finished correlated feature removal in ",
    signif(delta, 3), " ", attr(delta, "units")
  ))
  
  return(trainData)
}
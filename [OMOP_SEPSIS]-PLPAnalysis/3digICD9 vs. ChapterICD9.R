# --- load saved 3-digit runs (date = day they were run) ----------------------
lr3Results <- PatientLevelPrediction::loadPlpResult(file.path(outputFolder, "singlePlpLR_3dig_20261118", "LR_3dig", "plpResult"))
rf3Results <- PatientLevelPrediction::loadPlpResult(file.path(outputFolder, "singlePlpRF_3dig_20261118", "RF_3dig", "plpResult"))

# --- chapters vs 3-digit, paired on the same test patients ----------------
compareAuc <- function(resA, resB) {
  p <- resA$prediction %>% dplyr::filter(evaluationType == "Test") %>%
    dplyr::select(rowId, outcomeCount, a = value) %>%
    dplyr::inner_join(resB$prediction %>% dplyr::filter(evaluationType == "Test") %>%
                        dplyr::select(rowId, b = value), by = "rowId")
  pROC::roc.test(pROC::roc(p$outcomeCount, p$a, quiet = TRUE),
                 pROC::roc(p$outcomeCount, p$b, quiet = TRUE),
                 method = "delong", paired = TRUE)
}

compareAuc(lrResults, lr3Results)   # LR: chapters vs 3-digit
compareAuc(rfResults, rf3Results)   # RF: chapters vs 3-digit
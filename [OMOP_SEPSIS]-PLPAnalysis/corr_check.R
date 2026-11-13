library(dplyr)
library(tidyr)

# covariates, reference and analysis type
covs <- plpData$covariateData$covariates   %>% dplyr::collect()
ref  <- plpData$covariateData$covariateRef %>% dplyr::collect()
aref <- plpData$covariateData$analysisRef  %>% dplyr::collect()

ref <- ref %>%
  dplyr::left_join(aref %>% dplyr::select(analysisId, isBinary, missingMeansZero), by = "analysisId")

# binary and count covariates: missing row means 0
# lab values: missing row means not measured (NA)
zero_ids <- ref %>%
  dplyr::filter(isBinary == "Y" | missingMeansZero == "Y") %>%
  dplyr::pull(covariateId) %>% as.character()

# wide format, one row per rowId
covariate_wide <- covs %>%
  dplyr::select(rowId, covariateId, covariateValue) %>%
  tidyr::pivot_wider(names_from = covariateId, values_from = covariateValue)

# fill with 0 only binary/count columns, labs stay NA
fill_cols <- intersect(zero_ids, colnames(covariate_wide))
covariate_wide[fill_cols] <- lapply(covariate_wide[fill_cols], function(x) ifelse(is.na(x), 0, x))

# drop constant columns
X <- covariate_wide[, -1]
X <- X[, vapply(X, function(x) sd(x, na.rm = TRUE) > 0, logical(1)), drop = FALSE]

# spearman (outliers + skewed labs), pairwise complete
cor_matrix <- cor(X, use = "pairwise.complete.obs", method = "spearman")

# short names for the plot
name_map <- setNames(ref$covariateName, as.character(ref$covariateId))
short_names <- name_map[colnames(cor_matrix)] %>%
  gsub("Delta within 48h ± 24h from baseline:", "Δ ", .) %>%
  gsub("Baseline Measurement: ", "BL ", .) %>%
  gsub("Chapter (\\d+):.*", "Ch\\1", .) %>%
  gsub(".*Invasive.*procedure.*hospitalization.*", "invproc", .)
dimnames(cor_matrix) <- list(short_names, short_names)

# heatmap, hclust order
corrplot::corrplot(cor_matrix, method = "color", order = "hclust", tl.cex = 0.6)

# pairs with |rho| > 0.8
high_pairs <- as.data.frame(as.table(cor_matrix)) %>%
  dplyr::filter(as.character(Var1) < as.character(Var2), abs(Freq) > 0.8) %>%
  dplyr::arrange(dplyr::desc(abs(Freq)))
print(high_pairs)

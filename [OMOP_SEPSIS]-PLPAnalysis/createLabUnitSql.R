# Legge i CSV in lab_units/ e costruisce le liste VALUES per la SQL di SETUP.
# Restituisce una lista con:
#   $conversion : "(codeset_id, 'source_unit_ucum', 'target_unit_ucum', factor), ..."
#   $exclusion  : "(codeset_id, measurement_concept_id, 'unit_ucum'), ..."
buildLabUnitSql <- function(dir_units = here::here("lab_units")) {
  
  rd <- function(f) read.csv(file.path(dir_units, f), stringsAsFactors = FALSE,
                             strip.white = TRUE, colClasses = "character")
  conv <- rd("lab_unit_conversion.csv")
  tgt  <- rd("lab_target_units.csv")
  excl <- rd("lab_exclusions.csv")
  
  # --- controlli ---------------------------------------------------------------
  orphan <- setdiff(conv$codeset_id, tgt$codeset_id)
  if (length(orphan) > 0)
    warning("Codeset in lab_unit_conversion.csv ma non in lab_target_units.csv (ignorati): ",
            paste(orphan, collapse = ", "))
  
  conv <- merge(conv, tgt[, c("codeset_id", "target_unit_ucum")], by = "codeset_id")
  
  if (any(is.na(suppressWarnings(as.numeric(conv$factor)))))
    stop("lab_unit_conversion.csv: factor non numerico in almeno una riga")
  
  if (any(duplicated(data.frame(conv$codeset_id, toupper(conv$source_unit_ucum)))))
    stop("lab_unit_conversion.csv: stessa unita' ripetuta per lo stesso codeset")
  
  no_rows <- setdiff(tgt$codeset_id, conv$codeset_id)
  if (length(no_rows) > 0)
    warning("Codeset senza nessuna unita' accettata (verranno esclusi): ",
            paste(no_rows, collapse = ", "))
  
  # --- costruzione VALUES ------------------------------------------------------
  q <- function(x) paste0("'", gsub("'", "''", x), "'")   # stringa SQL
  
  conv <- conv[order(as.integer(conv$codeset_id)), ]
  conversion <- paste(sprintf("(%d, %s, %s, %s)",
                              as.integer(conv$codeset_id),
                              q(conv$source_unit_ucum),
                              q(conv$target_unit_ucum),
                              formatC(as.numeric(conv$factor), format = "f", digits = 8)),
                      collapse = ",\n")
  
  exclusion <- if (nrow(excl) == 0) "(-1, -1, 'NONE')" else
    paste(sprintf("(%d, %.0f, %s)",
                  as.integer(excl$codeset_id),
                  as.numeric(excl$measurement_concept_id),
                  q(excl$source_unit_ucum)),
          collapse = ",\n")
  
  list(conversion = conversion, exclusion = exclusion)
}
cat("[2/2] Performing the analysis on cases only")

cohortTable <- "OMOP_SEPSIS_cohort_diagn_results" # Prefix for table created by the analysis
cohortIdRicoveri <- 2 # Cohort ID Ricoveri
cohortIdSepsi <- 1 # Cohort ID Sepsi

# Define output folder ----
outputFolder <- here::here("OMOP_SEPSIS_results_PredictorVariables")   
# Create output folder if it doesn't exist
if (!file.exists(outputFolder)){
  dir.create(outputFolder, recursive = TRUE)}

# Directory with sql files 
sqlFolder <- file.path(here(), "sql")

# Connect to database ----
conn <- connect(connectionDetails = connectionDetails)

# Extract covariates ----
cat("Executing query to retrieve diagnosis groups...")
# Diagnosis groups (ICD9 codes)
sqlFile <- "gruppi-id9cm_casi.sql"
sql <- readChar(file.path(sqlFolder, sqlFile), file.info(file.path(sqlFolder, sqlFile))$size)

sql <- SqlRender::render(sql,
                         cdm_schema = cdmDatabaseSchema,
                         results_schema = resultsDatabaseSchema,
                         vocabulary_schema = cdmDatabaseSchema,
                         cohort_table = cohortTable,
                         cohort_id_ricoveri = cohortIdRicoveri,
                         cohort_id_sepsi = cohortIdSepsi) %>%
  SqlRender::translate(targetDialect = connectionDetails$dbms)

DatabaseConnector::executeSql(conn, sql, progressBar = TRUE, reportOverallTime = TRUE)

disconnect(conn)

# Other predictors
sqlFile <- "estrazione_covariate_casi.sql"
sql <- readChar(file.path(sqlFolder, sqlFile), file.info(file.path(sqlFolder, sqlFile))$size)

sql <- SqlRender::render(sql,
                         cdm_schema = cdmDatabaseSchema,
                         results_schema = resultsDatabaseSchema,
                         vocabulary_schema = cdmDatabaseSchema,
                         cohort_table = cohortTable,
                         cohort_id_ricoveri = cohortIdRicoveri,
                         cohort_id_sepsi = cohortIdSepsi) %>%
  SqlRender::translate(targetDialect = connectionDetails$dbms)

conn <- connect(connectionDetails = connectionDetails)

DatabaseConnector::executeSql(conn, sql, progressBar = TRUE, reportOverallTime = TRUE)

# Predictor variables counts ----
cat("Counting occurrences and producing the results...")
conn <- connect(connectionDetails = connectionDetails)
count_predictors_db <- dplyr::tbl(conn, in_schema(resultsDatabaseSchema, "omop_sepsis_covariates_cases"))

# Numero di ricoveri
n_ricoveri <- count_predictors_db %>%
  count() %>%
  collect() %>%
  pull()

predictors <- list()

# Sex
predictors[["sex"]] <- count_predictors_db %>%
  filter(!is.na(sex) & sex != 0) %>%
  summarize(variable_name = "Sesso",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Age
predictors[["age"]] <- count_predictors_db %>%
  filter(!is.na(age)) %>%
  summarize(variable_name = "Età",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Provenienza
predictors[["provenienza"]] <- count_predictors_db %>%
  filter(!is.na(provenienza) & provenienza != 0) %>%
  summarize(variable_name = "Provenienza",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Reparto ricovero
predictors[["reparto"]] <- count_predictors_db %>%
  filter(!is.na(reparto_ricovero) & reparto_ricovero != 0) %>%
  summarize(variable_name = "Reparto",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Emocultura
predictors[["emocultura"]] <- count_predictors_db %>%
  filter(!is.na(emocultura) & emocultura != 0) %>%
  summarize(variable_name = "Microbiologia - emocultura",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Urinocultura
predictors[["urinocultura"]] <- count_predictors_db %>%
  filter(!is.na(urinocultura) & urinocultura != 0) %>%
  summarize(variable_name = "Microbiologia - Urinocultura",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Procedure invasive
predictors[["procedure_invasive"]] <- count_predictors_db %>%
  filter(!is.na(procedure_invasive) & procedure_invasive != 0) %>%
  summarize(variable_name = "Procedure invasive",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# HGB (Emoglobina)
predictors[["hgb"]] <- count_predictors_db %>%
  filter(hgb_base == 1 & hgb_post == 1) %>%
  summarize(variable_name = "Laboratorio - HGB (Emoglobina)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# RBC (Eritrociti)
predictors[["rbc"]] <- count_predictors_db %>%
  filter(rbc_base == 1 & rbc_post == 1) %>%
  summarize(variable_name = "Laboratorio - RBC (Eritrociti)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# HCT (Ematocrito)
predictors[["hct"]] <- count_predictors_db %>%
  filter(hct_base == 1 & hct_post == 1) %>%
  summarize(variable_name = "Laboratorio - HCT (Ematocrito)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# MCV (Volume Corpuscolare Medio)
predictors[["mcv"]] <- count_predictors_db %>%
  filter(mcv_base == 1 & mcv_post == 1) %>%
  summarize(variable_name = "Laboratorio - MCV (Volume Corpuscolare Medio)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# MCH (Contenuto HGB medio)
predictors[["mch"]] <- count_predictors_db %>%
  filter(mch_base == 1 & mch_post == 1) %>%
  summarize(variable_name = "Laboratorio - MCH (Contenuto HGB medio)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# MCHC (Conc. HGB Globulare Media)
predictors[["mchc"]] <- count_predictors_db %>%
  filter(mchc_base == 1 & mchc_post == 1) %>%
  summarize(variable_name = "Laboratorio - MCHC (Conc. HGB Globulare Media)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# RDW
predictors[["rdw"]] <- count_predictors_db %>%
  filter(rdw_base == 1 & rdw_post == 1) %>%
  summarize(variable_name = "Laboratorio - RDW",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# WBC (Leucociti)
predictors[["wbc"]] <- count_predictors_db %>%
  filter(wbc_base == 1 & wbc_post == 1) %>%
  summarize(variable_name = "Laboratorio - WBC (Leucociti)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Neutrofili (valore assoluto)
predictors[["neutro_cont"]] <- count_predictors_db %>%
  filter(neutro_cont_base == 1 & neutro_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Neutrofili (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Neutrofili (percentuale)
predictors[["neutro_perc"]] <- count_predictors_db %>%
  filter(neutro_perc_base == 1 & neutro_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Neutrofili (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Linfociti (valore assoluto)
predictors[["linfo_cont"]] <- count_predictors_db %>%
  filter(linfo_cont_base == 1 & linfo_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Linfociti (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Linfociti (percentuale)
predictors[["linfo_perc"]] <- count_predictors_db %>%
  filter(linfo_perc_base == 1 & linfo_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Linfociti (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Monociti (valore assoluto)
predictors[["mono_cont"]] <- count_predictors_db %>%
  filter(mono_cont_base == 1 & mono_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Monociti (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Monociti (percentuale)
predictors[["mono_perc"]] <- count_predictors_db %>%
  filter(mono_perc_base == 1 & mono_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Monociti (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Eosinofili (valore assoluto)
predictors[["eosi_cont"]] <- count_predictors_db %>%
  filter(eosi_cont_base == 1 & eosi_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Eosinofili (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Eosinofili (percentuale)
predictors[["eosi_perc"]] <- count_predictors_db %>%
  filter(eosi_perc_base == 1 & eosi_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Eosinofili (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Basofili (valore assoluto)
predictors[["baso_cont"]] <- count_predictors_db %>%
  filter(baso_cont_base == 1 & baso_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Basofili (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Basofili (percentuale)
predictors[["baso_perc"]] <- count_predictors_db %>%
  filter(baso_perc_base == 1 & baso_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Basofili (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Eritroblasti (valore assoluto)
predictors[["eritro_cont"]] <- count_predictors_db %>%
  filter(eritro_cont_base == 1 & eritro_cont_post == 1) %>%
  summarize(variable_name = "Laboratorio - Eritroblasti (valore assoluto)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Eritroblasti (percentuale)
predictors[["eritro_perc"]] <- count_predictors_db %>%
  filter(eritro_perc_base == 1 & eritro_perc_post == 1) %>%
  summarize(variable_name = "Laboratorio - Eritroblasti (percentuale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PLT (Piastrine) 
predictors[["plt"]] <- count_predictors_db %>%
  filter(plt_base == 1 & plt_post == 1) %>%
  summarize(variable_name = "Laboratorio - PLT (Piastrine) ",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PDW (Anisocitosi PLT) 
predictors[["pdw"]] <- count_predictors_db %>%
  filter(pdw_base == 1 & pdw_post == 1) %>%
  summarize(variable_name = "Laboratorio - PDW (Anisocitosi PLT) ",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# MPV (Volume Piastrinico Medio) 
predictors[["mpv"]] <- count_predictors_db %>%
  filter(mpv_base == 1 & mpv_post == 1) %>%
  summarize(variable_name = "Laboratorio - MPV (Volume Piastrinico Medio) ",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# EGA-EAB 
predictors[["ega_egb"]] <- count_predictors_db %>%
  filter(ega_base == 1 & ega_post == 1) %>%
  summarize(variable_name = "Laboratorio - EGA-EAB",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PT 
predictors[["pt"]] <- count_predictors_db %>%
  filter(pt_base == 1 & pt_base == 1) %>%
  summarize(variable_name = "Laboratorio - PT (Tempo di protombina)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PTT 
predictors[["ptt"]] <- count_predictors_db %>%
  filter(ptt_base == 1 & ptt_base == 1) %>%
  summarize(variable_name = "Laboratorio - PTT (Tempo di tromboplastina parziale)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# INR 
predictors[["inr"]] <- count_predictors_db %>%
  filter(inr_base == 1 & inr_base == 1) %>%
  summarize(variable_name = "Laboratorio - INR (International normalized ratio)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Transaminasi 
predictors[["transaminasi"]] <- count_predictors_db %>%
  filter(transaminasi_base == 1 & transaminasi_post == 1) %>%
  summarize(variable_name = "Laboratorio - Transaminasi",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Bilirubina 
predictors[["bilirubina"]] <- count_predictors_db %>%
  filter(bilirubina_base == 1 & bilirubina_post == 1) %>%
  summarize(variable_name = "Laboratorio - Bilirubina",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Creatinina 
predictors[["creatinina"]] <- count_predictors_db %>%
  filter(creatinina_base == 1 & creatinina_post == 1) %>%
  summarize(variable_name = "Laboratorio - Creatinina",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Azotemia 
predictors[["azotemia"]] <- count_predictors_db %>%
  filter(azotemia_base == 1 & azotemia_post == 1) %>%
  summarize(variable_name = "Laboratorio - Azotemia",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Glicemia 
predictors[["glicemia"]] <- count_predictors_db %>%
  filter(glicemia_base == 1 & glicemia_post == 1) %>%
  summarize(variable_name = "Laboratorio - Glicemia",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Sodio (Na)
predictors[["sodio"]] <- count_predictors_db %>%
  filter(sodium_base == 1 & sodium_post == 1) %>%
  summarize(variable_name = "Laboratorio - Sodio (Na)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Cloro (Cl)
predictors[["cloro"]] <- count_predictors_db %>%
  filter(chloride_base == 1 & chloride_post == 1) %>%
  summarize(variable_name = "Laboratorio - Cloro (Cl)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Potassio (K)
predictors[["potassio"]] <- count_predictors_db %>%
  filter(potassium_base == 1 & potassium_post == 1) %>%
  summarize(variable_name = "Laboratorio - Potassio (K)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PCT 
predictors[["pct"]] <- count_predictors_db %>%
  filter(pct_base == 1 & pct_post == 1) %>%
  summarize(variable_name = "Laboratorio - PCT (Procalcitonina)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# PCR
predictors[["pcr"]] <- count_predictors_db %>%
  filter(pcr_base == 1 & pcr_post == 1) %>%
  summarize(variable_name = "Laboratorio - PCR (Proteina C reattiva)",
            n = n()) %>%
  collect() %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Gruppi di diagnosi
count_diag_db <- dplyr::tbl(conn, in_schema(resultsDatabaseSchema, "omop_sepsis_icd9_diagnosis_cases")) %>%
  group_by(icd9_group, icd9_group_name) %>%
  count() %>%
  arrange(desc(n)) %>%
  show_query() 

count_diag <- count_diag_db %>%
  collect()

count_diag <- count_diag %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Capitoli ICD-9-CM
count_diag_capitoli_db <- dplyr::tbl(conn, in_schema(resultsDatabaseSchema, "omop_sepsis_icd9_diagnosis_cases")) %>%
  mutate(icd9_group_num = as.integer(icd9_group),
         capitolo_icd9 = case_when(icd9_group_num <= 139 ~ "1 - Malattie infettive e parassitarie (001-139)",
                                   icd9_group_num >= 140 & icd9_group_num <= 239 ~ "2 - Tumori (140-239)",
                                   icd9_group_num >= 240 & icd9_group_num <= 279 ~ "3 - Malattie delle ghiandole endocrine, della nutrizione e del metabolismo, e disturbi immunitari (240-279)",
                                   icd9_group_num >= 280 & icd9_group_num <= 289 ~ "4 - Malattie del sangue e organi emopoietici (280-289)",
                                   icd9_group_num >= 290 & icd9_group_num <= 319 ~ "5 - Disturbi mentali (290-319)",
                                   icd9_group_num >= 320 & icd9_group_num <= 389 ~ "6 - Malattie del sistema nervoso e degli organi di senso (320-389)",
                                   icd9_group_num >= 390 & icd9_group_num <= 459 ~ "7 - Malattie del sistema circolatorio (390-459)",
                                   icd9_group_num >= 460 & icd9_group_num <= 519 ~ "8 - Malattie dell'apparato respiratorio (460-519)",
                                   icd9_group_num >= 520 & icd9_group_num <= 579 ~ "9 - Malattie dellapparato digerente (520-579)",
                                   icd9_group_num >= 580 & icd9_group_num <= 629 ~ "10 - Malattie dell'apparato genitourinario (580-629)",
                                   icd9_group_num >= 630 & icd9_group_num <= 677 ~ "11 - Complicazioni della gravidanza, del parto e del puerperio (630-677)",
                                   icd9_group_num >= 680 & icd9_group_num <= 709 ~ "12 - Malattie della pelle e del tessuto sottocutaneo (680-709)",
                                   icd9_group_num >= 710 & icd9_group_num <= 739 ~ "13 - Malattie del sistema osteomuscolare e del tessuto connettivo (710-739)",
                                   icd9_group_num >= 740 & icd9_group_num <= 759 ~ "14 - Malformazioni congenite (740-759)",
                                   icd9_group_num >= 760 & icd9_group_num <= 779 ~ "15 - Alcune condizioni morbose di origine perinatale (760-779)",
                                   icd9_group_num >= 780 & icd9_group_num <= 799 ~ "16 - Sintomi, segni, e stati morbosi maldefiniti (780-799)",
                                   icd9_group_num >= 800 & icd9_group_num <= 999 ~ "17 - Traumatismi e avvelenamenti (800-999)",
                                   TRUE ~ "(678-679)")) %>%
  group_by(visit_occurrence_id, capitolo_icd9) %>%
  summarize(n = sum(n_diagnosi)) %>%
  ungroup() %>%
  group_by(capitolo_icd9) %>%
  count() %>%
  arrange(desc(n))

count_diag_capitoli <- count_diag_capitoli_db %>%
  collect()

count_diag_capitoli <- count_diag_capitoli %>%
  mutate(perc = round(n / n_ricoveri, digits = 2))

# Disconnect
disconnect(conn)

# Write results ----
predictors_df <- bind_rows(predictors, .id = "variable_name")

wb <- createWorkbook()
addWorksheet(wb, "Predittori")
addWorksheet(wb, "Comorbidità - gruppi ICD-9-CM")
addWorksheet(wb, "Comorbidità - capitoli ICD-9-CM")

writeData(wb,sheet = "Predittori", data.frame("n_ricoveri" = n_ricoveri), borders = "all", borderColour = "#999999",
          headerStyle = createStyle(border = c("top", "bottom", "left", "right"), borderColour = "#999999", textDecoration = "bold"))
setColWidths(wb,sheet = "Predittori",cols = 1, widths = "auto")

writeData(wb,sheet = "Predittori", predictors_df, startRow = 4, borders = "all", borderColour = "#999999",
          headerStyle = createStyle(border = c("top", "bottom", "left", "right"), borderColour = "#999999", textDecoration = "bold"))
setColWidths(wb,sheet = "Predittori",cols = 1:ncol(predictors_df), widths = "auto")

writeData(wb,sheet = "Comorbidità - gruppi ICD-9-CM", count_diag, borders = "all", borderColour = "#999999",
          headerStyle = createStyle(border = c("top", "bottom", "left", "right"), borderColour = "#999999", textDecoration = "bold"))
setColWidths(wb,sheet = "Comorbidità - gruppi ICD-9-CM",cols = 1:ncol(count_diag), widths = "auto")

writeData(wb,sheet = "Comorbidità - capitoli ICD-9-CM", count_diag_capitoli, borders = "all", borderColour = "#999999",
          headerStyle = createStyle(border = c("top", "bottom", "left", "right"), borderColour = "#999999", textDecoration = "bold"))
setColWidths(wb,sheet = "Comorbidità - capitoli ICD-9-CM",cols = 1:ncol(count_diag_capitoli), widths = "auto")

file_name <- file.path(outputFolder, paste(databaseId, "predittori-CASI.xlsx", sep = "-"))
saveWorkbook(wb, file_name, overwrite = TRUE)

cat(sprintf("%s created in the results folder", file_name))
cat("*****")
cat("Done!")
cat("If everything has run correctly, two Excel files containing your results should now be available in the output folder, ready to share")
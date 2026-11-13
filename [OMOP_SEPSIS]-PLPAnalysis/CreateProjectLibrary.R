# **********************************************************
# STEP 1: Create project library and synchronize repository
# **********************************************************

# You need to run this code only once

# if you have not installed renv, please first install uncommenting the line below: 
# install.packages("renv")

renv::activate()
renv::restore()


# ----------------------------------------------------------
# Python environment for RF, LightGBM, SVM (scikit-learn)
# ----------------------------------------------------------
envName <- "r-reticulate"

if (!reticulate::virtualenv_exists(envName)) {
  reticulate::virtualenv_create(envName)
}
reticulate::use_virtualenv(envName, required = TRUE)
reticulate::py_install("scikit-learn==1.8.0", envname = envName)
reticulate::py_config()   # check python path and version
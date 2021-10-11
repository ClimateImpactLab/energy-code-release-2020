# Install R packages

# to fix reticulate
install.packages("devtools", repos="http://cran.us.r-project.org")
library("devtools")
devtools::install_github("rstudio/reticulate")

list.of.packages <- c("readr", "haven","Rcpp", "imputeTS", "ggplot2", "DescTools", "mvtnorm", "magrittr", "dplyr", "testit", "stringr", "readstata13", "viridis", "gridExtra", "grid", "lattice", "ncdf4", "narray", "tidyr", "cowplot", "data.table", "gdata")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.us.r-project.org")


# If you encounter R issues, it might be worth trying out updating R:
# # on windows: 
# if(!require(installr)) {
#   install.packages("installr"); 
#   require(installr)
# } #load / install+load installr
# updateR()

# on Mac: download latest installer from https://www.r-project.org/
# the code has been tested on R 4.1.1

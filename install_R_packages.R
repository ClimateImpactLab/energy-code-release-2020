# Install R packages

# to fix reticulate
install.packages("devtools", repos="http://cran.us.r-project.org")
library("devtools")
devtools::install_github("rstudio/reticulate")

list.of.packages <- c("readr","tidyverse", "haven","Rcpp", "imputeTS",
 "ggplot2", "DescTools", "mvtnorm", "magrittr", "dplyr", 
 "testit", "stringr", "readstata13", "viridis", "gridExtra", 
 "grid", "lattice", "ncdf4", "narray", "tidyr", "cowplot", 
 "data.table", "gdata", "logr", "miceadds", "R.utils","rlist",
 "pacman","ggnewscale","sp","rgdal","maptools")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.us.r-project.org")



install.packages("maptools")
library(maptools)
# if the above two lines fail for you:
# on OS X, you may need to download GDAL from http://www.kyngchaos.com/software/frameworks/
# and then run the following line:
# install.packages('rgdal', type = "source", configure.args=c('--with-proj-include=/Library/Frameworks/PROJ.framework/Headers', '--with-proj-lib=/Library/Frameworks/PROJ.framework/unix/lib'))



# If you encounter R issues, it might be worth trying out updating R:
# # on windows: 
# if(!require(installr)) {
#   install.packages("installr"); 
#   require(installr)
# } #load / install+load installr
# updateR()

# on Mac: download latest installer from https://www.r-project.org/
# the code has been tested on R 4.1.1

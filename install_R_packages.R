# Install R packages
list.of.packages <- c("ggplot2", "DescTools", "mvtnorm", "magrittr", "dplyr", "testit", "stringr", "readstata13", "viridis", "gridExtra", "grid", "lattice", "ncdf4", "narray", "tidyr", "cowplot", "data.table", "gdata")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)

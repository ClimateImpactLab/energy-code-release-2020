# Calculate price increases for non-US countries for which we have price data.
# take the earliest/latest years available in the data (IEA_price.dta)

# risingverse
rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
cilpath.r:::cilpath()
library(readstata13)


setwd(paste0(REPO,"/energy-code-release-2020/"))

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'


# Source a python code that lets us load SSP data directly from the SSPs
# Make sure you are in the risingverse conda environment for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
# source_python(paste0(projection.packages, "future_gdp_pop_data.py"))

setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))


prices = read.dta13(paste0(db,"/IEA_Replication/Data/Projection/prices/1_inter",
	"IEA_prices.dta.dta"))
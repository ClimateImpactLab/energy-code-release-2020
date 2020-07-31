# Code for plotting delta beta plots, for diagnosing what's going on in individual IR projections 

#load packages

rm(list = ls())
library(stringr)
squish_function <- stringr::str_squish
​

#set model, and options for running the delta betas
# Edit these lines to change what the delta beta will pop out! Also check the args below make sense, combined with these 

model <- "TINV_clim" #poly or spline
model_long <- "TINV_clim_income_spline"
clim_data <- "GMFD" #BEST
product.list <- c("other_energy","electricity")
flow <- "OTHERIND"
grouping_test <- "semi-parametric"
price_growth_rate <- "014" # "03" "0"
product <- "other_energy"
years = c(2099)
all_years = c(years, 2010)
regions = c("GBR.1.10")



# TO-DO
# to get the covariate file
# import delimited "`allcalcs'/hddcddmodel_COMPILE_total_energy-allcalcs-FD_FGLS_FE_ITFIN_inter_BEST_poly2_COMPILE_total_energy_Model1_TINV_clim.csv", clear varn(61) rowrange(61)
# keep region year climtascdd20 climtashdd20 loggdppc 





#set directories
output = "/mnt/CIL_energy/code_release_data/projection_system_outputs/plot_single/"
git <- "/home/liruixue/repos"


# check necessary packages are installed
list.of.packages <- c("ggplot2", "DescTools", "mvtnorm", "magrittr", "dplyr", "testit", "stringr", "readstata13", "viridis", "gridExtra", "grid", "lattice", "ncdf4", "narray", "tidyr", "cowplot", "data.table", "gdata")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


#load functions
source(paste0(git,'/post-projection-tools/response_function/yellow_purple_package.R'))
source(paste0(git,'/gcp-energy/rationalized/2_projection/2_processing/packages/response_function.R'))


# Set location of files needed for the code to run (covs, csvv climate output)
csvv.dir = '/home/liruixue/repos/energy-code-release-2020/pixel_interaction/projection_inputs/csvv/TINV_clim/'
config.path <- paste0(git,"/energy-code-release-2020/pixel_interaction/projection_inputs/configs/",clim_data,"/",model,"/break2_Exclude/", grouping_test,"/Projection_Configs/sacagawea/run/diagnostics/")
cov.dir <- paste0("/mnt/CIL_energy/IEA_Replication/Data/Projection/covariates/FD_FGLS_719_Exclude_all-issues_break2_",grouping_test,"_",model,"_income_spline.csv")
tas.path <- paste0("/shares/gcp/climate/BCSD/hierid/popwt/daily/") #location of input impact files
output.dir <- output


# Define the arguments that get passed into the delta beta functions...
args = list(
  regions=regions,
  years=years,
  grouping_test=grouping_test,
  clim_data = clim_data,
  model= model_long,
  y.lim=c(15,-5),
  mat.file = paste('damages',model,grouping_test,"break2_Exclude", clim_data, sep = "_"),
  bound_to_hist = F,
  csvv.dir = csvv.dir,
  csvv.name = NULL, 
  csvv.name.glue = 'FD_FGLS_inter_OTHERIND_{product}_TINV_clim.csvv',
  ncname = '1.6',
  cov.dir = cov.dir, 
  covarkey = 'region',
  product = product,
  func = get.energy.response,
  y.lab = 'Impacts pc', 
  unit = 'impactpc', 
  get.covariates=T, 
  inc.adapt=F,
  covar.names = c("climtas-cdd-20","climtas-hdd-20","loggdppc"),
  list.names = c("climtascdd20","climtashdd20","loggdppc"),
  c.margin = c(.25,.25,0,.25), # (t,r,b,l)
  h.margin = c(.05,.25,.25,.25),
  legend.pos = c(.63,.95),
  export.singles=F,
  export.matrix=T,
  export.path=output.dir,
  # location.dict=location.dict,
  # suffix=paste("_",model,grouping_test,"break2_Exclude",clim_data,sep = "_"),
  delta.beta=T,
  add.cov.table = T,
  db.suffix = paste0('delta_covs_', product, '_other_energy_test')
)

# Run it...
curve_ds2 = do.call(generate_yellow_purple,args)

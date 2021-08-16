# Code for plotting delta beta plots, for diagnosing what's going on in individual IR projections 

#load packages

rm(list = ls())
library(stringr)
squish_function <- stringr::str_squish
​

#set model, and options for running the delta betas
# Edit these lines to change what the delta beta will pop out! Also check the args below make sense, combined with these 

model <- "TINV_clim" #poly or spline
model_long <- "TINV_clim"
clim_data <- "GMFD" #BEST
product.list <- c("other_energy","electricity")
flow <- "OTHERIND"
grouping_test <- "semi-parametric"
price_growth_rate <- "014" # "03" "0"
product <- "electricity"
years = c(2015)
all_years = c(years, 2010)
regions = c("USA.48.2971")




#set directories
output = "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/plot_single/"
git <- "/home/liruixue/repos/energy-code-release-2020/"


# check necessary packages are installed
list.of.packages <- c("ggplot2", "DescTools", "mvtnorm", "magrittr", "dplyr", "testit", "stringr", "readstata13", "viridis", "gridExtra", "grid", "lattice", "ncdf4", "narray", "tidyr", "cowplot", "data.table", "gdata")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)


#load functions
source(paste0(git,'3_post_projection/0_utils/yellow_purple_package.R'))
source(paste0(git,'3_post_projection/0_utils/response_function.R'))


# Set location of files needed for the code to run (covs, csvv climate output)
csvv.dir = '/home/liruixue/repos/energy-code-release-2020/projection_inputs/csvv/TINV_clim/'
config.path <- paste0(git,"/projection_inputs/configs/",clim_data,"/",model,"/break2_Exclude/", grouping_test,"/Projection_Configs/sacagawea/run/diagnostics/")
cov.dir <- paste0("/mnt/CIL_energy/code_release_data_pixel_interaction/",
  "/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv")
tas.path <- paste0("/shares/gcp/climate/BCSD/hierid/popwt/daily/") #location of input impact files
output.dir <- output



# cov_electricity_single= read_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/single-OTHERIND_electricity_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/rcp85/CCSM4/high/SSP3/hddcddspline_OTHERIND_electricity-allcalcs-FD_FGLS_inter_OTHERIND_electricity_TINV_clim.csv",
#   skip = 114) %>% 
#   write_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))
# output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'




# Define the arguments that get passed into the delta beta functions...
args = list(
  regions=regions,
  years=years,
  grouping_test=grouping_test,
  clim_data = clim_data,
  model= model_long,
  # y.lim=c(15,-5),
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
  # TT_upper_bound = 40,
  # TT_lower_bound = -10,
  get.covariates=T, 
  drop_zero_bins = F,
  inc.adapt=F,
  rnd.digits = 5,
  covar.names = c("climtas-cdd-20","climtas-hdd-20","loggdppc"),
  list.names = c("climtascdd20","climtashdd20","loggdppc"),
  c.margin = c(.25,.25,0.25,.25), # (t,r,b,l)
  h.margin = c(.05,.25,.25,.25),
  legend.pos = c(.63,.95),
  export.singles=F,
  export.matrix=T,
  export.path=output.dir,
  # location.dict=location.dict,
  # suffix=paste("_",model,grouping_test,"break2_Exclude",clim_data,sep = "_"),
  delta.beta=T,
  add.cov.table = T,
  db.suffix = paste0('delta_covs_', product, '_electricity')
)

# Run it...
curve_ds2 = do.call(generate_yellow_purple,args)




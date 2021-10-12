# P values for figures in the text: 
# need to run under risingverse
rm(list = ls())

# RCP 8.5 electricity impact at 2099 (GJ per capita)
# RCP 8.5 other fuels impact at 2099 (GJ per capita)
# RCP 4.5 electricity impact at 2099 (GJ per capita)
# RCP 4.5 other fuels impact at 2099 (GJ per capita)
# Damages as % of GDP at 2099 under RCP8.5
# Damages as % of GDP at 2099 under RCP4.5

library(dplyr)
library(readr)
library(reticulate)
library(tidyr)
library(miceadds)
library(ggplot2)
library(readr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
library(numDeriv)
library(stats)
library(reticulate)
library(R.cache)
library(parallel)
library(rlist)
library(future)
library(testit)
library(data.table)
library(ncdf4)
library(reshape2)
library(stringr)
library(glue)

cilpath.r:::cilpath()

git <- paste0("/home/liruixue/repos")
prospectus.tools.lib <- paste0("/home/liruixue/repos",'/prospectus-tools/gcp/extract/')
p_p_tools <- paste0(git, "/post-projection-tools/")
# # Enable python use by R
use_python(paste0('/home/',"liruixue",'/miniconda3/envs/', "risingverse-py27", '/bin/python'), required = T)
# # Source the relevant codes (including python code for getting weights and GCM names) 
setwd(prospectus.tools.lib)


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))
source_python(paste0(projection.packages, "future_gdp_pop_data.py"))
source_python(paste0(projection.packages, "fetch_weight.py"))

####################################################
# 1 Functions

mc <- function(seed, iterations, mean_sd_df, gcm_weight_df, year) {
  
  # Set seed for replicability 
  set.seed(seed)
  
  # 1. Take random draws from a uniform distribution
  p <- runif(iterations) %>% 
    as.data.frame() %>%
    rename(u = ".")
  
  # 2. Send this random variable to one of the gcms, by creating and then binning the cdf
  gcm_weight_df = data.frame(gcm=names(gcm_weight_df), norm_weight=unlist(gcm_weight_df))

  df_cdf <- gcm_weight_df %>%
    dplyr::mutate(cdf = cumsum(norm_weight)) 
  print('got df_cdf')

  p$gcm <- cut(p$u, breaks = c(0, df_cdf$cdf), labels=df_cdf$gcm)
  
  # 3. Join information about mean and variances
  p <- p %>%
    left_join(mean_sd_df, by="gcm")

  # 4. take draws from the relevant normal distributions
  p$value <- rnorm(iterations, mean = p$mean, sd = p$sd)
  print('taken the draws')
  # 5. Return a df in the form needed for Trin's plotting code
  p <- p %>% 
    dplyr::select(value) 
  p$year <- year
  p$weight <- 1

  return(p)
}
  

#Get gcm list of gcm weights for a given rcp
get.normalized.weights <- function (gcms, rcp) {
	weights.list = mapply(FUN = fetch_weight.memo, gcm = gcms, rcp = rcp, SIMPLIFY = FALSE)
	normalized.weights.list = mapply(FUN = `/`, weights.list, Reduce("+",weights.list), SIMPLIFY = FALSE)
	return(normalized.weights.list)
}

fetch_weight.memo = addMemoization(fetch_weight)

get_ci = function(rcp, year, unit, price, spec, iam) {

	if(is.null(price)){
		dollar_convert = NULL
	}else{
		dollar_convert = "yes"
	}

	args = list(conda_env = "risingverse-py27",
			    proj_mode = '', # '' and _dm are the two options
			    region = "global", # needs to be specified for 
			    rcp = rcp, 
			    ssp = "SSP3", 
			    price_scen = price, # have this as NULL, "price014", "MERGEETL", ...
			    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
			    uncertainty = "full", # full, climate, values
			    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
			    iam = iam, 
			    model = "TINV_clim", 
			    adapt_scen = "fulladapt", 
			    clim_data = "GMFD", 
			    yearlist = year,  
			    spec = spec,
			    dollar_convert= dollar_convert,
			    grouping_test = "semi-parametric")

	df = do.call(load.median, args) %>% 
			select(year, mean, q5, q95) 

	if(unit !="impactpc"){ #GJ conversion
		df = df	%>%
			dplyr::mutate(mean = mean / 0.0036, q5 = q5 / 0.0036, q95 = q95/ 0.0036)
	}

	return(df)
}


get.dfs <- function(env, IR, ssp, iam, rcp, price = NULL, unit, year, fuel) {
  
 
  geo_level = ifelse(IR == "global", "aggregated", "levels")
  price_scen = price

  if(is.null(price)){dollar_convert=NULL} else{dollar_convert = "yes"}

  mean_df <- load.median(
    conda_env = env,
    proj_mode = '', # '' and _dm are the two options
    region = IR, # needs to be specified for 
    rcp = NULL, 
    ssp = ssp, 
    price_scen = price, # have this as NULL, "price014", "MERGEETL", ...
    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "values", # full, climate, values
    geo_level = geo_level, # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = NULL, 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = year,  
    spec = fuel,
    dollar_convert = dollar_convert, 
    grouping_test = "semi-parametric" ) %>%
    dplyr::filter(!! iam==`iam`, !! rcp==`rcp`) %>%
    dplyr::select(gcm, value, weight) %>%
    rename(mean=value)

  var_df <- load.median(
    conda_env = env,
    proj_mode = '_dm', # '' and _dm are the two options
    region = IR, # needs to be specified for 
    rcp = NULL, 
    ssp = ssp, 
    price_scen = price, # have this as NULL, "price014", "MERGEETL", ...
    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "values", # full, climate, values
    geo_level = geo_level, # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = NULL, 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = year,  
    spec = fuel,
    dollar_convert = dollar_convert, 
    grouping_test = "semi-parametric")  %>%
    dplyr::filter(!! iam==`iam`, !!rcp==`rcp`) %>%
    dplyr::select(gcm, value, weight) %>%
    rename(variance=value) %>%
    dplyr::mutate(sd=sqrt(variance))

  df_joined = left_join(mean_df, var_df) 


  if(rcp=="rcp85"){
    assert(dim(df_joined)==c(33, 5))
  }
  
  return(df_joined)
}

get.gcm.list <- function(projection.path = glue::glue("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost"), rcp = 'rcp85', ...) {
	kwargs = list(...)
	file.name = "median_OTHERIND_electricity_TINV_clim_GMFD"
	path.2.gcm.files = paste(projection.path, file.name,'median', rcp, sep = '/')
	list.gcms = list.dirs(path = path.2.gcm.files, full.names = FALSE, recursive = FALSE)
	return(list.gcms)
}


# Function for generating p values using MC analysis

get_p_val = function(env, IR, ssp, price, unit, 
						year, fuel, rcp, iam, seed, iterations){

	# Get a df with each GCMs mean and variances
	df_joined <- get.dfs(env=env, IR=IR, ssp=ssp, price=price, 
		unit=unit, year=year, fuel=fuel, rcp=rcp, iam=iam)
	
	# Get the GCM list and their weights
	gcms = get.gcm.list(rcp = rcp)

	gcm.weights <- get.normalized.weights(gcms=gcms, rcp = rcp) 
	print('got the gcm weights')
	# Take draws from each GCM, with the number of draws depending on the weights

	print(paste(seed, iterations, sep = "  "))
	print(dim(df_joined))
	print(dim(gcm.weights))

	df_mc <- mc(seed = seed, iterations = iterations, 
	  	mean_sd_df=df_joined, gcm_weight_df=gcm.weights, year =year) %>% 
		as.data.frame() 

	# Convert to GJ if unit is impact_pc
	if(!is.null(price)) {
		print('converting to GJ')
		df_mc = df_mc %>% 
			dplyr::mutate(value = value / 0.0036)
	}

	# Count the number of draws that fall above / below zero. Note - this is a two sided test
	if(mean(df_mc$value) > 0) {
		pval = 2 * length(which(df_mc$value < 0)) / iterations
	} else{
		pval = 2 * length(which(df_mc$value > 0)) / iterations	
	}

	df = get_ci(rcp = rcp, year = year, unit = unit, price = price, spec = fuel, iam = iam)

	# Get results in a nice dataframe for output
	results = data.frame(fuel = fuel, rcp = rcp, iam = iam, 
							unit= unit, ssp = ssp, mean =mean(df_mc$value), pval = pval, 
							q5 = df$q5[1], q95 = df$q95[1])
	return(results)
}



##################################################
# 2 GDP values for rescaling

gdp_2099 = (read_csv(paste0(output, 
	'/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv')) %>% filter(year == 2099))$gdp / 1000000000


##################################################
# 3 Run the functions and get the required outputs

# Run it for the following...
# RCP 8.5 electricity impact at 2099 (GJ per capita)
# RCP 8.5 other fuels impact at 2099 (GJ per capita)
# RCP 4.5 electricity impact at 2099 (GJ per capita)
# RCP 4.5 other fuels impact at 2099 (GJ per capita)

fuels = list("OTHERIND_other_energy","OTHERIND_electricity" )
rcps = list("rcp45", "rcp85")
options = expand.grid(fuel = fuels, rcp =rcps) 


args = list(env= "risingverse-py27", IR = "global", ssp = "SSP3", price=NULL, unit="impactpc", 
				year = 2099, iam="high", seed=123, 
				iterations=100000)

fuels = mapply(get_p_val, rcp = options$rcp, fuel = options$fuel, 
		MoreArgs = args, SIMPLIFY = FALSE) %>%
		bind_rows()


# Run for total energy damages...
# Damages as % of GDP at 2099 under RCP8.5
# Damages as % of GDP at 2099 under RCP4.5

total = list("OTHERIND_total_energy")
total_options = expand.grid(fuel = total, rcp = rcps)

args_total = list(env= "risingverse-py27", IR = "global", ssp = "SSP3", 
				price="price014", unit="damage", 
				year = 2099, iam="high", seed=123, 
				iterations=100000)

total = mapply(get_p_val, rcp = total_options$rcp, fuel = total_options$fuel, 
		MoreArgs = args_total, SIMPLIFY = FALSE) %>%
		bind_rows() 

# Convert the total damages to percent of 2099 gdp
total_gdp = total %>% 
	mutate(mean = mean  /gdp_2099, 
			q5 = q5 /gdp_2099, 
			q95 = q95 /gdp_2099) %>%
	mutate(unit = "proportion_gdp")

# to display without scientific notations
options(scipen=999)
# Export the final output: 
df = bind_rows(total, fuels) %>%
	bind_rows(total_gdp)


write_csv(df, "/home/liruixue/repos/energy-code-release-2020/data/p_values.csv")

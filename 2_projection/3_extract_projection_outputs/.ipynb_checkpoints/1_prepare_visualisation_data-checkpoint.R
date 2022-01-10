# Prepare code release data, and save it on Dropbox...
# Note - all maps in the paper are for 2099, SSP3, rcp85, high, so these are hard coded 
# This code should be run from inside the risingverse-py27 conda environment 

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
library(logr)
LOG <- Sys.getenv(c("LOG"))
log_open(file.path(LOG, "2_projection/3_extract_projection_outputs/1_prepare_visualisation_data.log"), logdir = FALSE)


REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))


dir = paste0(OUTPUT, '/projection_system_outputs/extracted_projection_data/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

# Note on naming convention: 
# Time series naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}

# Map data naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}-{year}-map



###############################################
# Impacts maps for figure 2A 
######################done#########################

get_main_model_impacts_maps = function(fuel, price_scen, unit, year, output){
	
	spec = paste0("OTHERIND_", fuel)
	df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = NULL, # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = year,  
                    spec = spec,
                    grouping_test = "semi-parametric",
                    regenerate = TRUE) %>%
		dplyr::select(region, year, mean,  q5, q10, q25, q50, q75, q90, q95) %>%
		dplyr::filter(year == !!year)

	price_tag = ifelse(is.null(price_scen), "impact_pc", price)
  write_csv(df, 
		paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
			'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-',price_tag ,'-',year,'-map.csv'))
}

fuels = c("electricity","other_energy")

df = lapply(fuels, get_main_model_impacts_maps, 
	price_scen = NULL, unit = "impactpc", year = 2099, output = OUTPUT)

# get data for some sanity checks
df = lapply(fuels, get_main_model_impacts_maps, 
  price_scen = NULL, unit = "impactpc", year = 2090, output = OUTPUT)


###############################################
# Get time series data for figure 2C
################### done############################
fuels = c("electricity", "other_energy")
rcps = c("rcp85", "rcp45")
adapt = c("fulladapt", "noadapt","incadapt")
options = expand.grid(fuels = fuels, rcps = rcps, adapt= adapt)

get_main_model_impacts_ts = function(fuel, rcp, adapt) {

	spec = paste0("OTHERIND_", fuel)
	names = c("mean", "q50", "q5", "q95", "q10", "q90", "q75","q25")

	df = load.median(  
					conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = rcp, 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "full", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = adapt, 
                    clim_data = "GMFD", 
                    yearlist = as.character(seq(1980,2099,1)),  
                    spec = spec,
                    grouping_test = "semi-parametric")%>%
		dplyr::filter(year > 2009) 
	
	write_csv(df, 
		paste0(OUTPUT, '/projection_system_outputs/time_series_data/', 
			'main_model-', fuel, '-SSP3-',rcp, '-high-',adapt,'-impact_pc.csv'))
}

# Get the required dataframe - note this extracts for you if the csv doesn't exist
mcmapply(get_main_model_impacts_ts, 
  fuel= options$fuels, rcp= options$rcps, adapt=options$adapt)




###############################################
# Figure 3
######################done#########################

# 3A  
# Need GDP data, at IR level, damages in 2099, and values csvs for each featured IR
# GDP data: 

# Get impacts data
args = list(
      conda_env = "risingverse-py27",
      proj_mode = '', # '' and _dm are the two options
      region = NULL, # needs to be specified for 
      rcp = "rcp85", 
      ssp = "SSP3", 
      price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
      unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
      uncertainty = "climate", # full, climate, values
      geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
      iam = "high", 
      model = "TINV_clim", 
      adapt_scen = "fulladapt", 
      clim_data = "GMFD", 
      dollar_convert = "yes",
      yearlist = 2099,  
      spec = "OTHERIND_total_energy",
      grouping_test = "semi-parametric",
      regenerate = FALSE)

impacts = do.call(load.median, args) %>%
	dplyr::select(region, mean, q5, q10, q25, q50, q75, q90, q95) %>%
	rename(damage = mean)

write_csv(impacts, 
		paste0(OUTPUT, '/projection_system_outputs/mapping_data/', 
			'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv'))


#####################done######################
# Get values csvs for the kernel density plots

IR_list = c("USA.14.608", "SWE.15", "CHN.2.18.78", "CHN.6.46.280", "IND.21.317.1249", "BRA.25.5235.9888")
IR_list_names = c("Chicago", "Stockholm", "Beijing", "Guangzhou", "Mumbai", "Sao Paulo")

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
    mutate(sd=sqrt(variance))

  df_joined = left_join(mean_df, var_df) 

  if(rcp=="rcp85"){
    assert(dim(df_joined)==c(33, 5))
  }
  
  return(df_joined)
}


get_IR_values_csv = function(IR) {
	df_joined <- get.dfs(env="risingverse-py27", IR=IR, 
					ssp="SSP3", price="price014", unit="damage", 
					year=2099, fuel="OTHERIND_total_energy", rcp="rcp85", iam="high") %>%
				dplyr::mutate(region = !!IR)
	return(df_joined)
}

df = lapply(IR_list, get_IR_values_csv) %>% 
	bind_rows() %>% as.data.frame()

write_csv(df, paste0(OUTPUT, '/projection_system_outputs/IR_GCM_level_impacts/',
	'gcm_damages-main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-select_IRs.csv'))


######################done#########################
# Get GCM list, and their respective weights, for use in the kernel density plots
# NOte - this pulls a gcm_weights csv from the mortality dropbox
get.normalized.weights <- function (rcp='rcp85') {

  df = read_csv('/mnt/Global_ACP/damage_function/GMST_anomaly/gcm_weights.csv') 

  if (rcp == 'rcp45'){
  	df$weight[df$gcm == "surrogate_GFDL-ESM2G_06"] = 0
  }
  norm = sum(df$weight)
  df = df %>% mutate(norm_weight = weight  /!! norm) %>%
  		dplyr::select(gcm, norm_weight)
  return(df)
}

gcms85 = get.normalized.weights(rcp = "rcp85") %>% rename(norm_weight_rcp85 = norm_weight)
gcms45 = get.normalized.weights(rcp = "rcp45") %>% rename(norm_weight_rcp45 = norm_weight)

df = left_join(gcms85, gcms45, by = "gcm") 
df = df[,c("gcm", "norm_weight_rcp45", "norm_weight_rcp85")]
write_csv(df, paste0(OUTPUT, '/miscellaneous/gcm_weights.csv'))


######################done#########################
 # 2 Load the impacts data for figure 3 time series as percent GDP

args = list(
    conda_env = "risingverse-py27",
    # proj_mode = '', # '' and _dm are the two options
    region = "global", # needs to be specified for 
    # rcp = "rcp85", 
    ssp = "SSP3", 
    price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "full", # full, climate, values
    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = "high", 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = as.character(seq(2010,2100,1)),  
    spec = "OTHERIND_total_energy",
    dollar_convert = "yes",
    grouping_test = "semi-parametric")

get_df_ts_main_model_total_energy = function(rcp, args) {
	plot_df = do.call(load.median, c(args, rcp = rcp, proj_mode = '')) %>% 
	                        dplyr::select(year, mean, q5, q95, rcp) %>%
	                        mutate(rcp = !!rcp)
	write_csv(plot_df, 
		paste0(OUTPUT, '/projection_system_outputs/time_series_data/', 
			'main_model-total_energy-SSP3-',rcp, '-high-fulladapt-price014.csv'))
}

rcps = c("rcp45", "rcp85")
lapply(rcps, get_df_ts_main_model_total_energy, args = args) 


# incadapt version for producing timeseries for referee comments
args = list(
    conda_env = "risingverse-py27",
    # proj_mode = '', # '' and _dm are the two options
    region = "global", # needs to be specified for 
    # rcp = "rcp85", 
    ssp = "SSP3", 
    price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "full", # full, climate, values
    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = "high", 
    model = "TINV_clim", 
    adapt_scen = "incadapt", 
    clim_data = "GMFD", 
    yearlist = as.character(seq(2010,2100,1)),  
    spec = "OTHERIND_total_energy",
    dollar_convert = "yes",
    grouping_test = "semi-parametric")

get_df_ts_main_model_total_energy = function(rcp, args) {
  plot_df = do.call(load.median, c(args, rcp = rcp, proj_mode = '')) %>% 
                          dplyr::select(year, mean, q5, q95, rcp) %>%
                          mutate(rcp = !!rcp)
  write_csv(plot_df, 
    paste0(OUTPUT, '/projection_system_outputs/time_series_data/', 
      'main_model-total_energy-SSP3-',rcp, '-high-incadapt-price014.csv'))
}

rcps = c("rcp85")
lapply(rcps, get_df_ts_main_model_total_energy, args = args) 




##########################
# Covariate data for blob plots: 
#############done#############
      
# Note - this is the output from a single run, since that produces an allcalcs file

# set path variables
covariates <- paste0(OUTPUT, 
  '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv')

# load and clean data
covars = as.data.frame(readr::read_csv(covariates)) %>% 
  rename( 'HDD20' = 'climtas-hdd-20', 'CDD20' = 'climtas-cdd-20') %>% 
  select(year, region, HDD20, CDD20, loggdppc, population) %>%
  subset(year %in% c(2090,2010))

write_csv(covars, 
	paste0(OUTPUT,'/projection_system_outputs/covariates/', 
	 'covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv'))


####################################################
 # Get time series data for global by rcp plots in figure D1
######################## done ############################

get_df_by_price_rcp = function(rcp, price) {

	print(paste0('rcp: ', rcp, ' price: ', price))

	price = as.character(price)

    args = list(
	    conda_env = "risingverse-py27",
	    proj_mode = '', # '' and _dm are the two options
	    region = "global", # needs to be specified for 
	    rcp = rcp, 
	    ssp = "SSP3", 
	    # price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
	    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
	    uncertainty = "full", # full, climate, values
	    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
	    iam = "high", 
	    model = "TINV_clim", 
	    adapt_scen = "fulladapt", 
	    clim_data = "GMFD", 
	    yearlist = as.character(seq(1980,2100,1)),  
	    spec = "OTHERIND_total_energy",
	    dollar_convert = "yes",
	    grouping_test = "semi-parametric"
    )

    if(!grepl("price", price)) {
        price_scen = paste0(price, "_", rcp)
    }else{
    	price_scen = price
    }

    plot_df = do.call(load.median, c(args, price_scen= price_scen)) %>% 
                        select(year, mean) %>% 
                        filter(year > 2009) 

    write_csv(plot_df, paste0(OUTPUT, '/projection_system_outputs/time_series_data/', 
    	'main_model-total_energy-SSP3-',rcp ,'-high-fulladapt-', price, '.csv'))   
}

rcps = c("rcp45", "rcp85")
pricelist = c("price0", "price03", "WITCHGLOBIOM42", 
	"MERGEETL60", "REMINDMAgPIE1730", "REMIND17CEMICS", "REMIND17") 

# Run across all price scenarios
options = expand.grid(rcp = rcps, price = pricelist)
mapply(get_df_by_price_rcp, price=options$price, rcp = options$rcp, SIMPLIFY = FALSE)




############################################################
# Slow adapt time series - ccsm 4 - extract a time series of global impacts-pc
########################## need rcp45? ##################################
      
# Note - we pull these impacts straight from the ncdf projection system output
      
get_file_name = function(type, fuel=NULL, double = NULL, histclim= NULL, rcp, dm = NULL) {
	
	if(!is.null(histclim)){
		histclim = "-histclim"
	}

	dir = paste0(OUTPUT,
  "/projection_system_outputs/single_projection/")

	if(type == "SA_single") {
		folder = paste0("single-OTHERIND_", fuel, "_FD_FGLS_1401_TINV_clim_GMFD_slow_adapt/", 
			rcp, "/CCSM4/high/SSP3/")
		name = paste0("FD_FGLS_inter_OTHERIND_", 
			fuel , "_TINV_clim")

		file = paste0(dir, folder, name, histclim, ".nc4")	
	}	
	if(type == "main_model_single") {
		folder_stem = paste0("median_OTHERIND_", fuel, "_TINV_clim")
		extra_folder_stem = paste0("_GMFD/median/",rcp,"/CCSM4/high/SSP3/")
		name = paste0("FD_FGLS_inter_OTHERIND_",  
			fuel, "_TINV_clim")

		file = paste0(dir, folder_stem, extra_folder_stem, name, histclim, ".nc4")	
	}	

	return(file)
}

get_long = function(file, pop_df, rcp) {

	print(paste0('opening file: ', file))
	nc <- nc_open(file)
	rebased = ncvar_get(nc, "rebased") %>%
			as.data.frame()
	yr = ncvar_get(nc, "year")
	region <- ncvar_get(nc, "regions") 

	colnames(rebased) = yr
	rebased$region = region

	print('reshaping and merging with population data (this might take a few seconds or so)')
	long = tidyr::gather(rebased, -region, key = "year", value = "rebased") %>%
		mutate(year = as.numeric(year)) %>%
		left_join(pop_df, by = c("region", "year")) %>%
		dplyr::filter(year >= 2010) %>%
		mutate(impact = rebased * pop) %>%
		group_by(year) %>%
		summarize(total_impact = sum(impact), pop = sum(pop)) %>%
		mutate(impact = total_impact/pop)
	print('closing nc')
	nc_close(nc)
	print('closed nc')
	return(long)
}
# function that takes the netcdf for each of the scenarios, and subtracts, passing back a df with FA
get_df = function(type, fuel=NULL, double=NULL, pop_df, rcp) {

	df_hist = get_file_name(type=type, fuel=fuel, double = double, histclim = "yes", rcp = rcp) %>%
			get_long(pop_df= pop_df) %>%
			rename(impact_hist = impact)

	df = get_file_name(type=type, fuel=fuel, double = double, histclim = NULL, rcp = rcp) %>%
			get_long(pop_df= pop_df) 

	df_fa = left_join(df, df_hist, by = "year") %>%
		mutate(fa_impact= impact - impact_hist) %>% 
		dplyr::filter(year >=2010) %>%
		mutate(year = as.numeric(year))

	return(df_fa)
}

join_df = function(type, pop_df, fuel){

	print('-------- rcp45 -----------')
	df_45 = get_df(type = type, pop_df= pop_df, fuel =fuel, rcp = "rcp45") %>%
		rename(rcp45 = fa_impact) 

	print('-------- rcp85 -----------')
	df_85 = get_df(type = type, pop_df= pop_df, fuel =fuel, rcp = "rcp85") %>%
		rename(rcp85 = fa_impact)

	df = left_join(df_45, df_85, by = "year") %>%
		select(year, rcp45, rcp85) %>%
		pivot_longer(-year, names_to = "rcp") %>%
		mutate(fuel = !!fuel)

	return(df)
}

save_csv_single = function(type, fuel, pop_df){
	
	df = join_df(type = type, pop_df = pop_df, fuel = fuel) %>%
		mutate(type = type) %>%
      mutate(mean = value ) %>%
      dplyr::select(-value)

	write_csv(df, paste0(OUTPUT, "/projection_system_outputs/time_series_data/CCSM4_single/",
		type,"-",fuel,"-SSP3-high-fulladapt-impact_pc.csv"))
}


pop_df = read_csv(paste0(OUTPUT,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv'))%>%
	group_by(region) %>%
	tidyr::complete(year = seq(2010,2100,1)) %>%
    fill(pop) %>%
    dplyr::select(region, year, pop)

save_csv_single(type = "SA_single", pop_df = pop_df, fuel = "other_energy")
save_csv_single(type = "SA_single", pop_df = pop_df, fuel = "electricity")
save_csv_single(type = "main_model_single", pop_df = pop_df, fuel = "other_energy")
save_csv_single(type = "main_model_single", pop_df = pop_df, fuel = "electricity")



############################################################
# lininter time series - for appendix figure I3
#######################done#####################################


get_plot_df = function(adapt="fulladapt", spec, rcp, model) {

# Set the general arguments for extraction
  args = list(
      conda_env = "risingverse-py27",
      proj_mode = '', # '' and _dm are the two options
      region = "global", # needs to be specified for 
      rcp = rcp, 
      ssp = "SSP3", 
      price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
      unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
      uncertainty = "climate", # full, climate, values
      geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
      iam = "high", 
      model = model, 
      adapt_scen = adapt, 
      clim_data = "GMFD", 
      dollar_convert = NULL, 
      yearlist = as.character(seq(2010,2099,1)),  
      spec = spec,
      grouping_test = "semi-parametric")

      df = do.call(load.median, args) %>% 
            select(year, mean)
      print('unit is going to be gigajoules per capita!')
      print(paste0('adaptation scenario is ', adapt))
      return(df)
}

df_full85_elec = get_plot_df(adapt = "fulladapt", 
	spec = "OTHERIND_electricity", rcp = "rcp85", model = "TINV_clim_lininter")
write_csv(df_full85_elec, 
	paste0(OUTPUT, '/projection_system_outputs/time_series_data/',
		'lininter_model-electricity-SSP3-rcp85-high-fulladapt-impact_pc.csv'))

df_full85_oe_elec = get_plot_df(adapt = "fulladapt", 
	spec = "OTHERIND_other_energy", rcp = "rcp85", model = "TINV_clim_lininter")
write_csv(df_full85_oe_elec, 
	paste0(OUTPUT, '/projection_system_outputs/time_series_data/',
		'lininter_model-other_energy-SSP3-rcp85-high-fulladapt-impact_pc.csv'))

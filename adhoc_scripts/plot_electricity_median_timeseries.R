
rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

user= 'liruixue'

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/pixel_interaction/'


dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
                    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

git = paste0("/home/", user,"/repos")

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(git,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0('/home/',user, '/repos/'))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

data = '/shares/gcp/social/parameters/energy_pixel_interaction/extraction/'

root =  "/home/liruixue/repos/energy-code-release-2020"
output = "/mnt/CIL_energy/pixel_interaction/projection_system_outputs/plot_single/"

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 
source(paste0(root, "/3_post_projection/0_utils/time_series.R"))


# figure 2C, but only for electricity point estimate

###############################################
# Get time series data for figure 2C
###############################################

# TO-DO: change back when both projections are run
# fuels = c("electricity", "other_energy")
fuels = c("electricity")

rcps = c("rcp85", "rcp45")
# adapt = c("fulladapt", "noadapt")
adapt = c("fulladapt")

options = expand.grid(fuels = fuels, rcps = rcps, adapt= adapt)

get_main_model_impacts_ts = function(fuel, rcp, adapt) {

	spec = paste0("OTHERIND_", fuel)
	names = c("mean")

	df = load.median(  
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
                    model = "TINV_clim", 
                    adapt_scen = adapt, 
                    clim_data = "GMFD", 
                    yearlist = as.character(seq(1980,2099,1)),  
                    spec = spec,
                    grouping_test = "semi-parametric")%>%
		dplyr::filter(year > 2009)
	
	write_csv(df, 
		paste0(output, '/projection_system_outputs/time_series_data/', 
			'main_model-', fuel, '-SSP3-',rcp, '-high-',adapt,'-impact_pc.csv'))
}

# Get the required dataframe - note this extracts for you if the csv doesn't exist
mcmapply(get_main_model_impacts_ts, 
  fuel= options$fuels, rcp= options$rcps, adapt=options$adapt)









#########################################
# 1. Figure 2C
# There are three functions needed for replicating this figure
    # "get.boxplot.vect" takes in a dataframe, and returns a vector of quantiles
    # "get_df_list_fig_2C" loads in the impacts projected data, and returns a formatted list of 
        # lines for plotting
    # "plot_ts_fig_2C" uses the above two functions, and the "time_series.R" code to 
        # replicate figure 2C


# Function that takes in the long data, subsets it and returns a list of dataframes 
# and vectors needed to plot the time series for a given fuel
get_df_list_fig_2C = function(data, fuel, rcp){
  
  # Load in the impacts data: 
  df= read_csv(glue(
    "{data}/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_{fuel}_TINV_clim_GMFD/SSP3-{rcp}_impactpc_median_high_fulladapt-aggregated.csv")) 
  df = df %>% filter(is.na(region)) %>% dplyr::select(c("year","mean"))
  # browser()
  return(df)
}

plot_df = get_df_list_fig_2C(data = data,fuel = "electricity", rcp = "rcp85")

# Plotting function, for replicating Figure 2C. Note - coloring in the paper requires 

# post processing in illustrator 
plot_ts_fig_2C = function(fuel, output, data, rcp){
  
  plot_df_85 = get_df_list_fig_2C(data = data,fuel = fuel, rcp = "rcp85")
  plot_df_45 = get_df_list_fig_2C(data = data,fuel = fuel, rcp = "rcp45")
  
  p <- ggtimeseries(
    df.list = list(plot_df_45 %>% as.data.frame(),
                   plot_df_85 %>% as.data.frame()
                   ),
    x.limits = c(2010, 2099),
    y.label = 'Hot and cold impacts: change in GJ/pc',
    legend.values = c("blue", "red"),
    legend.title = "RCP",
    rcp.value = 'rcp85', ssp.value = 'SSP3', iam.value = 'high',
    legend.breaks = c("RCP 45", "RCP 85"))+ 
  ggtitle(paste0(fuel, "-high","-SSP3","-mean"))   
  # browser()
  ggsave(paste0(output, "/fig_2C_", fuel, "_time_series.pdf"), p)
  return(p)
}

# p = plot_ts_fig_2C(data = data, fuel = "other_energy", output = output)
q = plot_ts_fig_2C(data = data, fuel = "electricity", output = output)





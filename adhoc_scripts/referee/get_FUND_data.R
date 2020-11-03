rm(list = ls())
library(dplyr)
library(reticulate)
library(miceadds)
library(ggplot2)
library(RColorBrewer)
cilpath.r:::cilpath()

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# source needed codes and set up paths
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")

source(paste0(REPO,"/energy-code-release-2020/3_post_projection/0_utils/time_series.R"))
miceadds::source.all(paste0(projection.packages,"load_projection/"))

get_fund_df = function(region, rcp, fuel, adapt_scen, year) {

		print(paste0('------------------------------', region, '------------------------------'))
		args = list(
		    conda_env = "risingverse-py27",
		    proj_mode = '', # '' and _dm are the two options
		    # region = "global", # needs to be specified for 
		    rcp = rcp, 
		    ssp = "SSP3", 
		    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
		    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
		    uncertainty = "climate", # full, climate, values
		    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
		    iam = "high", 
		    model = "TINV_clim", 
		    adapt_scen = adapt_scen, 
		    clim_data = "GMFD", 
		    dollar_convert = NULL, 
		    yearlist = year,  
		    spec = fuel,
		    grouping_test = "semi-parametric")

	    plot_df = do.call(load.median, c(args, region = region)) %>% 
	                        select(year, mean)
	    # names(plot_df) = c("year", region)
	    return(plot_df)
}

df = get_fund_df(region = "FUND-CAM", rcp = "rcp85", fuel = "OTHERIND_electricity", 
	adapt_scen = "noadapt", year = 2099)




rm(list = ls())
library(dplyr)
library(reticulate)
library(miceadds)
library(ggplot2)
library(tidyverse)
library(RColorBrewer)
cilpath.r:::cilpath()

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# source needed codes and set up paths
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")

source(paste0(REPO,"/energy-code-release-2020/3_post_projection/0_utils/time_series.R"))
miceadds::source.all(paste0(projection.packages,"load_projection/"))


get_df = function(region, rcp, fuel, price_scen = NULL, unit = "impactpc") {

	print(paste0('------------------------------', region, '------------------------------'))

	args = list(
	    conda_env = "risingverse-py27",
	    proj_mode = '', # '' and _dm are the two options
	    # region = "global", # needs to be specified for 
	    rcp = rcp, 
	    ssp = "SSP3", 
	    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
	    unit = unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
	    uncertainty = "climate", # full, climate, values
	    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
	    iam = "high", 
	    model = "TINV_clim", 
	    adapt_scen = "fulladapt", 
	    clim_data = "GMFD", 
	    dollar_convert = NULL, 
	    yearlist = as.character(seq(1980,2100,1)),  
	    spec = fuel,
	    grouping_test = "semi-parametric")

    plot_df = do.call(load.median, c(args, region = region)) %>% 
                        dplyr::select(year, mean)
    # names(plot_df) = c("year", region)
    return(plot_df)
}
# df = get_fund_df(region = "FUND-CAM", rcp = "rcp85", fuel = "OTHERIND_electricity", 
# 	adapt_scen = "noadapt", year = 2099)
aggregated_regions = c("FUND-ANZ", "FUND-CAM", "FUND-CAN", "FUND-CHI", "FUND-EEU", "FUND-FSU", "FUND-JPK", "FUND-LAM", "FUND-MAF", "FUND-MDE", "FUND-SAS", "FUND-SEA", "FUND-SIS", "FUND-SSA", "FUND-USA", "FUND-WEU")
df = mapply(get_df, region = aggregated_regions, rcp = "rcp85", unit = "damage", price_scen = "price014", fuel = "OTHERIND_total_energy", SIMPLIFY = FALSE)
FUND_ours = do.call(rbind, c(df, make.row.names = TRUE))
FUND_ours$regions = rownames(FUND_ours)
rownames(FUND_ours) = NULL
FUND_ours$regions = substr(FUND_ours$regions, 6,8)

head(FUND_ours)

FUND_cooling = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_cooling.csv"))
FUND_heating = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_heating.csv"))

FUND = merge(FUND_cooling, FUND_heating, by = c("time","regions")) %>% 
	mutate(fund_total = cooling + heating) %>%
	group_by(time) %>%
	rename(year = time) %>% 
	filter(year <= 2100, year >= 1981)
head(FUND)

combined = merge(FUND_ours, FUND, by = c("regions", "year")) %>% 
	mutate(mean = mean / 1000000000)



	

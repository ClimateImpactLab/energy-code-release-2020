rm(list = ls())
library(dplyr)
library(reticulate)
library(miceadds)
library(ggplot2)
library(tidyverse)
library(RColorBrewer)
library(parallel)
cilpath.r:::cilpath()

library(ggrepel)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")


source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# source needed codes and set up paths
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")

source(paste0(REPO,"/energy-code-release-2020/3_post_projection/0_utils/time_series.R"))
miceadds::source.all(paste0(projection.packages,"load_projection/"))


# plot_adapt = function(adapt = "fulladapt") {
# 	get_df = function(region, rcp, fuel, price_scen = NULL, unit = "impactpc", dollar_convert = NULL, adapt = adapt) {
# 		print(paste0('------------------------------', region, '------------------------------'))
# 		args = list(
# 		    conda_env = "risingverse-py27",
# 		    proj_mode = '', # '' and _dm are the two options
# 		    # region = "global", # needs to be specified for 
# 		    rcp = rcp, 
# 		    ssp = "SSP3", 
# 		    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
# 		    unit = unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
# 		    uncertainty = "climate", # full, climate, values
# 		    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
# 		    iam = "high", 
# 		    model = "TINV_clim", 
# 		    adapt_scen = adapt, 
# 		    clim_data = "GMFD", 
# 		    dollar_convert = dollar_convert, 
# 		    yearlist = as.character(seq(1980,2100,1)),  
# 		    spec = fuel,
# 		    grouping_test = "semi-parametric")

# 	    plot_df = do.call(load.median, c(args, region = region)) %>% 
# 	                        dplyr::select(year, mean)
# 	    # names(plot_df) = c("year", region)
# 	    return(plot_df)
# 	}

# 	# load the file used in mortality for dollar conversion
# 	# this value is not used for the %gdp calculation
# 	file_fed = read_csv('/shares/gcp/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv')
# 	convert_1995_to_2019 = (file_fed %>% filter(year == 2019))$gdpdef / (file_fed %>% filter(year == 1995))$gdpdef 


# 	# SSP3
# 	aggregated_regions = c("FUND-ANZ", "FUND-CAM", "FUND-CAN", "FUND-CHI", "FUND-EEU", "FUND-FSU", "FUND-JPK", "FUND-LAM", "FUND-MAF", "FUND-MDE", "FUND-SAS", "FUND-SEA", "FUND-SIS", "FUND-SSA", "FUND-USA", "FUND-WEU")
# 	df = mapply(get_df, region = aggregated_regions, adapt = adapt, rcp = "rcp85", unit = "damage", price_scen = "price014", fuel = "OTHERIND_total_energy", dollar_convert = "yes", SIMPLIFY = FALSE)
# 	FUND_ours = do.call(rbind, c(df, make.row.names = TRUE))
# 	FUND_ours$regions = rownames(FUND_ours)
# 	rownames(FUND_ours) = NULL
# 	FUND_ours$regions = substr(FUND_ours$regions, 6,8)
# 	FUND_ours = FUND_ours %>% filter(year == 2099)


# 	# FUND
# 	FUND_cooling = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_cooling.csv"))
# 	FUND_heating = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_heating.csv"))

# 	FUND = merge(FUND_cooling, FUND_heating, by = c("time","regions")) %>% 
# 		mutate(fund_total = (cooling + heating)) %>%
# 		rename(year = time) 

# 	# rebase fund data
# 	FUND_rebaser = FUND %>% filter(year >= 2001, year <= 2010) %>%
# 	 	group_by(regions) %>%
# 	 	summarise(rebaser = mean(fund_total))

# 	FUND_rebased = merge(FUND, FUND_rebaser, by = "regions") %>% 
# 		filter(year == 2099) %>%
# 		mutate(fund_total = -(fund_total - rebaser) * convert_1995_to_2019)%>%
# 		select(year, regions, fund_total) 

# 	# plot
# 	plot_df = merge(FUND_rebased, FUND_ours, by = c("year", "regions"))

# 	p = ggplot(plot_df, aes(x = mean, y = fund_total)) + 
# 		geom_point() + 
# 		geom_abline(intercept = 0, slope = 1) +
# 		geom_text_repel(label = plot_df$regions, size = 6)
		

# 	ggsave(p, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_vs_SSP3_scatterplot_{adapt}.pdf'))

# 	# showing %GDP

# 	# load world GDP for SSP3 and FUND

# 	macro_regions = read_csv("/shares/gcp/regions/macro-regions.csv", skip = 37) %>% 
# 		select(`region-key`, FUND) %>%
# 		rename(iso = `region-key`)

# 	macro_regions

# 	df_gdp = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/', 
# 		'SSP3-high-IR_level-gdppc_pop-2099.csv')) %>%
# 		select(region, gdp99) %>%
# 		mutate(iso = substr(region, 1, 3)) %>%
# 		group_by(iso) %>%
# 		summarize(country_gdp = sum(gdp99))

# 	df_gdp = merge(df_gdp, macro_regions, by = "iso") %>%
# 		group_by(FUND) %>%
# 		summarize(region_gdp = sum(country_gdp))  %>%
# 		rename(regions = FUND)



# 	df_gdp_fund = read_csv(paste0(REPO,"/energy-code-release-2020/data/", 
# 	                       "/FUND_GDP_bn1995USD.csv")) %>% 
# 				rename(year = time) %>% 
# 				dplyr::filter(year ==2099)

# 	# calculate percentage GDP
# 	FUND_all = merge(FUND_rebased, df_gdp_fund, by = c("year","regions")) %>%
# 			mutate(percent_gdp_fund = fund_total / income / convert_1995_to_2019 * 100)


# 	SSP3_all = merge(FUND_ours , df_gdp, by ="regions" ) %>%
# 			mutate(percent_gdp_ssp3 = mean * 1000000000 / 0.0036 / region_gdp * 100)


# 	plot_df_gdp = merge(FUND_all, SSP3_all, by = c("regions"))

# 	p = ggplot(plot_df_gdp, aes(x = percent_gdp_ssp3, y = percent_gdp_fund)) + 
# 		geom_point() +
# 		geom_abline(intercept = 0, slope = 1) +
# 		geom_text_repel(label = plot_df_gdp$regions, size = 6)
# 	p	

# 	ggsave(p, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_vs_SSP3_scatterplot_percent_gdp_{adapt}.pdf'))
# }

# plot_adapt("fulladapt")
# plot_adapt("noadapt")
# plot_adapt("incadapt")



# plot all three adaptations on the same plot

get_df = function(region, rcp, fuel, price_scen = NULL, unit = "impactpc", dollar_convert = NULL, adapt = adapt) {

	print(paste0('------------------------------', region, '------------------------------'))

	# browser()

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
	    adapt_scen = as.character(adapt), 
	    clim_data = "GMFD", 
	    dollar_convert = dollar_convert, 
	    yearlist = 2099,  
	    spec = fuel,
	    grouping_test = "semi-parametric")

    plot_df = do.call(load.median, c(args, region = as.character(region)))  %>% 
                        dplyr::select(year, mean)

    plot_df$adapt = as.character(adapt)
    plot_df$regions = as.character(region)
    
    # names(plot_df) = c("year", region)
    return(plot_df)

}

# load the file used in mortality for dollar conversion
# this value is not used for the %gdp calculation
file_fed = read_csv('/shares/gcp/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv')
convert_1995_to_2019 = (file_fed %>% filter(year == 2019))$gdpdef / (file_fed %>% filter(year == 1995))$gdpdef 


# SSP3
aggregated_regions = c("FUND-ANZ", "FUND-CAM", "FUND-CAN", "FUND-CHI", "FUND-EEU", "FUND-FSU", "FUND-JPK", "FUND-LAM", "FUND-MAF", "FUND-MDE", "FUND-SAS", "FUND-SEA", "FUND-SIS", "FUND-SSA", "FUND-USA", "FUND-WEU")
adapt = c("fulladapt","noadapt","incadapt")
args = expand.grid(region = aggregated_regions, adapt = adapt)

df = mapply(get_df, region = args$region, adapt = args$adapt, rcp = "rcp85", unit = "damage", price_scen = "price014", fuel = "OTHERIND_total_energy", dollar_convert = "yes", SIMPLIFY = FALSE)

FUND_ours = do.call(rbind, c(df, make.row.names = TRUE))
# FUND_ours$regions = rownames(FUND_ours)
# rownames(FUND_ours) = NULL
FUND_ours$regions = substr(FUND_ours$regions, 6,8)
FUND_ours = FUND_ours %>% filter(year == 2099)


# FUND
FUND_cooling = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_cooling.csv"))
FUND_heating = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_heating.csv"))

FUND = merge(FUND_cooling, FUND_heating, by = c("time","regions")) %>% 
	mutate(fund_total = (cooling + heating)) %>%
	rename(year = time) 

# rebase fund data
FUND_rebaser = FUND %>% filter(year >= 2001, year <= 2010) %>%
 	group_by(regions) %>%
 	summarise(rebaser = mean(fund_total))

FUND_rebased = merge(FUND, FUND_rebaser, by = "regions") %>% 
	filter(year == 2099) %>%
	mutate(fund_total = -(fund_total - rebaser) * convert_1995_to_2019)%>%
	select(year, regions, fund_total) 

# plot
plot_df = merge(FUND_rebased, FUND_ours, by = c("year", "regions"), all.y = TRUE)

p = ggplot(plot_df, aes(x = mean, y = fund_total, color = adapt)) + 
	geom_point() + 
	geom_abline(intercept = 0, slope = 1) +
	geom_text_repel(label = plot_df$regions, size = 6)
p	

ggsave(p, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_vs_SSP3_scatterplot_all_scenarios.pdf'))

# showing %GDP
# load world GDP for SSP3 and FUND

macro_regions = read_csv("/shares/gcp/regions/macro-regions.csv", skip = 37) %>% 
	select(`region-key`, FUND) %>%
	rename(iso = `region-key`)

macro_regions

df_gdp = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/', 
	'SSP3-high-IR_level-gdppc_pop-2099.csv')) %>%
	select(region, gdp99) %>%
	mutate(iso = substr(region, 1, 3)) %>%
	group_by(iso) %>%
	summarize(country_gdp = sum(gdp99))

df_gdp = merge(df_gdp, macro_regions, by = "iso") %>%
	group_by(FUND) %>%
	summarize(region_gdp = sum(country_gdp))  %>%
	rename(regions = FUND)



df_gdp_fund = read_csv(paste0(REPO,"/energy-code-release-2020/data/", 
                       "/FUND_GDP_bn1995USD.csv")) %>% 
			rename(year = time) %>% 
			dplyr::filter(year ==2099)

# calculate percentage GDP
FUND_all = merge(FUND_rebased, df_gdp_fund, by = c("year","regions")) %>%
		mutate(percent_gdp_fund = fund_total / income / convert_1995_to_2019 * 100)


SSP3_all = merge(FUND_ours , df_gdp, by ="regions" ) %>%
		mutate(percent_gdp_ssp3 = mean * 1000000000 / 0.0036 / region_gdp * 100)


plot_df_gdp = merge(FUND_all, SSP3_all, by = c("regions"))

p = ggplot(plot_df_gdp, aes(x = percent_gdp_ssp3, y = percent_gdp_fund, color = adapt)) + 
	geom_point() +
	geom_abline(intercept = 0, slope = 1) +
	geom_abline(intercept = 0, slope = 0) +
	geom_vline(xintercept = 0)+
	geom_text_repel(label = plot_df_gdp$regions, size = 6)
p	

ggsave(p, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_vs_SSP3_scatterplot_percent_gdp_all_scenarios.pdf'))


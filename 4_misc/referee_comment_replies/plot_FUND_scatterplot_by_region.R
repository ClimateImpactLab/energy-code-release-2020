# plot fund vs projected impacts 
# with regions on the x axis, and impacts on y axis
rm(list = ls())
library(dplyr)
library(reticulate)
library(miceadds)
library(ggplot2)
library(tidyverse)
# library(RColorBrewer)
library(parallel)
cilpath.r:::cilpath()
library(ggrepel)
library(reshape2)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
REPO <- "/home/liruixue/repos"
source(glue("{REPO}/mortality/utils/wrap_mapply.R"))
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# source needed codes and set up paths
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")

source(paste0(REPO,"/energy-code-release-2020/3_post_projection/0_utils/time_series.R"))
miceadds::source.all(paste0(projection.packages,"load_projection/"))


# plot all three adaptations on the same plot

get_df = function(region, rcp, fuel, price_scen = NULL, unit = "impactpc", dollar_convert = NULL, adapt = adapt) {

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
	    adapt_scen = as.character(adapt), 
	    clim_data = "GMFD", 
	    dollar_convert = dollar_convert, 
	    yearlist = 2099,  
	    spec = fuel,
	    grouping_test = "semi-parametric",
	    regenerate = FALSE)

    plot_df = do.call(load.median, args) 

    plot_df = plot_df %>% 
    	 filter(region == !!region) %>% dplyr::select(year,region, mean, q5, q95) 

    plot_df$adapt = as.character(adapt)
    plot_df$regions = as.character(region)
    
    return(plot_df)

}

# load the file used in mortality for dollar conversion
# this value is not used for the %gdp calculation
file_fed = read_csv('/shares/gcp/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv')
convert_1995_to_2019 = (file_fed %>% filter(year == 2019))$gdpdef / (file_fed %>% filter(year == 1995))$gdpdef 
convert_2005_to_2019 = (file_fed %>% filter(year == 2019))$gdpdef / (file_fed %>% filter(year == 2005))$gdpdef 


# SSP3
aggregated_regions = c("FUND-ANZ", "FUND-CAM", "FUND-CAN", "FUND-CHI", "FUND-EEU", "FUND-FSU", "FUND-JPK", "FUND-LAM", "FUND-MAF", "FUND-MDE", "FUND-SAS", "FUND-SEA", "FUND-SIS", "FUND-SSA", "FUND-USA", "FUND-WEU")
adapt = c("fulladapt","noadapt","incadapt")
args = expand.grid(region = aggregated_regions, adapt = adapt)

df = wrap_mapply(
	FUN = get_df, 
	region = aggregated_regions,
	adapt = adapt, 
	rcp = "rcp85", 
	unit = "damage", 
	price_scen = "price014", 
	fuel = "OTHERIND_total_energy", 
	dollar_convert = "yes", 
	mc.cores = 16,
	SIMPLIFY = FALSE)

FUND_ours = do.call(rbind, c(df, make.row.names = TRUE))
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
	group_by(FUND) 	%>% 
	summarize(region_gdp = sum(country_gdp)) %>%
	rename(regions = FUND)

# df_gdp$region_name = df_gdp$regions

df_gdp$regions_name = c("","Australia and New Zealand",
	"Central America",
	"Canada",
	"China plus",
	"Central and Eastern Europe",
	"Former Soviet Union",
	"Japan and South Korea",
	"Latin America",
	"North Africa",
	"Middle East",
	"South Asia",
	"Southeast Asia",
	"Small Island States",
	"Sub-Saharan Africa",
	"USA",
	"Western Europe")


df_gdp_fund = read_csv(paste0(REPO,"/energy-code-release-2020/data/", 
                       "/FUND_GDP_bn1995USD.csv")) %>% 
			rename(year = time) %>% 
			dplyr::filter(year ==2099)

# calculate percentage GDP
FUND_all = merge(FUND_rebased, df_gdp_fund, by = c("year","regions")) %>%
		mutate(percent_gdp_fund = fund_total / income / convert_1995_to_2019 * 100)


SSP3_all = merge(FUND_ours , df_gdp, by ="regions" ) %>%
		mutate(percent_gdp_ssp3 = mean * 1000000000 / 0.0036 / region_gdp * 100,
			percent_gdp_ssp3_q5 = q5 * 1000000000 / 0.0036 / region_gdp * 100,
			percent_gdp_ssp3_q95 = q95 * 1000000000 / 0.0036 / region_gdp * 100)


plot_df_gdp = merge(FUND_all, SSP3_all, by = c("regions"))



df = plot_df_gdp %>% select(percent_gdp_fund, percent_gdp_ssp3, percent_gdp_ssp3_q5, percent_gdp_ssp3_q95, adapt, regions,regions_name) 


df_long = df %>% gather(var, pct_gdp, -c(regions_name, adapt, regions))

cols <- c("FUND" = "maroon", "fulladapt" = "steelblue4", "incadapt" = "steelblue3", "noadapt" = "steelblue2")


p_bar = ggplot(df, aes(x = regions_name)) +
	geom_bar(aes(weight = percent_gdp_ssp3,fill = "fulladapt"), 
		data = df %>% filter(adapt == "fulladapt"),
		position = position_nudge(x = -0.1), width = 0.1) +
    geom_errorbar(
	    data = df %>% filter(adapt == "fulladapt"),  
	    aes(x=regions_name, ymin = percent_gdp_ssp3_q5, 
	    	ymax = percent_gdp_ssp3_q95), 
	   	size =0.2, width = 0.08,
	   	position = position_nudge(x = -0.1)) +
	geom_bar(aes(weight = percent_gdp_ssp3,fill = "incadapt"), 
		data = df %>% filter(adapt == "incadapt"),
		position = position_nudge(x = 0), width = 0.1) +
	geom_errorbar(
	    data = df %>% filter(adapt == "incadapt"),  
	    aes(x=regions_name, ymin = percent_gdp_ssp3_q5, 
	    	ymax = percent_gdp_ssp3_q95), 
	   	size =0.2, width = 0.08,
	   	position = position_nudge(x = 0)) +
	geom_bar(aes(weight = percent_gdp_ssp3,fill = "noadapt"), 
		data = df %>% filter(adapt == "noadapt"),
		position = position_nudge(x = 0.1), width = 0.1) +
    geom_errorbar(
	    data = df %>% filter(adapt == "noadapt"),  
	    aes(x=regions_name, ymin = percent_gdp_ssp3_q5, 
	    	ymax = percent_gdp_ssp3_q95), 
	   	size =0.2, width = 0.08,
	   	position = position_nudge(x = 0.1)) +
	geom_bar(aes(weight = percent_gdp_fund,fill = "FUND"), 
		data = df %>% filter(adapt == "incadapt"),
		position = position_nudge(x = 0.2), width = 0.1) + 
    scale_x_discrete(labels = function(x) str_wrap(x, width = 8)) + 
	scale_fill_manual(limits = c("fulladapt","incadapt","noadapt", "FUND"), 
		values = cols, name = NULL) + 
	theme_bw() + 
	theme(panel.border = element_blank(), panel.grid.major = element_blank(),
	panel.grid.minor = element_blank(), axis.line = element_line(colour = "black"))+
	geom_hline(yintercept = 0)

p_bar


ggsave(p_bar, file = glue('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_vs_SSP3_barplot_percent_gdp_all_scenarios.pdf'),
	width = 10, height = 6)


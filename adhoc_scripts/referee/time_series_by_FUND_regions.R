# plot time series of damages, by IAM

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

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")


# a function to get data for each fund region
# define a function to allow us to do a mapply festival 

get_df = function(region, rcp, fuel, price_scen = NULL, unit = "impactpc", dollar_convert = NULL) {
	print(paste0('------------------------------', region, '------------------------------'))

	args = list(
	    conda_env = "risingverse-py27",
	    proj_mode = '', # '' and _dm are the two options
	    # region = "global", # needs to be specified for 
	    rcp = rcp, 
	    ssp = "SSP3", 
	    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
	    unit = unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
	    uncertainty = "full", # full, climate, values
	    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
	    iam = "high", 
	    model = "TINV_clim", 
	    adapt_scen = "fulladapt", 
	    clim_data = "GMFD", 
	    dollar_convert = dollar_convert, 
	    yearlist = as.character(seq(1980,2100,1)),  
	    spec = fuel,
	    grouping_test = "semi-parametric")

    plot_df = do.call(load.median, c(args, region = region)) %>% 
                        dplyr::select(year, mean)
    return(plot_df)
}



# global FUND vs our main results in %GDP

# load world GDP for SSP3 and FUND
df_gdp = read_csv(paste0(DB_data, '/projection_system_outputs/covariates/', 
                       "/SSP3-global-gdp-time_series.csv"))

df_gdp_fund = read_csv(paste0(REPO,"/energy-code-release-2020/data/", 
                       "/FUND_GDP_bn1995USD.csv")) %>% 
			group_by(time) %>%
			summarise(gdp= sum(income)) %>%
			rename(year = time) %>% 
			dplyr::filter(year >= 2001, year <= 2100)

# load the file used in mortality for dollar conversion
# this value is not used for the %gdp calculation
file_fed = read_csv('/shares/gcp/estimation/mortality/release_2020/data/3_valuation/inputs/adjustments/fed_income_inflation.csv')
convert_1995_to_2019 = (file_fed %>% filter(year == 2019))$gdpdef / (file_fed %>% filter(year == 1995))$gdpdef 



# load projected impacts in billion of 2019 dollar
total_rcp85 = get_df(rcp = "rcp85", region = c("global"), fuel = "OTHERIND_total_energy", price_scen = "price014", unit = "damage", dollar_convert = TRUE) %>% 
				dplyr::select(year, mean)
total_rcp45 = get_df(rcp = "rcp45", region = c("global"), fuel = "OTHERIND_total_energy", price_scen = "price014", unit = "damage", dollar_convert = TRUE) %>%
				dplyr::select(year, mean)


# calcualte percent gdp for SSP3 impacts
df_85 = total_rcp85 %>%
  left_join(df_gdp, by = "year") %>% 
  mutate(mean = mean * 1000000000) %>% #convert from billions of dollars 
  mutate(percent_gdp = (mean/gdp) *100 / 0.0036) %>% 
  dplyr::select(year, percent_gdp)

df_45 = total_rcp45 %>%
  left_join(df_gdp, by = "year") %>% 
  mutate(mean = mean * 1000000000) %>% #convert from billions of dollars 
  mutate(percent_gdp = (mean/gdp) *100 / 0.0036) %>% 
  dplyr::select(year, percent_gdp)

# load FUND impacts in billion 1995 dollar
FUND_cooling = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_cooling.csv"))
FUND_heating = read_csv(paste0(REPO,"/energy-code-release-2020/data/", "FUND_impacts_bn1995USD_heating.csv"))

# sum cooling and heating
FUND_sum = merge(FUND_cooling, FUND_heating, by = c("time","regions")) %>% 
	mutate(total_energy = cooling + heating) %>%
	group_by(time) %>%
	summarise(mean= sum(total_energy)) %>%
	rename(year = time) %>% 
	filter(year <= 2100, year >= 2001)

# calculate rebaser
rebaser <- with(FUND_sum, mean(mean[year >= 2001 & year <= 2010]) )

# calculate % GDP for FUND impacts
df_fund = FUND_sum %>%
  left_join(df_gdp_fund, by = "year") %>% 
  mutate(mean = mean - rebaser) %>% #convert from billions of dollars 
  mutate(percent_gdp = -(mean/gdp) *100)  %>% 
  dplyr::select(year, percent_gdp)


# plot
getPalette = colorRampPalette(brewer.pal(9, "Set1"))
p <- ggtimeseries(df.list = list(df_45 %>% as.data.frame() , 
                df_85 %>% as.data.frame(),
                df_fund %>% as.data.frame()), 
                  df.x = "year",
                  x.limits = c(2010, 2100),                               
                  # y.limits=c(-0.8,0.2),
                  y.label = "%GDP", 
                  legend.title = "Model", 
                  legend.breaks = c("rcp45","rcp85","FUND"), 
                  legend.values = getPalette(3),
                  rcp.value = "rcp85", ssp.value = "SSP3", iam.value = "high") 

ggsave(p, file = '/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_global_time_series.pdf')




################################ old code by tom, no need to review for now ###################################

# args = list(
#     conda_env = "risingverse-py27",
#     proj_mode = '', # '' and _dm are the two options
#     region = "global", # needs to be specified for 
#     rcp = "rcp85", 
#     ssp = "SSP3", 
#     price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
#     unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
#     uncertainty = "climate", # full, climate, values
#     geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
#     # iam = "high", 
#     model = "TINV_clim", 
#     adapt_scen = "fulladapt", 
#     clim_data = "GMFD", 
#     dollar_convert = "yes", 
#     yearlist = as.character(seq(1980,2100,1)),  
#     spec = "OTHERIND_total_energy",
#     grouping_test = "semi-parametric")

# args$iam = "high"
# df_high = do.call(load.median, args) %>% dplyr::select(year, mean)

# args$iam = "low"
# df_low = do.call(load.median, args) %>% dplyr::select(year, mean)

# p <- ggtimeseries(df.list = list(df_high, df_low), 
#                               df.x = "year",
#                               x.limits = c(2010, 2100),                               
#                               # y.limits=c(-0.8,0.2),
#                               y.label = "Total Damages, Billions of 2019 dollars", 
#                               legend.title = "Iam", legend.breaks = c("high", "low"), 
#                               legend.values = c('blue', 'red'))
# p




# plot_funds = function(rcp, aggregated_regions, fuel) {

# 	df = mapply(get_df, region = aggregated_regions, rcp = rcp, fuel = fuel, SIMPLIFY = FALSE)

# 	# Get the required number of colors for plotting in the legend 
# 	print('getting colors')
# 	colourCount = length(aggregated_regions)
# 	getPalette = colorRampPalette(brewer.pal(9, "Set1"))
# 	print('plotting')
# 	p <- ggtimeseries(df.list = df, 
# 	                              df.x = "year",
# 	                              x.limits = c(2010, 2100),                               
# 	                              # y.limits=c(-0.8,0.2),
# 	                              y.label = paste0(fuel, " impactpc"), 
# 	                              legend.title = "FUND-Region", 
# 	                              legend.breaks = aggregated_regions, 
# 	                              legend.values = getPalette(colourCount),
# 	                              rcp.value = rcp, ssp.value = "SSP3", iam.value = "high") 
# 	p
# 	return(p)
# }


# aggregated_regions = c("global", "FUND-ANZ", "FUND-CAM", "FUND-CAN", "FUND-CHI", "FUND-EEU", "FUND-FSU", "FUND-JPK", "FUND-LAM", "FUND-MAF", "FUND-MDE", "FUND-SAS", "FUND-SEA", "FUND-SIS", "FUND-SSA", "FUND-USA", "FUND-WEU")
# x = plot_funds(rcp = "rcp85", aggregated_regions = aggregated_regions, fuel = "OTHERIND_other_energy")
# ggsave(x, file = '/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_other_energy_impactpc.png')
# y = plot_funds(rcp = "rcp85", aggregated_regions = aggregated_regions, fuel = "OTHERIND_electricity")
# ggsave(y, file = '/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/FUND_elec_impactpc.png')

# # get a csv of the damages, for ashwin: 
# get_and_name = function(rcp, region) {
# 	args = list(
# 		    conda_env = "risingverse-py27",
# 		    proj_mode = '', # '' and _dm are the two options
# 		    # region = "global", # needs to be specified for 
# 		    rcp = rcp, 
# 		    ssp = "SSP3", 
# 		    price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
# 		    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
# 		    uncertainty = "climate", # full, climate, values
# 		    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
# 		    iam = "high", 
# 		    model = "TINV_clim", 
# 		    adapt_scen = "fulladapt", 
# 		    clim_data = "GMFD", 
# 		    dollar_convert = "yes", 
# 		    yearlist = as.character(seq(1980,2100,1)),  
# 		    spec = "OTHERIND_total_energy",
# 		    grouping_test = "semi-parametric")
	
# 	df = do.call(load.median, c(args, region = region)) %>% 
# 	                        dplyr::select(mean)
# 	names(df) = c(region)
# 	return(df)
# }

# save_csv = function(rcp) {
# 	df = mapply(get_and_name, region = aggregated_regions, rcp = "rcp45", SIMPLIFY = FALSE) %>%
# 			bind_cols()
# 	df$year = seq(1981,2100,1)
# 	write_csv(df, paste0('/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/FUND/damages-price014-',
# 		rcp, 'total_energy-SSP3-high.csv'))
# 	return(df)
# }
# y = save_csv(rcp = "rcp45")
# z = save_csv(rcp = "rcp85")




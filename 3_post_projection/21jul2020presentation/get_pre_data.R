

# Rae liruixue@uchicago.edu
# 10 jul 2020
# to extract time series data for all climate models as percentage gdp
# similar to figure 3B


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
source("imgcat.R")

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools,
               RColorBrewer)




user= 'liruixue'

db = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/'
output = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data/'
dir = paste0('/shares/gcp/social/parameters/energy/extraction/',
                    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Set paths
git = paste0("/home/", user,"/repos")
# Source time series plotting codes
source(paste0(git, "/energy-code-release-2020/3_post_projection/0_utils/time_series.R"))



# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(git,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0('/home/',user, '/repos/'))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

# get damages 
df_dmg = load.median(conda_env = "risingverse-py27",
               proj_mode = '', # '' and _dm are the two options
               region = "global", # needs to be specified for 
               # rcp = "rcp45", 
               ssp = "SSP3", 
               price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
               unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
               uncertainty = "values", # full, climate, values
               geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
               # iam = "high", 
               model = "TINV_clim_income_spline", 
               adapt_scen = "fulladapt", 
               clim_data = "GMFD", 
               yearlist = as.character(seq(2010,2099,1)),  
               spec = "OTHERIND_total_energy",
               dollar_convert = "yes",
               grouping_test = "semi-parametric") %>%
	dplyr::select(year, rcp, iam, gcm, value) %>%
	dplyr::filter(iam == "high")


write_csv(df_dmg, 
	paste0(output, '/projection_system_outputs/21jul2020_pre_data/', 
		'main_model-', "OTHERIND_total_energy", '-SSP3-high-fulladapt-',"price014" ,'-2010_2099-damages-timeseries.csv'))

# get GDP
df_gdp = read_csv(paste0(output, '/projection_system_outputs/covariates/', 
                      "/SSP3-global-gdp-time_series.csv"))

# convert damage to percent GDP
df_pct = df_dmg %>% 
     dplyr::left_join(df_gdp, by = "year")%>% 
     dplyr::mutate(value = value * 1000000000) %>% #convert from billions of dollars 
     dplyr::mutate(percent_gdp = (value/gdp)*100) %>%
     dplyr::select(year, gcm, rcp, value, percent_gdp) %>%
     dplyr::rename(damage = value)


write_csv(df_pct, 
     paste0(output, '/projection_system_outputs/21jul2020_pre_data/', 
          'main_model-', "OTHERIND_total_energy", '-SSP3-high-fulladapt-',"price014" ,'-2010_2099-pct-gdp-timeseries.csv'))

DB_data = output

# get anomalies
GMST_anom <- read_csv(glue("{DB_data}/projection_system_outputs/damage_function_estimation/GMTanom_all_temp_2001_2010.csv"))
GMST_anom <- GMST_anom %>% dplyr::filter(year == 2099) %>% dplyr::select(-year)

df_pct <- merge(df_pct, GMST_anom, by = c("gcm","rcp"))

# plot it like figure 3B

#########################################
# 2. Figure 3B

# Load in the impacts data
df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                   'main_model-total_energy-SSP3-rcp45-high-fulladapt-price014.csv'))%>% 
mutate(rcp = "rcp45") %>% 
bind_rows(
 read_csv(paste0(DB_data, '/projection_system_outputs/time_series_data/', 
                 'main_model-total_energy-SSP3-rcp85-high-fulladapt-price014.csv')) %>% 
   mutate(rcp = "rcp85")
)

# Get separate dataframes for rcp45 and rcp85, for plotting
format_df = function(rcp, df_impacts, df_gdp){
     df = df_impacts %>% 
      dplyr::filter(rcp == !!rcp) %>% 
      left_join(df_gdp, by = "year")%>% 
      mutate(mean = mean * 1000000000, q95 = q95 *1000000000 , q5 = q5* 1000000000) %>% #convert from billions of dollars 
      mutate(percent_gdp = (mean/gdp) *100, 
             ub = (q95/gdp) *100, 
             lb = (q5/gdp) *100)

     df_mean = df %>% 
      dplyr::select(year, percent_gdp)

     return(list(df, df_mean))
}



df_45 = format_df(rcp = 'rcp45', df_impacts= df_impacts, df_gdp = df_gdp)
df_85 = format_df(rcp = 'rcp85', df_impacts= df_impacts, df_gdp = df_gdp)
unique_gcms = unique(df_dmg[['gcm']])


df_pct_45 <- df_pct %>% 
      dplyr::filter(rcp == "rcp45")
df_pct_85 <- df_pct %>% 
      dplyr::filter(rcp == "rcp85")

max_anom_45 <- max(df_pct_45$temp)
max_anom_85 <- max(df_pct_85$temp)


# standardize alpha values to 0-1
df_pct_45$alpha_values <- 1 - df_pct_45$temp / max_anom_45
df_pct_85$alpha_values <- df_pct_85$temp / max_anom_85


# Call the ggtimeseries function, and also add on extra ribbons and the gcms
p <- ggtimeseries(df.list = list(as.data.frame(df_45[2]), as.data.frame(df_85[2])), 
               df.x = "year",
               x.limits = c(2010, 2100),                               
               y.limits=c(-0.8,0.2),
               y.label = "% GDP", 
               legend.title = "RCP", legend.breaks = c("RCP 4.5", "RCP 8.5"), 
               legend.values = c('blue', 'red')) + 
geom_ribbon(data = df_45[[1]], aes(x=df_45[[1]]$year, ymin=df_45[[1]]$ub, ymax=df_45[[1]]$lb), 
           fill = "blue", alpha=0.1, show.legend = FALSE) +
geom_ribbon(data = df_85[[1]], aes(x=df_85[[1]]$year, ymin=df_85[[1]]$ub, ymax=df_85[[1]]$lb), 
           fill = "red",  alpha=0.1, show.legend = FALSE) + 
geom_line(data = df_pct_45, aes(x = year, y = percent_gdp, group = gcm),
  alpha = 0.3, show.legend = FALSE,colour = "blue") +
geom_line(data = df_pct_85, aes(x = year, y = percent_gdp, group = gcm), 
  alpha = 0.3, show.legend = FALSE, colour = "red") +
ggtitle("Damages as a percent of global gdp, ssp3-high")


ggsave(p, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/all_gcm_plot_with_mean.pdf"))


p_45 <- ggplot(data = df_pct_45, aes(x = year, y = percent_gdp, group = gcm, alpha = alpha_values), 
  show.legend = FALSE) + geom_line(colour = "blue") + coord_cartesian(ylim = c(-0.8,0.2), xlim = c(2010, 2100))  +
ggtitle("Damages as a percent of global gdp, ssp3-high")

p_85 <- ggplot(data = df_pct_85, aes(x = year, y = percent_gdp, group = gcm, alpha = alpha_values), 
  show.legend = FALSE) + geom_line(colour = "red") + coord_cartesian(ylim = c(-0.8,0.2), xlim = c(2010, 2100))  +
ggtitle("Damages as a percent of global gdp, ssp3-high")



ggsave(p_45, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/p_45.pdf"))

ggsave(p_85, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/p_85.pdf"))


# color the lines with different shades, the warmest being the darkest shade of red 
# and the coldest being the darkest shade of blue


p <- ggtimeseries(df.list = list(as.data.frame(df_45[2]), as.data.frame(df_85[2])), 
               df.x = "year",
               x.limits = c(2010, 2100),                               
               y.limits=c(-0.8,0.2),
               y.label = "% GDP", 
               legend.title = "RCP", legend.breaks = c("RCP 4.5", "RCP 8.5"), 
               legend.values = c('blue', 'red')) + 
geom_ribbon(data = df_45[[1]], aes(x=df_45[[1]]$year, ymin=df_45[[1]]$ub, ymax=df_45[[1]]$lb), 
           fill = "blue", alpha=0.1, show.legend = FALSE) +
geom_ribbon(data = df_85[[1]], aes(x=df_85[[1]]$year, ymin=df_85[[1]]$ub, ymax=df_85[[1]]$lb), 
           fill = "red",  alpha=0.1, show.legend = FALSE) + 
geom_line(data = df_pct_45, aes(x = year, y = percent_gdp, group = gcm, alpha = alpha_values), 
  show.legend = FALSE, colour = "blue")  +
geom_line(data = df_pct_85, aes(x = year, y = percent_gdp, group = gcm, alpha = alpha_values), 
  show.legend = FALSE, colour = "red")  + scale_alpha(range = c(0, 0.7)) +
ggtitle("Damages as a percent of global gdp, ssp3-high")


ggsave(p, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/all_gcm_gradient_with_mean.pdf"))









	
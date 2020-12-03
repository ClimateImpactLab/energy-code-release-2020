

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
library(ggplot2)
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 



# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools,
               RColorBrewer)



user= 'liruixue'

db = '/mnt/norgay_synology_drive/CIL_energy/'
output = '/mnt/norgay_synology_drive/CIL_energy/code_release_data_pixel_interaction/'
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


df_dmg_45 <- df_dmg %>% filter(rcp == "rcp45")


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
GMST_anom <- GMST_anom %>% 
  dplyr::filter(year == 2099) %>% 
  dplyr::select(-year) %>% 
  dplyr::rename(anom_2099 = temp)

df_pct <- merge(df_pct, GMST_anom, by = c("gcm","rcp"))

write_csv(df_pct, 
  paste0(output, '/projection_system_outputs/21jul2020_pre_data/', 
    'main_model-', "OTHERIND_total_energy", '-SSP3-high-fulladapt-',"price014" ,'-2010_2099-pct-timeseries-with-anom.csv'))

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


df_pct <- df_pct %>% 
  dplyr::mutate(
    rcp = replace(rcp, rcp=="rcp45", "RCP 4.5"),
    rcp = replace(rcp, rcp=="rcp85", "RCP 8.5")
  )

df_pct_45 <- df_pct %>% 
      dplyr::filter(rcp == "RCP 4.5")
df_pct_85 <- df_pct %>% 
      dplyr::filter(rcp == "RCP 8.5")

max_anom_45 <- max(df_pct_45$anom_2099)
max_anom_85 <- max(df_pct_85$anom_2099)

# standardize alpha values to 0-1
df_pct_45$alpha_values <- 1 - df_pct_45$anom_2099 / max_anom_45
df_pct_85$alpha_values <- df_pct_85$anom_2099 / max_anom_85

df_pct_all <- rbind(df_pct_45,df_pct_85)%>%
                    mutate(lab = paste0(rcp, " - ", gcm))
distinct_colours = df_pct_all %>% select(gcm,rcp,alpha_values,lab) %>%distinct() 

df_45_plot <- df_45[[2]] %>% mutate(rcp = "RCP 4.5", gcm = "global", lab = "RCP 4.5 - Global Mean") 
df_85_plot <- df_85[[2]] %>% mutate(rcp = "RCP 8.5", gcm = "global", lab = "RCP 8.5 - Global Mean") 
df_all_plot <- df_pct_all%>% select(year, percent_gdp, rcp, gcm, lab) 

df_pct_all_w_mean <- do.call("rbind", list(df_all_plot, df_45_plot, df_85_plot))


# only plot the GDMs
p <- ggplot(data = df_pct_all, aes(x = year, y = percent_gdp, 
          group = lab, colour = lab), show.legend = TRUE,  legend.title = "RCP - GCM") +geom_line() + 
          scale_colour_manual(name = "legend", values = c(

"RCP 4.5 - ACCESS1-0" = alpha("blue", 0.5120153),                      
"RCP 4.5 - bcc-csm1-1"= alpha("blue", 0.7123560),
"RCP 4.5 - BNU-ESM"= alpha("blue", 0.5549285),
"RCP 4.5 - CanESM2"= alpha("blue", 0.4917690),
"RCP 4.5 - CCSM4"= alpha("blue", 0.6559215),
"RCP 4.5 - CESM1-BGC"= alpha("blue", 0.6962213),
"RCP 4.5 - CNRM-CM5"= alpha("blue", 0.6064683),
"RCP 4.5 - CSIRO-Mk3-6-0"= alpha("blue", 0.4946302),
"RCP 4.5 - GFDL-CM3"= alpha("blue", 0.3785487),
"RCP 4.5 - GFDL-ESM2G"= alpha("blue", 0.8458004),
"RCP 4.5 - GFDL-ESM2M"= alpha("blue", 0.7633897),
"RCP 4.5 - inmcm4"= alpha("blue", 0.7163151),
"RCP 4.5 - IPSL-CM5A-LR"= alpha("blue", 0.4687884),
"RCP 4.5 - IPSL-CM5A-MR"= alpha("blue", 0.5058260),
"RCP 4.5 - MIROC5"= alpha("blue", 0.6208987),
"RCP 4.5 - MIROC-ESM-CHEM"= alpha("blue", 0.4500579),
"RCP 4.5 - MIROC-ESM"= alpha("blue", 0.4281735),
"RCP 4.5 - MPI-ESM-LR"= alpha("blue", 0.6623592),
"RCP 4.5 - MPI-ESM-MR"= alpha("blue", 0.6725359),
"RCP 4.5 - MRI-CGCM3"= alpha("blue", 0.6039329),
"RCP 4.5 - NorESM1-M"= alpha("blue", 0.6371774),
"RCP 4.5 - surrogate_CanESM2_89"= alpha("blue", 0.3507029),
"RCP 4.5 - surrogate_CanESM2_94"= alpha("blue", 0.2617547),
"RCP 4.5 - surrogate_CanESM2_99"= alpha("blue", 0.0000000),
"RCP 4.5 - surrogate_GFDL-CM3_89"= alpha("blue", 0.3507029),
"RCP 4.5 - surrogate_GFDL-CM3_94"= alpha("blue", 0.2617547),
"RCP 4.5 - surrogate_GFDL-CM3_99"= alpha("blue", 0.0000000),
"RCP 4.5 - surrogate_GFDL-ESM2G_01"= alpha("blue", 0.8327678),
"RCP 4.5 - surrogate_GFDL-ESM2G_11"= alpha("blue", 0.7799322),
"RCP 4.5 - surrogate_MRI-CGCM3_01"= alpha("blue", 0.8327678),
"RCP 4.5 - surrogate_MRI-CGCM3_06"= alpha("blue", 0.7971401),
"RCP 4.5 - surrogate_MRI-CGCM3_11"= alpha("blue", 0.7799322),
"RCP 8.5 - ACCESS1-0" = alpha("red", 0.4635836) ,
"RCP 8.5 - bcc-csm1-1" = alpha("red", 0.3784361),
"RCP 8.5 - BNU-ESM" = alpha("red", 0.4655724),
"RCP 8.5 - CanESM2" = alpha("red", 0.4975567),
"RCP 8.5 - CCSM4" = alpha("red", 0.3970815),
"RCP 8.5 - CESM1-BGC" = alpha("red", 0.3854496),
"RCP 8.5 - CNRM-CM5" = alpha("red", 0.3860531),
"RCP 8.5 - CSIRO-Mk3-6-0" = alpha("red", 0.4655853),
"RCP 8.5 - GFDL-CM3" = alpha("red", 0.5142154),
"RCP 8.5 - GFDL-ESM2G" = alpha("red", 0.3107868),
"RCP 8.5 - GFDL-ESM2M" = alpha("red", 0.3008806),
"RCP 8.5 - inmcm4" = alpha("red", 0.2994252),
"RCP 8.5 - IPSL-CM5A-LR" = alpha("red", 0.5143264),
"RCP 8.5 - IPSL-CM5A-MR" = alpha("red", 0.5058648),
"RCP 8.5 - MIROC5" = alpha("red", 0.3611091),
"RCP 8.5 - MIROC-ESM-CHEM" = alpha("red", 0.5843797),
"RCP 8.5 - MIROC-ESM" = alpha("red", 0.5368475),
"RCP 8.5 - MPI-ESM-LR" = alpha("red", 0.4042531),
"RCP 8.5 - MPI-ESM-MR" = alpha("red", 0.4053162),
"RCP 8.5 - MRI-CGCM3" = alpha("red", 0.3754158),
"RCP 8.5 - NorESM1-M" = alpha("red", 0.3480407),
"RCP 8.5 - surrogate_CanESM2_89" = alpha("red", 0.6490317),
"RCP 8.5 - surrogate_CanESM2_94" = alpha("red", 0.7202207),
"RCP 8.5 - surrogate_CanESM2_99" = alpha("red", 1.0000000),
"RCP 8.5 - surrogate_GFDL-CM3_89" = alpha("red", 0.6490317),
"RCP 8.5 - surrogate_GFDL-CM3_94" = alpha("red", 0.7202207),
"RCP 8.5 - surrogate_GFDL-CM3_99" = alpha("red", 1.0000000),
"RCP 8.5 - surrogate_GFDL-ESM2G_01" = alpha("red", 0.2403981),
"RCP 8.5 - surrogate_GFDL-ESM2G_06" = alpha("red", 0.2685275),
"RCP 8.5 - surrogate_GFDL-ESM2G_11" = alpha("red", 0.2829168),
"RCP 8.5 - surrogate_MRI-CGCM3_01" = alpha("red", 0.2403981),
"RCP 8.5 - surrogate_MRI-CGCM3_06" = alpha("red", 0.2685275),
"RCP 8.5 - surrogate_MRI-CGCM3_11" = alpha("red", 0.2829168)
)
, labels = distinct_colours$lab)



ggsave(p, height = 7, width = 20, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/all_gcm_gradient_with_mean.pdf"))





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


# Call the ggtimeseries function, and also add on extra ribbons and the gcms
p <- ggtimeseries(df.list = NULL, 
               df.x = "year",
               x.limits = c(2010, 2100),                               
               y.limits=c(-0.8,0.2),
               y.label = "% GDP", 
               legend.title = "legend", legend.breaks = c("RCP 4.5", "RCP 8.5")) + 
geom_ribbon(data = df_45[[1]], aes(x=df_45[[1]]$year, ymin=df_45[[1]]$ub, ymax=df_45[[1]]$lb), 
           fill = "blue", alpha=0.1, show.legend = FALSE) +
geom_ribbon(data = df_85[[1]], aes(x=df_85[[1]]$year, ymin=df_85[[1]]$ub, ymax=df_85[[1]]$lb), 
           fill = "red",  alpha=0.1, show.legend = FALSE)  + 
geom_line(data = df_pct_all_w_mean, aes(x = year, y = percent_gdp, 
          group = lab, colour = lab, size = lab), show.legend = TRUE) + 
          scale_colour_manual(guide = "legend", values = c(
"RCP 4.5 - ACCESS1-0" = alpha("blue", 0.5120153),                      
"RCP 4.5 - bcc-csm1-1"= alpha("blue", 0.7123560),
"RCP 4.5 - BNU-ESM"= alpha("blue", 0.5549285),
"RCP 4.5 - CanESM2"= alpha("blue", 0.4917690),
"RCP 4.5 - CCSM4"= alpha("blue", 0.6559215),
"RCP 4.5 - CESM1-BGC"= alpha("blue", 0.6962213),
"RCP 4.5 - CNRM-CM5"= alpha("blue", 0.6064683),
"RCP 4.5 - CSIRO-Mk3-6-0"= alpha("blue", 0.4946302),
"RCP 4.5 - GFDL-CM3"= alpha("blue", 0.3785487),
"RCP 4.5 - GFDL-ESM2G"= alpha("blue", 0.8458004),
"RCP 4.5 - GFDL-ESM2M"= alpha("blue", 0.7633897),
"RCP 4.5 - inmcm4"= alpha("blue", 0.7163151),
"RCP 4.5 - IPSL-CM5A-LR"= alpha("blue", 0.4687884),
"RCP 4.5 - IPSL-CM5A-MR"= alpha("blue", 0.5058260),
"RCP 4.5 - MIROC5"= alpha("blue", 0.6208987),
"RCP 4.5 - MIROC-ESM-CHEM"= alpha("blue", 0.4500579),
"RCP 4.5 - MIROC-ESM"= alpha("blue", 0.4281735),
"RCP 4.5 - MPI-ESM-LR"= alpha("blue", 0.6623592),
"RCP 4.5 - MPI-ESM-MR"= alpha("blue", 0.6725359),
"RCP 4.5 - MRI-CGCM3"= alpha("blue", 0.6039329),
"RCP 4.5 - NorESM1-M"= alpha("blue", 0.6371774),
"RCP 4.5 - surrogate_CanESM2_89"= alpha("blue", 0.3507029),
"RCP 4.5 - surrogate_CanESM2_94"= alpha("blue", 0.2617547),
"RCP 4.5 - surrogate_CanESM2_99"= alpha("blue", 0.0000000),
"RCP 4.5 - surrogate_GFDL-CM3_89"= alpha("blue", 0.3507029),
"RCP 4.5 - surrogate_GFDL-CM3_94"= alpha("blue", 0.2617547),
"RCP 4.5 - surrogate_GFDL-CM3_99"= alpha("blue", 0.0000000),
"RCP 4.5 - surrogate_GFDL-ESM2G_01"= alpha("blue", 0.8327678),
"RCP 4.5 - surrogate_GFDL-ESM2G_11"= alpha("blue", 0.7799322),
"RCP 4.5 - surrogate_MRI-CGCM3_01"= alpha("blue", 0.8327678),
"RCP 4.5 - surrogate_MRI-CGCM3_06"= alpha("blue", 0.7971401),
"RCP 4.5 - surrogate_MRI-CGCM3_11"= alpha("blue", 0.7799322),
"RCP 8.5 - ACCESS1-0" = alpha("red", 0.4635836) ,
"RCP 8.5 - bcc-csm1-1" = alpha("red", 0.3784361),
"RCP 8.5 - BNU-ESM" = alpha("red", 0.4655724),
"RCP 8.5 - CanESM2" = alpha("red", 0.4975567),
"RCP 8.5 - CCSM4" = alpha("red", 0.3970815),
"RCP 8.5 - CESM1-BGC" = alpha("red", 0.3854496),
"RCP 8.5 - CNRM-CM5" = alpha("red", 0.3860531),
"RCP 8.5 - CSIRO-Mk3-6-0" = alpha("red", 0.4655853),
"RCP 8.5 - GFDL-CM3" = alpha("red", 0.5142154),
"RCP 8.5 - GFDL-ESM2G" = alpha("red", 0.3107868),
"RCP 8.5 - GFDL-ESM2M" = alpha("red", 0.3008806),
"RCP 8.5 - inmcm4" = alpha("red", 0.2994252),
"RCP 8.5 - IPSL-CM5A-LR" = alpha("red", 0.5143264),
"RCP 8.5 - IPSL-CM5A-MR" = alpha("red", 0.5058648),
"RCP 8.5 - MIROC5" = alpha("red", 0.3611091),
"RCP 8.5 - MIROC-ESM-CHEM" = alpha("red", 0.5843797),
"RCP 8.5 - MIROC-ESM" = alpha("red", 0.5368475),
"RCP 8.5 - MPI-ESM-LR" = alpha("red", 0.4042531),
"RCP 8.5 - MPI-ESM-MR" = alpha("red", 0.4053162),
"RCP 8.5 - MRI-CGCM3" = alpha("red", 0.3754158),
"RCP 8.5 - NorESM1-M" = alpha("red", 0.3480407),
"RCP 8.5 - surrogate_CanESM2_89" = alpha("red", 0.6490317),
"RCP 8.5 - surrogate_CanESM2_94" = alpha("red", 0.7202207),
"RCP 8.5 - surrogate_CanESM2_99" = alpha("red", 1.0000000),
"RCP 8.5 - surrogate_GFDL-CM3_89" = alpha("red", 0.6490317),
"RCP 8.5 - surrogate_GFDL-CM3_94" = alpha("red", 0.7202207),
"RCP 8.5 - surrogate_GFDL-CM3_99" = alpha("red", 1.0000000),
"RCP 8.5 - surrogate_GFDL-ESM2G_01" = alpha("red", 0.2403981),
"RCP 8.5 - surrogate_GFDL-ESM2G_06" = alpha("red", 0.2685275),
"RCP 8.5 - surrogate_GFDL-ESM2G_11" = alpha("red", 0.2829168),
"RCP 8.5 - surrogate_MRI-CGCM3_01" = alpha("red", 0.2403981),
"RCP 8.5 - surrogate_MRI-CGCM3_06" = alpha("red", 0.2685275),
"RCP 8.5 - surrogate_MRI-CGCM3_11" = alpha("red", 0.2829168),
"RCP 4.5 - Global Mean" = alpha("blue", 1),
"RCP 8.5 - Global Mean" = alpha("red", 1)
)
, breaks = c(distinct_colours$lab, c("RCP 4.5 - Global Mean","RCP 8.5 - Global Mean"))) + 
scale_size_manual(
  values = c(rep(0.5, 65), 1,1) ,
  breaks =  c(distinct_colours$lab, c("RCP 4.5 - Global Mean","RCP 8.5 - Global Mean")))


ggsave(p, height = 7, width = 20, file = paste0(output, 
     "/projection_system_outputs/21jul2020_pre_data/combined.pdf"))


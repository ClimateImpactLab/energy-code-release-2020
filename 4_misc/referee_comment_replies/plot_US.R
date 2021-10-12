# Produces maps displayed in the energy paper. Uses Functions in mapping.R
# figure 2A for asia only

rm(list = ls())
library(ggplot2)
library(magrittr)
library(dplyr)
library(parallel)
library(glue)
library(data.table)
library(ncdf4)
library(ggpubr)
library(gridExtra)

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = "/home/liruixue/repos/energy-code-release-2020/figures"

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))


# #############################################
# # 2. Figure 2 A
#############################################

continents <- setnames(subset(fread("/shares/gcp/regions/continents2.csv"), select=c('alpha-3', 'sub-region')), c('iso', 'continent'))
regions <- setnames(subset(fread("/shares/gcp/regions/hierarchy.csv"), select=c('region-key', 'is_terminal')), c('region', 'is_terminal'))

regions[,iso:=substr(x=region,start=1,stop=3)]

setkey(regions, iso)
setkey(continents, iso)

DT <- regions[continents][is_terminal==TRUE][,is_terminal:=NULL][,iso:=NULL][continent!=""][]

DT[,iso:=substr(x=region,start=1,stop=3)]

split <- sapply(unique(DT[,iso]),function(c) DT[iso==c], simplify=FALSE)


USA_IRs = split$USA[,region]

mymap_USA = mymap %>% dplyr::filter(as.character(id) %in% USA_IRs)



plot_2A = function(fuel, bound, DB_data, map=mymap_USA) {

  # Load in the impacts-pc data
  df= read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 

  df = df %>% dplyr::filter(region %in% USA_IRs)
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
  p = join.plot.map(map.df = map, 
                     df = df, 
                     df.key = "region", 
                     plot.var = "mean", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map_USA.pdf"), p)
  print(paste0(output, "/fig_2A_", fuel, "_impacts_map_USA.pdf"))
}
plot_2A(fuel = "electricity", bound = 3, DB_data = DB_data)
# plot_2A(fuel = "other_energy", bound = 18, DB_data = DB_data)

######################################################################################## 

# get US average and plot
library(glue)
library(R.cache)
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

print("test6")
cilpath.r:::cilpath()
db = '/mnt/CIL_energy/'
# output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

df = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "USA", # needs to be specified for 
                regions = "USA",
                # regions_suffix = resolution,
                rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "climate", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = "high", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = seq(2099),  
                spec = "OTHERIND_electricity",
                dollar_convert = NULL,
                grouping_test = "semi-parametric",
                regenerate = FALSE)

df = df %>% filter(region == "USA", year == 2099)


# plot the USA mean on the map
USA_mean = df$mean

plot_2A = function(fuel, bound, DB_data, map=mymap_USA) {

  # Load in the impacts-pc data
  df= read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 

  df = df %>% dplyr::filter(region %in% USA_IRs)
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  rescale_value <- scale_v*bound
  
  df = df %>% mutate(mean = USA_mean)

  p = join.plot.map(map.df = map, 
                     df = df, 
                     df.key = "region", 
                     plot.var = "mean", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = paste0(fuel, " imapacts, GJ PC, 2099"), 
                     map.title = paste0(fuel, 
                                    "_TINV_clim_SSP3-rcp85_impactpc_high_fulladapt_2099"))
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map_USA_average.pdf"), p)
  print(paste0(output, "/fig_2A_", fuel, "_impacts_map_USA_average.pdf"))
}
plot_2A(fuel = "electricity", bound = 3, DB_data = DB_data)



########################################################################################

# get some stats to plot  

df = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = NULL, # needs to be specified for 
                rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "climate", # full, climate, values
                geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = "high", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = 2099,  
                spec = "OTHERIND_electricity",
                dollar_convert = NULL,
                grouping_test = "semi-parametric") 


# Miami: USA.10.360 --- 2.978277
# Minneapolis: USA.24.1343 --  -0.1809538

Miami = (df %>% filter(region == "USA.10.360", year == 2099))$mean
Minneapolis = (df %>% filter(region == "USA.24.1343", year == 2099))$mean

Miami
Minneapolis



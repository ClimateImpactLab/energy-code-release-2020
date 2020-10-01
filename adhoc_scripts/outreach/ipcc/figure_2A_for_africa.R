# Produces maps displayed in the energy paper. Uses Functions in mapping.R
# done 26 aug 2020
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
output = "/mnt/CIL_energy/outreach/ipcc"

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))


# #############################################
# # 2. Figure 2 A




#############################################
# subset to african IRs
ContinentSplit <- function(weirdlist = FALSE){

  continents <- setnames(subset(fread("/shares/gcp/regions/continents2.csv"), select=c('alpha-3', 'region')), c('iso', 'continent'))
  regions <- setnames(subset(fread("/shares/gcp/regions/hierarchy.csv"), select=c('region-key', 'is_terminal')), c('region', 'is_terminal'))

  regions[,iso:=substr(x=region,start=1,stop=3)]
  
  setkey(regions, iso)
  setkey(continents, iso)

  DT <- regions[continents][is_terminal==TRUE][,is_terminal:=NULL][,iso:=NULL][continent!=""][]

  split <- sapply(unique(DT[,continent]),function(c) DT[continent==c], simplify=FALSE)

  if (weirdlist) split <- mapply(RegionListName,d=split, n=names(split), SIMPLIFY = FALSE)

  return(split)
}

split = ContinentSplit()
african_IRs = split$Africa[,region]
mymap_africa = mymap %>% dplyr::filter(as.character(id) %in% african_IRs)


plot_2A = function(fuel, bound, DB_data, map=mymap_africa) {

  # Load in the impacts-pc data
  df= read_csv(
    paste0(DB_data, '/projection_system_outputs/mapping_data/', 
           'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-impact_pc-2099-map.csv')) 

  df = df %>% dplyr::filter(region %in% african_IRs)
  # df = df %>% dplyr::mutate(mean = 1 / 0.0036 * mean)
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
  ggsave(paste0(output, "/fig_2A_", fuel, "_impacts_map_africa.pdf"), p)
}
plot_2A(fuel = "electricity", bound = 3, DB_data = DB_data)
plot_2A(fuel = "other_energy", bound = 18, DB_data = DB_data)















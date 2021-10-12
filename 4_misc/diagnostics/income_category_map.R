# color the map by the 4 categories
# income is above cutoff under both IR- and country-level income
# income is below cutoff under both IR- and country-level income
# income is below cutoff under IR-level income and above cutoff under country-level income
# income is above cutoff under IR-level income and below cutoff under country-level income


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
cilpath.r:::cilpath()

root =paste0(REPO,"/energy-code-release-2020/") 
setwd(root)

db = '/mnt/CIL_energy/'
output = paste0(root,'/figures')
source(paste0(REPO, "/post-projection-tools/mapping/imgcat.R")) #this redefines the way ggplot plots. 
source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

# Load in the required pacages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")


########### load the data needed ############ 
# Covariates are from a single run allcalcs file
# get country-level income
cov_pixel_interaction= read_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

country_inc = cov_pixel_interaction %>%
		dplyr::select(year, region, loggdppc) %>%
		dplyr::filter(year %in% c(2015, 2099)) %>%
		rename(country_inc = loggdppc)

# get IR-level income
IR_inc = read_csv(paste0("/mnt/CIL_energy/",
	'IEA_Replication/Data/Projection/covariates/', 
	'FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline.csv'))%>%
		dplyr::filter(year %in% c(2015, 2099))%>%
		dplyr::select(year, region, loggdppc)%>%
		rename(IR_inc = loggdppc)

cutoff = 9.087

# income is above cutoff under both IR- and country-level income
# income is below cutoff under both IR- and country-level income
# income is below cutoff under IR-level income and above cutoff under country-level income
# income is above cutoff under IR-level income and below cutoff under country-level income

inc = merge(country_inc, IR_inc, by = c('year','region')) 


inc_cat = inc %>% 
		dplyr::mutate(cat1 = ifelse(country_inc > cutoff & IR_inc > cutoff, 1, 0),
					  cat2 = ifelse(country_inc <= cutoff & IR_inc <= cutoff, 2, 0),
					  cat3 = ifelse(country_inc > cutoff & IR_inc <= cutoff, 3, 0),
					  cat4 = ifelse(country_inc <= cutoff & IR_inc > cutoff, 4, 0)
					  ) %>%
		dplyr::mutate(cat = cat1 + cat2 + cat3 + cat4) %>%
		dplyr::select(year, region, cat) %>% 
		dplyr::filter(year == 2099)



######################### plot maps ###########################

mymap = load.map(shploc = paste0(output, "/shapefiles/world-combo-new-nytimes"))

p = join.plot.map(map.df = mymap, 
                 df = inc_cat, 
                 df.key = "region", 
                 plot.var = "cat", 
                 topcode = F, 
                 # topcode.ub = max(rescale_value),
                 breaks_labels_val = c(1,2,3,4),
                 color.scheme = "div", 
                 rescale_val = c(1,2,3,4),
                 colorbar.title = paste0("income group"), 
                 map.title = paste0("IR vs Country Level Income Groups"))
p
ggsave(paste0(output, "/IR-vs-country_income-groups_map.pdf"), p)






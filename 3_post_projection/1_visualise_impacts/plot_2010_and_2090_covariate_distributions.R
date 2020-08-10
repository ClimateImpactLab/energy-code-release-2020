
###########################################################
##                 Generating Blob Plots                 ##
###########################################################

rm(list = ls())

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               RColorBrewer, 
               scales, 
               grid)

DB = "/mnt"

DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2010"
output = paste0(root, "/figures/fig_Appendix-C3_sample_overlap_present_future")

covariates <- paste0(DB_data, "/projection_system_outputs/covariates/",
                     "/covariates-SSP3-rcp85-high-2010_2090-CCSM4.csv")

# load and clean data
covars = as.data.frame(readr::read_csv(covariates))

# plotting limits
lb = 0
ub = 2000
rescale_val = c(0, 0.005, 0.05, 0.2, .5, .75, 1) * ub
limits_val = c(lb,ub)
breaks_labels_val = seq(lb, ub, abs(ub-lb)/5)
grey.colors <- brewer.pal(7, "Greys")[2:7]
red.colors <- brewer.pal(7, "YlOrRd")[2:7]
bin_num <- 50
drop_val <- T


# plot cdds both colors

p_cdd = ggplot() +
  geom_bin2d(data=covars, 
             aes(x=CDD20, y=loggdppc), 
             colour="white",
             bins = bin_num,
             drop = drop_val,
             na.rm = TRUE) +
  facet_wrap(~year, nrow = 1) + 
  expand_limits(y=0) +
  scale_fill_gradientn(colours = red.colors, 
                       name = "Frequency", 
                       limits = limits_val,  
                       breaks = breaks_labels_val, 
                       labels = breaks_labels_val,
                       values=rescale(rescale_val),
                       na.value=NA) +
  theme(panel.background = element_rect(fill = 'white', colour = 'grey'))

ggplot2::ggsave(width = 20, height = 10, plot = p_cdd, filename = paste0(output,'/Kdensity_CDD20_loggdppc_red.pdf'))

p_cdd = ggplot() +
  geom_bin2d(data=covars, 
             aes(x=CDD20, y=loggdppc), 
             colour="white",
             bins = bin_num,
             drop = drop_val,
             na.rm = TRUE) +
  facet_wrap(~year, nrow = 1) + 
  expand_limits(y=0) +
  scale_fill_gradientn(colours = grey.colors, 
                       name = "Frequency", 
                       limits = limits_val,  
                       breaks = breaks_labels_val, 
                       labels = breaks_labels_val,
                       values=rescale(rescale_val),
                       na.value=NA) +
  theme(panel.background = element_rect(fill = 'white', colour = 'grey'))

ggplot2::ggsave(width = 20, height = 10, plot = p_cdd, filename = paste0(output,'/Kdensity_CDD20_loggdppc_gray.pdf'))


# plot hdds both colors

p_hdd = ggplot() +
  geom_bin2d(data=covars, 
             aes(x=HDD20, y=loggdppc), 
             colour="white",
             bins = bin_num,
             drop = drop_val,
             na.rm = TRUE) +
  facet_wrap(~year, nrow = 1) + 
  expand_limits(y=0) +
  scale_fill_gradientn(colours = red.colors, 
                       name = "Frequency", 
                       limits = limits_val,  
                       breaks = breaks_labels_val, 
                       labels = breaks_labels_val,
                       values=rescale(rescale_val),
                       na.value=NA) +
  theme(panel.background = element_rect(fill = 'white', colour = 'grey'))

ggplot2::ggsave(width = 20, height = 10, plot = p_hdd, filename = paste0(output,'/Kdensity_HDD20_loggdppc_red.pdf'))

p_hdd = ggplot() +
  geom_bin2d(data=covars, 
             aes(x=HDD20, y=loggdppc), 
             colour="white",
             bins = bin_num,
             drop = drop_val,
             na.rm = TRUE) +
  facet_wrap(~year, nrow = 1) + 
  expand_limits(y=0) +
  scale_fill_gradientn(colours = grey.colors, 
                       name = "Frequency", 
                       limits = limits_val,  
                       breaks = breaks_labels_val, 
                       labels = breaks_labels_val,
                       values=rescale(rescale_val),
                       na.value=NA) +
  theme(panel.background = element_rect(fill = 'white', colour = 'grey'))

ggplot2::ggsave(width = 20, height = 10, plot = p_hdd, filename = paste0(output,'/Kdensity_HDD20_loggdppc_gray.pdf'))



# Get a statistic for the paper:
# How much of the projected sample do we cover with our insample temperature/income distribution

max_gdp_2010 = max(covars$loggdppc[covars$year ==2010])
max_cdd_2010 = max(covars$CDD20[covars$year ==2010])
pop_2090 = sum(covars$population[covars$year ==2090], na.rm = TRUE)

proportion = sum(covars$population[
  (covars$CDD20 < max_cdd_2010) & (covars$loggdppc < max_gdp_2010) & (covars$year ==2090)], na.rm = TRUE) / pop_2090
proportion

# Impacts by income deciles bar chart
# done 26 aug 2020
# changed to income decile by country income oct 2020
rm(list = ls())
# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "/mnt"

DB_data = paste0(DB, "/CIL_energy/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")


# Take deciles of 2010 income/ clim data distribution of IRs, by getting equal populations in each population

get_deciles = function(df){
  
  # df = country_inc_aggregated
  deciles = df %>% 
    dplyr::filter(year == 2010)
  

  # # Get cut-off population levels for each quantile
  # total_pop = sum(deciles$pop)
  # pop_per_quantile = total_pop / 10
  
  # deciles <- deciles[order(deciles$loggdppc),] 
  # deciles$cum_pop = cumsum(deciles$pop)
  # deciles$decile = 10
  
  # # Loop over deciles, assigning them to the ordered IRs up to the point where population is equal in each decile
  # for (quant in 1:10){
  #   deciles$decile[deciles$cum_pop < quant* pop_per_quantile & deciles$cum_pop >= (quant-1)* pop_per_quantile] <- quant
  # }
  # browser()
  deciles$decile = ntile(deciles$loggdppc,10)

  
  return(dplyr::select(iso, decile))
}

# Load in pop and income data
# df_covariates = read_csv(paste0(DB_data, '/projection_system_outputs/covariates', 
#                         '/SSP3-high-IR_level-gdppc-pop-2012.csv'))

# # Find each Impact region's 2012 decile of income per capita. 
# deciles = get_deciles(df_covariates)


# pop = read_csv(paste0("/mnt/CIL_energy/code_release_data_pixel_interaction",'/projection_system_outputs/covariates/' ,
#   'SSP3_IR_level_population.csv'))


cov_pixel_interaction= read_csv(paste0("/mnt/CIL_energy/code_release_data_pixel_interaction", 
  '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

country_inc = cov_pixel_interaction %>%
    dplyr::select(year, region, loggdppc)%>%
    rename(country_inc = loggdppc) %>% 
    mutate(iso = substr(region, 1,3)) 

# country_inc = merge(country_inc, pop, by = c("region", "year"))

country_inc_aggregated =  country_inc %>% group_by(iso, year) %>%
  summarize(loggdppc = mean(country_inc))

deciles = get_deciles(country_inc_aggregated)

country_inc_deciles = merge(country_inc, deciles, by = c("iso"))

# countries = country_inc %>% select(iso, year, country_inc) %>%
# filter(year == 2012) %>% unique()



# Load in impacts data
df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/mapping_data',
                "/main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv")) %>%
  mutate(damage = damage * 1000000000) %>% 
  mutate(iso = substr(region, 1,3)) %>% 
  left_join(deciles, by = "iso")

# Join with 2099 population data
df_pop99= read_csv(paste0(DB_data, '/projection_system_outputs/covariates', 
                                   '/SSP3-high-IR_level-gdppc_pop-2099.csv')) %>% 
  dplyr::select(region, pop99)

df_impacts = df_impacts %>% 
    left_join(df_pop99, by = "region")

# Collapse to decile level
df_plot = df_impacts %>% 
  group_by(decile) %>% 
  summarize(total_damage_2099 = sum(damage), 
            total_pop_2099 = sum(pop99))%>%
  mutate(damagepc = total_damage_2099 / total_pop_2099 )


# Plot and save 
p = ggplot(data = df_plot) +
  geom_bar(aes( x=decile, y = damagepc ), 
           position="dodge", stat="identity", width=.8) + 
  theme_minimal() +
  ylab("Impact of Climate Change, 2019 USD") +
  xlab("2012 Income Decile") +
  scale_x_discrete(limits = seq(1,10))

ggsave(p, file = paste0(output, 
    "/fig_Appendix-H1-new_SSP3-high_rcp85-total-energy-price014-damages_by_country_inc_decile.pdf"), 
    width = 8, height = 6)




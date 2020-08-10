# Impacts by income deciles bar chart

rm(list = ls())
# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "C:/Users/TomBearpark/synologyDrive"

DB_data = paste0(DB, "/GCP_Reanalysis/ENERGY/code_release_data_pixel_interaction")
root =  "C:/Users/TomBearpark/Documents/energy-code-release-2020"
output = paste0(root, "/figures")


# Take deciles of 2012 income/ clim data distribution of IRs, by getting equal populations in each population

get_deciles = function(df){
  
  deciles = df %>% 
    filter(year == 2012)
  
  # Get cut-off population levels for each quantile
  total_pop = sum(deciles$pop)
  pop_per_quantile = total_pop / 10
  
  deciles <- deciles[order(deciles$gdppc),] 
  deciles$cum_pop = cumsum(deciles$pop)
  deciles$decile = 10
  
  # Loop over deciles, assigning them to the ordered IRs up to the point where population is equal in each decile
  for (quant in 1:10){
    deciles$decile[deciles$cum_pop < quant* pop_per_quantile & deciles$cum_pop >= (quant-1)* pop_per_quantile] <- quant
  }
  
  deciles = deciles %>%
    dplyr::select(region, decile)
  
  return(deciles)
}

# Load in pop and income data
df_covariates = read_csv(paste0(DB_data, '/projection_system_outputs/covariates', 
                        '/SSP3-high-IR_level-gdppc-pop-2012.csv'))

# Find each Impact region's 2012 decile of income per capita. 
deciles = get_deciles(df_covariates)


# Load in impacts data
df_impacts = read_csv(paste0(DB_data, '/projection_system_outputs/mapping_data',
                "/main_model-total_energy-SSP3-rcp85-high-fulladapt-price014-2099-map.csv")) %>%
  mutate(damage = damage * 1000000000) %>% 
  left_join(deciles, by = "region")

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
    "/fig_Appendix-H1_SSP3-high_rcp85-total-energy-price014-damages_by_inc_decile.pdf"), 
    width = 8, height = 6)




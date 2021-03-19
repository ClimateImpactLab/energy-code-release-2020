# plot map of the alternative population to check if they make sense
rm(list = ls())
library(glue)

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr)

DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

source(paste0(root, "/3_post_projection/0_utils/mapping.R"))

#############################################
# 1. Load in a world shapefile, containing Impact Region boundaries, and convert to a 
#     dataframe for plotting

mymap = load.map(shploc = paste0(DB_data, "/shapefiles/world-combo-new-nytimes"))


# new population for jones paper
df= read_csv("/home/liruixue/temp/pop.csv") 

for (yr in seq(2010, 2100, 10)) {
  df_plot = df %>% filter(year == yr) %>% 
    dplyr::select(c("sum_value","hierid")) 
  # Set scaling factor for map color bar
  scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
  bound = ceiling(max(df_plot$sum_value))
  rescale_value <- scale_v * bound

  p = join.plot.map(map.df = mymap, 
                     df = df_plot, 
                     df.key = "hierid", 
                     plot.var = "sum_value", 
                     topcode = T, 
                     topcode.ub = max(rescale_value),
                     breaks_labels_val = seq(-bound, bound, bound/3),
                     color.scheme = "div", 
                     rescale_val = rescale_value,
                     colorbar.title = glue("population (person)"), 
                     map.title =  glue("population {}", yr))

  ggsave(paste0("/home/liruixue/temp/pop_map_",yr,".pdf"), p)

}

df_year_iso = df %>% mutate(iso = substr(hierid, 1, 3)) %>%
  group_by(iso, year) %>%
  summarize(sum = sum(sum_value))


df_year = df %>% mutate(iso = substr(hierid, 1, 3)) %>%
  group_by(year) %>%
  summarize(sum = sum(sum_value))
 

# old IR poopulation maps for comparison

output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

df = read_csv(paste0(output, '/projection_system_outputs/covariates/', 
  'SSP3-high-IR_level-gdppc_pop-2099.csv'))


df = df %>% mutate(iso = substr(region, 1, 3)) %>%
  group_by(iso) %>%
  summarize(sum = sum(pop99))


scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
bound = ceiling(max(df$pop99))
rescale_value <- scale_v * bound

p = join.plot.map(map.df = mymap, 
                   df = df, 
                   df.key = "region", 
                   plot.var = "pop99", 
                   topcode = T, 
                   topcode.ub = max(rescale_value),
                   breaks_labels_val = seq(-bound, bound, bound/3),
                   color.scheme = "div", 
                   rescale_val = rescale_value,
                   colorbar.title = glue("population (person)"), 
                   map.title =  glue("old population 2099"))

ggsave(paste0("/home/liruixue/temp/old_pop_map_2099.pdf"), p)



df = read_csv(paste0(output, '/projection_system_outputs/covariates/', 
  'SSP3-high-IR_level-gdppc-pop-2012.csv'))



scale_v = c(-1, -0.2, -0.05, -0.005, 0, 0.005, 0.05, 0.2, 1)
bound = ceiling(max(df$pop))
rescale_value <- scale_v * bound

p = join.plot.map(map.df = mymap, 
                   df = df, 
                   df.key = "region", 
                   plot.var = "pop", 
                   topcode = T, 
                   topcode.ub = max(rescale_value),
                   breaks_labels_val = seq(-bound, bound, bound/3),
                   color.scheme = "div", 
                   rescale_val = rescale_value,
                   colorbar.title = glue("population (person)"), 
                   map.title =  glue("old population 2012", ))

ggsave(paste0("/home/liruixue/temp/old_pop_map_2012.pdf"), p)

# new_pop
df= read_csv("/home/liruixue/temp/pop.csv") 

df %>% mutate(iso = substr(hierid, 1, 3)) %>%
  group_by(year) %>%
  summarize(sum = sum(sum_value))

df %>% mutate(iso = substr(hierid, 1, 3)) %>%
  group_by(year, iso) %>%
  summarize(sum = sum(sum_value))


# old_pop
df_global = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/', 
  '/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv'))

df = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/', 
  '/projection_system_outputs/covariates/', 
  'SSP3-high-IR_level-gdppc-pop-2012.csv')) %>% summarize(sum = sum(pop))

df = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/', 
  '/projection_system_outputs/covariates/', 
  'SSP3-high-IR_level-gdppc_pop-2099.csv')) %>% summarize(sum = sum(pop99))



# SSP3 data
df = read_csv("/shares/gcp/social/baselines/population/merged/population-merged.SSP3.csv", 
  skip = 12) 

df %>% group_by(year) %>% summarize(sum = sum(value))


df %>% mutate(iso = substr(region, 1, 3)) %>%
  group_by(year, iso) %>%
  summarize(sum = sum(value)) %>%
  filter(year >= 2010)




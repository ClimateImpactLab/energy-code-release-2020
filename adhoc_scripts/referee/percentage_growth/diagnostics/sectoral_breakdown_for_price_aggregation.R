#Code Purpose: For the break2 price update, explore residential share of consumption for other eneryg sub-products
#Author: Maya Norman
#Date last motified 7/5/19

#clean environment
rm(list = ls())

#load packages
library(ggplot2)
library(rgdal)
library(dplyr)
library(magrittr)
library(rgeos)
library(viridis)
library(RColorBrewer)
library(readstata13)
library(hexbin)
library(gtable)
library(gridExtra)
library(grid)
library(maptools)
library(scales)
library(rnaturalearth)
library(testit)
library(ggpubr)
library(reshape2)

#Set up paths
user <- Sys.getenv("LOGNAME")

#for customized use change first argument to your local username
db <- ifelse(user == "mayanorman", paste0("/Users/",user,"/Dropbox"), paste0("/home/", user))
git <- ifelse(user == "mayanorman", paste0("/Users/",user,"/Documents/Repos"), paste0("/home/", user))

misc_data <- paste0(db, "/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Miscellaneous/") #location of input
output <- paste0(db, "/GCP_Reanalysis/ENERGY/IEA/Robustness_and_Reference/price_update_break2/") #location of input


################################################################################################
# Step 1) Load and prepare data
################################################################################################

#Load list of countries in projection data
df.covar <- read.dta13(paste0(db, "/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/covars_TINV_clim_1218.dta"))
df.covar$iso = substr(df.covar$region,1,3)
countrylist = unique(as.vector(df.covar$iso))

#Specify flows and products of interest (flows = TOTIND + TOTOTHER; products = other_energy sub products)
productlist.level2 <- c("COAL", "PEAT", "OILSHALE", "TOTPRODS", "NATGAS", "SOLWIND", "GEOTHERM", "COMRENEW", "HEAT", "HEATNS")
productlist.level3 <- c("cokcoal", "bitcoal", "lpg", "resfuel", "diesel", "gasoline", "othercoal", "otheroil")

# important coal products: bitcoal cokcoal othercoal ("hardcoal" "brown" "antcoal" "subcoal" "lignite" "peat" "patfuel" "ovencoke" "gascoke" "coaltar" "bkb" "gaswksgs" "cokeovgs" "blfurgs" "peatprod" "ogases" "oilshale")
#leaving out "brown" "hardcoal" "lignite"  "patfuel"  "subcoal" because missing for some countries in time period 

othercoal.list <- c( "antcoal", "peat", "ovencoke", "gascoke", "coaltar", "bkb", "gaswksgs", "cokeovgs", "blfurgs", "peatprod", "ogases", "oilshale")

# important oil products: gasoline (nonbiogaso avgas jetgas) resfuel diesel lpg otheroil ("refingas" "ethane" "othkero" "naphtha" "whitesp" "lubric" "bitumen" "parwax" "petcoke" "ononspec" "nonbiodies" "nonbiojetk")

otheroil.list <- c("refingas", "ethane", "othkero", "naphtha", "whitesp", "lubric", "bitumen", "parwax", "petcoke", "ononspec", "nonbiodies", "nonbiojetk")

flowlist = c("RESIDENT","COMMPUB","ONONSPEC","AGRICULT","FISHING","TOTIND")

#load and clean data
# more aggregated product data than below
df.level2 <- read.dta13(paste0(misc_data, "IEA_BAL_All3_rep.dta")) %>%
  filter(flow %in% flowlist) %>%
  filter(country %in% countrylist) %>%
  melt( id.vars = c("unit", "country", "flow", "year")) %>%
  filter(variable %in% productlist.level2) %>%
  subset(year >= 2005 & year <= 2015)

# most deaggregated product data
df.level3 <- read.dta13(paste0(db, "/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data/Coal_Oil_Segmented.dta")) %>%
  filter(country %in% countrylist) 

df.level3$gasoline = df.level3$NONBIOGASO + df.level3$AVGAS + df.level3$JETGAS
df.level3 <- df.level3 %>%
  melt( id.vars = c("country", "year", "flow")) %>%
  mutate(variable = tolower(variable)) %>%
  mutate(flow = toupper(flow)) %>%
  subset(year >= 2005 & year <= 2015)

othercoal <- summaryBy(value ~ country + year + flow, data = filter(df.level3, variable %in% othercoal.list), FUN = sum) %>% 
  rename(value = value.sum) %>%
  mutate(variable = "othercoal")
otheroil <- summaryBy(value ~ country + year + flow, data = filter(df.level3, variable %in% otheroil.list), FUN = sum) %>% 
  rename(value = value.sum) %>%
  mutate(variable = "otheroil")

df.level3 <- rbind(df.level3, othercoal, otheroil) %>% filter(variable %in% productlist.level3)




##################################################################################################
# Step 2) Construct Area Plots For Each In Sample Projection Country 
# Purpose: displaying presents of Non-Specified sector and zeroes
# in other energy sub-product data.
##################################################################################################

#get countrylist (intersection of projection countries and insample load countries)
countrylist = unique(as.vector(df.level3$country))

#create proportion for normalized area plots
for.plotting <- df.level3 %>%
  group_by(country,year,variable)%>%
  mutate(sum = sum(value)) %>%
  mutate(proportion = value/sum) %>%
  data.frame()

#Plot
for (cntry in countrylist) {

  df.plot <- subset(for.plotting, country == cntry)
  
  area_plot_prop <- ggplot(df.plot, aes(x=round(year,5), y=proportion, fill=flow)) + 
    geom_area(alpha=0.4 , size=.2, colour="black") +
    xlim(2005,2015)
  area_plot <- ggplot(df.plot, aes(x=round(year,5), y=value, fill=flow)) + 
    geom_area(alpha=0.4 , size=.2, colour="black") +
    xlim(2005,2015)

  area_plot_facet_prop <- area_plot_prop + facet_grid(vars(variable), scales = "free_y") +
       theme(strip.background = element_blank(), 
        strip.text = element_text(face="bold", size=7),
        strip.placement = "outside", 
        panel.spacing = unit(1, "lines")) + 
      labs(x= "Year", y= "Proportion of Load in each Sector")   

  area_plot_facet <- area_plot + facet_grid(vars(variable), scales = "free_y") +
     theme(strip.background = element_blank(), 
      strip.text = element_text(face="bold", size=7),
      strip.placement = "outside", 
      panel.spacing = unit(1, "lines")) + 
    labs(x= "Year", y= "Load in each Sector kWh") 

  plot <- ggarrange(area_plot_facet_prop, area_plot_facet, 
          ncol = 2,
          common.legend = TRUE) 
  plot <- annotate_figure(plot, fig.lab = paste0(cntry), fig.lab.face = "bold")
  ggsave(plot, file = paste0(output,cntry,"_area_plot_level3.png"),width = 10, height = 10)

}

##################################################################################################
# Step 3) Create Box-Plots describing distribution of residential share including only 
# countries that meet the following criteria
# Criteria: a) drop country if non-specified is non-zero for any product
#           b) drop country if zero for all products for either industrial 
#              (totind) or totother (all sectors besides industrial)
# Product Specific Criteria: 
#            a) drop country if non-specified is non-zero for specific product
#            b) drop country if zero for all products for either industrial (totind) or totother 
#                (all sectors besides industrial)               
###################################################################################################

# Part A) Make Box Plot for Original Criteria

# Finding countries where criteria a binds

criteria.a <- function(data) {
  
  crit.a <- data %>%
    filter(flow == "ONONSPEC") %>%
    filter(year == 2012) %>%
    group_by(country) %>% # OG criteria 
    summarise(max = max(value)) %>%
    data.frame() %>%
    subset(max != 0)

  unique(as.vector(crit.a$country))
}

# Finding countries where criteria b binds

criteria.b <- function(data) {
  criteria.b1 <- data %>%
    filter(flow == "TOTIND") %>%
    filter(year == 2012) %>%
    group_by(country) %>%
    summarise(max = max(value)) %>%
    data.frame() %>%
    subset(max == 0)

  criteria.b2 <- data %>%
    filter(flow != "TOTIND") %>%
    filter(year == 2012) %>%
    group_by(country) %>%
    summarise(max = max(value)) %>%
    data.frame() %>%
    subset(max == 0)

  unique(c(as.vector(criteria.b1$country),as.vector(criteria.b2$country))) 
}

# Subset main dataset to only have countries for which criteria a and b do not bind

countrylist = unique(c(criteria.a(df.level3),criteria.b(df.level3)))

df.nonbinding = df.level3 %>% filter(!(country %in% countrylist)) %>% filter(year == 2012) %>% filter(flow %in% c("RESIDENT","INDUSTRIAL"))

df.shares = df.nonbinding %>%
  group_by(country,variable) %>%
  mutate(sum = sum(value)) %>%
  mutate(share = value/sum) %>%
  data.frame() %>%
  filter(flow == "RESIDENT") %>%
  na.omit() %>%
  group_by(variable) %>%
  mutate(count = n()) %>% data.frame() %>% select(variable, share, count)

#define function for plotting count
stat_box_data <- function(y, upper_limit = max(df.shares$share) * 1.18) {
  return(
    data.frame(
      y = 0.95 * upper_limit,
      label = paste('count =', length(y), '\n',
                    'mean =', round(mean(y), 2), '\n',
                    'median =', round(median(y), 2), '\n')
    )
  )
}

box.plot <- ggplot(df.shares, aes(x=variable, y=share)) + 
  geom_boxplot() +
  #ylim(0,1) +
  stat_summary(
    fun.data = stat_box_data, 
    geom = "text", 
    hjust = 0.5,
    vjust = .9) +
  labs(title = "Residential Consumption Share", x = "Product", y = "Share")

ggsave(box.plot, file = paste0(output,"residential_share_by_product_level3.png"),width = 10, height = 10)

# Part B) Make Box Plot for Product Specific Criteria

# Finding countries where product specific criteria a binds

criteria.a <- df.other %>%
  filter(flow == "ONONSPEC") %>%
  filter(year == 2012) %>%
  group_by(country, variable) %>% # OG criteria 
  summarise(max = max(value)) %>%
  data.frame() %>%
  subset(max != 0)

# Subset main dataset to only have countries for which criteria a and b do not bind

df.nonbinding = df.other %>% filter(!(country %in% countrylist.b)) %>% filter(year == 2012) %>% left_join(criteria.a) %>% subset(is.na(max))

df.shares = df.nonbinding %>%
  group_by(country,variable) %>%
  mutate(sum = sum(value)) %>%
  mutate(share = value/sum) %>%
  data.frame() %>%
  filter(flow == "RESIDENT") %>%
  select(variable,share) %>%
  na.omit() %>%
  group_by(variable) %>%
  mutate(count = n()) %>% data.frame() %>% select(variable, share, count)

box.plot <- ggplot(df.shares, aes(x=variable, y=share)) + 
  geom_boxplot() +
  #ylim(0,1) +
  stat_summary(
    fun.data = stat_box_data, 
    geom = "text", 
    hjust = 0.5,
    vjust = .9) +
  labs(title = "Residential Consumption Share", x = "Product", y = "Share")

ggsave(box.plot, file = paste0(output,"product_specific_criteria_residential_share_by_product.png"),width = 10, height = 10)

# Plot a country energy consumption time series with fixed effect regimes. 
# To run, ensure you have installed haven and ggplot packages, and update the "root" string to your repo location

# Clean environment, and load up the required packages
rm(list = ls())
if (!require(tidyverse)) { install.packages("tidyverse"); library(tidyverse) } 
if (!require(haven)) { install.packages("haven"); library(haven) } 

root = "/Users/{YOUR_USERNAME}/Documents/repos/energy-code-release"

# load data and select only relevant variables==
df <- read_dta(paste0(root, "/data/GMFD_TINV_clim_regsort.dta")) %>%
	dplyr::select(country, year, product, load_pc, region_i, FEtag)

# Gigajoule plot for the final paper, for italy-other eenergy
name <- "ITALY-OTHER_ENERGY"
df.plot = df %>% subset(product == "other_energy" & country == "ITA")

ggplot() +
  geom_line(aes(x=year, y=load_pc, group=region_i, color= FEtag), data = df.plot, size=.3) +
  ylab("Load pc (GJ)") + 
  xlab("Year") +
  theme_bw() + theme(plot.title=element_text(size=7),
                     axis.title.y=element_text(size = 9, vjust=+0.2),
                     axis.title.x=element_text(size = 9, vjust=-0.2),
                     axis.text.y=element_text(size = 7),
                     axis.text.x=element_text(size = 7),
                     panel.grid.major = element_blank(),
                     panel.grid.minor = element_blank(),
                     legend.position = "none") +
  ggtitle(paste0(name)) 
ggsave(file = paste0(root,"/figures/fig_Appendix-A1_ITA_other_fuels_time_series_regimes.pdf"), width = 6, height = 6)

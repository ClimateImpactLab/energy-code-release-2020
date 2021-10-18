# Plot a country energy consumption time series with fixed effect regimes. 
# To run, ensure you have installed haven and ggplot packages, and update the "root" string to your repo location

# Clean environment, and load up the required packages
rm(list = ls())
library(logr)
library(haven) 
library(tidyverse)

REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
LOG <- Sys.getenv(c("LOG"))

log_open(file.path(LOG, "0_make_dataset/4_plot_ITA_other_energy_regimes_timeseries.log"), logdir = FALSE)

root = paste0(REPO, "/energy-code-release-2020")

# load data and select only relevant variables==
df <- read_dta(paste0(DATA, "/regression/GMFD_TINV_clim_regsort.dta")) %>%
	dplyr::select(country, year, product, load_pc, region_i, FEtag)

# Gigajoule plot for the final paper, for italy-other eenergy
name <- "ITALY-OTHER_ENERGY"
df.plot = df %>% subset(product == "other_energy" & country == "ITA")

ggplot() +
  geom_line(aes(x=year, y=load_pc, group=region_i, color= FEtag), data = df.plot, size=.3) +
  ylab("Total consumption per capita (GJ)") + 
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
ggsave(file = paste0(OUTPUT,"/figures/fig_Appendix-A1_ITA_other_fuels_time_series_regimes.pdf"), width = 6, height = 6)

log_print("Output:")
log_print(paste0(OUTPUT,"/figures/fig_Appendix-A1_ITA_other_fuels_time_series_regimes.pdf"))

log_close()



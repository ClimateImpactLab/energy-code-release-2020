# calculating feedback effect for appendix K

# get numbers used in the paper from NumberReferences.tex
# need to run in risingverse-py27


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
cilpath.r:::cilpath()


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

pop = (read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/', 
	'SSP3-high-IR_level-gdppc_pop-2099.csv')) %>%
	summarize(total_pop = sum(pop99)))$total_pop

# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation)
impactpc_other = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
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
                    yearlist = 2099,  
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
impact_other = impactpc_other$mean*pop/ 1000000000



# Global Electricity Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation)
impactpc_elec = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
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
                    yearlist = 2099,  
                    spec = "OTHERIND_electricity",
                    grouping_test = "semi-parametric")
impact_elec = impactpc_elec$mean*pop / 1000000000




# data sources: 
# https://www.eia.gov/todayinenergy/detail.php?id=32572
# Table 1: https://www.epa.gov/sites/production/files/2018-03/documents/emission-factors_mar_2018_0.pdf

# EF : emission factor

mmBTU_per_kwh = 0.003412969
nat_gas_CC_heat_rate = 7340
kwh_per_GJ = 277.7777778

EF_table = data.frame(
	chemical = c("CO2","N2O","CH4"),
	# elec_EF_kg_per_kwh = c(0.3894604,0.000000734,0.00000734),
	# other_EF_kg_per_kwh = c(0.18109215,0.0000003412969283,0.0000034129692833),
	nat_gas_EF_kg_per_mmbtu = c(53.06,0.0001,0.001),
	gwps = c(1,298,25))

EF_table = EF_table %>%
			mutate(other_EF_kg_per_kwh = nat_gas_EF_kg_per_mmbtu * mmBTU_per_kwh,
				   elec_EF_kg_per_kwh = nat_gas_EF_kg_per_mmbtu / 1000000 * nat_gas_CC_heat_rate) %>%

EF_elec = sum(EF_table$elec_EF_kg_per_kwh * kwh_per_GJ / 1000)
EF_other = sum(EF_table$other_EF_kg_per_kwh * kwh_per_GJ / 1000)

additional_emission_elec = EF_elec * impact_elec
additional_emission_other = EF_other * impact_other


output_table = data.frame(electricity = c(impactpc_elec$mean, impact_elec, EF_elec, additional_emission_elec),
						  other_fuels = c(impactpc_other$mean, impact_other, EF_other, additional_emission_other))
rownames(output_table) = c("Per capita impact (GJ)","Total impact (billion GJ)",
	"Emissions factor (t CO2e per GJ)","Additional emissions (Gt CO2e)")

write.csv(output_table, "/home/liruixue/repos/energy-code-release-2020/data/appendix_K_table.csv")





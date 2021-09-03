* code doing this sanity check:
* pick a couple of IRs (2 from among the kernel density IRs 
* that are in different countries would be fine) and plot 
* their electricity/other fuels prices over time, 
* under the tool price scenario and the 1.4% scenario. 
* actually this doesn’t even need to be in a graph. 
* it can just be in a spreadsheet.

* prices are stored at /shares/gcp/social/baselines/energy
clear all
set more off
macro drop _all

use "/shares/gcp/social/baselines/energy/IEA_Price_FIN_Clean_gr0082_GLOBAL_COMPILE.dta", clear
rename other_energycompile_price other_energy_price_0082
rename electricitycompile_price electricity_price_0082
drop *peak*
*gen growth_rate = "0.0082"
tempfile p0082
save `p0082'

use "/shares/gcp/social/baselines/energy/IEA_Price_FIN_Clean_grm0027_GLOBAL_COMPILE.dta", clear
rename other_energycompile_price other_energy_price_m0027
rename electricitycompile_price electricity_price_m0027
drop *peak*
*gen growth_rate = "-0.0027"
tempfile pm0027
save `pm0027'

use "/shares/gcp/social/baselines/energy/IEA_Price_FIN_Clean_gr014_GLOBAL_COMPILE.dta", clear
rename other_energycompile_price other_energy_price_014
rename electricitycompile_price electricity_price_014
drop *peak*

*gen growth_rate = "0.014"
tempfile p014
save `p014'

merge 1:1 year country using `pm0027', nogen
merge 1:1 year country using `p0082', nogen

keep if country == "CHN" | country == "IND" | country == "BRA" | country == "USA" | country == "SWE"
twoway line other_energy_price_0082 other_energy_price_014 year, by(country) 
graph export "/home/liruixue/repos/energy-code-release-2020/figures/price/other_energy.pdf", replace

twoway line electricity_price_m0027 electricity_price_014 year, by(country) 
graph export "/home/liruixue/repos/energy-code-release-2020/figures/price/electricity.pdf", replace




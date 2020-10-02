/*
Creator: Yuqi Song
Date last modified: 1/25/19 
Last modified by: Maya Norman

Purpose: Extrapolate Price Data

Notes: Need to check price units confirm PPP

To Do:

* improve pop data use
* make sure no countries are in the data set that we dont want to be in the dataset!
* fix intermediary dataset names so they make more sense

*/


clear all
set more off
macro drop _all
pause on

//SET UP RELEVANT PATHS

	 * This path is for running the code on Sacagawea
local ROOT "/home/liruixue"
local DROPBOX "/mnt"
local GIT "`ROOT'/repos/energy-code-release-2020"
local RAWDATA "/shares/gcp/estimation/energy/IEA"
	
global replicated_data "`DROPBOX'/CIL_energy/IEA_Replication/Data"
global price_data "$replicated_data/Projection/prices"
global sub_script_path "`GIT'/adhoc_scripts/referee/percentage_growth/sub_scripts"
global covar_data "`DROPBOX'/CIL_energy/IEA_Replication/Data/Projection/covariates/FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline.csv"

********************************************************************************

/* 

Step 0: load in and clean supllementary datasets -- subregionids, population,
load, whole sample

*/

//subregionids

insheet using "$replicated_data/Cleaning/UNSD — Methodology.csv", comma names clear
do `sub_script_path'/subregionid_clean
tempfile subregion
save `subregion', replace

//Full dataset: pop
use "$replicated_data/Analysis/GMFD/rationalized_code/replicated_data/data/IEA_Merged_long_GMFD.dta", clear
qui keep if year==2010
replace pop=round(pop)

//pop data
keep country pop
qui keep if pop!=.
qui duplicates drop country, force
tempfile pop
save `pop', replace

//whole sample
insheet using "$covar_data", clear
qui keep if year==2010
qui gen iso=substr(region,1,3)
qui duplicates drop iso, force 
keep iso
rename iso country
qui merge 1:1 country using `subregion'
drop if _merge==2
**Assign regions**
qui replace subregionid=7 if country=="TWN"
qui replace subregionid=4 if country=="KO-"
qui replace subregionid=9 if country=="SMX"
qui replace subregionid=9 if country=="CL-"
qui replace subregionid=8 if country=="SP-"
qui replace country="XKO" if country=="KO-"
drop _merge
drop if subregionid==.
tempfile allregions
save `allregions', replace
//load income deflator data
**WB source**
import excel using "$replicated_data/Cleaning/API_NY.GDP.DEFL.ZS_DS2_en_excel_v2.xls", sheet("Data") firstrow clear cellrange(A3:BI268)
do `sub_script_path'/prices/clean/clean_deflator_data
tempfile deflat_usa
qui save `deflat_usa', replace

/*

Step 1: Extrapolate in sample price data so that there is one tax free price observation 
for each country, flow, product if there exists a price value in at least one year for a given 
country, product, flow, product combination.

*/

**Bring in cleaned and Deflated Data
insheet using "$price_data/1_inter/IEA_Price.csv", comma names clear
sort country year

do `sub_script_path'/prices/construct/1_extrapolate_inSample
do `sub_script_path'/prices/construct/2_clean_inSample_priceData

tempfile inSample
save `inSample', replace

/*

Step 2: Extrapolate prices so that all countries have a tax free price observation
for each flow and product combination. If a given country, flow, product combination
is missing, the country, flow, product combination should be assigned the global
populaiton weighted mean.

*/

**Part A: Bring in pop data, whole sample of countries and subregionids

***Merge in subregionids

use `inSample', clear
merge 1:1 country using `allregions', keep(2 3) nogen
save `inSample', replace

***Add in populations
merge 1:1 country using `pop', keep(1 3) nogen
replace pop = . if year == . //this is unnecessary, but keeps code keeps code clean and direct

**Assign all inSample observations to the Global group
qui gen GLOBALgroup=1

**Part B: Extrapolate

do `sub_script_path'/prices/construct/3_extrapolate_outSample
save `inSample', replace

//Save Dataset: 
qui save "$price_data/1_inter/IEA_Price_InSample_GLOBAL.dta", replace

/*

Step 3: Calculate consumption shares for the 3 different fuel levels 

*3 different fuel levels:

	1) other_energy, electricity
	2) natgas, coal, etc.
	3) coal and oil subfuels
	
*/

**Generate share data subfuels of Oil and Coal (fuel level 3 shares)

qui use "$price_data/1_inter/consumption_shares.dta", clear
merge m:1 country using `allregions', keep (3) nogen //dropping one relevant country here (Netherland Antilles -- historically was dropping as well)
keep if flow == "compile"

//please ignore how convoluted this is... just need to get all the names correct for the rest of the script
rename * value*
rename (valuecountry valueflow valuesubregionid) (country flow subregionid)
reshape long value, i(country flow subregionid) j(product) string
replace product = lower(product)
reshape wide value, i(country flow subregionid) j(product) string
reshape wide value*, i(country subregionid) j(flow) string
rename value* *

//get level 3 shares: coal and oil subproducts
foreach type in "Coal" "Oil" {
	preserve
	drop coalcompile oil_productscompile
	do `sub_script_path'/shares/gen_`type'_shares
	tempfile `type'sub
	qui save ``type'sub', replace
	restore
}

** Generate share data subfuels of other energy (fuel level 2 shares)
do $sub_script_path/shares/gen_other_energy_product_shares

foreach type in "Coal" "Oil" {
	qui merge 1:1 country subregionid using ``type'sub'
	assert _merge == 3
	drop _merge
}

**MLI gives the average**
foreach var of varlist *share2 *share3 {
	qui replace `var'=0 if `var' == .
}

keep country *share2 *share3 subregionid
tempfile IEA_insample_share
save `IEA_insample_share', replace

**Sample mean by subregionid**

**Spillover to all regions**
qui use `allregions', clear
merge 1:1 country using `IEA_insample_share'
assert _merge!=2
drop _merge
keep country subregionid *share2 *share3
sort country
save "$price_data/1_inter/IEA_share_sort_all_GLOBAL_COMPILE.dta", replace

/*

Step 3.5: Estimate Global average consumption shares for 
aggregating price data (don't want price data to be sector specific)

*/

qui use "$price_data/1_inter/consumption_shares.dta", clear
merge m:1 country using `allregions', keep (3) nogen //dropping one relevant country here (Netherland Antilles -- historically was dropping as well)

//clean data
rename NONBIODIES DIESEL
gen GASOLINE = NONBIOGASO + AVGAS + JETGAS
keep country flow GASOLINE COKCOAL BITCOAL LPG RESFUEL GASOLINE NATGAS DIESEL  
rename * value*
rename (valuecountry valueflow) (country flow)
reshape long value, i(country flow) j(product) string

//find global share averages for each product we have other energy price data for 
do $sub_script_path/shares/global_average_shares
tempfile sector_shares
save `sector_shares', replace

/*

Step 4: Combine output of steps 2 and 3 to calculate:

	1) consumption share weighted average prices for other_energy product prices 
	2) consumption share weighted other_energy price for each country flow combination

Notes:

	a) If the consumption share weighted average price ends up being a zero or 
	missing value, compute the average other_energy product price instead. 
	
	b)Because there are only residential and industrial prices, we compute the 
	industrial consumption share by adding TOTIND and COMMPUB sectors together. 

*/

**load price data and clean
qui use "$price_data/1_inter/IEA_Price_InSample_GLOBAL.dta", clear

**merge in shares to aggregate sector specific prices for each fuel and clean

//rename for reshape
foreach sector in "households" "industry" {
	rename *`sector'_atprice `sector'_atprice*
}
reshape long households_atprice industry_atprice, i(year country) j(product) string
merge m:1 product using `sector_shares', keep (1 3) nogen //note shares should sum to 1 if they aren't missing
gen compile_atprice = households_atprice*share_households + industry_atprice*share_industry

//if missing price for household or industry replace with nonmissing price value 
foreach sector in "households" "industry" {	
	replace compile_atprice = `sector'_atprice if missing(compile_atprice)
}

//the new price should fit between the two sector disaggregated prices, or equal one in the case where one sector's price was missing
assert(compile_atprice >= min(households_atprice, industry_atprice) & compile_atprice <= max(households_atprice, industry_atprice))

keep year country product compile_atprice subregionid GLOBALgroup
reshape wide compile_atprice, i(country year subregionid GLOBALgroup) j(product) string
rename compile_atprice* *compile_atprice

**merge in shares to aggregate fuels up to other energy
qui merge 1:1 country using "$price_data/1_inter/IEA_share_sort_all_GLOBAL_COMPILE.dta"
assert _merge==3
drop _merge

//Generate other energy share weighted average price
do $sub_script_path/other_energy_share_weighted_average_price

/*

Step 5: Construct Electricity Prices using the World Energy Outlook 2017 IEA 
figure. Prices are extrapolated using geographic nearest neighbor. Only one 
electricity price is assigned to each country; there are no flow specific 
elctricity prices. Prices are also converted to 2005 USD/kWh. 

*/

merge 1:1 country using `pop', keep(1 3) nogen
assert pop!=3 if inlist(country, "USA","CAN","CHN","JPN","KOR")


//construct/extrapolate electricity prices
do $sub_script_path/prices/construct/construct_electricity_prices
drop pop

//make sure only have countries of interest

merge 1:1 country using `allregions', keep(3) nogen 

//Deflate electricity prices

preserve
	qui use `deflat_usa', clear
	qui keep if year==2016
	tempfile deflat2016
	qui save `deflat2016', replace
restore
preserve
	qui use `deflat_usa', clear
	qui keep if year==2014
	tempfile deflat2014
	qui save `deflat2014', replace
restore

cap drop id
qui gen id=1
qui merge m:1 id using `deflat2016'
drop _merge
qui replace electricitycompile_atprice = electricitycompile_atprice * def2005/def
drop def def2005
qui merge m:1 id using `deflat2014'
drop _merge
qui replace electricitycompile_peakprice = electricitycompile_peakprice * def2005/def
drop def def2005
drop id year

qui save "$price_data/2_final/IEA_Price_FIN_GLOBAL_COMPILE.dta", replace


/*

Step 6: Clean and Grow Price Data

*/

//Clean price data
rename *_atprice *_price
keep country electricity* other_energy* 
qui save "$price_data/2_final/IEA_Price_FIN_Clean_GLOBAL_COMPILE.dta", replace

**Grow prices**

local mg=0

foreach gr of num 0 0.014 0.02 0.03 0.05 { 

preserve
	rename *peakprice *peak
	foreach var of varlist *price *peak {
	rename `var' `var'2010
	forval yr=2011/2100 {
		local j=`yr'-1
		qui gen double `var'`yr'=`var'`j'*(1+`gr')
	}
	}
	qui reshape long electricitycompile_peak other_energycompile_price electricitycompile_price , i(country) j(year)
	rename *peak *peakprice
	label data "price growth rate=`gr'"
	
	**replace back names of James**
	qui replace country="KO-" if country=="XKO"
	qui replace country="SMX" if country=="SXM"
	local gr = subinstr("`gr'",".","",.) 
	
	qui save "$price_data/2_final/IEA_Price_FIN_Clean_gr`gr'_GLOBAL_COMPILE.dta", replace
restore

local mg=`mg'+1

}

* Note - this line needs a little bit of fumbling, depending on who the user is
if "`c(username)'" == "tbearpar"{
	shell scp -i ~/.ssh/id_rsa.pub $price_data/2_final/IEA_Price_FIN_Clean_gr*_GLOBAL_COMPILE.dta tbearpark@sacagawea.gspp.berkeley.edu:/shares/gcp/social/baselines/energy/
}
else{
	shell scp -i ~/.ssh/id_rsa.pub $price_data/2_final/IEA_Price_FIN_Clean_gr*_GLOBAL_COMPILE.dta `c(username)'@sacagawea.gspp.berkeley.edu:/shares/gcp/social/baselines/energy/
}

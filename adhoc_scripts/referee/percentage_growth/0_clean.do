/*
Creator: Maya Norman
Date last modified: 7/10/19 
Last modified by: Maya

Purpose: Clean Data that supports 1_extrapolate.do

*/


clear all
set more off
macro drop _all
pause on

//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{
	local ROOT "/Users/`c(username)'"
	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "`ROOT'/Documents/Repos/gcp-energy"

}
else if "`c(username)'" == "manorman"{
	 * This path is for running the code on Sacagawea
	local ROOT "/home/`c(username)'"
	local DROPBOX "/home/`c(username)'"
	local GIT "`ROOT'/gcp-energy"
}

else if "`c(username)'" == "tbearpar"{
	 * This path is for running the code on Sacagawea
	local ROOT "/home/tbearpark"
	local DROPBOX "/local/shsiang/Dropbox"
	local GIT "`ROOT'/repo/gcp-energy"
}

* new prices output file root: 
global intermediate_price_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Projection/prices/1_inter"
global sub_script_path "`GIT'/rationalized/2_projection/0_clean_prices/percentage_growth/sub_scripts"
global dataset_construction "`GIT'/rationalized/0_make_dataset"
global RAWDATA "/shares/gcp/estimation/energy/IEA"
global cleaning_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Cleaning"

/*

Step 1: Load, clean and Merge Price Data

*/

**Part a: Non-OECD**
//Merging in all individual csvs
global oecd = 0
insheet using "$RAWDATA/END_NMC_06112017200924980.csv", comma names clear
do $sub_script_path/prices/clean/nmc_labels //does not alter dataset just outputs a labels dataset into RAW and DATA
do $sub_script_path/prices/clean/clean_rawPrices

save "$intermediate_price_data/IEA_Price_NMC.dta", replace

**Part b: OECD**
//Merging in all individual csvs
global oecd = 1
insheet using "$RAWDATA/END_US_07112017180419706.csv", comma names clear
do $sub_script_path/prices/clean/oecd_labels //identical to nmc_labels just outputs different filenames
do $sub_script_path/prices/clean/clean_rawPrices

save "$intermediate_price_data/IEA_Price_OECD.dta", replace

//Part c: Append and factoring
use "$intermediate_price_data/IEA_Price_NMC.dta", clear
append using "$intermediate_price_data/IEA_Price_OECD.dta"

do $sub_script_path/prices/clean/convert_and_net_tax

label data "deflated to 2005 USD/kWh, real values"
sort country year
order country year *atprice *price *tax
save "$intermediate_price_data/IEA_Price.dta", replace
outsheet using "$intermediate_price_data/IEA_Price.csv", comma replace

/*

Step 2: Create Coal and Oil subfuel load datasets

*/

//Part A: Load and clean 2013-15 load data for consumption shares

//load necessary dataset names
import delimited using "$cleaning_data/raw_IEA_data_toc.csv", clear varnames(4)
keep if dataset_id == "share_price" & name != "Full dataset.csv"
levelsof name, local(datalist)

//load load data
local counter = 1
foreach name in `datalist' {

	insheet using "$RAWDATA/`name'", comma names clear
	gen batch = `counter'

	if `counter' == 1 {
		qui tempfile data
		qui save `data', replace
	}
	else {
		append using `data'
		qui save `data', replace
	}

	local counter = `counter' + 1

}

//clean data
replace value=. if inlist(flagcodes, "M","C","L") 
rename (v2 v4 v6 time) (country_description product_description flow_description year)
pause
keep country* year product* flow* value batch

do $sub_script_path/shares/0_break2_clean.do

save `data', replace

//Part B: Load and clean 1960-2013 load data for consumption shares

insheet using "$RAWDATA/Full dataset.csv", comma names clear
rename time year
drop if year == 2013
gen batch = `counter'
replace value=. if inlist(flagcodes,"M","C","L")
keep country year product flow value batch
do $sub_script_path/shares/0_break2_clean.do
append using `data'
keep year country product flow value
save `data', replace

//Part C: Load and Clean Aggregated Fuel Load Data for consumption shares

do $dataset_construction/energy_load_data/1_extract_clean_energy_load_data
rename (*TOTIND *TOTOTHER) (TOTIND* TOTOTHER*)
reshape long TOTIND TOTOTHER, i(year country) j(product) string
rename (TOTOTHER TOTIND) (valueTOTOTHER valueTOTIND)
reshape long value, i(year country product) j(flow) string
drop if product == "natural_gas"
append using `data'

// Part D: Clean and Save Full Dataset for Price Construction

//convert units
**Replacing and Collapse for all coal**
local factor=0.0238845897  //IEA conversion meter usage, 1TJ to kt
foreach prod in "GASWKSGS" "COKEOVGS" "BLFURGS" "OGASES" "NATGAS" {
	replace value=value*`factor' if product=="`prod'"
}	

**Convert to kWh**
local factor=11630000
replace value=value*`factor' if !inlist(product,"coal", "natural_gas", "electricity", "heat_other", "biofuels", "oil_products", "solar")

//clean up names so reshaping is done without creating duplicate observations
qui replace country="XKO" if country=="KOSOVO"
qui replace country="GRL" if country=="GREENLAND"
qui replace country="MLI" if country=="MALI"
qui replace country="MUS" if country=="MAURITIUS"

//note: exceptions are for countries that do not exist in the 2012 dataset
//note: second set of exceptions are for level 2 products only have TOTOTHER up to 2012
qui keep if year==2012 | (year==2013 & country=="CUW") | (year==2013 & country=="NER") | (year==2013 & country=="SSD") | (year==2013 & country=="SUR")
drop if year==2012 & inlist(country, "CUW","NER","SSD","SUR") & !inlist(product,"coal", "natural_gas", "electricity", "heat_other", "biofuels", "oil_products", "solar")
drop if year==2013 & inlist(country, "CUW","NER","SSD","SUR") & inlist(product,"coal", "natural_gas", "electricity", "heat_other", "biofuels", "oil_products", "solar")
drop year

**Reshape**
replace flow=lower(flow)
reshape wide value, i(country product) j(flow) string
gen valuecompile = valuetotother + valuetotind

//industrial for price aggregation across sectors, totind for price aggregation across fuels
gen valueindustrial = valuetotind + valueagricult + valuecommpub + valuefishing if !inlist(product,"coal", "natural_gas", "electricity", "heat_other", "biofuels", "oil_products", "solar")
drop valueagricult valuecommpub valuefishing
reshape long value, i(country product) j(flow) string
reshape wide value, i(country flow) j(product) string
rename value* *

**Save Consumption share data
order country 
sort country
label data "unit: kWh"
save "$intermediate_price_data/consumption_shares.dta", replace



/*

Purpose: Master Do File for Dataset Construction

This script takes in raw data input files either downloaded from the internet or constructed using merge_transform_average.py
(https://bitbucket.org/ClimateImpactLab/climate_data_aggregation/src/master/). Please use 0_Clim_Config_Gen.do to write configs
that are passed into the Climate Data Aggregation code.

Before this do file is run the following steps need to be completed:

1) Load, population, and income data must be extracted.
	-Please refer to https://paper.dropbox.com/doc/Energy-Replication-Data-Extraction-and-Clean--AcW~Qw9B5VVB29k4PJCYL1I3Ag-VAYyKKRjKXNub5MzctYgB
	for data extraction instructions.

2) Climate Data Must be Generated
	- Climate Data is generated to reflect geographical regions used in the load data. 
	See the dropbox paper referenced above as well as the aggregated climate data cleaning code to understand how the 
	climate data is generated to reflect load data specific geographic regions.

What happens in the do files called in this script:

Step 1) Construct Population, Income, Load, and Climate Datasets
Step 2) Merge Population, Income, Load and Climate Datasets

*/

clear all
set more off
macro drop _all
pause on
cap ssc install rangestat

cilpath
/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 
local root "$REPO/energy-code-release-2020"


/////////////////////////////////////////////////////////////////////////////////////////////////

* Step 0: Define code and dataset paths

// code path referenced by multiple files
global dataset_construction "`root'/0_make_dataset/"

// output data path
local DATA "`root'/data"

********************************************************************************************************************************************
*Step 1: Construct Population/Income, Load, and Climate Datasets
********************************************************************************************************************************************

//Part A: Climate Data Construction

do "$dataset_construction/climate/1_clean_climate_data.do"
clean_climate_data, clim("GMFD") programs_path("$dataset_construction/climate/programs")

// *****************************
// code to check the difference between pixel-level vs normal interacted terms
gen old_polyBelow1_x_hdd = polyBelow1_GMFD * hdd20_GMFD
gen old_polyBelow2_x_hdd = polyBelow2_GMFD * hdd20_GMFD

gen old_polyAbove1_x_cdd = polyAbove1_GMFD * cdd20_GMFD
gen old_polyAbove2_x_cdd = polyAbove2_GMFD * cdd20_GMFD

gen new_polyBelow1_x_hdd = polyBelow1_x_hdd_GMFD
gen new_polyBelow2_x_hdd = polyBelow2_x_hdd_GMFD

gen new_polyAbove1_x_cdd = polyAbove1_x_cdd_GMFD
gen new_polyAbove2_x_cdd = polyAbove2_x_cdd_GMFD



foreach v in polyBelow1_x_hdd polyBelow2_x_hdd polyAbove1_x_cdd polyAbove2_x_cdd {
	di "variable: `v'"
	qui corr old_`v' new_`v'
	di "all: `r(rho)'"
	qui corr old_`v' new_`v' if country == "USA"
	di "USA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "CHN"
	di "CHN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "FRA"
	di "FRA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "RUS"
	di "RUS: `r(rho)'"
	qui corr old_`v' new_`v' if country == "JPN"
	di "JPN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "IND"
	di "IND: `r(rho)'"
	qui corr old_`v' new_`v' if country == "MEX"
	di "MEX: `r(rho)'"
	qui corr old_`v' new_`v' if country == "BRA"
	di "BRA: `r(rho)'"
	qui corr old_`v' new_`v' if country == "CAN"
	di "CAN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "FIN"
	di "FIN: `r(rho)'"
	qui corr old_`v' new_`v' if country == "GRL"
	di "GRL: `r(rho)'"
	qui corr old_`v' new_`v' if country == "DNK"
	di "DNK: `r(rho)'"
	
	di ""

}

//gen diff = new_interaction - old_interaction
//gen diff_pct = diff / old_interaction
//sum old_interaction new_interaction diff*
// *****************************

tempfile climate_data
save `climate_data', replace
save "`DATA'/climate_data", replace
//Part B: Population and Income Data Construction
use "`DATA'/climate_data", clear

do "$dataset_construction/pop_and_income/1_extract_and_clean.do"

tempfile population_and_income_data
save `population_and_income_data', replace

//Part C: Load Data Clean and Prepare For Merge with Pop, Inc, and Climate Data

do $dataset_construction/energy_load/1_extract_clean_energy_load_data.do

//Restrict Dataset to specified years (increase balance in dataset)
drop if year > 2010 | year < 1971

tempfile energy_load_data
save `energy_load_data', replace

******************************************************************************************************************************************
*Step 2: Merge Pop, Inc and Climate Data with Load Data and Clean Dataset Based on Specification
******************************************************************************************************************************************

//Part A: Merge Data
use `energy_load_data', clear

merge m:1 country year using `population_and_income_data'
keep if _merge!=2
drop _merge
**climate**
merge m:1 year country using `climate_data'
keep if _merge!=2
drop _merge

//Part B: Construct Per Capita and log_pc

//Constructing per capita and log(pc) measures
foreach var of varlist coal* oil* natural_gas* electricity* heat_other* biofuels* solar* {
	qui gen double `var'_pc = `var' / pop
	qui gen double `var'_log_pc = log(`var'_pc)
} 

//Part C: Complete Specification Specific Data Set Cleaning Steps

do "$dataset_construction/merged/0_break2_clean.do"  

di "mission complete :)"
save "`DATA'/IEA_Merged_long_GMFD.dta", replace




/*

Purpose: Master Do File for Analysis Dataset Construction
(Takes dataset from cleaned from IEA_merged_long*.dta to GMFD_*_regsort.dta)

Step 1) Construct reporting regimes and drop data according to selected coded issues
Step 2) Match product specific climate data with product
Step 3) Identify income spline knot location by constructing two income groups for each product
Step 4) Perform Final Cleaning Steps before first differenced interacted variable construction
	* Classify countries within 1 of 13 UN regions
	* Classify countries in income deciles and groups
Step 5) Construct First Differenced Interacted Variables
 
*/

clear all
set more off
qui ssc inst egenmore
macro drop _all
pause off
cilpath

/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 

global root "$REPO/energy-code-release-2020"

/////////////////////////////////////////////////////////////////////////////////////////////////

******Set Script Toggles********************************************************

// What model do you want? TINV_clim or TINV_clim_EX
global model "TINV_clim"
local model $model	

*************************************************************************
* Step 1) Construct FE regimes and drop data according to specification
*************************************************************************

do "$root/0_make_dataset/merged/1_issue_fix_v2.do"

//rename COMPILE -- OTHERIND and make sure only have desired flows and products for spec
// OTHERIND = TOTOTHER + TOTIND

replace flow = "OTHERIND" if flow == "COMPILE"
keep if inlist(flow, "OTHERIND")
keep if inlist(product, "other_energy", "electricity")

*************************************************************************
* Step 2) Match Product Specific Climate Data with respective product
*************************************************************************

* Reference climate data construction for information about the issues causing different climate data for different products

forval p=1/4 {
	replace temp`p'_GMFD = temp`p'_other_GMFD if inlist(product,"other_energy")
}

forval q=1/2 {
	replace precip`q'_GMFD = precip`q'_other_GMFD if product=="other_energy"
	replace polyAbove`q'_GMFD = polyAbove`q'_other_GMFD if inlist(product,"other_energy")
	replace polyBelow`q'_GMFD = polyBelow`q'_other_GMFD if inlist(product,"other_energy")
}

replace cdd20_TINV_GMFD = cdd20_other_TINV_GMFD if inlist(product,"other_energy")
replace hdd20_TINV_GMFD = hdd20_other_TINV_GMFD if inlist(product,"other_energy")


***********************************************************************************************************************
* Step 3) Identify income spline knot location by constructing two income groups for each product
***********************************************************************************************************************

//Part A) Prepare Dataset for Income group construction by ensuring only data included in regression remains in dataset

	//Keep only observations we actually have data for
	drop if load_pc == . | lgdppc_MA15 == . | temp1_GMFD == .


	// zero energy consumption for electricity or other energy for TOTOTHER and TOTIND deamed infeasible -> drop observations
	drop if load_pc == 0

	//generate reporting regimes
	egen region_i = group(country FEtag flow product)
	sort region_i year
	tset region_i year

	//Organize variables
	order country year flow product load_pc lgdppc_MA15 pop FEtag *GMFD*

//Part B) Construct Income Groups

	preserve

		duplicates drop country year, force

		// create income and climate quantiles 
		qui egen gpid=xtile(lgdppc_MA15), nq(10)
		pause
		qui egen tpid=xtile(cdd20_TINV_GMFD), nq(3)
		qui egen tgpid=xtile(lgdppc_MA15), nq(3)

		**reversing the order of tpid to put hot ones on top**
		qui replace tpid = 4 - tpid
			
		//Generate large income groups (knot location varies by product)

		qui generate largegpid_electricity =.
		qui replace largegpid_electricity = 1 if (gpid>=1) & (gpid<=6) 
		qui replace largegpid_electricity = 2 if gpid==7 | gpid==8 
		qui replace largegpid_electricity = 2 if gpid==9 | gpid==10 
						
		qui generate largegpid_other_energy =.
		qui replace largegpid_other_energy = 1 if (gpid >= 1) & (gpid <= 2) 
		qui replace largegpid_other_energy = 2 if (gpid >= 3) & (gpid <= 6) 
		qui replace largegpid_other_energy = 2 if (gpid >= 7) & (gpid <= 10)				

		** center the year around 1971
		gen cyear = year - 1971

		** generate year variable for piecewise linear time effect interaction
		gen pyear = year - 1991 if year >= 1991
		replace pyear = 1991 - year if year < 1991


		//keep only necessary vars
		keep cdd20_TINV_GMFD hdd20_TINV_GMFD country *year lgdppc_MA15 gpid tpid tgpid large*

		// generate average variables for climate and income quantiles for plotting
		//average CDD in each cell
		qui egen avgCDD_tpid=mean(cdd20_TINV_GMFD), by(tpid) 
		//average HDD in each cell
		qui egen avgHDD_tpid=mean(hdd20_TINV_GMFD), by(tpid) 
		//average lgdppc in each cell
		qui egen avgInc_tgpid=mean(lgdppc_MA15), by(tgpid) 
		//average lgdppc in each climate decile
		qui egen avgInc_tpid=mean(lgdppc_MA15), by(tpid) 

		qui egen maxInc_gpid=max(lgdppc_MA15), by(gpid) //max lgdppc in each cell - this is needed for configs
		
		//max lggdppc for each large income group for each cell
		foreach var in "other_energy" "electricity" {
			qui egen maxInc_largegpid_`var'=max(lgdppc_MA15), by(largegpid_`var') 
		}


		local break_data "$root/data/break_data_`model'.dta"
		save "`break_data'", replace

	restore

***********************************************************************************************************************
*Step 4) Perform Final Cleaning Steps
***********************************************************************************************************************

//Merge in income group definitions
merge m:1 country year using `break_data', nogen keep(3)
sort gpid

//Generate product specific large income groups
gen largegpid = largegpid_electricity if product == "electricity"
replace largegpid = largegpid_other_energy if product == "other_energy"
drop largegpid_electricity largegpid_other_energy

//Generate dummy variable by income decile and group 
tab gpid, gen(ind)
tab largegpid, gen(largeind)

//Generate sector and fuel dummies

* 1 = electricity, 2 = other_energy
tab product, gen(indp)
egen product_i = group(product)

* only 1 sector, so this step exists due to path dependency
tab flow, gen(indf)
egen flow_i = group(flow)


* generate time period dummies for interaction
** for piecewise linear interaction
gen indt = 1 if year >= 1991
replace indt = 0 if year < 1991

** for decades interaction
gen indd = 0
replace indd = 1 if year >= 1980
replace indd = 2 if year >= 1990
replace indd = 3 if year >= 2000



// Classify world into 13 regions based on UN World Regions Classifications (for fixed effect... reference Temperature Response of Energy Consumption Section )

**Clean the region data**
preserve
insheet using "$root/data/UNSD — Methodology.csv", comma names clear
generate subregionid=.
replace subregionid=1 if regionname=="Oceania" 
replace subregionid=2 if subregionname=="Northern America" 
replace subregionid=3 if subregionname=="Northern Europe" 
replace subregionid=4 if subregionname=="Southern Europe"
replace subregionid=5 if subregionname=="Western Europe"
replace subregionid=6 if subregionname=="Eastern Europe" | subregionname=="Central Asia" 
replace subregionid=7 if subregionname=="Eastern Asia" 
replace subregionid=8 if subregionname=="South-eastern Asia" 
replace subregionid=9 if intermediateregionname=="Caribbean" | intermediateregionname=="Central America"
replace subregionid=10 if intermediateregionname=="South America"
replace subregionid=11 if subregionname=="Sub-Saharan Africa" 
replace subregionid=12 if subregionname=="Northern Africa" | subregionname=="Western Asia" 
replace subregionid=13 if subregionname=="Southern Asia"
drop if subregionid==.
keep isoalpha3code subregionid subregionname
replace subregionname="Oceania" if subregionid==1
replace subregionname="Caribbean and Central America" if subregionid==9
replace subregionname="South America" if subregionid==10
replace subregionname="Central Asia and Eastern Europe" if subregionid==6
replace subregionname="Western Asia and Northern Africa" if subregionid==12
rename isoalpha3code country 
tempfile subregion
save `subregion', replace
restore

merge m:1 country using `subregion'
keep if _merge!=2
drop _merge

replace subregionid = 6 if country=="FSUND"
replace subregionid = 4 if country=="YUGOND"
replace subregionid = 7 if country=="TWN"
replace subregionid = 4 if country=="XKO"
replace subregionname = "Central Asia and Eastern Europe" if country == "FSUND"
replace subregionname = "Southern Europe" if country == "YUGOND"
replace subregionname = "Eastern Asia" if country == "TWN"
replace subregionname = "Southern Europe" if country=="XKO"

***********************************************************************************************************************
* Step 5) Construct First Differenced Interacted Variables
***********************************************************************************************************************
do "$root/0_make_dataset/merged/2_construct_FD_interacted_variables.do"
save "$root/data/GMFD_`model'_regsort.dta", replace


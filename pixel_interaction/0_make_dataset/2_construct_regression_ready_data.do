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


/////////////// SET UP USER SPECIFIC PATHS //////////////////////////////////////////////////////

// path to energy-code-release repo 

global root "/home/liruixue/repos/energy-code-release-2020/pixel_interaction"

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

		//keep only necessary vars
		keep cdd20_TINV_GMFD hdd20_TINV_GMFD country year lgdppc_MA15 gpid tpid tgpid large*

		// generate average variables for climate and income quantiles for plotting
		//average CDD in each cell
		qui egen avgCDD_tpid=mean(cdd20_TINV_GMFD), by(tpid) 
		//average HDD in each cell
		qui egen avgHDD_tpid=mean(hdd20_TINV_GMFD), by(tpid) 
		//average lgdppc in each cell
		qui egen avgInc_tgpid=mean(lgdppc_MA15), by(tgpid) 

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

/* 
// see difference between old and new interactions
//use "$root/data/GMFD_`model'_regsort.dta", replace
use "${root}/data/climate_data.dta", clear
gen old_interaction = cdd20_TINV_GMFD * polyAbove1_GMFD
gen new_interaction = polyAbove1_x_cdd_GMFD
gen diff = new_interaction - old_interaction
gen pct_diff = diff / old_interaction
sum *interaction *diff*
corr old_interaction new_interaction
//keep if inlist(country, "VAT") //one-pixel country
keep if inlist(country, "MAF") 
//two-pixel country
list *interaction *diff* cdd20_TINV_GMFD polyAbove1_GMFD polyAbove1_x_cdd_GMFD country
keep *interaction *diff* cdd20_TINV_GMFD polyAbove1_GMFD polyAbove1_x_cdd_GMFD country year
 */
/* some checks For MAF
segment weights
     +-------------------------------------------------------------------------------------------------------+
     | iso       area   pix_ce~x   pix_ce~y     pop   areato~l   poptotal     areawt     popwt         shpid |
     |-------------------------------------------------------------------------------------------------------|
  1. | MAF   .0046577    -63.125     18.125   27385   .0047939      27389   .9715909   .999854   gadm28_adm0 |
  2. | MAF   .0001362    -62.875     18.125       4   .0047939      27389   .0284091   .000146   gadm28_adm0 |
     +-------------------------------------------------------------------------------------------------------+

long run climate in these two pixels at pixel level
     +--------------------------------+
     | pix_ce~x   pix_ce~y    lr_clim |
     |--------------------------------|
  1. |  -63.125     18.125   2138.848 |
  2. |  -62.875     18.125   846.4422 |
     +--------------------------------+
which, if aggregated with popwt, equals 
 */


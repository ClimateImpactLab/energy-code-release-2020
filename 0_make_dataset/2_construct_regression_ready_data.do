/*

Creator: Yuqi Song
Date last modified: 5/6/19 
Last modified by: Maya Norman

Purpose: Master Do File for Analysis Dataset Construction
(Takes dataset from cleaned from IEA_merged_long*.dta to IEA_merged_long*_regsort.dta)

Step 1) Construct FE regimes and drop data according to selected coded issues
Step 2) Match product specific climate data with product
Step 3) Prepare data for Income Group Construction and Construct Income Groups 
Step 4) Perform Final Cleaning Steps before first differenced interacted variable construction
	* Classify countries within 1 of 13 UN regions
	* Classify countries in income deciles and groups
Step 5) Construct First Differenced Interacted Variables
 
*/


clear all
set more off
macro drop _all
pause off


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman" {

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy/rationalized_code/0_make_dataset"

}
else if "`c(username)'" == "manorman" {
	
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/`c(username)'/gcp-energy/rationalized_code/0_make_dataset"

}

******Set Script Toggles********************************************************

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//Set Data type
global case "Exclude" //"Exclude" "Include"
local case $case

global bknum "break2"
local bknum $bknum

//Issue Fix 
	
global IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues
local IF $IF

//income grouping test: 

global grouping_test "visual" //visual (3 income groups), semi-parametric (2 income groups, top two income groups in visual get combined into 1 income group)
local grouping_test $grouping_test

//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
global model "TINV_clim"
local model $model

global submodel ""
local submodel $submodel

//Define if covariates are MA15 or TINV
if ("$model" != "TINV_both") {
	//Climate Var Average type
	local ma_clim "TINV"

	//Income Var Average type
	local ma_inc "MA15"
}
else if ("$model" == "TINV_both") {

	//Climate Var Average type
	local ma_clim "TINV"

	//Income Var Average type
	local ma_inc "TINV"
	
}

//Climate Data type
global clim_data "GMFD"
local clim_data $clim_data

***********************************************************************************
* Step 0) Confirm Toggles are Correctly Set up
***********************************************************************************

local name "`clim_data'/rationalized_code/$data_type/data/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'"
di "`name'_`model'_`data_type'_regsort.dta"
di "Is this the right specification?????????????????"
pause

*************************************************************************
* Step 1) Construct FE regimes and drop data according to specification
*************************************************************************

do "`GIT'/merged_data/1_issue_fix_v2.do"

//rename COMPILE -- OTHERIND and make sure only have desired flows and products for spec
if ("`bknum'" == "break2") {
	replace flow = "OTHERIND" if flow == "COMPILE"
	keep if inlist(flow, "OTHERIND")
	keep if inlist(product, "other_energy", "electricity")
} 
else {
	di "No bknum cleaning Step Occurred!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	pause
}

*************************************************************************
* Step 2) Match Product Specific Climate Data with respective product
*************************************************************************

*Reference climate data construction for information about the issues causing different climate data for different products

forval p=1/4 {
	replace temp`p'_`clim_data' = temp`p'_other_`clim_data' if inlist(product,"other_energy")
}

forval q=1/2 {
	replace precip`q'_`clim_data' = precip`q'_other_`clim_data' if product=="other_energy"
	replace polyAbove`q'_`clim_data' = polyAbove`q'_other_`clim_data' if inlist(product,"other_energy")
	replace polyBelow`q'_`clim_data' = polyBelow`q'_other_`clim_data' if inlist(product,"other_energy")
}

replace cdd20_`ma_clim'_`clim_data' = cdd20_other_`ma_clim'_`clim_data' if inlist(product,"other_energy")
replace hdd20_`ma_clim'_`clim_data' = hdd20_other_`ma_clim'_`clim_data' if inlist(product,"other_energy")


***********************************************************************************************************************
* Step 3) Income Group Construction plus a couple necessary cleaning steps for proper construction
***********************************************************************************************************************

//Part A) Prepare Dataset for Income group construction by ensuring only data included in regression remains in dataset

	//Keep only observations we actually have data for
	drop if load_pc == . | lgdppc_`ma_inc' == . | temp1_`clim_data' == .

	if ("`case'" == "Exclude") {
		drop if load_pc == 0
		
		local warning_message = "`warning_message' observations dropped if load_pc == 0!!!!!!!!"
	}
	else {

		di "Zeroes were kept in!!!!!!!!!"
		pause

	}

	//Keep only years in range

	drop if year<1971 | year>2011

	//generate FE regime
	if ("`IF'" != "face-value") {
		egen region_i = group(country FEtag flow product)
	}
	else if ("`IF'" == "face-value") {
		egen region_i = group(country flow product)
		local warning_message = "`warning_message' FEtag notincluded in FE regime!!!!!!!!!!!!!"
	}
	else {

		local warning_message = "`warning_message' Issues Are not being Properly Dealt with in Fixed Effect Construction!!!!!!!!!"
		
	}


	sort region_i year
	tset region_i year

	gen FD_load_`spe'pc = D.load_`spe'pc

	//Organize variables
	order country year flow product load_pc lgdppc_`ma_inc' pop FEtag *`clim_data'*

//Part B) Construct Income Groups

	preserve

		if ("`ma_inc'" == "MA15" | "`ma_clim'" == "MA15") {
		//observation for every country year where we have an observation
			duplicates drop country year, force
		}
		else if ("`ma_inc'" == "TINV" & "`ma_clim'" == "TINV") {
		//observation for every country where we have any observation
			duplicates drop country, force
		}

		**sort**
		di "lgdppc_`ma_inc'"
		pause
		qui egen gpid=xtile(lgdppc_`ma_inc'), nq(10)
		qui egen qgpid=xtile(lgdppc_`ma_inc'), nq(5)
		qui egen tgpid=xtile(lgdppc_`ma_inc'), nq(3)
		qui egen cpid=xtile(cdd20_`ma_clim'_`clim_data'), nq(10)
		qui egen qcpid=xtile(cdd20_`ma_clim'_`clim_data'), nq(5)
		qui egen tpid=xtile(cdd20_`ma_clim'_`clim_data'), nq(3)

		**reversing the order of tpid to put hot ones on top**
		qui replace tpid=4-tpid
			
		//Generate large income groups
		
		if ("$grouping_test" == "visual" & "`bknum'" == "break2" & "`case'" == "Exclude") {
		
			**regrouping gpid**
			qui generate largegpid_electricity =.
			qui replace largegpid_electricity = 1 if (gpid>=1) & (gpid<=6) 
			qui replace largegpid_electricity = 2 if gpid==7 | gpid==8 
			qui replace largegpid_electricity = 3 if gpid==9 | gpid==10 
							
			//1-2-2
			qui generate largegpid_other_energy =.
			qui replace largegpid_other_energy = 1 if (gpid >= 1) & (gpid <= 2) 
			qui replace largegpid_other_energy = 2 if (gpid >= 3) & (gpid <= 6) 
			qui replace largegpid_other_energy = 3 if (gpid >= 7) & (gpid <= 10)

			sort gpid
		}
		else if ("$grouping_test" == "semi-parametric" & "`bknum'" == "break2" & "`case'" == "Exclude") {
		
			**regrouping gpid**
			qui generate largegpid_electricity =.
			qui replace largegpid_electricity = 1 if (gpid>=1) & (gpid<=6) 
			qui replace largegpid_electricity = 2 if gpid==7 | gpid==8 
			qui replace largegpid_electricity = 2 if gpid==9 | gpid==10 
							
			//1-2-2
			qui generate largegpid_other_energy =.
			qui replace largegpid_other_energy = 1 if (gpid >= 1) & (gpid <= 2) 
			qui replace largegpid_other_energy = 2 if (gpid >= 3) & (gpid <= 6) 
			qui replace largegpid_other_energy = 2 if (gpid >= 7) & (gpid <= 10)

			sort gpid
		}
				

		//generate cell ids based on income groups (for plotting arrays)
		qui generate largeallid_electricity=largegpid_electricity+100*tpid
		qui generate largeallid_other_energy=largegpid_other_energy+100*tpid
		qui generate allid=gpid+100*tpid

		//generate cell ids based on income terciles
		qui generate tallid = tgpid+100*tpid

		//keep only necessary vars
		keep cdd20_`ma_clim'_`clim_data' hdd20_`ma_clim'_`clim_data' country year lgdppc_`ma_inc' gpid qgpid tpid tgpid cpid qcpid large* allid tallid
		
		local sumStat_list " qgpid gpid largegpid_electricity largegpid_other_energy tallid allid largeallid_electricity largeallid_other_energy tpid tgpid "


		foreach dd in `sumStat_list' {
			qui bysort `dd': egen numberC_`dd'=nvals(country) //number of country
			qui egen avgCDD_`dd'=mean(cdd20_`ma_clim'_`clim_data'), by(`dd') //average CDD in each cell
			qui egen avgHDD_`dd'=mean(hdd20_`ma_clim'_`clim_data'), by(`dd') //average HDD in each cell
			cap egen avgTmean_`dd'=mean(Tmean_`ma_clim'), by(`dd') //average HDD in each cell
			qui egen avgInc_`dd'=mean(lgdppc_`ma_inc'), by(`dd') //average lgdppc in each cell
			qui egen maxCDD_`dd'=max(cdd20_`ma_clim'_`clim_data'), by(`dd') //max CDD in each cell
			qui egen maxHDD_`dd'=max(hdd20_`ma_clim'_`clim_data'), by(`dd') //max HDD in each cell
			qui egen maxInc_`dd'=max(lgdppc_`ma_inc'), by(`dd') //max lgdppc in each cell
			qui egen minCDD_`dd'=min(cdd20_`ma_clim'_`clim_data'), by(`dd') //min CDD in each cell
			qui egen minHDD_`dd'=min(hdd20_`ma_clim'_`clim_data'), by(`dd') //min HDD in each cell
			qui egen minInc_`dd'=min(lgdppc_`ma_inc'), by(`dd') //min lgdppc in each cell
		}

		//keep only necessary vars
		cap keep country year gpid qgpid cpid qcpid tpid* tgpid* large* allid tallid avg* numberC* min* max*
		local break_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/`data_type'/data/break10_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`level'_`model'_`data_type'.dta"
		save "`break_data'", replace

	restore

***********************************************************************************************************************
*Step 4) Perform Final Cleaning Steps
***********************************************************************************************************************

//Merge in income group definitions
if ("`ma_inc'" == "MA15" | "`ma_clim'" == "MA15") {
	merge m:1 country year using `break_data'
}
else if ("`ma_inc'" == "TINV" & "`ma_clim'" == "TINV" ) {
	merge m:1 country using `break_data'
}
pause

keep if _merge == 3
drop _merge
sort gpid

//Generate income group specific income groups
gen largegpid = largegpid_electricity if product == "electricity"
replace largegpid = largegpid_other_energy if product == "other_energy"
drop largegpid_electricity largegpid_other_energy

//Gnerate dummy variable by income decile and group 
tab gpid, gen(ind)
cap tab largegpid, gen(largeind)

//Generate climate quintile dummies (can delete this section of code later)
tab qcpid, gen(climind)

**merge in subregion classifications**
**Clean the region data**
preserve
insheet using "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Cleaning/UNSD — Methodology.csv", comma names clear
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

do "`GIT'/merged_data/2_construct_FD_interacted_variables.do"
save "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`name'_`model'_`data_type'_regsort.dta", replace

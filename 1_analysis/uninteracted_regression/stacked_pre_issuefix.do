clear all
set more off
macro drop _all
pause on


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy/rationalized_code/0_make_dataset"

}
else if "`c(username)'" == "manorman"{
	
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"
	local GIT "/home/`c(username)'/gcp-energy/rationalized_code/0_make_dataset"

}


//Climate Data type
global clim_data "GMFD"
local clim_data $clim_data

global case "Exclude" //"Exclude" "Include"
local case $case
//Breakdown of fuels and products: break2 --> only two groups other_energy and electricity

global bknum "break2"
local bknum $bknum

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

local replicated_data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

//for plotting:

local o 4
local region "CAN"

********************************************************************************
*Step 1: Load Energy Data 
********************************************************************************

//Part A: Make Energy Dataset Tempfile and retrieve Country List for looping
use "`replicated_data'/Analysis/`clim_data'/rationalized_code/`data_type'/data/IEA_Merged_long_`clim_data'.dta", clear

*************************************************************************
*Step 2) Match Product Specific Climate Data with respective product
*************************************************************************

*Reference climate data construction for information about the issues causing different climate data for different products

forval p=1/4 {
	replace temp`p'_`clim_data' = temp`p'_other_`clim_data' if inlist(product,"other_energy","total_energy")
}

forval q=1/2 {
	replace precip`q'_`clim_data' = precip`q'_other_`clim_data' if product=="other_energy" | product=="total_energy"
	replace polyAbove`q'_`clim_data' = polyAbove`q'_other_`clim_data' if inlist(product,"other_energy","total_energy")
	replace polyBelow`q'_`clim_data' = polyBelow`q'_other_`clim_data' if inlist(product,"other_energy","total_energy")
}

*************************************************************************
*Step 3) Prepare Data for Regression
*************************************************************************

keep if country == "`region'"
keep if year > 1970 & year < 2011
qui egen region_i = group(country flow product)

sort region_i year
xtset region_i year

//tab product
*1=electricity, 2=other_energy*
tab product, gen(indp)
egen product_i = group(product)

//tab flow
*1=COMMPUB, 2=RESIDENT, 3=TOTIND*
tab flow, gen(indf)
egen flow_i = group(flow)
summ flow_i

**load**
gen double loadlag = L1.load_pc
gen double FD_load_pc = load_pc - loadlag
		
**temp**
forval i=1/4 {
	qui gen double temp`i'_`clim_data'_lag=L1.temp`i'_`clim_data'
	qui gen double FD_temp`i'_`clim_data'=temp`i'_`clim_data'-temp`i'_`clim_data'_lag
}
order FD_temp1 FD_temp2 FD_temp3 FD_temp4
				
**precip**
forval i=1/2 {
	qui gen double precip`i'_`clim_data'_lag=L1.precip`i'_`clim_data'
	qui gen double FD_precip`i'_`clim_data'=precip`i'_`clim_data'-precip`i'_`clim_data'_lag
}

//interacted temp coef, beta by large group
local tempregressor=""
forval pg=1/2 {
	local tempgroupC`pg'=""
	forval fg=1/1 {
		local tempgroupB`fg'=""
		forval k=1/4 {
			local add="c.indp`pg'#c.indf`fg'#c.FD_temp`k'"
			local tempgroupB`fg'="`tempgroupB`fg'' `add'"
		}
		local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
	}
	local tempregressor="`tempregressor' `tempgroupC`pg''"
}
					

//interacted precip coef, controls, not varying across groups
local precipregressor=""
	forval pg=1/2 {
		local precipgroupC`pg'=""
		forval fg=1/1 {
			local precipgroupB`fg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.FD_precip`k'"
				local precipgroupB`fg'="`precipgroupB`fg'' `add'"
			}
			local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
		}
		local precipregressor="`precipregressor' `precipgroupC`pg''"
}

//run first stage regression
reg FD_load_pc `tempregressor' `precipregressor' 
estimates save "`ster'/FD/`region'_FD_clim`clim_data'_poly`o'_`bknum'_`case'.ster", replace


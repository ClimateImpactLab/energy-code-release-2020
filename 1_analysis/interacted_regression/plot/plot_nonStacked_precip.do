/*
Creator: Maya Norman
Date last modified: 12/17/18 
Last modified by: 

Purpose: Make Presentation Style Array

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX
SubModel Options (only available if model is TINV_clim): 
-decadal interaction (decinter) 
-unrestricted income (ui) 
-linear interaction (lininter)

Input Data Options: `clim'_`model'_`data_type'.dta
-model: TINV_clim, TINV_both_G64, TINV_clim_EX
-clim: GMFD_v3, BEST
-data_type: historic_data, replicated_data

*/


clear all
set more off
macro drop _all


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}


******Set Script Toggles********************************************************

//set up for IV
local IV "off"

//Set data type ie historic or replicated
global data_type "historic_data"
local data_type $data_type


******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both_G64, TINV_clim_EX
		global model "TINV_clim"
		local model $model
		
	//Submodel type-- (Default: "")
		global submodel ""
		local submodel ""

	//Climate Data type
		global clim "BEST"
		local clim_data $clim
		
	//Flow product type
		global product "total_energy"
		local var $product
		
		global flow "COMPILE"
		local tag $flow
	
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both_G64") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"
		
		//number of INC groups
		local IG 3

	}
	else if ("$model" == "TINV_both_G64") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"
		
		//number of INC groups
		local IG 2
		
	}
	
	//Set submodel
	if ("$model" == "TINV_clim") {
		
		local submodel "$submodel"

	}
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Data/`clim_data'/historic_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Data/`clim_data'/historic_code/$data_type/sters"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/historic_code/$data_type/figures"	

if ("$data_type"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("$data_type"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

**Load data and ster
if ("`IV'"=="off") {
	
	use "`data'/`clim_data'_`model'_`data_type'_regsort.dta", replace
	local climlist "`clim_data'"
	
}

estimate use "`ster'/FD_FGLS_inter_`clim_data'_poly2_`tag'_`var'_`model'.ster"				

			
**plotting precip**
qui summ precip1_`clim_data'
local maxp=ceil(`r(max)'/365.25)
local minp=floor(`r(min)'/365.25)
local mpoint=round(-_b[FD_precip1]/(2*_b[FD_precip2]))
				
local pgap=1
local pobs=(`maxp'-`minp')/`pgap'+1


qui drop if _n > 0
qui set obs `pobs'
replace precip1_`clim_data' = (_n-1)*`pgap' + `minp'
replace precip2_`clim_data' = precip1_`clim_data'^2
local line = "_b[FD_precip1_`clim_data'] * precip1_`clim_data' + _b[FD_precip2_`clim_data'] * precip2_`clim_data'"
					
** Predict			
qui predictnl yhat = `line', se(se) ci(lower upper)

** Plot
tw rarea upper lower precip1_`clim_data', col(ltbluishgray) || line yhat precip1_`clim_data', lc (dknavy) ///
yline(0) xlabel(, labsize(small)) ///
ylabel(, labsize(small)) legend(off) title("Precip") ///
ytitle("kWh/pc", size(small)) xtitle("Precipitation[mm]", size(small)) ///
title("Interactive Precip Response Model", size(small)) ///
subtitle("`clim_data', `tag', `var', `model'", size(small)) ///
plotregion(color(white)) graphregion(color(white)) 
graph export  "`output'/prcp_FD_FGLS_inter_poly2_`model'_`tag'_`var'_`clim_data'_array.pdf", replace
	

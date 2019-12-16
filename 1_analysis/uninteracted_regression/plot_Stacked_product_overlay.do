/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Plot non-stacked uninteracted regression 
-model: TINV_clim

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX


Input Data Options: `clim'_`model'_`data_type'_regsort.dta
-data_type: historic_data, replicated_data
*/

clear all
set more off
macro drop _all
pause on

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

//Set data type ie historic or replicated
global data_type "replicated_data"
local data_type $data_type

//set up ZeroSubset toggle

local case "Exclude" // "Exclude" "Include"

//Number of data subsets used to estimate
local bknum "break2"

//Issue Fix
local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues

******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		global model "TINV_clim"
		local model $model
				
		local qt 5 //number of income quantiles
		local t "I" //type of quantile
		
	//Specification:
	
		//First Difference
			global FD "FD" // FD vs noFD
			local FD $FD
			
			if ("`FD'" == "noFD") {

				local fd ""
		
			}
			else {

				local fd "FD_"

			}
			
		//FGLS
			local FGLS "_FGLS" // "_FGLS" ""
	
		//Issue Fix
			local IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues
			
		//Poly
			local o 4 //order of polynomial options: 2,3,4
		
	//Submodel type-- (Default: "")
		global submodel ""
		local submodel ""
	
	//Climate Data type
		global clim_data "GMFD"
		local clim_data $clim_data
	
		
	//Flow product type

		local product_list "other_energy electricity"
		
		local flow_list "OTHERIND" //"COMMPUB TOTIND RESIDENT"
	
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"
		
		//number of INC groups
		local IG 3

	}
	else if ("$model" == "TINV_both") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"
		
		//number of INC groups
		local IG 3
		
	}
	
	//Set submodel
	if ("$model" == "TINV_clim") {
		
		local submodel "$submodel"

	}
********************************************************************************

//Setting path shortcuts

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

local OUTPUT "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/rationalized_code/$data_type/figures"


if ("$data_type"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("$data_type"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

use "`data'/clim`clim_data'_`case'`IF'_`bknum'_visual_`model'_`data_type'_regsort.dta", clear
		

local regionlist " OECD GLOBAL "
local GLOBAL_color "dknavy"
local GLOBAL_colTT "Blue"
local OECD_color "dkorange"
local OECD_colTT "Orange"

local productlist " electricity other_energy "
local electricity_color "dknavy"
local electricity_colTT "Blue"
local other_energy_color "dkorange"
local other_energy_colTT "Orange"

local typelist "`productlist'"

foreach k of num 1/4 {
	rename temp`k'_`clim_data' temp`k'	
	replace temp`k' = temp1^`k'
}

*--Global Energy Consumption Response Plot Using Poly 4 Model--*

foreach tag in "OTHERIND" {

	local fg = 1
	local tit "All Flows"

		preserve
			//local values
			local min = -5
			local max = 35
			local omit = 20
			local obs = `max' + abs(`min') + 1

			drop if _n > 0
			set obs `obs'
			replace temp1 = _n + `min' -1
		
		local colorGuide = ""
		local SE = ""
		local noSE = ""
		
		foreach type in `typelist' {

				if "`type'"=="electricity" {
					local stit="Electricity"
					local pg=1
					local region = "GLOBAL"
				}
				else if "`type'"=="other_energy" {
					local stit="Non-Electricity"
					local pg=2
					local region = "GLOBAL"
				}
			
				//load ster file
				estimate use "`ster'/FD_FGLS/`region'_`FD'_FGLS_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'"
				
				//loop over the polynomials' degree and save the predict command in the local `line'
				local line = "_b[c.indp`pg'#c.indf`fg'#c.`fd'temp1_`clim_data'] * (temp1 - `omit')"
				foreach k of num 2/4 {
					replace temp`k' = temp1 ^ `k'
					local add = "+ _b[c.indp`pg'#c.indf`fg'#c.`fd'temp`k'_`clim_data'] * (temp`k' - `omit'^`k')"
					local line "`line' `add'"
				}
				
				//predict
				predictnl yhat_`type' = `line', se(se_`type') ci(lower_`type' upper_`type')
								
				local SE "`SE' rarea upper_`type' lower_`type' temp1, col(``type'_color'%20) || line yhat_`type' temp1, lc (``type'_color') ||" 
				local noSE "`noSE' line yhat_`type' temp1, lc (``type'_color') ||" 
				loc colorGuide = "`colorGuide' `stit' (``type'_colTT')"

		}
		
		cap mkdir "`OUTPUT'/uninteracted_response"	
		
		di "`SE'"
		di "`noSE'"

		pause

		//plot with SE
		tw `SE' , ///
		yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
		ylabel(-5(5)20, labsize(vsmall) nogrid) legend(off) ///
		title("`o' Polynomial Response `tit' " , size(vsmall)) ///
		subtitle("`colorGuide' " , size(vsmall)) ///
		ytitle("", size(small)) xtitle("", size(vsmall)) ///
		plotregion(color(white)) graphregion(color(white))
		graph export "`OUTPUT'/uninteracted_response/product_overlay_`region'_uninteracted_response_FD_FGLS_clim`clim_data'_`case'`IF'_`bknum'_`model'_poly`o'.pdf", replace


		//plot with no SE
		tw `noSE' , ///
		yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
		ylabel(-5(5)20, labsize(vsmall) nogrid) legend(off) ///
		title("`o' Polynomial Response `tit' " , size(vsmall)) ///
		subtitle("`colorGuide'" , size(vsmall)) ///
		ytitle("", size(small)) xtitle("", size(small)) ///
		plotregion(color(white)) graphregion(color(white))
		graph export "`OUTPUT'/uninteracted_response/product_overlay_`region'_uninteracted_response_FD_FGLS_clim`clim_data'_`case'`IF'_`bknum'_`model'_poly`o'_noSE.pdf", replace

		graph drop _all
		restore


}

/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Plot non-stacked decile regression (Overlay and Non-Overlay Options)
-model: TINV_clim

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX


Input Data Options: `clim'_`model'_`data_type'_regsort.dta
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
				
		local qt 10 //number of income quantiles
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
				
		//Poly
			local o 2 //order of polynomial options: 2,3,4
		
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

local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/rationalized_code/$data_type/figures"	

//Set up locals for plotting
	local min = -5
	local max = 35
	local omit = 20
	local obs = `max' + abs(`min') + 1
	local midcut=20

local electricity_col "dknavy"
local electricity_colTT "Blue"
local other_energy_col "dkorange"
local other_energy_colTT "Orange"

//load data and set values for overlay
	
use "`DATA'/data/clim`clim_data'_`case'`IF'_`bknum'_visual_`model'_`data_type'_regsort.dta", replace
	


//clean data for plotting
drop if _n > 0
set obs `obs'
replace temp1_`clim_data' = _n + `min' -1

foreach k of num 1/4 {
	rename temp`k'_`clim_data' temp`k'
	replace temp`k' = temp1 ^ `k'
}


*--Decile Plots for Total Energy All Flows Combined Regression--*

foreach tag in "OTHERIND" {

		local fg = 1
		local tit "All Flows"

		//set up graphing locals for graph combined
		local graphic=""
		local graphic_noSE=""

		forval lg=1/`qt' { //income group

			local cellid=`lg'
			


		preserve

		//set up graphing code
			loc SE ""
			loc nonSE ""
			local colorGuide ""	

		foreach var in "electricity" "other_energy" {

			if "`var'"=="electricity" {
				local stit="Electricity"
				local pg=1
			}
			else if "`var'"=="other_energy" {
				local stit="Non-Electricity"
				local pg=2
			}

			*loop over the polynomials' degree and save the predict command in the local `line'
			local line = "_b[c.indp`pg'#c.indf`fg'#c.`fd'I`lg'temp1] * (temp1 - `omit')"
			foreach k of num 2/`o' {
				replace temp`k' = temp1 ^ `k'
				local add = "+_b[c.indp`pg'#c.indf`fg'#c.`fd'I`lg'temp`k'] * (temp`k' - `omit'^`k')"
				local line "`line' `add'"
			}

			estimates use "`DATA'/sters/`FD'`FGLS'/quant`t'`qt'_`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
						
			//predict
			predictnl yhat_`var' = `line', se(se_`var') ci(lower_`var' upper_`var')
				
			loc SE = "`SE' rarea upper_`var' lower_`var' temp1, col(``var'_col'%30) || line yhat_`var' temp1, lc (``var'_col') ||"
			loc noSE "`noSE' line yhat_`var' temp1, lc (``var'_col') ||"
			loc colorGuide = "`colorGuide' `var' (``var'_colTT')"

		}

		// outputting data for reference/paper statistics
		
		keep temp1 yhat* se_* lower_* upper_*
		// outsheet using "`DATA'/plotting_responses/quant`t'`qt'_decile`lg'_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_clim`clim_data'_`case'`IF'_`bknum'.csv", comma replace

		//plot with SE
		tw `SE' , ///
		yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
		ylabel(, labsize(vsmall) nogrid) legend(off) ///
		subtitle("", size(vsmall) color(dkgreen)) ///
		ytitle("", size(small)) xtitle("", size(small)) ///
		plotregion(color(white)) graphregion(color(white)) nodraw ///
		name(addgraph`cellid', replace)

		//plot with no SE
		tw `noSE' , ///
		yline(0, lwidth(vthin)) xlabel(`min'(10)`max', labsize(vsmall)) ///
		ylabel(, labsize(vsmall) nogrid) legend(off) ///
		subtitle("", size(vsmall) color(dkgreen)) ///
		ytitle("", size(small)) xtitle("", size(small)) ///
		plotregion(color(white)) graphregion(color(white)) nodraw ///
		name(addgraph`cellid'_noSE, replace)
		
		restore
							

		//add graphic
		local graphic="`graphic' addgraph`cellid'"
		local graphic_noSE="`graphic_noSE' addgraph`cellid'_noSE"
	}				
									
	
	//combine cells with SE
	graph combine `graphic', imargin(zero) ycomm rows(1) xsize(20) ysize(3) ///
	title("Poly `o' `qt' Quantile Model for `tit' (`model')", size(small)) ///
	subtitle("`colorGuide'", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb, replace)
	graph export "`output'/quantile_plots/product_overlay_quant`t'`qt'_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_clim`clim_data'_`case'`IF'_`bknum'.pdf", replace

	//combine cells no SE
	graph combine `graphic_noSE', imargin(zero) ycomm rows(1) xsize(20) ysize(3) ///
	title("Poly `o' `qt' Quantile Model for `tit' (`model')", size(small)) ///
	subtitle("`colorGuide'", size(small)) ///
	plotregion(color(white)) graphregion(color(white)) name(comb_noSE, replace)
	graph export "`output'/quantile_plots/product_overlay_quant`t'`qt'_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_clim`clim_data'_`case'`IF'_`bknum'_noSE.pdf", replace
				
	graph drop _all
				

}



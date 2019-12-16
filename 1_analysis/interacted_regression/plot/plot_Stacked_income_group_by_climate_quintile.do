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
global data_type "historic_data"
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
		local IG 4

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

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/"	
local output "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/historic_code/$data_type/figures"	

if ("$data_type"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("$data_type"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

//Set up locals for plotting
	local min = -5
	local max = 35
	local omit = 20
	local obs = `max' + abs(`min') + 1
	local midcut=20

//load data and set values for overlay
	
	use "`data'/`clim_data'/historic_code/$data_type/data/clim`clim_data'_`case'`IF'_`bknum'_`model'_`data_type'_regsort.dta", replace
	


//clean data for plotting
drop if _n > 0
set obs `obs'
replace temp1_`clim_data' = _n + `min' -1

foreach k of num 1/4 {
	rename temp`k'_`clim_data' temp`k'
	replace temp`k' = temp1 ^ `k'
}


*--Decile Plots for Total Energy All Flows Combined Regression--*



foreach var in "electricity" "other_energy" {


				if "`var'"=="electricity" {
					local stit="Electricity"
					local pg=1
					local IG = 4
				}
				else if "`var'"=="other_energy" {
					local stit="Non-Electricity"
					local pg=2
					local IG = 2
				}

	foreach tag in "OTHERIND" {

					local fg = 1
					local tit "All Flows"
					
					if "`tag'"=="RESIDENT" {
						local tit="Residential"
						local fg=2
					}
					else if "`tag'"=="COMMPUB" {
						local tit="Commercial and Public"
						local fg=1
					}
					else if "`tag'"=="TOTIND" {
						local tit="Industrial"
						local fg=3
					}

		//set up graphing locals for graph combined
		local graphic=""
		local graphic_noSE=""
		
		
		forval lg=`IG'(-1)1 { //income group
			forval qg=1/5 {
				local cellid=`lg' + `qg'*100
			


					preserve
		
					//set up graphing code
					loc SE ""
					loc nonSE ""
					
						*loop over the polynomials' degree and save the predict command in the local `line'
							local line = "_b[c.indp`pg'#c.indf`fg'#c.`fd'C`qg'I`lg'temp1] * (temp1 - `omit')"
								foreach k of num 2/`o' {
									replace temp`k' = temp1 ^ `k'
									local add = "+_b[c.indp`pg'#c.indf`fg'#c.`fd'C`qg'I`lg'temp`k'] * (temp`k' - `omit'^`k')"
									local line "`line' `add'"
								}

							estimates use "`ster'/`clim_data'/historic_code/$data_type/sters/`FD'`FGLS'/ClimQuant5_IncGroups_`FD'`FGLS'_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
							
							//predict
							predictnl yhat_`clim_data' = `line', se(se_`clim_data') ci(lower_`clim_data' upper_`clim_data')
					
					loc SE = "`SE' rarea upper_`clim_data' lower_`clim_data' temp1, col(dknavy%30) || line yhat_`clim_data' temp1, lc (dknavy) ||"
					loc noSE "`noSE' line yhat_`clim_data' temp1, lc (dknavy) ||"
			

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
	}				

		cap mkdir "`output'/income_group_by_climate_quintile/`tag'_`var'"	

						//combine cells with SE
						graph combine `graphic', imargin(zero) ycomm rows(`IG') xsize(8) ysize(3) ///
						title("Poly `o' Income Group by Climate Quintile Model for `tit' `stit' (`model')", size(small)) ///
						subtitle("`colorGuide'", size(small)) ///
						plotregion(color(white)) graphregion(color(white)) name(comb, replace)
						graph export "`output'/income_group_by_climate_quintile/`tag'_`var'/ClimQuant5_IncGroups_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_`var'_clim`clim_data'_`case'`IF'_`bknum'.pdf", replace

						//combine cells no SE
						graph combine `graphic_noSE', imargin(zero) ycomm rows(`IG') xsize(8) ysize(3) ///
						title("Poly `o' Income Group by Climate Quintile Model for `tit' `stit' (`model')", size(small)) ///
						subtitle("`colorGuide'", size(small)) ///
						plotregion(color(white)) graphregion(color(white)) name(comb_noSE, replace)
						graph export "`output'/income_group_by_climate_quintile/`tag'_`var'/ClimQuant5_IncGroups_`FD'`FGLS'_inter_poly`o'_`model'_`tag'_`var'_clim`clim_data'_`case'`IF'_`bknum'_noSE.pdf", replace
				
					graph drop _all
				
			}
	}



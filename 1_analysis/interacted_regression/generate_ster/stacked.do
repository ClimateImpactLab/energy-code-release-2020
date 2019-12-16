/*
Creator: Maya Norman
Date last modified: 12/17/18 
Last modified by: 

Purpose: Run interacted regression (generate sters) Flow & Product specific
Stacked regression
-model: TINV_clim

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX
SubModel Options (only available if model is TINV_clim): 
-decadal interaction (decinter)
-unrestricted income (ui)
-linear interaction (lininter)

Input Data Options: `clim_data'_`model'_`data_type'_regsort.dta
-data_type: historic_data, replicated_data
*/


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

local data_type $data_type

//Number of data subsets used to estimate
local bknum $bknum

local case $case // "Exclude" "Include"

//income grouping test

local grouping_test $grouping_test

******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		local model $model
		local model_name $model
		
	//Submodel type-- (Default: "")
	local submodel $submodel
		
	if ("`submodel'" == "decinter" | "`submodel'" == "lininter") {
			
		local time_dummy $time_dummy
			
	}
	
	//Climate Data type
	local clim_data $clim_data
		
	//Issue Fix
	
	local IF $IF
	
	
	//Specification:
	
		local FD $FD
		
		if ("`FD'" == "noFD") {

			local fd ""
	
		}
		else if ("`FD'" == "FD") {

			local fd "FD_"

		}
	
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
	
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

********************************************************************************
*Step 1: Load Data and Clean
********************************************************************************

if (inlist("`model'","TINV_clim","TINV_clim_ui", "TINV_clim_income_spline", "TINV_clim_lininter", "TINV_clim_decinter")) {
	use "`data'/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_TINV_clim_`data_type'_regsort.dta", clear
}
else {
	use "`data'/clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_`model'_`data_type'_regsort.dta", clear
}

pause
cap drop DumC*
			
//keep 6 categories

if ("`bknum'" == "break6") {
	keep if flow=="RESIDENT" | flow=="COMMPUB" | flow=="TOTIND" 
}
else if ("`bknum'" == "break4") {
	keep if flow=="TOTOTHER" | flow == "TOTIND"
}
else if ("`bknum'" == "break2") {
	keep if flow=="OTHERIND"
}

keep if product=="electricity" | product=="other_energy"

//tab product
*1=electricity, 2=other_energy
tab product, gen(indp)
egen product_i = group(product)

//tab flow
*1=COMMPUB, 2=RESIDENT, 3=TOTIND
tab flow, gen(indf)
egen flow_i = group(flow)
summ flow_i
local fn `r(max)'


//local pooled FE
local FE4 = "i.flow_i#i.product_i#i.year#i.subregionid"
//encode country, gen(cnt)

********************************************************************************
*Step 2: Prepare Regressors and Run Regression
********************************************************************************

//set time
sort region_i year 
tset region_i year

//identify number of income groups
sum largegpid
local IG = `r(max)'

//interacted lgdppcMA, controls, vary by large group
foreach control in "lgdppc_`ma_inc'" {
	local `control'regressor=""
	forval pg=1/2 {
		local `control'groupC`pg'=""
		forval fg=1/`fn' {
			local `control'groupB`fg'=""
			forval lg = 1/`IG' {
				local `control'groupA`lg'="c.indp`pg'#c.indf`fg'#c.`fd'I`lg'`control'"
				local `control'groupB`fg'="``control'groupB`fg'' ``control'groupA`lg''"
			}
			local `control'groupC`pg'="``control'groupC`pg'' ``control'groupB`fg''"
		}
		local `control'regressor="``control'regressor' ``control'groupC`pg''"
	}
}

//income bin dummies
drop DumInc*
forval pg=1/2 {
	forval fg=1/`fn' {
		forval lg=1/`IG' {
			gen DumIncG`lg'F`fg'P`pg'=`fd'largeind`lg'*indf`fg'*indp`pg'
		}
	}
}


//interacted precip coef, controls, not varying across groups
local precipregressor_`clim_data'=""
forval pg=1/2 {
	
	local precipgroupC`pg'=""
	
	forval fg=1/`fn' {
		
		local precipgroupB`fg'=""
	
		forval k=1/2 {
			local add="c.indp`pg'#c.indf`fg'#c.`fd'precip`k'_`clim_data'"
			local precipgroupB`fg'="`precipgroupB`fg'' `add'"
		}
		
		local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
	}
	
	local precipregressor_`clim_data'="`precipregressor_`clim_data'' `precipgroupC`pg''"
}

		
//interacted temp coef, beta by large group
local tempregressor_`clim_data' = ""
forval pg=1/2 {
	local tempgroupC`pg'=""
	forval fg=1/`fn' {
		local tempgroupB`fg'=""
		forval lg = 1/`IG' {
			local tempgroupA`lg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.`fd'I`lg'temp`k'_`clim_data'"
				local tempgroupA`lg'="`tempgroupA`lg'' `add'"
			}
			local tempgroupB`fg'="`tempgroupB`fg'' `tempgroupA`lg''"
		}
		local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
	}
	local tempregressor_`clim_data'="`tempregressor_`clim_data'' `tempgroupC`pg''"
}

if ("`submodel'"=="income_spline" | "`model'" == "TINV_clim_income_spline") {

	local tempregressor_`clim_data' = ""
	forval pg=1/2 {
		local tempgroupC`pg'=""
		forval fg=1/`fn' {
			local tempgroupB`fg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.`fd'temp`k'_`clim_data'"
				local tempgroupB`fg'="`tempgroupB`fg'' `add'"
			}
			local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
		}
		local tempregressor_`clim_data'="`tempregressor_`clim_data'' `tempgroupC`pg''"
	}
}


//interacted temp coef, TmeanMA cov by large group
local covregressor_`clim_data'=""
forval pg=1/2 {
	local covgroupC`pg'=""
	forval fg=1/`fn' {
		local covgroupB`fg'=""
		forval lg = 1/`IG' {
			local covgroupA`lg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.`fd'cdd20_`ma_clim'I`lg'temp`k'_`clim_data' c.indp`pg'#c.indf`fg'#c.`fd'hdd20_`ma_clim'I`lg'temp`k'_`clim_data'"
				local covgroupA`lg'="`covgroupA`lg'' `add'"
			}
			local covgroupB`fg'="`covgroupB`fg'' `covgroupA`lg''"
		}
		local covgroupC`pg'="`covgroupC`pg'' `covgroupB`fg''"
	}
	local covregressor_`clim_data'="`covregressor_`clim_data'' `covgroupC`pg''"
}


if (("`submodel'"=="income_spline" | "`model'" == "TINV_clim_income_spline")) {

	local covregressor_`clim_data'=""
	forval pg=1/2 {
		local covgroupC`pg'=""
		forval fg=1/`fn' {
			local covgroupB`fg'=""			
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.`fd'cdd20_`ma_clim'temp`k'_`clim_data' c.indp`pg'#c.indf`fg'#c.`fd'hdd20_`ma_clim'temp`k'_`clim_data'"
				local covgroupB`fg'="`covgroupB`fg'' `add'"
			}			
			local covgroupC`pg'="`covgroupC`pg'' `covgroupB`fg''"
		}
		local covregressor_`clim_data'="`covregressor_`clim_data'' `covgroupC`pg''"
	}
}


if ("`submodel'"=="ui" | "`model'" == "TINV_clim_ui") {
	local ui_covregressor_`clim_data'=""
	forval pg=1/2 {
		local ui_covgroupC`pg'=""
		//generate high income group based on number of groupings for a given product
		summ largegpid if indp`pg' == 1
		local num_IG = `r(max)'
		forval fg=1/`fn' {
			local ui_covgroupB`fg'=""
			forval lg = `num_IG'/`num_IG' {
				local ui_covgroupA`lg'=""
				forval k=1/2 {
					local add="c.indp`pg'#c.indf`fg'#c.`fd'lgdppc_`ma_inc'I`lg'temp`k'_`clim_data'"
					local ui_covgroupA`lg'="`ui_covgroupA`lg'' `add'"
				}
				local ui_covgroupB`fg'="`ui_covgroupB`fg'' `ui_covgroupA`lg''"
			}
			local ui_covgroupC`pg'="`ui_covgroupC`pg'' `ui_covgroupB`fg''"
		}
		local ui_covregressor_`clim_data'="`ui_covregressor_`clim_data''`ui_covgroupC`pg''"
	}
	local model_name "`model'_`submodel'"
}


//generate income spline covregressor based on grouping_test
if (("`submodel'"=="income_spline" | "`model'" == "TINV_clim_income_spline") & "`grouping_test'" == "semi-parametric") {
	local income_spline_covregressor=""
	forval pg=1/2 {
		local income_spline_covgroupC`pg'=""
		forval fg=1/`fn' {
			local income_spline_covgroupB`fg'=""
			forval lg = 1/`IG' {
				local income_spline_covgroupA`lg'=""
				forval k=1/2 {
					local add="c.indp`pg'#c.indf`fg'#c.`fd'dc1_lgdppc_`ma_inc'I`lg'temp`k'"
					local income_spline_covgroupA`lg'="`income_spline_covgroupA`lg'' `add'"
				}
				local income_spline_covgroupB`fg'="`income_spline_covgroupB`fg'' `income_spline_covgroupA`lg''"
			}
			local income_spline_covgroupC`pg'="`income_spline_covgroupC`pg'' `income_spline_covgroupB`fg''"
		}
		local income_spline_covregressor="`income_spline_covregressor'`income_spline_covgroupC`pg''"
	}
	local model_name "`model'_`submodel'"
} 
else if (("`submodel'"=="income_spline" | "`model'" == "TINV_clim_income_spline") & "`grouping_test'" == "visual") {
	local income_spline_covregressor=""
	forval pg=1/2 {
		local income_spline_covgroupC`pg'=""
		//generate high income group based on number of groupings for a given product
		forval fg=1/`fn' {
			local income_spline_covgroupB`fg'=""
			forval k=1/2 {
				local add="c.indp`pg'#c.indf`fg'#c.`fd'dc1_lgdppc_`ma_inc'I1temp`k'"
				local add="`add' c.indp`pg'#c.indf`fg'#c.`fd'spline2temp`k'"
				local add="`add' c.indp`pg'#c.indf`fg'#c.`fd'dc2_lgdppc_`ma_inc'I3temp`k'" 
				local income_spline_covgroupB`fg'="`income_spline_covgroupB`fg'' `add'"
			}
			local income_spline_covgroupC`pg'="`income_spline_covgroupC`pg'' `income_spline_covgroupB`fg''"
		}
		local income_spline_covregressor="`income_spline_covregressor'`income_spline_covgroupC`pg''"
	}
	local model_name "`model'_`submodel'"
}

di "`income_spline_covregressor'"
pause

if ("`submodel'"== "lininter") {
	local lininter_tempregressor_`clim_data'=""
	forval pg=1/2 {
		local lininter_tempgroupC`pg'=""
		forval fg=1/`fn' {
			local lininter_tempgroupB`fg'=""
			forval lg = 1/`IG' {
				
				//make temp year interaction either income group specific or not
				if ("`model'" == "TINV_clim") local tt = "I`lg'"
				else if ("`model'" == "TINV_clim_income_spline") local tt = ""
				else {
					di "Model is not coded up."
					pause
				}

				local lininter_tempgroupA`lg'=""

				forval k=1/2 {

					local add="c.indp`pg'#c.indf`fg'#c.`fd'year`tt'temp`k'_`clim_data'"
					local lininter_tempgroupA`lg'="`lininter_tempgroupA`lg'' `add'"
				
				}

				local lininter_tempgroupB`fg'="`lininter_tempgroupB`fg'' `lininter_tempgroupA`lg''"
			
			}
			
			local lininter_tempgroupC`pg'="`lininter_tempgroupC`pg'' `lininter_tempgroupB`fg''"
		}

		local lininter_tempregressor_`clim_data'="`lininter_tempregressor_`clim_data'' `lininter_tempgroupC`pg''"
	}

	if ("`time_dummy'" == "wtimeDummy") {
		local time_income_interaction = ""
		forval fg=1/`fn' {
			forval pg=1/2 {
				forval lg = 1/`IG' {
					local add="c.indp`pg'#c.indf`fg'#c.year#c.largeind`lg'"	
					local time_income_interaction = "`time_income_interaction' `add'"
				}
			}
		}	
	
		local model_name "`model'_`submodel'_wtimeDummy"
	} 
	else {
	
		local model_name "`model'_`submodel'"
	}
	
	local lininter_tempregressor_`clim_data' = "`lininter_tempregressor_`clim_data'' `time_income_interaction'"
	
	di "`lininter_tempregressor_`clim_data''"
	pause
}

if ("`submodel'"=="lininter" & "`model'" == "TINV_clim_income_spline" & "`grouping_test'" == "semi-parametric") {

	local lininterincomespline=""
	forval pg=1/2 {
		local lininterincomesplineC`pg'=""
		
		forval fg=1/`fn' {
			local lininterincomesplineB`fg'=""
			forval lg = 1/`IG' {

				local lininterincomesplineA`lg'=""
				forval k=1/2 {
					local add="c.indp`pg'#c.indf`fg'#c.`fd'dc1_lgdppc_`ma_inc'yearI`lg'temp`k'"
					local lininterincomesplineA`lg'="`lininterincomesplineA`lg'' `add'"
				}
				local lininterincomesplineB`fg'="`lininterincomesplineB`fg'' `lininterincomesplineA`lg''"
			}
			local lininterincomesplineC`pg'="`lininterincomesplineC`pg'' `lininterincomesplineB`fg''"
		}
		local lininterincomespline="`lininterincomespline'`lininterincomesplineC`pg''"
	}
	
	local model_name "`model'_`submodel'"
	di "`lininterincomespline'"
	pause
}

if ("`submodel'"== "decinter") {
	//replace income group dummy with an income group dummy interacted with each decade
	
	if (strpos("`model'","income_spline") == 0) {
		
		drop DumInc*
			
		forval pg=1/2 {
			forval fg=1/`fn' {
				forval lg=1/`IG' {
					forval dg=1/4 {
						gen DumIncG`lg'D`dg'F`fg'P`pg'=FD_DumInc`lg'Dec`dg'*indf`fg'*indp`pg'
					}
				}
			}
		}
	}

	local tempregressor_`clim_data' = ""

	forval pg=1/2 {
		local tempgroupC`pg'=""
		forval fg=1/`fn' {
			local tempgroupB`fg'=""
			forval dg=1/4 {
				local tempgroupD`dg'=""
				forval lg = 1/`IG' {
					if strpos("`model'","income_spline") == 0 local t = "I`lg'"
					else local t = ""
					local tempgroupA`lg'=""
					forval k=1/2 {
						local add="c.indp`pg'#c.indf`fg'#c.`fd'D`dg'`t'temp`k'_`clim_data'"
						local tempgroupA`lg'="`tempgroupA`lg'' `add'"
					}
					local tempgroupD`dg'="`tempgroupD`dg'' `tempgroupA`lg''"
				}
				local tempgroupB`fg'="`tempgroupB`fg'' `tempgroupD`dg''"
			}
			local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
		}
		local tempregressor_`clim_data'="`tempregressor_`clim_data'' `tempgroupC`pg''"
	}

	if ("`time_dummy'" == "wtimeDummy") {
		
		local decadal_income_interaction = ""
		forval fg=1/`fn' {
			forval pg=1/2 {
				forval dg=1/4 {
					forval lg = 1/`IG' {
						local add = "c.indp`pg'#c.indf`fg'#c.decind`dg'#c.largeind`lg'"	
						local decadal_income_interaction = "`decadal_income_interaction' `add'"
					}
				}
			}
		}	
	
		local model_name "`model'_`submodel'_wtimeDummy"
	} 
	else {
	
		local model_name "`model'_`submodel'"
	}
}	
	

cap mkdir "`ster'/`FD'"
cap mkdir "`ster'/`FD'_FGLS"

di "ui_cov `ui_covregressor_`clim_data''"

di "reghdfe FD_load_`spe'pc `tempregressor_`clim_data'' `precipregressor_`clim_data'' `covregressor_`clim_data'' `lgdppc_`ma_inc'regressor' `ui_covregressor_`clim_data'' `lininter_tempregressor_`clim_data'' `decadal_income_interaction' DumInc*, absorb(`FE4') cluster(region_i) residuals(resid)"
//run first stage regression
reghdfe FD_load_`spe'pc `tempregressor_`clim_data'' `precipregressor_`clim_data'' `covregressor_`clim_data'' ///
`lgdppc_`ma_inc'regressor' `ui_covregressor_`clim_data'' `income_spline_covregressor' `lininter_tempregressor_`clim_data'' `lininterincomespline' ///
`decadal_income_interaction' DumInc*, absorb(`FE4') cluster(region_i) residuals(resid)
estimates save "`ster'/`FD'/`FD'_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'", replace	

pause

//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
drop resid

//run second stage FGLS regression
reghdfe FD_load_`spe'pc `tempregressor_`clim_data'' `precipregressor_`clim_data'' `covregressor_`clim_data'' ///
`lgdppc_`ma_inc'regressor' `ui_covregressor_`clim_data'' `income_spline_covregressor' `lininter_tempregressor_`clim_data'' `lininterincomespline' ///
`decadal_income_interaction' DumInc* [pw=weight], absorb(`FE4') cluster(region_i) residuals(resid)
estimates save "`ster'/`FD'_FGLS/`FD'_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'_poly2_`model_name'", replace	

pause




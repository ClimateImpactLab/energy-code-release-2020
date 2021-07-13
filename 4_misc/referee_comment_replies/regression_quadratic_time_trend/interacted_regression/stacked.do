/*

Purpose: Run a stacked interacted regression. 
In other words, generate energy-temperature response sters for fully interacted model.

*/

****** Set Model Specification Locals ******************************************

local model "$model"
local submodel "$submodel"

// create local for naming ster file

if "`submodel'" != "" local model_name = "`model'_`submodel'"
else local model_name = "`model'"

********************************************************************************
* Step 1: Load Data
********************************************************************************

if (strpos("`model_name'", "EX") == 0) {
	use "$DATA/regression/GMFD_`model'_regsort.dta", clear
}
else {
	use "$DATA/regression/GMFD_`model_name'_regsort.dta", clear
}

********************************************************************************
* Step 2: Prepare Regressors and Run Regression
********************************************************************************

// set time
sort region_i year 
tset region_i year

* long run income x income group

local lgdppc_MA15_r = ""

forval pg=1/2 {
	forval lg = 1/2 {
		local lgdppc_MA15_r = "`lgdppc_MA15_r' c.indp`pg'#c.indf1#c.FD_I`lg'lgdppc_MA15"
	}		
}

* large income group dummies

forval pg=1/2 {
	forval lg=1/2 {
		gen DumIncG`lg'F1P`pg' = FD_largeind`lg'*indf1*indp`pg'
	}
}


* precip

local precip_r = ""

forval pg=1/2 {
	forval k = 1/2 {
		local precip_r = "`precip_r' c.indp`pg'#c.indf1#c.FD_precip`k'_GMFD"
	}		
}

* temp

local temp_r = ""

forval pg=1/2 {
	forval k=1/2 {
		local temp_r = "`temp_r' c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD"
	}
}

* temp x long run climate

local climate_r = ""
forval pg = 1/2 {
	forval lg = 1/2 {
		forval k = 1/2 {
			local climate_r = "`climate_r' c.indp`pg'#c.indf1#c.FD_hdd20_TINVtemp`k'_GMFD c.indp`pg'#c.indf1#c.FD_cdd20_TINVtemp`k'_GMFD"
		}
	}		
}

* temp x income spline

local income_spline_r = ""
forval pg=1/2 {
	forval lg = 1/2 {
		forval k = 1/2 {
			local income_spline_r = "`income_spline_r' c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
		}
	}		
}

if ("`submodel'" == "lininter") {
	
	* temp x year

	local year_temp_r = ""

	forval pg=1/2 {
		forval k = 1/2 {
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.FD_yeartemp`k'_GMFD"
		}	
	}
		
	* temp x year x income spline

	local year_income_spline_r = ""
	
	forval pg=1/2 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15yearI`lg'temp`k'"
			}
		}		
	}
}


//run first stage regression
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' ///
`lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' ///
DumInc*, absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i) residuals(resid)
estimates save "$OUTPUT/sters/FD_inter_`model_name'", replace	

//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
drop resid

//run second stage FGLS regression
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' ///
`lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' ///
DumInc* [pw = weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i)
estimates save "$OUTPUT/sters/FD_FGLS_inter_`model_name'", replace

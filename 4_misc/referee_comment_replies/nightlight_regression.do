
clear all
set more off
macro drop _all
cilpath

* merge in the nightlight data
global root "${REPO}/energy-code-release-2020"

* get nightlight data
import delimited using "/shares/gcp/social/baselines/nightlights_downscale/NL/nightlights_1992_test2.csv", clear
rename iso country
drop year
rename sumpop nightlight
replace nightlight = log(nightlight)
* merge with our existing data
merge 1:n country using "$DATA/regression/GMFD_TINV_clim_regsort.dta"
drop if _merge != 3
* 194 observations dropped
save "$DATA/regression/GMFD_TINV_clim_regsort_nightlight_1992.dta", replace



use "$DATA/regression/GMFD_TINV_clim_regsort_nightlight_1992.dta", clear

********************************************************************************
* Prepare Regressors and Run Regression 
********************************************************************************

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

* CHECK: 
* nightlight term
local nightlight_r = ""
forval pg = 1/2 {
	forval k = 1/2 {
		local nightlight_r = "`nightlight_r' c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD#c.nightlight "
	}
}

* CHECK: added the nightlight_r term
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' `nightlight_r' `lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' DumInc*, absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i) residuals(resid)
estimates save "$OUTPUT/sters/FD_inter_nightlight", replace	


drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
drop resid

* CHECK: added the nightlight_r term
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' `nightlight_r' `lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' DumInc* [pw = weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i)
estimates save "$OUTPUT/sters/FD_FGLS_inter_nightlight", replace



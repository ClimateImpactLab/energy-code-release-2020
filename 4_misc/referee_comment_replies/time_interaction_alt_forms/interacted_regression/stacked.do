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

// set time variable to be interacted
if ("`submodel'" == "plininter") {
	local yr pyear
	local indv indt
} 
else {
	local yr year
	local indv indd

}

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
if ("`submodel'" != "coldsidehighincsep") & ("`submodel'" != "dechighincsep") & ("`submodel'" != "dechighincsepcold") {
	forval pg=1/2 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local income_spline_r = "`income_spline_r' c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
}
// for the two models separating low income, high income but not always rich, and electricity always rich:
else {
	// low income terms
	forval pg=1/2 {
		forval lg = 1/1 {
			forval k = 1/2 {
				local income_spline_r = "`income_spline_r' c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
	// high income but not always rich terms
	forval pg=1/2 {
		forval lg = 2/2 {
			forval k = 1/2 {
				local income_spline_r = "`income_spline_r' c.indp`pg'#c.indf1#c.largeind_notallyears#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
	// high income always rich terms, electricity only
	forval pg=1/1 {
		forval lg = 2/2 {
			forval k = 1/2 {
				local income_spline_r = "`income_spline_r' c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
}

* temp x year

local year_temp_r = ""

if ("`submodel'" == "plininter") {
	forval pg=1/2 {
		forval k = 1/2 {
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#i.`indv'#c.FD_`yr'temp`k'_GMFD"
		}	
	}
} 
else if ("`submodel'" == "decinter") { 
	// for decadal interaction, use temp interacted with decadal indicator
	forval pg=1/2 {
		forval k=1/2 {
			local year_temp_r = "`year_temp_r' i.indd#c.indp`pg'#c.indf1#c.FD_temp`k'_GMFD"
		}
	}
}
else if ("`submodel'" == "dechighinc") | ("`submodel'" == "dechighincsep")  { 
	// for decadal interaction, use temp interacted with decadal indicator
	// only for electricity (pg==1)
	forval pg=1/1 {
		forval k=1/2 {
			local year_temp_r = "`year_temp_r' i.indd#c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_temp`k'_GMFD"
		}
	}
}
else if ("`submodel'" == "dechighincsepcold") | ("`submodel'" == "dechighinccold")   { 
	// for decadal interaction, use temp interacted with decadal indicator
	// only for electricity (pg==1)
	forval pg=1/1 {
		forval k=1/2 {
			local year_temp_r = "`year_temp_r' i.indd#c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_polyBelow`k'_GMFD"
		}
	}
}
else if ("`submodel'" == "p80elecinter"){
	// p80elecinter model
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	// note that unlike in plininter model, here indp80 is prefixed with c., not i. 
	// since we don't want the case for indp80==0
	forval pg=1/1 {
		forval k = 1/2 {
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.indp80#c.FD_p80yrtemp`k'_GMFD"
		}	
	}
}
else if ("`submodel'" == "coldsidep80") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval k = 1/2 {   
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.indp80#c.FD_p80yr_polyBelow`k'_GMFD"		
		}	
	}
} 
else if ("`submodel'" == "coldside") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval k = 1/2 {   
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.FD_year_polyBelow`k'_GMFD"
		}	
	}
} 
else if ("`submodel'" == "coldsidehighinc") | ("`submodel'" == "coldsidehighincsep"){
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval k = 1/2 {   
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_year_polyBelow`k'_GMFD"
		}	
	}
} 
else if ("`submodel'" == "twosidedp80") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval k = 1/2 {   
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.indp80#c.FD_p80yr_polyBelow`k'_GMFD"
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#c.indp80#c.FD_p80yr_polyAbove`k'_GMFD"
		}	
	}
} 
else if ("`submodel'" == "coldsidepwl") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	// note that the only difference with coldsidep80 model
	// is that here indp80 is prefixed with i.,  
	forval pg=1/1 {
		forval k = 1/2 {   
			local year_temp_r = "`year_temp_r' c.indp`pg'#c.indf1#i.indp80#c.FD_p80yr_polyBelow`k'_GMFD"
		}	
	}
} 

* temp x year x income spline

local year_income_spline_r = ""

if ("`submodel'" == "plininter") {
	forval pg=1/2 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#i.`indv'#c.FD_dc1_lgdppc_MA15`yr'I`lg'temp`k'"
			}
		}		
	}
} 
else if ("`submodel'" == "decinter") {
	forval pg=1/2 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' i.indd#c.indp`pg'#c.indf1#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
}
else if ("`submodel'" == "dechighinc") | ("`submodel'" == "dechighincsep") {
	// only for electricity (pg==1) and for high income (lg == 2)
	forval pg=1/1 {
		forval lg = 2/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' i.indd#c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_dc1_lgdppc_MA15I`lg'temp`k'"
			}
		}		
	}
}
else if ("`submodel'" == "dechighincsepcold") |  ("`submodel'" == "dechighinccold") {
	// only for electricity (pg==1) and for high income (lg == 2)
	forval pg=1/1 {
		forval lg = 2/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' i.indd#c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_dc1_lgdppc_MA15I`lg'polyBelow`k'"
			}
		}		
	}
}
else if ("`submodel'" == "p80elecinter") {
	// p80elecinter model
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	// note that unlike in plininter model, here indp80 is prefixed with c., not i. 
	// since we don't want the case for indp80==0
	forval pg=1/1 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.indp80#c.FD_dc1_lgdppc_MA15p80yrI`lg'temp`k'"
			}
		}		
	}
}
else if ("`submodel'" == "coldsidep80") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.indp80#c.FD_lgdppc_MA15p80yrI`lg'polyBelow`k'"
			}
		}		
	}
}
else if ("`submodel'" == "coldsidehighinc") | ("`submodel'" == "coldsidehighincsep"){
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	// only include high income terms lg=2
	forval pg=1/1 {
		forval lg = 2/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.largeind_allyears#c.FD_lgdppc_MA15yearI`lg'polyBelow`k'"
			}
		}		
	}
}
else if ("`submodel'" == "coldside") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.FD_lgdppc_MA15yearI`lg'polyBelow`k'"
			}
		}		
	}
}
else if ("`submodel'" == "twosidedp80") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.indp80#c.FD_lgdppc_MA15p80yrI`lg'polyBelow`k'"
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#c.indp80#c.FD_lgdppc_MA15p80yrI`lg'polyAbove`k'"
			}
		}		
	}
}
else if ("`submodel'" == "coldsidepwl") {
	// * 1 = electricity, 2 = other_energy
	// include only electricity terms
	forval pg=1/1 {
		forval lg = 1/2 {
			forval k = 1/2 {
				local year_income_spline_r = "`year_income_spline_r' c.indp`pg'#c.indf1#i.indp80#c.FD_lgdppc_MA15p80yrI`lg'polyBelow`k'"
			}
		}		
	}
}



//run first stage regression
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' ///
`lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' ///
DumInc*, absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i) residuals(resid)
estimates save "$OUTPUT/sters/FD_inter_`model_name'", replace	

// copy the ster file for plotting separately for always rich and sometimes rich groups 
if  (strpos("`model_name'", "sep") > 0) | (strpos("`model_name'", "highinc") > 0) {
	estimates save "$OUTPUT/sters/FD_inter_`model_name'_alwaysrich", replace	
}

//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
drop resid //included

//run second stage FGLS regression
reghdfe FD_load_pc `temp_r' `precip_r' `climate_r' ///
`lgdppc_MA15_r' `income_spline_r' `year_temp_r' `year_income_spline_r' ///
DumInc* [pw = weight], absorb(i.flow_i#i.product_i#i.year#i.subregionid) cluster(region_i) residuals(resid)
estimates save "$OUTPUT/sters/FD_FGLS_inter_`model_name'", replace

// copy the ster file for plotting separately for always rich and sometimes rich groups 
if  (strpos("`model_name'", "sep") > 0) | (strpos("`model_name'", "highinc") > 0) {
	estimates save "$OUTPUT/sters/FD_FGLS_inter_`model_name'_alwaysrich", replace	
}


ssc install sepscatter

/* some summary statistics for decadal regression residuals */
if (strpos("`model_name'", "decinter") > 0) {
	keep if product == "electricity"
	// always rich
	gen category = "always rich" if largeind_allyears == 1
	replace category = "rich" if largeind2 == 1 & largeind_allyears == 0
	replace category = "poor" if largeind1 == 1 

	sepscatter resid year, separate(category)
	graph export "$OUTPUT/figures/scatterplot_decinter_residuals_by_income_group.pdf", replace
	
	scatter resid year if category == "always rich"
	graph export "$OUTPUT/figures/scatterplot_decinter_residuals_always_rich.pdf", replace
	scatter resid year if category == "rich"
	graph export "$OUTPUT/figures/scatterplot_decinter_residuals_rich.pdf", replace
	scatter resid year if category == "poor"
	graph export "$OUTPUT/figures/scatterplot_decinter_residuals_poor.pdf", replace

}








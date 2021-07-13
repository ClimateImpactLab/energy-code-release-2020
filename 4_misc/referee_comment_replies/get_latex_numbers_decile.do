clear all
set more off
macro drop _all
pause on
cilpath

global root "${REPO}/energy-code-release-2020"
global model "TINV_clim"
set scheme s1color


local model = "$model"



* electricity 
local electricity_col "dknavy"
local electricity_colTT "Blue"

* other energy 
local other_energy_col "dkorange"
local other_energy_colTT "Orange"
			
use "$DATA/regression/GMFD_`model'_regsort.dta", clear

local obs = 35 + abs(-5) + 1

drop if _n > 0
set obs `obs'

replace temp1_GMFD = _n - 6

foreach k of num 1/2 {
	rename temp`k'_GMFD temp`k'
	replace temp`k' = temp1 ^ `k'
}

********************************************************************************
* Step 2: Plot Plot Plot
********************************************************************************

forval lg=1/10 {
			
	local SE ""
	local noSE ""
	local colorGuide ""	

	foreach var in "electricity" "other_energy" {

		if "`var'" == "electricity" {
			local pg = 1
		}
		else if "`var'" == "other_energy" {
			local pg=2
		}

		* construct local variable that holds dose response
		
		local line = ""
		local add = ""
		
		forval k = 1/2 {

			local line = "`line'`add'_b[c.indp`pg'#c.indf1#c.FD_I`lg'temp`k'] * (temp`k' - 20^`k')"
			local add " + "

		} 

		* use ster to estimate dose response

		estimates use "$OUTPUT/sters/FD_FGLS_income_decile_`model'"
		predictnl yhat`lg'_`var' = `line', se(se`lg'_`var') ci(lower`lg'_`var' upper`lg'_`var')
		
		loc SE = "`SE' rarea upper`lg'_`var' lower`lg'_`var' temp1, col(``var'_col'%30) || line yhat`lg'_`var' temp1, lc (``var'_col') ||"
		loc noSE "`noSE' line yhat`lg'_`var' temp1, lc (``var'_col') ||"
		loc colorGuide = "`colorGuide' `var' (``var'_colTT')"

		if (`lg' == 10) {
			di "`lg'"
			di "`var'"
			list temp1 yhat`lg'_`var'
			
		}

	}
	
}				
									
	

graph drop _all	

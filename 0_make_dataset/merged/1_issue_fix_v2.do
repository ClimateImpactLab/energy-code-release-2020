/*

Purpose: Apply Coded Issues

*/

******Set Script Toggles********************************************************

// toggle for dropping exclusively estimated data
local model $model

********************************************************************************
* Step 1: Load Energy Data and Coded Issues to Apply to Energy Dataset
********************************************************************************

// Part A: Make Energy Dataset Tempfile and retrieve Country List for looping

use "$DATA/regression/IEA_Merged_long_GMFD.dta", clear
drop countryid
keep if year>=1971 & year<=2012
generate FEtag="G"
tempfile energy_long
save `energy_long', replace
keep if temp1_GMFD !=.
duplicates drop country, force
levelsof country, local(countrylist)

// Part B: Load Coded Issues - type/set of coded issues specified with toggle at top of code

insheet using "$root/0_make_dataset/coded_issues/cleaned_coded_issues.csv", comma names clear

foreach variable in "grey" "flag_drop" {
	replace `variable' = 0 if `variable' == .
}

// Part C: Set up Exclusively Estimated Observations to be Dropped if model requires it

if ("`model'" == "TINV_clim_EX" ) {
	replace grey = 9 if ex_ex == 1 
	di "Set up exclusively estimated data to be dropped."
}

********************************************************************************
* Step 2: Clean Coded Issues and Save in Issue Type Specific Datasets
********************************************************************************

** replace to match the main file**
keep country sector fuel issue_code year_start year_end flag_drop grey

foreach var in fuel sector {
	qui replace `var'="" if `var' == "." | `var'==""
}

rename sector flow
rename fuel product

replace product="biofuels" if product=="biofuels and waste" | product == "biofuelsandwaste"
replace product="heat_other" if product=="heat"
replace product="natural_gas" if product=="natural gas" | product=="naturalgas"
replace product="oil_products" if product=="oil"
replace product="solar" if product=="solar and geothermal"
replace product="all" if product==""

** save FEcut and dropped files individually**

// Create tempfile for coded issues that classify observations into a FE regime
preserve
	keep if flag_drop==0 & grey==0
	drop flag_drop grey
	tempfile fixed_effects
	save `fixed_effects', replace
restore

// Create tempfile for coded 
preserve
	keep if flag_drop==1
	drop flag_drop grey
	tempfile flag_drop_issues
	save `flag_drop_issues', replace
restore

preserve
	keep if grey == 1
	drop flag_drop grey
	tempfile grey_one_issues
	save `grey_one_issues', replace
restore

preserve
	keep if grey == 9
	drop flag_drop grey
	tempfile grey_nine_issues
	save `grey_nine_issues', replace
restore

**Make temp files for saving future data

preserve
	drop if _n > 0
	tempfile fixed_effects_file
	save `fixed_effects_file', replace
	tempfile flag_drop_issues_file
	save `flag_drop_issues_file', replace
	tempfile grey_one_issues_file
	save `grey_one_issues_file', replace
	tempfile grey_nine_issues_file
	save `grey_nine_issues_file', replace
restore

********************************************************************************
* Step 3: Write Programs To Use In Country Flow Product Loop
********************************************************************************

//Issue Data Cleaning and Reshaping Programs

program define clean_issues

syntax , country(string) flow(string) product(string)

	//di "country: `country' flow: `flow' product: `product'"

	//country
	qui keep if country=="`country'"
				
	//flow

	qui replace flow="`flow'"

	//product
	if ("`product'"=="other_energy") {
		qui keep if product!="electricity"
	}
	else if ("`product'"== "electricity") {
		qui keep if product=="`product'" | product=="all" | product=="all but biofuels" | product == "allbutbiofuels"
	}
				
	qui replace product="`product'"

end

program define restructure_issues, rclass

	**duplicates drop**
	qui duplicates drop year_start year_end, force
					
	**sort and generate tag**
	sort year_start
	qui drop if country==""
	qui generate idn=_n
					
	**local parameters**
	qui summ idn
	local mt=r(N)
					
	**invert to obtain year segments**
	qui drop issue_code //drop disturbing factors for now
	qui reshape wide year_start year_end, i(country flow product) j(idn)

	return scalar mt = `mt'
end


//Programs specific to each particular type of issue

program define fixed_effects //pass in number of observations to apply
	
	**assign flags to different years, Greg's algorithm of adding on**
	forval i=1/`1' {
		qui replace FEtag=FEtag+"1" if year>=year_start`i' & year<=year_end`i' 
		qui replace FEtag=FEtag+"0" if year<year_start`i' | year>year_end`i' 
	}

end

program define flag_drop_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year>=year_start`i' & year<=year_end`i' 
	}

end

program define grey_one_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year<year_start`i' | year>year_end`i' 
	}

end

program define grey_nine_issues //pass in number of observations to apply

	forval i=1/`1' {
		qui drop if year>=year_start`i' & year<=year_end`i' 
	}


end

********************************************************************************
* Step 4: Apply Issues Selected and Save Issue Fixed Data
********************************************************************************

**loop through fuels**
foreach var in "other_energy" "electricity" {
	**loop through sectors**
	foreach tag in "COMPILE" {
		**loop through countries**
		foreach loc in `countrylist' {
		
			timer on 1
			
			local merge_file "energy_long"
			
			foreach it in "fixed_effects" "flag_drop_issues" "grey_one_issues" "grey_nine_issues" { //note order issues are applied matters
				
				//load in and clean issues
				qui use ``it'', clear
				
				clean_issues, country("`loc'") flow("`tag'") product("`var'")
				
				qui count 
				local ct=r(N)
				local zt=1
								
				**proceed only when the issue exists**
				if `ct'!=0 & `zt'==1 {
					
					//compress issues so no time segements overlap, clean, and reshape
					restructure_issues
					local mt =`r(mt)'
					
					**merge back to IEA datas**
					qui merge 1:m country flow product using ``merge_file''
					
					//Datasets only have to match if no data points have been dropped
					if ("`it'" == "fixed_effects" | "`it'" == "flag_drop_issues" ) {
						assert _merge != 1
					}
					
					qui keep if _merge == 3
					drop _merge
					
					//run issue type specific program to clean data
					`it' `mt'
			
					**save and tempfile**
					drop year_start* year_end*
					tempfile file`loc'
					qui save `file`loc'', replace
					
				}
				else if `ct'==0 & `zt'==1 {
					
					**keep the original data**
					qui use ``merge_file'', clear
					qui keep if country=="`loc'"
					qui keep if flow=="`tag'"
					qui keep if product=="`var'"
					
					**save and tempfile**
					tempfile file`loc'
					qui save `file`loc'', replace
				
				}
				else if `zt'==0 {
				
					**keep the original data**
					qui use ``merge_file'', clear
					qui drop if _n>0
					
					**save and tempfile**
					tempfile file`loc'
					qui save `file`loc'', replace	
					
				}
				local merge_file = "`it'_file"
				**appending back to the long data**
				qui use ``merge_file'', clear
				append using `file`loc''
				qui save ``merge_file'', replace
			}
			
			timer off 1
			qui timer list 1
			local tim=r(t1)
			timer clear
			
			**keep time track**
			display "`var' `tag' `loc'-`tim's"
		
		}
	}
}

use `grey_nine_issues_file', clear

// clean up shop
drop issue_code year_start year_end flag_drop grey
sort flow product country year flow

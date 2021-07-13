
/*

* Purpose: Testing for the existence of unit roots in energy load data
	* Does this separately for electricity and other energy

Uses cleaned dataset outputted by 2_construct_regression_ready_data.do
Outputs two figures - one for each product

*/

clear all
set more off

* Set up the paths:
cilpath
global root "$REPO/energy-code-release-2020"

global DATA "$root/data"
global OUT "$OUTPUT/figures"


** TESTING EXISTENCE OF UNIT ROOTS **

global data_name "GMFD_TINV_clim_regsort.dta"

* Loop over the different products, and the different types of tests
foreach test in "vecrank" "egranger" {
	foreach prod in "other_energy" "electricity" {

		*load dataset, subset to relevant product

*		loc prod "electricity"
*		loc test "vecrank"
		use "$DATA/$data_name", clear
		keep if product=="`prod'"

		if "`prod'" == "electricity" {
			loc temp_var temp1_GMFD	
		} 
		else {
			loc temp_var temp1_other_GMFD
		}

		*Time set the data 
		sort region_i year 
		xtset region_i year


		*initialize - create tempfile shells, to append the test values into 
		preserve
			clear
			generate lag=.
			generate country=""
			generate FEtag=""
			if "`test'" == "vecrank" {
				* TO-DO: need to change later
				foreach ind in N reject_null {
					generate double `ind'=.
				}
			} 
			if "`test'" == "egranger" {
				* TO-DO: need to change later
				foreach ind in N1 N2 Zt cv5 lags reject_null {
					generate double `ind'=.
				}
				generate default=.
			}
			tempfile testfile
			save `testfile', replace
		restore
		
		forval ll=0/2 {  
			*loop around lags

			levelsof region_i, loc(FEs)
			foreach i in `FEs' {  
				*loop around FE regimes 
				di "for test `test', we are on region_i = `i', prod = `prod', lag = `ll'"
				* Run cap so that it records missing for regimes with only 2 obs
				if "`test'" == "vecrank" {
					cap vecrank load_pc `temp_var' if region_i==`i', trend(rconstant) lags(`ll')
					
					local vN = e(N)

				*	matrix trace_matrix = e(trace)
				*	vtrace vtrace[1,1]

					if e(k_ce99) == 0 {
						loc vreject_null = 0
					}
					else {
						loc vreject_null = 1
					}

					*foreach ind in N max trace lags {
					*	local v`ind'=e(`ind')
					*}
					* Save a dataset of the results as a tempfile, for appending 
					preserve
						keep if region_i==`i'
						duplicates drop region_i, force
						keep country FEtag
						generate lag=`ll'
						* Save the results 
						foreach ind in N reject_null {
							generate `ind'=`v`ind''
						}
						* Append the results together
						append using `testfile'
						save `testfile', replace	
					restore
				}

				if "`test'" == "egranger" {
					cap egranger load_pc `temp_var' if region_i==`i', trend lags(`ll')

					foreach ind in N1 N2 Zt cv5 lags {
						local v`ind'=e(`ind')
					}

					if `vZt' > `vcv5' {
						loc vreject_null = 1
					}
					else {
						loc vreject_null = 0
					}

					* Save a dataset of the results as a tempfile, for appending 
					preserve
						keep if region_i==`i'
						duplicates drop region_i, force
						keep country FEtag
						generate default=0
						generate lag=`ll'
						* Save the results of the PR test 
						foreach ind in N1 N2 Zt lags cv5 reject_null {
							generate `ind'=`v`ind''
						}
						* Append the results together
						append using `testfile'
						save `testfile', replace	
					restore
				}

			} 
			* end of loop across regions
			di "done with lag `ll'"
		} 
		* end of loop across lags
		di "Saving the tempfiles, prod `prod', test `test'"

		*save this product's csv
		use `testfile', clear
		sort country FEtag lag
		order country FEtag lag 
		tempfile `test'_`prod'
		save ``test'_`prod'', replace 
		* uncomment the next line if you want to look at the results in a csv
		* export delim using "$OUT/A4_Unit_Root_Tests/bycountry_`test'_`prod'.csv", replace

	} 
	* end of loop over prod types
} 
* end of loop over test types



**----Plotting Histograms for Above Two Tests----**

foreach prod in "other_energy" "electricity" {
	if "`prod'"== "other_energy" {
		local sub_tit="Other Energy"
	}
	else {
		local sub_tit="Electricity"
	}
	foreach test in "vecrank" "egranger" { 
		if "`test'"=="vecrank" {
			local gtit="vecrank"
		}
		else {
			local gtit="egranger"
		}
		use ``test'_`prod'', clear

		forval ll=0/2 {
			*plot
			twoway (histogram reject_null if lag==`ll', width(0.05) fcolor(white) fraction),title("Lag `ll'", size(small)) xtitle("P value", size(small)) xline(0.05, lcolor(navy) noextend) graphregion(color(white)) plotregion(color(white)) xlabel(, labsize(small)) ylabel(, labsize(small)) legend(off) ytitle("Fraction", size(small)) name(hist`test'`ll', replace)
		}
		*combine lag graphs
		graph combine hist`test'0 hist`test'1 hist`test'2, ycomm xcomm imargin(zero) rows(1) xsize(9) ysize(4) title("`gtit'", size(small)) graphregion(color(white)) plotregion(color(white)) name(mhist`test', replace)
	}
	* Combine across lags and across tests, for a given product
	graph combine mhistvecrank mhistegranger, rows(2) xsize(9) ysize(8) subtitle("`sub_tit' reject_null Histograms") graphregion(color(white)) plotregion(color(white))
	* Save the graph 
	graph export "$OUT/cointegration_tests_vecrank-rconstant_egranger_z_val_hists_`prod'.pdf", replace
}
graph drop _all	

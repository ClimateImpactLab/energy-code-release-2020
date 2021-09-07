/*

* Purpose: Testing for the existence of unit roots in energy load data
	* Does this separately for electricity and other energy

Uses cleaned dataset outputted by 2_construct_regression_ready_data.do
Outputs two figures - one for each product

*/

clear all
set more off
global LOG: env LOG
log using $LOG/0_make_dataset/3_unit_root_test_and_plot.log, replace

* Set up the paths:



global REPO: env REPO
global DATA: env DATA 
global OUTPUT: env OUTPUT 
global root "$REPO/energy-code-release-2020"

global OUT "$OUTPUT/figures"


** TESTING EXISTENCE OF UNIT ROOTS **

global data_name "GMFD_TINV_clim_regsort.dta"

* Loop over the different products, and the different types of tests
foreach test in "DF" "PR" {
	foreach prod in "other_energy" "electricity" {

		//load dataset, subset to relevant product

		use "$DATA/regression/$data_name", clear
		keep if product=="`prod'"

		//Time set the data 
		sort region_i year 
		xtset region_i year

		//initialize - create tempfile shells, to append the test values into 
		preserve
			clear
			generate lag=.
			generate country=""
			generate FEtag=""
			if "`test'" == "DF" {
				foreach ind in N Zt p {
					generate double `ind'=.
				}
			} 
			if "`test'" == "PR" {
				foreach ind in N Zt Zrho p lags {
					generate double `ind'=.
				}
				generate default=.
			}
			tempfile testfile
			save `testfile', replace
		restore
		
		forval ll=0/2 {  //loop around lags

			levelsof region_i, loc(FEs)
			foreach i in `FEs' {  //loop around FE regimes 

				di "for test `test', we are on region_i = `i', prod = `prod', lag = `ll'"

				* Run cap so that it records missing for regimes with only 2 obs
				if "`test'" == "DF" {
					cap dfuller load_pc if region_i==`i', trend lags(`ll')
					foreach ind in N Zt p {
						local v`ind'=r(`ind')
					}
					* Save a dataset of the results as a tempfile, for appending 
					preserve
						keep if region_i==`i'
						duplicates drop region_i, force
						keep country FEtag
						generate lag=`ll'
						* Save the results of the DF test 
						foreach ind in N Zt p {
							generate `ind'=`v`ind''
						}
						* Append the results together
						append using `testfile'
						save `testfile', replace	
					restore
				}

				if "`test'" == "PR" {
					cap pperron load_pc if region_i==`i', trend lags(`ll')
					foreach ind in N Zt Zrho p lags {
						local v`ind'=r(`ind')
					}
					* Save a dataset of the results as a tempfile, for appending 
					preserve
						keep if region_i==`i'
						duplicates drop region_i, force
						keep country FEtag
						generate default=0
						generate lag=`ll'
						* Save the results of the PR test 
						foreach ind in N Zt Zrho p lags {
							generate `ind'=`v`ind''
						}
						* Append the results together
						append using `testfile'
						save `testfile', replace	
					restore
				}

			} // end of loop across regions
			di "done with lag `ll'"
		} // end of loop across lags
		di "Saving the tempfiles, prod `prod', test `test'"

		//save this product's csv
		use `testfile', clear
		sort country FEtag lag
		order country FEtag lag N Zt p
		tempfile `test'_`prod'
		save ``test'_`prod'', replace 
		// uncomment the next line if you want to look at the results in a csv
		* export delim using "$OUT/A4_Unit_Root_Tests/bycountry_`test'_`prod'.csv", replace

	} // end of loop over prod types
} // end of loop over test types

**----Plotting Histograms for Above Two Tests----**

foreach prod in "other_energy" "electricity" {
	if "`prod'"== "other_energy" {
		local sub_tit="Other Energy"
		local rgb_color 222 154 73
	}
	else {
		local sub_tit="Electricity"
		local rgb_color 76 87 115
	}
	foreach test in "DF" "PR" { 
		if "`test'"=="DF" {
			local gtit="Augmented Dickey Fuller Unit Root Test"
		}
		else {
			local gtit="Phillips Perron Unit Root Test"
		}
		use ``test'_`prod'', clear

		forval ll=0/2 {
			
			//plot
			twoway (histogram p if lag==`ll', width(0.05) lcolor("`rgb_color'") fcolor("`rgb_color'") fraction), ///
			title("Lag `ll'", size(small)) xtitle("P value", size(small)) ///
			xline(0.05, lcolor(navy) noextend) ///
			graphregion(color(white)) plotregion(color(white)) ///
			xlabel(, labsize(small)) ylabel(, labsize(small)) legend(off) ///
			ytitle("Fraction", size(small)) name(hist`test'`ll', replace)
		}
		//combine lag graphs
		graph combine hist`test'0 hist`test'1 hist`test'2, ycomm xcomm imargin(zero) rows(1) xsize(9) ysize(4) ///
			title("`gtit'", size(small)) graphregion(color(white)) plotregion(color(white)) ///
			name(mhist`test', replace)
	}
	// Combine across lags and across tests, for a given product
	graph combine mhistDF mhistPR, rows(2) xsize(9) ysize(8) ///
		subtitle("`sub_tit' Unit Root Test P-value Histograms") ///
		graphregion(color(white)) plotregion(color(white))
	* Save the graph 
	graph export "$OUT/fig_Appendix-A2_Unit_Root_Tests_p_val_hists_`prod'.pdf", replace
}
graph drop _all	

log close _all

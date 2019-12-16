* Unit root diagnostics and Plotting
* 
clear all
set more off

if c(hostname) == "EPIC-14669" { 
	global DB "C:/Users/TomBearpark/Dropbox/GCP_Reanalysis/ENERGY"
}

global DATA "$DB/IEA_Replication/Data/Analysis/GMFD/rationalized_code/replicated_data/data"
global OUT "$DB/IEA_Replication/Analysis/Output/GMFD/rationalized_code/replicated_data/figures/unit_root"

********************************************************************************
**                      TESTING EXISTENCE OF UNIT ROOTS                       **
********************************************************************************

global data_name "climGMFD_Exclude_all-issues_break2_semi-parametric_TINV_clim_replicated_data_regsort.dta"

foreach test in "DF" "PR" {
	* local test "PR"
	foreach prod in "other_energy" "electricity" {
		//load dataset, subset to relevant product
		* local prod "other_energy"

		use "$DATA/$data_name", clear
		keep if product=="`prod'"

		//Time set the data 
		sort region_i year 
		xtset region_i year

		//initialize - get the tempfiles going, to append the values into - 
		// note they are slightly different for the different test types 
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
		export delim using "$OUT/csvs/bycountry_`test'_`prod'.csv", replace

	} // end of loop over prod types
} // end of loop over test types

**----Plotting Histograms for Above Two Tests----**

clear
foreach prod in "other_energy" "electricity" {
	if "`prod'"== "other_energy" {
		local sub_tit="Other Energy"
	}
	else {
		local sub_tit="Electricity"
	}
	foreach test in "DF" "PR" { 
		if "`test'"=="DF" {
			local gtit="Augmented Dickey Fuller Unit Root Test"
		}
		else {
			local gtit="Phillips Perron Unit Root Test"
		}
		import delim using "$OUT/csvs/bycountry_`test'_`prod'.csv", clear

		forval ll=0/2 {
			//plot
			twoway (histogram p if lag==`ll', width(0.05) fcolor(white) fraction), ///
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
	graph combine mhistDF mhistPR, rows(2) xsize(9) ysize(8) ///
	subtitle("`sub_tit' Unit Root Test P-value Histograms") ///
	graphregion(color(white)) plotregion(color(white))
	graph export "$OUT/histograms/p_val_hists_`prod'.pdf", replace
}
graph drop _all	

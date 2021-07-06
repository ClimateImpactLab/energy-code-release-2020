
* Calculate price increases for non-US countries for which we have price data.
* take the earliest/latest years available in the data (IEA_price.dta)
clear all
restore, not
global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/1_inter/"
*global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/2_final/"

use "${path}/consumption_shares.dta", clear
levelsof country, local(countries)

* check and found that only LVA has duplicated entries
*use "${path}/IEA_Price.dta", clear
*bysort country year: gen duplicates = _N > 1
*list country year if duplicates == 1
tempname results
tempfile results_file
postfile `results' str10 country str20 price start_year end_year n_obs annual_growth_rate_pct using "`results_file'", replace
quietly{
	foreach c of local countries {
		di "`c'"
		if "`c'" == "LVA" continue
		use "${path}/IEA_Price.dta", clear
		keep if country == "`c'"

		* drop fuels that don't have any observations
		foreach var of varlist *price* {
		    capture assert mi(`var')
		    if !_rc {
		       drop `var'
		    }
		}

		encode country, gen(iso)
		isid year
		xtset iso year

		* loop through each fuel and calculate compound growth rate
		* for those with at least 5 years observation
		foreach var of varlist _all {
			if strpos("`var'", "price")>0 {
				*di "`var'"
				preserve
				drop if `var'==.
				*list year
				* find how many years the time series is
				gen run = .
				replace run = cond(L.run == ., 1, L.run + 1)
				egen maxrun = max(run)
				* only compute price growth rate for time series > 5yrs long
				if maxrun[1] >=5 {
					loc n_yr = year[_N] - year[1]
					gen grate = .
					replace grate = ((`var'[_N] / `var'[1]) ^(1/`n_yr') - 1 ) * 100
					*format grate %8.3f
					*loc n_ts_length = maxrun[1]
					loc growth_rate = grate[1]
					loc start_year = year[1]
					loc end_year = year[_N]
					local fmt_grate: display %4.2f `growth_rate'

					noisily di "`c'  `var'  `n_ts_length' years `start_year' to `end_year'  `fmt_grate'%" 
					post `results' ("`c'") ("`var'") (`start_year') (`end_year') (`n_yr')  (`fmt_grate')

				}
				restore
			}
		}
	}
}
postclose `results'

use `results_file', clear
export delimited using  "/home/liruixue/repos/energy-code-release-2020/data/price_growth_rates.csv", replace


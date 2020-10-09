
* Calculate price increases for non-US countries for which we have price data.
* take the earliest/latest years available in the data (IEA_price.dta)
global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/1_inter/"
*global path "/mnt/CIL_energy/IEA_Replication/Data/Projection/prices/2_final/"

use "${path}/consumption_shares.dta", clear


quietly{
	foreach c in "CHN" "BRA" "IND" "MEX" "ZAF" "KAZ" "THA" "VEN" {
		use "${path}/IEA_Price.dta", clear
		keep if country == "`c'"
		*keep if country == "BRA"
		di "`c'" 

		* drop fuels that don't have any observations
		foreach var of varlist _all {
		    capture assert mi(`var')
		    if !_rc {
		       drop `var'
		    }
		}

		encode country, gen(iso)
		xtset iso year

		* loop through each fuel and calculate compound growth rate
		* for those with at least 5 years observation
		foreach var of varlist _all {
			if strpos("`var'", "price")>0 {
				*di "`var'"
				preserve
				drop if `var'==.
				gen run = .
				replace run = cond(L.run == ., 1, L.run + 1)
				egen maxrun = max(run)
				if maxrun[1] >=5 {
					loc n_yr = maxrun[1] - 1
					gen grate = .
					replace grate = ((`var'[_N] / `var'[1]) ^(1/`n_yr') - 1 ) * 100
					*format grate %8.3f
					loc n_ts_length = maxrun[1]
					loc growth_rate = grate[1]
					local fmt_grate: display %4.2f `growth_rate'

					noisily di "`c'  `var'  `n_ts_length' years   `fmt_grate'%"
				}
				restore
			}
		}
	}
}


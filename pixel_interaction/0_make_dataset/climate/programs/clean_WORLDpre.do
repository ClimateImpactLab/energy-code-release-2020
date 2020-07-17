/*
Purpose: WORLD/pre1991 Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues--

SDN: Data for South Sudan are available from 2012. Prior to 2012, they are included in Sudan
ETH: ETH: Prior to 1992, ERI included in Ethiopia
Countries in former soviet union pre 1990: AZE, BLR, KAZ, KGZ, LVA, LTU, MDA, RUS, TJK, TKM, UKR, UZB, ARM, EST, GEO
Countries in former Yugoslavia pre 1990: HRV, MKD, MNE, SRB, SVN, BIH, XKO

What else happens in this function:

1) Construct Fiscal Years based on the following issues:
ETH: Data are reported according to the Ethiopian financial year, which runs from 1 July to 30 June of the next year.

2) Clean up shop: rename countries, generate product specific climate variables, 
change temporal unit from monthly to yearly

3) Generate long run climate measures

4) drop countries in years where spatial dimensions are no longer relevant

*/




program define clean_WORLDpre
	
	
	**Step 1: fix fiscal years
	
	sort country year month
	egen id = group(year month)
	encode country, gen(cnt)
	tset cnt id
	
	**fix fiscal years according to Azhar's code**
	foreach var of varlist tmax* tavg* prcp*  {
		qui generate double `var'_N=`var'
		qui replace `var'_N = F6.`var' if country=="ETH"
	}

	keep *_N country year month
	rename *_N *

	
	**Step 2: Clean up Shop
	
	**generate other energy specific climate variables so can make product specific other energy
	generate_other

	**rename**
	drop if country == "BL"
	drop if country == "CS"
	replace country = "FSUND" if country=="UST"
	replace country = "YUGOND" if country=="YG"
	replace country = "SDN" if country=="SD"

	
	collapse_monthly_to_yearly
	
	**Step 3: Generate long run climate measures
	**generating MA and TINV**
	longrun_climate_measures
	
	**Step 4: Drop Countries where spatial dimension not relevant
	foreach var of varlist tmax* tavg* prcp* {
		qui replace `var' = . if inlist(country, "YUGOND", "FSUND") & year > 1989
		qui replace `var' = . if inlist(country, "ETH") & year > 1991
	}


end


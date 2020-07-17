/*
Purpose: Helper Functions To Simplify Climate Data Cleaning Loop

Included Functions:
1) process monthly: transforms monthly aggregated climate data from wide to long
2) process yearly: transforms yearly aggregated climate data from wide to long
3) collapse_monthly_to_yearly: transform monthly data into yearly data -- 
	- this program gets called after fiscal year fixing specific to a region occured in a clean*.do program
4) calculates long run time invariant climate measures
5) Generate climate variable specific to other energy 
	- in practice this just means generating all the variables with an "_other" tag
	- in a couple instances this variable with the other tag is treated differently
	(which is why it exists at all)

*/

program define process_monthly 
	
	qui reshape long y, i(iso) j(date) string
	qui generate year=substr(date,1,4)
	qui generate month=substr(date,7,2)
	qui destring year, force replace
	qui destring month, force replace
	drop date
	rename iso country

end

program define process_yearly

	rename iso iso
	qui reshape long y, i(iso) j(year)
	rename iso country

end

program define collapse_monthly_to_yearly

	**collapse**
	foreach var of varlist tmax* tavg* prcp* {
		qui generate tagmis=(`var'==.)
		qui bysort country year: egen testmis=sum(tagmis)
		qui replace `var'=. if testmis>0
		drop tagmis testmis
	}
	qui collapse (sum) tmax* tavg* prcp*, by(country year)

end

program define longrun_climate_measures

	foreach var of varlist tmax* {
		qui bysort country: egen double `var'_TINV = mean(`var') if year >= 1971 & year <= 2010
	}

end

program define generate_other
* removed tmax*
	di "generate_other"
	foreach var of varlist tmax* tavg* prcp* {
		qui generate double `var'_other=`var'
	}
	di "end generate_other"

end

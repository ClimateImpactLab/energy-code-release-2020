
/*
Sub-script purpose: Extrapolate in sample price data so that there is one price observation 
for each country, flow, product if there exists a price value in at least one year for a given 
country, product, flow, product combination. In other words if tax data is missing, but price 
data is there use the price data even though it isn't net of taxes.
*/


//place in price if price exists but tax missing
foreach prod in bitcoal cokcoal diesel electr hsfo leadprem leadreg lfo lpg lsfo natgas ///
			 unprem95 unprem98 unreg {
		foreach sec in households industry {
				qui replace `prod'`sec'_atprice=`prod'`sec'_price if (`prod'`sec'_atprice==. & `prod'`sec'_price!=.)
		}	
}


//carry forward - prices increasing at 1.4% per year to make 2012 values comparable

loc growth = 1.014

foreach prod in bitcoal cokcoal diesel electr hsfo leadprem leadreg lfo lpg lsfo natgas ///
			 unprem95 unprem98 unreg {
		foreach sec in households industry {
			foreach itm in price tax atprice {
				sort country year
				by country: replace `prod'`sec'_`itm' = `prod'`sec'_`itm'[_n - 1] * `growth' if `prod'`sec'_`itm' == .

			}	
		}
}


//keep 2012 or max year
qui drop if year>2012
bysort country: egen maxyear = max(year)
qui keep if year == maxyear
drop maxyear

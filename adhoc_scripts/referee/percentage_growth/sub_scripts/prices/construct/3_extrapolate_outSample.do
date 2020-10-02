
//Extrapolate with global average

//Loop through all variables to fill in
foreach prod in bitcoal cokcoal othercoal diesel resfuel gasoline lpg otheroil coal oil natgas solar biofuels heat {
	foreach sec in households industry {
		
		preserve
		**obtain insample mean for product flow combo**
		qui keep if `prod'`sec'_atprice!=.
		qui count
		local cN=r(N)
		if `cN'!=0 {
				qui collapse (mean) `prod'`sec'_atprice [fw=pop]
				local sub =`prod'`sec'_atprice
				di "`prod' `sec' has an inSample mean"
		}
		restore
		
		**replacing levels by levels**
		qui replace `prod'`sec'_atprice=`sub' if (`prod'`sec'_atprice==.)
			
		**drop**
		local sub = .
	}
}

//Clean
qui drop if subregionid==.
drop pop
qui replace year=2012 if year==.

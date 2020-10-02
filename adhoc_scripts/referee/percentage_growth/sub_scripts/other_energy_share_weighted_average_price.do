//Generate share weighted average for other_energy

**Compute the product of price*share **
rename *share* *share
foreach prod in bitcoal cokcoal othercoal diesel resfuel gasoline lpg otheroil {
	foreach sec in compile {
		qui gen double `prod'`sec'_sums=`prod'`sec'_atprice*`prod'`sec'_share
	}
}

**Level 3: coal segments **

/*

Compute the coal price as the consumption share weighted sum of bitcoal, cokcoal, 
and other coal prices. If the resulting value is a zero or missing, compute the 
coal price as the average of the bitcoal, cokcoal, and other coal price.

*/

foreach sec in compile {
	qui egen coalsum`sec'=rowtotal(bitcoal`sec'_sums cokcoal`sec'_sums othercoal`sec'_sums)
	qui egen coalshr`sec'=rowtotal(bitcoal`sec'_share cokcoal`sec'_share othercoal`sec'_share)
	qui gen double coalprc`sec'=coalsum`sec'/coalshr`sec'
	qui egen mcoalprc`sec'=rowmean(bitcoal`sec'_atprice cokcoal`sec'_atprice othercoal`sec'_atprice)
	qui replace coalprc`sec'=mcoalprc`sec' if (coalprc`sec'==. | coalprc`sec'==0)
	qui replace othercoal`sec'_atprice=coalprc`sec' if othercoal`sec'_atprice==.
	qui replace coal`sec'_atprice=coalprc`sec' if coal`sec'_atprice==.
	drop coalprc* mcoalprc* coalsum* coalshr*
}		

**Level 3: oil segments**

/*

Compute the oil price as the consumption share weighted sum of diesel, resfuel, 
gasoline, lpg and other oil prices. If the resulting value is a zero or missing, 
compute the oil price as the average of the diesel, resfuel, gasoline, lpg and 
other oil prices.

*/


foreach sec in compile {
	qui egen oilsum`sec'=rowtotal(diesel`sec'_sums resfuel`sec'_sums gasoline`sec'_sums lpg`sec'_sums otheroil`sec'_sums)
	qui egen oilshr`sec'=rowtotal(diesel`sec'_share resfuel`sec'_share gasoline`sec'_share lpg`sec'_share otheroil`sec'_share)
	qui gen double oilprc`sec'=oilsum`sec'/oilshr`sec'
	qui egen moilprc`sec'=rowmean(diesel`sec'_atprice resfuel`sec'_atprice gasoline`sec'_atprice lpg`sec'_atprice otheroil`sec'_atprice)
	qui replace oilprc`sec'=moilprc`sec' if (oilprc`sec'==. | oilprc`sec'==0)
	qui replace otheroil`sec'_atprice=oilprc`sec' if otheroil`sec'_atprice==.
	qui replace oil`sec'_atprice=oilprc`sec' if oil`sec'_atprice==.
	drop oilprc* moilprc* oilsum* oilshr*
}	


**Level 2: all segments**

/*

Compute the other_energy price as the consumption share weighted sum of oil, 
coal, natgas, solar, biofuels and heat prices. If the resulting value is a zero 
or missing, compute the other_energy price as the average of the oil, coal, 
natgas, solar, biofuels and heat prices.

*/


foreach prod in coal oil natgas {
	foreach sec in compile {
		qui gen double `prod'`sec'_sums=`prod'`sec'_atprice*`prod'`sec'_share
	}
}

foreach sec in compile {
	qui egen nesum`sec'=rowtotal(coal`sec'_sums oil`sec'_sums natgas`sec'_sums)
	qui egen neshr`sec'=rowtotal(coal`sec'_share oil`sec'_share natgas`sec'_share)
	qui gen double neprc`sec'=nesum`sec'/neshr`sec'
	qui egen mneprc`sec'=rowmean(coal`sec'_atprice oil`sec'_atprice natgas`sec'_atprice)
	qui replace neprc`sec'=mneprc`sec' if (neprc`sec'==. | neprc`sec'==0)
	rename neprc`sec' other_energy`sec'_atprice
	drop mneprc* nesum* neshr*
}

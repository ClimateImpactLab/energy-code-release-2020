
//Generate share data for the different products

**Shares Level 2, over other energy**

//using incomplete other energy share because we don't have prices for the other other energy products
qui generate double other_energycompile = coalcompile + oil_productscompile + natgascompile + biofuelscompile + heat_othercompile + solarcompile

foreach prod in coal oil_products natgas biofuels heat_other solar {
	foreach sec in compile {
		qui gen double `prod'`sec'_share2=`prod'`sec'/other_energy`sec'
	}
}

rename heat_other* heat*
rename oil_products* oil*

**Save**
keep country subregionid *share2
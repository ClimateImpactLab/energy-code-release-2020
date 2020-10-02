//Generate oil subfuel shares

**Generate grand total**
foreach sec in compile {
	local oil`sec' = ""
	foreach prod in "refingas" "ethane" ///
					"lpg" "avgas" "jetgas" "othkero" "resfuel" "naphtha" "whitesp" "lubric" ///
					"bitumen" "parwax" "petcoke" "ononspec" "nonbiodies" "nonbiojetk" "nonbiogaso" {
					local add="`prod'`sec'"
					local oil`sec'="`oil`sec'' `add'"
	}
	qui egen oil_products`sec'=rowtotal(`oil`sec'')
}
rename nonbiodies* diesel*
foreach sec in compile {
	qui gen double gasoline`sec'=nonbiogaso`sec'+avgas`sec'+jetgas`sec'
}
**Compute shares**
foreach prod in lpg resfuel diesel gasoline {
	foreach sec in compile {
		qui gen double `prod'`sec'_share3=`prod'`sec'/oil_products`sec'
	}
}
foreach sec in compile {
	qui gen double otheroil`sec'_share3=1-lpg`sec'_share3-resfuel`sec'_share3-diesel`sec'_share3-gasoline`sec'_share3
	qui replace otheroil`sec'_share3=0 if otheroil`sec'_share3<0 & otheroil`sec'_share3>-0.0001
}
**Save**
keep country subregionid *share3

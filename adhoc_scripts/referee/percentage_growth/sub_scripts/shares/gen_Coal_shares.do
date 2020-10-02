//Generate coal subfuel shares

**Generage grand total**
foreach sec in compile {
	local coal`sec'=""
	foreach prod in "hardcoal" "brown" "antcoal" "cokcoal" "bitcoal" "subcoal" "lignite" "peat" ///
					"patfuel" "ovencoke" "gascoke" "coaltar" "bkb" "gaswksgs" "cokeovgs" "blfurgs" ///
					"peatprod" "ogases" "oilshale" {
					local add="`prod'`sec'"
					local coal`sec'="`coal`sec'' `add'"
	}
	qui egen coal`sec'=rowtotal(`coal`sec'')
}
**Compute shares**
foreach prod in bitcoal cokcoal {
	foreach sec in compile {
		qui gen double `prod'`sec'_share3=`prod'`sec'/coal`sec'
	}
}
foreach sec in compile {
	qui gen double othercoal`sec'_share3=1-bitcoal`sec'_share3-cokcoal`sec'_share3
	qui replace othercoal`sec'_share3=0 if othercoal`sec'_share3<0 & othercoal`sec'_share3>-0.0001
}
**Save**
keep country subregionid *share3

//convert to kwh and subtract off tax

local factor=11630
foreach prod in bitcoal cokcoal diesel electr hsfo leadprem leadreg lfo lpg lsfo natgas ///
			 unprem95 unprem98 unreg {
		foreach sec in HOUSEHOLDS INDUSTRY {
			qui replace `prod'`sec'_price=`prod'`sec'_price/`factor'
			qui replace `prod'`sec'_tax=`prod'`sec'_tax/`factor'
			qui generate double `prod'`sec'_atprice = `prod'`sec'_price - `prod'`sec'_tax
		}
}

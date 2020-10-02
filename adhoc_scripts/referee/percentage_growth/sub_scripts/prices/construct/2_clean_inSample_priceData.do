//Subscript purpose: clean in sample price data and add price variables for prices not in sample

//Keep wanted variables
keep country year ///
	 bitcoalhouseholds_atprice bitcoalindustry_atprice ///
	 cokcoalhouseholds_atprice cokcoalindustry_atprice ///
	 dieselhouseholds_atprice dieselindustry_atprice ///
	 hsfohouseholds_atprice hsfoindustry_atprice ///
	 lfohouseholds_atprice lfoindustry_atprice ///
	 lpghouseholds_atprice lpgindustry_atprice ///
	 lsfohouseholds_atprice lsfoindustry_atprice ///
	 natgashouseholds_atprice natgasindustry_atprice ///
	 unprem95households_atprice unprem95industry_atprice ///
	 unprem98households_atprice unprem98industry_atprice ///
	 unreghouseholds_atprice unregindustry_atprice 

	 
//construct resfuel and gasoline price from the mean of subfuel prices
foreach sec in households industry {
	**fuel oil**
	qui egen resfuel`sec'_atprice=rmean(hsfo`sec'_atprice lfo`sec'_atprice lsfo`sec'_atprice)
	**gasoline**
	qui egen gasoline`sec'_atprice=rmean(unprem95`sec'_atprice unprem98`sec'_atprice unreg`sec'_atprice)
}

//Drop unwanted subcategories
drop hsfo* lfo* lsfo*
drop unprem95* unprem98* unreg*

//Fill in uncated categories
foreach sec in households industry {
	**other coal**
	qui gen double othercoal`sec'_atprice=.
	**other oil**
	qui gen double otheroil`sec'_atprice=.
	**total coal**
	qui gen double coal`sec'_atprice=.
	**total oil**
	qui gen double oil`sec'_atprice=.
	**solar and geothermal**
	qui gen double solar`sec'_atprice=.
	**biofuels**
	qui gen double biofuels`sec'_atprice=.
	**heat**
	qui gen double heat`sec'_atprice=.
}



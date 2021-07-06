/*
Purpose: MDA_other Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

MDA: Official figures on natural gas imports, natural gas inputs to power plants, electricity production and consumption 
are modified by the IEA Secretariat to include estimates for supply and demand for the autonomous region of Stînga Nistrului 
(also known as the Pridnestrovian Moldavian Republic or Transnistria). Other energy production or consumption from this region is not included in the Moldovan data.


*/

program define clean_MDA_other

	replace country="MDA"

	**rename as others**
	foreach var of varlist tmax* tavg* prcp*  {
		rename `var' `var'_other
	}
	
	**generating MA**
	longrun_climate_measures

end

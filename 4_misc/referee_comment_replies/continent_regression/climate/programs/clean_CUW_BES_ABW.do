/*
Purpose: CUW_BES_ABW Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

From 2012 onwards, data now account for the energy statistics of Curaçao Island only. 
Prior to 2012, data remain unchanged and still cover the entire territory of the former Netherland Antilles

*/

program define clean_CUW_BES_ABW

	replace country="CUW"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures



end

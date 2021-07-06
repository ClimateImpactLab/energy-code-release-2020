/*
Purpose: ITA_SMR_VAT Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

ITA- “Includes San Marino and the Holy See.”

*/



program define clean_ITA_SMR_VAT

	replace country="ITA"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures

end

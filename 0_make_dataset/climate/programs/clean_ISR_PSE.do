/*
Purpose: ISR_PSE Shape File Climate Data Clean Function
Note: this file relies on programs in the helper_functions.do script

Primary Function:

Provide geographic issue fixes for the following issues and complete subsequent cleaning steps--

The statistical data for Israel are supplied by and under the responsibility of the relevant Israeli authorities. 
The use of such data by the OECD is without prejudice to the status of the Golan Heights, 
East Jerusalem and Israeli settlements in the West Bank under the terms of international law

*/


program define clean_ISR_PSE

	replace country="ISR"

	**kenya fix**
	generate_other

	**generating MA**
	longrun_climate_measures


end

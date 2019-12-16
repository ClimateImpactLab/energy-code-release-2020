/*
Creator: Yuqi Song
Date last modified: 5/17/19 
Last modified by: Maya Norman

P-value Test
	a) Within each grouping scenario compare responses of adjacent income groups. In practice this means for each
	set of adjacent income groups in a grouping scenario, there is a different equality tested for each
	test degree.
	b) currently comparison is run at 0 and 30, but functionality allows for other 
	sets of test degrees.
	c) currently set up to do a joint ftest, meaning each grouping scenario recieves 
	1 pvalue

MSE Test

Test all different possible income quintile groupings and compare response functions across possible
groupings.

*/


clear all
set more off
macro drop _all
pause off //turn pause on to troubleshoot or look for errors


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"
	local GIT "/Users/`c(username)'/Documents/Repos/gcp-energy"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}


******Set Script Toggles********************************************************

//Set data type ie historic or replicated
global data_type "historic_data"
local data_type $data_type

//Set Data type

local qt "5" // (can be used on higher order quantile regressions)


//Set zero subset case
global case "Exclude"
local case $case
global bknum "break2"
local bknum $bknum


global grouping_test "visual"
local grouping_test $grouping_test

	//Poly
	global o 2
	local o $o
	
	global FD "FD"
	local FD $FD

	//Issue Fix
	global IF "_all-issues" //second-reading-issues revised-first-reading-issues matched-issues all-issues face-value first-reading-issues
	local IF $IF
	
******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		global model "TINV_clim"
		local model $model

	//Climate Data type
		global clim_data "GMFD"
		local clim_data $clim_data
		
	//Product and flow
	
		local tag "OTHERIND"
		local var "other_energy"
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"

	}
	else if ("$model" == "TINV_both") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"
		
	}
********************************************************************************

//Setting path shortcuts and make directories if they don't already exist

local dd "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis"
local data "`dd'/`clim_data'/rationalized_code/$data_type/data"	
local break_data "`dd'/`clim_data'/rationalized_code/$data_type/data" //If incuts is distinct from temp break data is located in different branch than data
local ster "`dd'/`clim_data'/rationalized_code/$data_type/sters"	
local OUTPUT "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Analysis/Output/`clim_data'/rationalized_code/$data_type/Ftest"
cap mkdir "`OUTPUT'"
cd "`OUTPUT'"

//Zeroing out at 20
local omit = 20



//initiate postfile
tempfile results
postfile test_results str09(model) str01(poly_order) str12(product) str12(grouping) str15(test_degrees) pvalue mse_sum_hat str20(mse_sum_hat_calculation) using "`results'", replace

//loop over polynomials
foreach o of num 2 3 4 {

	//loop over possible income groupings (note only set up for quintiles right now... need to set up algorithm to create groupings automatically
	foreach grouping in "1_1_1_1_1" "1_1_1_2" "1_2_1_1" "2_1_1_1" "1_1_2_1" "1_2_2"  "2_1_2" "2_2_1" "1_3_1" "1_1_3" "3_1_1" "1_4" "4_1" "3_2" "2_3" "5" {

	
		local grouping_list ""
	
		//from grouping find: number of characters in string and number of income groups
		local qt = ceil(length("`grouping'")/2) 
		local qt_m1 = `qt' - 1 //for looping later on want 1 less than number of groups
		local num_chars = 2*`qt' - 1 //had some bug issues with length() so 
			
		di "`grouping' number of groups: `qt'" 
		//pause //turn pause on to check to make sure code is working as desired
			
		//decifer from grouping string how to break up quintiles
		
		local g_split = "`grouping'"
		
		forval g=1/`qt' {
			
			local group`g' = substr("`g_split'", 1,1)
			local g_split = substr("`g_split'", 3,`num_chars')
			local num_chars = `num_chars' - 2
			local grouping_list "`grouping_list' group`g': `group`g''"
			
		}
			
		di "`grouping'"
		di "`grouping_list'"
			
		//pause

		//confirm ster file exists or run ster file generation script
		cap confirm file "`ster'/FD_FGLS/income_grouping_`grouping'_FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"

		if _rc != 0 {

			di "`ster'/FD_FGLS/income_grouping_`grouping'_FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'.ster"
			di "Does not exist"
			di "generating..."
			do `GIT'/rationalized_code/1_analysis/income_heterogeneity/1_generate_sters.do

		}
		else {
			
			//load Data
			use "`data'/clim`clim_data'_`case'`IF'_`bknum'_`model'_`data_type'_regsort.dta", clear
			estimates use "`ster'/FD_FGLS/income_grouping_`grouping'_FD_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'_poly`o'_`model'"
			ereturn display

		}
		
		//loop over products
		foreach var in "electricity" "other_energy" {

			//for stacked ster set up indices for the two products
			if "`var'"=="electricity" {
					local pg=1
			}
			else if "`var'"=="other_energy" {
				local pg=2
			}
		
		//because only one flow set up index, but keep flow functionality in code
		local fg = 1 //for otherind
			
			//loop over different sets of test degrees
			foreach numberlist in "0" "0 30" "30" /*"0 5 10 30" "5 10 30" "0 5 10 15 25 30" "5 10 15 25 30" "5 10 15 25 30 35" "5 10 30 35"*/ {
				
				local ftest_equation ""
				local mse = 0
				local mse_equation ""
				/* using the current specification there is no way to test a single 
				income group grouping thus I assign a placeholder (999) for this situation
				for now
				*/
				if (`qt' != 1) {
					//loop over test degrees in specified set
					foreach testDegree of num `numberlist' { 
						
						//refresh local so as to not create issues
						local ftest_equation_deg`testDegree' ""
						
						***center degrees at 20 and create polynomial orders
						local coef`ls'deg1=`testDegree' - `omit'
						foreach k of num 2/`o' {
							local coef`ls'deg`k'=(`testDegree')^`k' - `omit'^`k'
						}
						
						//write out a response equation for each income group
						forval flg=1/`qt' {		
							local line`flg' = "_b[c.indp`pg'#c.indf`fg'#c.FD_I`flg'temp1_`clim_data'] * (`coef`ls'deg1')"
							foreach k of num 2/`o' {
								local add = "+_b[c.indp`pg'#c.indf`fg'#c.FD_I`flg'temp`k'_`clim_data'] * (`coef`ls'deg`k'')"
								local line`flg' "`line`flg'' `add'"
								di "`line`flg''"
							}
						}
						
						//write out ftest eqations which compares response at a given temp of adjacent income groups
						forval g=1(1)`qt_m1' {
								
							local ng = `g' + 1
							local add_equation "(`line`g''= `line`ng'')"
							local ftest_equation_deg`testDegree' "`ftest_equation_deg`testDegree'' `add_equation'"
							
						}
						
						local ftest_equation = "`ftest_equation' `ftest_equation_deg`testDegree''"
						
						
						//calculate weighted mse for given test degree
						
						forval q=1(1)5 {
							
							di `mse'
							
							
							//Figure out which income group quintile is in
							local cut = 0
							
							forval ig=1(1)`qt' {
								
								di "cut: `cut'"
								local cut = `cut' + `group`ig''
								di "new cut: `cut' addition: `group`ig''"
								
								if `q' <=  `cut' {
									local g = `ig' //set income group
									di "income group: `g' quintile:`q'"
									continue, break
								}
								
							}
							
							local average_response = `line`g''
							local mse = `mse' + (`average_response')^2
							local mse_equation = "`mse_equation' + round((`average_response')^2,0.1)"
							
							di (`average_response')^2
							di `mse'
							di "quintile:`q' income group:`g'"
							di "`grouping_list'"
							pause 
							
						}
						
					}
					
					di "test `ftest_equation', m"
					test `ftest_equation', m
					//pause //again if you turn pause on, this is a useful spot to stop and check everything is working as desired
					local p = `r(p)'
				}
				else {
					
					local p = 999
					
					//loop over test degrees in specified set
					foreach testDegree of num `numberlist' { 
						
						***center degrees at 20 and create polynomial orders
						local coef`ls'deg1=`testDegree' - `omit'
						foreach k of num 2/`o' {
							local coef`ls'deg`k'=(`testDegree')^`k' - `omit'^`k'
						}
						
						//write out a response equation for each income group
						forval flg=1/`qt' {		
							local line`flg' = "_b[c.indp`pg'#c.indf`fg'#c.FD_I`flg'temp1_`clim_data'] * (`coef`ls'deg1')"
							foreach k of num 2/`o' {
								local add = "+_b[c.indp`pg'#c.indf`fg'#c.FD_I`flg'temp`k'_`clim_data'] * (`coef`ls'deg`k'')"
								local line`flg' "`line`flg'' `add'"
								di "`line`flg''"
							}
						}
						
						//calculate weighted mse 
						
						forval q=1(1)5 {
							
							di `mse'
							
							local average_response = `line1'
							local mse = `mse' + (`average_response')^2
							local mse_equation = "`mse_equation' + round((`average_response')^2,0.1)"
							
							di (`average_response')^2
							di `mse'
							pause 
							
						}
						
					}
					
				}
				post test_results ("`model'") ("`o'") ("`var'") ("`grouping'") ("`numberlist'") (`p') (`mse'/5) ("`mse_equation'")
			}
		}				
	}
}


postclose test_results
use `results', clear

//order pvalues
replace mse_sum_hat = -mse_sum_hat

sort model product poly test_degrees pvalue
by model product poly test_degrees: gen pvalue_rank = _n

sort model product poly test_degrees mse_sum_hat
by model product poly test_degrees: gen mse_sum_hat_rank = _n

outsheet using "`OUTPUT'/income_grouping_test_quant5.csv", comma names replace

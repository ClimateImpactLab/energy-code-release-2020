/*
Creator: Yuqi Song
Date last modified: 1/15/19 
Last modified by: Maya Norman

Purpose: Run non-stacked income quantile regression (generate sters)
-model: TINV_clim

Climate Data Options: BEST, GMFD, GMFD_v3
Model Options: TINV_clim, TINV_both_64, TINV_clim_EX


Input Data Options: `clim'_`model'_`data_type'_regsort.dta
-data_type: historic_data, replicated_data
*/


//SET UP RELEVANT PATHS

if "`c(username)'" == "mayanorman"{

	local DROPBOX "/Users/`c(username)'/Dropbox"

}
else if "`c(username)'" == "manorman"{
	// This path is for running the code on Sacagawea
	local DROPBOX "/home/`c(username)'"
	local RAWDATA "/shares/gcp/estimation/energy/IEA"

}

******Set Script Toggles********************************************************

//Set data type ie historic or replicated
local data_type $data_type

//set up ZeroSubset toggle

local case $case // "Exclude" "Include"

//Number of data subsets used to estimate
local bknum $bknum

//winsorized data

local winsorization $winsorization
local level $level

//income grouping test

local grouping_test $grouping_test

//Issue Fix
local IF $IF

local qt $qt //5 or 10

******Set Model Parameters******************************************************


	//Model type-- Options: TINV_clim, TINV_both, TINV_clim_EX
		local model $model
		
	
	//Climate Data type
		local clim_data $clim_data
	
	
	//Specification:
	
		//First Difference
			local FD $FD
			
			if ("`FD'" == "noFD") {

				local fd ""
		
			}
			else {

				local fd "FD_"

			}
	
		//Poly
			local o $o
			
		//type of quantile
			local t $t
	
	
	//Define if covariates are MA15 or TINV
	if ("$model" != "TINV_both") {
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "MA15"
		
		//number of INC groups
		local IG 3

	}
	else if ("$model" == "TINV_both") {
	
		//Climate Var Average type
		local ma_clim "TINV"

		//Income Var Average type
		local ma_inc "TINV"
		
		//number of INC groups
		local IG 2
		
	}
	
********************************************************************************

//Setting path shortcuts

local data "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/data"	
local ster "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data/Analysis/`clim_data'/rationalized_code/$data_type/sters"	

if ("$data_type"=="historic_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA/Yuqi_Codes/Data"
}
else if ("$data_type"=="replicated_data") {
	local DATA "`DROPBOX'/GCP_Reanalysis/ENERGY/IEA_Replication/Data"
}

*--All Flow & Product Comb Energy Poly Decile Regression for FD-FGLS-FE Model--*


		
		********************************************************************************
		*Step 1: Load Data and Clean
		********************************************************************************
		
		use "`data'/`name'clim`clim_data'_`case'`IF'_`bknum'_`grouping_test'`winsorization'`level'_`model'_`data_type'_regsort.dta", clear
		cap egen region_i = group(country FEtag flow product)
		cap gen cluster_i = region_i
		
		//keep specific sector-fuel
		
		if ("`bknum'" == "break6") {
			keep if flow=="RESIDENT" | flow=="COMMPUB" | flow=="TOTIND" 
		}
		else if ("`bknum'" == "break4") {
			keep if flow=="TOTIND" | flow=="TOTOTHER" 
		}
		else if ("`bknum'" == "break2") {
			keep if flow=="OTHERIND"
		}
		
		keep if product=="electricity" | product=="other_energy"
		
		if (`qt' == 5 & "`t'" == "I") {
			//regroup quintiles
			qui gen qpid=int((gpid+1)/2)
			drop ind*
			qui tab qpid, gen(ind)
			pause
		}
		else if (`qt' == 10 & "`t'" == "C") {
			
			cap drop cpid
			drop ind*
			qui tab cpid, gen(ind)
		
		}
		else if (`qt' == 5 & "`t'" == "C") {
			
			cap drop qcpid
			qui gen qcpid=int((cpid+1)/2)
			drop ind*
			qui tab qcpid, gen(ind)
			
		}
		
		
		//tab product
		*1=electricity, 2=other_energy*
		tab product, gen(indp)
		egen product_i = group(product)

		//tab flow
		*1=COMMPUB, 2=RESIDENT, 3=TOTIND*
		tab flow, gen(indf)
		egen flow_i = group(flow)
		summ flow_i
		local fn = `r(max)'
			

		********************************************************************************
		*Step 2: Prepare for Regression
		********************************************************************************
		
		//local pooled FE**					
		local FE4 = "i.flow_i#i.product_i#i.year#i.subregionid"

		//set time
		sort region_i year 
		xtset region_i year

		//drop conflicts from master file with large groups
		drop I1* I2* I3* //I4*
		drop FD_I1* FD_I2* FD_I3* //FD_I4*

			//decile inc group lag
			forval lg=1/`qt' {
				gen ind`lg'_lag=L1.ind`lg'
				gen FD_ind`lg'=ind`lg'-ind`lg'_lag
			}

			//decile inc groupxtemp
			forval lg=1/`qt' {
				forval i=1/4 {
					gen double `t'`lg'temp`i'_`clim_data'=temp`i'_`clim_data'*ind`lg'
					gen double `t'`lg'temp`i'_lag_`clim_data'=temp`i'_lag_`clim_data'*ind`lg'_lag
					gen double FD_`t'`lg'temp`i'_`clim_data'= `t'`lg'temp`i'_`clim_data'-`t'`lg'temp`i'_lag_`clim_data'
					di "I made it here `lg' `i'"
				}
			}
			
			//interacted temp coef, Beta by large group
			local tempregressor=""
			forval pg=1/2 {
				local tempgroupC`pg'=""
				forval fg=1/`fn' {
					local tempgroupB`fg'=""
					forval lg = 1/`qt' {
						local tempgroupA`lg'=""
						forval k=1/`o' {
							local add="c.indp`pg'#c.indf`fg'#c.`fd'`t'`lg'temp`k'_`clim_data'"
							local tempgroupA`lg'="`tempgroupA`lg'' `add'"
						}
						local tempgroupB`fg'="`tempgroupB`fg'' `tempgroupA`lg''"
					}
					local tempgroupC`pg'="`tempgroupC`pg'' `tempgroupB`fg''"
				}
				local tempregressor="`tempregressor' `tempgroupC`pg''"
			}

			//interacted precip coef, controls, not varying across groups
			local precipregressor=""
			forval pg=1/2 {
				local precipgroupC`pg'=""
				forval fg=1/`fn' {
					local precipgroupB`fg'=""
					forval k=1/2 {
						local add="c.indp`pg'#c.indf`fg'#c.`fd'precip`k'_`clim_data'"
						local precipgroupB`fg'="`precipgroupB`fg'' `add'"
					}
					local precipgroupC`pg'="`precipgroupC`pg'' `precipgroupB`fg''"
				}
				local precipregressor="`precipregressor' `precipgroupC`pg''"
			}

			//income bin dummies
			cap drop DumInc*
			forval pg=1/2 {
				forval fg=1/`fn' {
					forval lg=1/`qt' {
						qui gen Dum`t'G`lg'F`fg'P`pg'=`fd'ind`lg'*indf`fg'*indp`pg'
					}
				}
			}
			
cap mkdir "`ster'/`FD'"
cap mkdir "`ster'/`FD'_FGLS"
			
//run first stage regression
reghdfe FD_load_`spe'pc `tempregressor' `precipregressor' Dum`t'*, absorb(`FE4') cluster(region_i) residuals(resid)
estimates save "`ster'/`FD'/quant`t'`qt'_`FD'_inter_clim`clim_data'_`case'`IF'_`bknum'`winsorization'`level'_poly`o'_`model'", replace	
			
pause
			
//calculating weigts for FGLS
drop if resid==.
bysort region_i: egen omega = var(resid)
qui gen weight = 1/omega
				
//run second stage FGLS regression
reghdfe FD_load_`spe'pc `tempregressor' `precipregressor' Dum`t'* [pw=weight], absorb(`FE4') cluster(region_i)
estimates save "`ster'/`FD'_FGLS/quant`t'`qt'_`FD'_FGLS_inter_clim`clim_data'_`case'`IF'_`bknum'`winsorization'`level'_poly`o'_`model'", replace

pause





/*

Purpose: 
1. Produce CSVV files - ie convert the stata ster files containing regression coefficients 
into a format that our projection system understands
2. Produce full stacked vcv for delta method processing (combining impacts across products to construct damages)

requires download of user written command matselrc: (can run net install http://www.stata.com/stb/stb56/dm79.pkg)

*/
	
********************************************************************************

//Defining Programs

// get product index for regression coefficients based on product
program define get_product_regression_index, rclass
syntax , product(string)

	if "`product'"=="electricity" {
		local pg=1

	}
	else if "`product'"=="other_energy" {
		local pg=2
	}

	return scalar pg = `pg'	
end

// return income group for decile and specification
program define get_income_group, rclass
syntax , model(string) grouping_test(string) product(string) bknum(string) g(integer) 

	if (strpos("`model'", "TINV_clim") > 0) {
		if ( "`bknum'" == "break2" & "`product'" == "other_energy") {

			if (`g'>=1) & (`g'<= 2) local lg = 1 
			if `g'>=3 & `g'<= 6  local lg = 2
			if `g'>=7 & `g'<= 10 local lg = 3 

		}
		else if ("`bknum'" == "break2" & "`product'" == "electricity") {
			if (`g'>=1) & (`g'<=6) local lg = 1 
			if `g'==7 | `g'==8  local lg = 2
			if `g'==9 | `g'==10 local lg = 3 
		}
		else {

			di "Must define income groups for `model' `grouping_test' `bknum' `case' `IF' `product'!"
			assert inlist(`lg',1,2,3,4)
		}

		if ("`grouping_test'" == "semi-parametric" & `lg' > 2) local lg = 2 //

		return scalar lg = `lg'	
	}
	else {

		di "Must define income groups for `model' `grouping_test' `bknum' `case' `IF' `product'!"
		assert inlist(`lg',1,2,3,4)

	}
end

// write csvv header for specifciation 
program define write_csvv_header
syntax , model(string) clim_data(string) spec_stem(string) product(string) num_coefficients(integer) num_observations(integer) ma_inc(string)

	pause
	file write csvv "---" _n
	file write csvv "oneline: Energy IEA global splited CDD/HDD interaction Model `model'" _n
	file write csvv "version: ENERGY-GLOBAL-INTERACTION-`model'-`clim_data'" _n
	file write csvv "dependencies: `spec_stem'_`model'`submodel_name'.ster" _n
	file write csvv "description: Global regression on sector OTHERIND, source `product', poly 2, Model `model', Spec=FD_FGLS_inter, Climate Data= `clim_data' . There are `num_coefficients' gamma reported in this CSVV in total. They can be equal across deciles depending on the model." _n
	file write csvv "csvv-version: girdin-2017-01-10" _n
	file write csvv "variables:" _n
	file write csvv "  tas: Daily average temperature [C]"_n
	file write csvv "  tas2: square daily average temperature [C^2]"_n
	file write csvv "  tas-cdd-20: Max of daily average temperature minus 20C and zero [C]"_n
	file write csvv "  tas-cdd-20-poly-2: Max of square daily average temperature minus square 20C and zero [C^2]"_n
	file write csvv "  tas-hdd-20: Max of 20C minus daily average temperature and zero [C]"_n
	file write csvv "  tas-hdd-20-poly-2: Max of square 20C minus square daily average temperature and zero [C^2]"_n
	file write csvv "  incbinN: income bin 1-10 sorted by `ma_inc' log GDP per cap, year 2000 dollars [NA]"_n
	file write csvv "  climtas-cdd-20: MA15 average yearly CDD 20C [degree-day]"_n 
	file write csvv "  climtas-hdd-20: MA15 average yearly HDD 20C [degree-day]"_n 

	file write csvv "  loggdppc-shifted: loggdppc - ibar [log(2005 PPP adjusted USD)]" _n
	file write csvv "  loggdppc: `ma_inc' average log GDP per capita [log(2005 PPP adjusted USD)]"_n

	file write csvv "  outcome: energy use per capita [kWh/pc]"_n          
	file write csvv "..." _n

	file write csvv "observations"_n
	file write csvv " `num_observations'" _n
end

// write out names of climate variables
program define write_climvar_header 
syntax , model(string)
	
	file write csvv "prednames"_n
	
	//10 decile groups
	
	*part 1: betas
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	
	*part 1.5: interacted betas
	if (strpos("`model'","lininter") > 0) {
		
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
	}
	*Part 2: gammas, CDD
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	file write csvv "tas-cdd-20, tas-cdd-20-poly-2, "
	
	*part 3: gammas, HDD
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2, "
	file write csvv "tas-hdd-20, tas-hdd-20-poly-2"
	
	**Part 3.5: gammas, lgdppc**
	
	file write csvv ","
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2, "
	file write csvv "tas, tas2"
	

	**Part 4: gammas, lgdppc**
	
	if (strpos("`model'","lininter") > 0) {
		file write csvv ","
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2, "
		file write csvv "tas, tas2"
	}
	
	file write csvv _n
end

// write out names of covariate variables
program define write_covar_header 
syntax , model(string)

	//Cov: 10 groups

	file write csvv "covarnames"_n

	*part 1: betas
	file write csvv "incbin1, incbin1, "
	file write csvv "incbin2, incbin2, "
	file write csvv "incbin3, incbin3, "
	file write csvv "incbin4, incbin4, "
	file write csvv "incbin5, incbin5, "
	file write csvv "incbin6, incbin6, "
	file write csvv "incbin7, incbin7, "
	file write csvv "incbin8, incbin8, "
	file write csvv "incbin9, incbin9, "
	file write csvv "incbin10, incbin10, "

	*part 1.5: interacted betas
	if (strpos("`model'`submodel_name'","lininter") > 0) {
		file write csvv "year*incbin1, year*incbin1, "
		file write csvv "year*incbin2, year*incbin2, "
		file write csvv "year*incbin3, year*incbin3, "
		file write csvv "year*incbin4, year*incbin4, "
		file write csvv "year*incbin5, year*incbin5, "
		file write csvv "year*incbin6, year*incbin6, "
		file write csvv "year*incbin7, year*incbin7, "
		file write csvv "year*incbin8, year*incbin8, "
		file write csvv "year*incbin9, year*incbin9, "
		file write csvv "year*incbin10, year*incbin10, "
	}

	*part 2: gammas, CDD
	file write csvv "climtas-cdd-20*incbin1, climtas-cdd-20*incbin1, "
	file write csvv "climtas-cdd-20*incbin2, climtas-cdd-20*incbin2, "
	file write csvv "climtas-cdd-20*incbin3, climtas-cdd-20*incbin3, "
	file write csvv "climtas-cdd-20*incbin4, climtas-cdd-20*incbin4, "
	file write csvv "climtas-cdd-20*incbin5, climtas-cdd-20*incbin5, "
	file write csvv "climtas-cdd-20*incbin6, climtas-cdd-20*incbin6, "
	file write csvv "climtas-cdd-20*incbin7, climtas-cdd-20*incbin7, "
	file write csvv "climtas-cdd-20*incbin8, climtas-cdd-20*incbin8, "
	file write csvv "climtas-cdd-20*incbin9, climtas-cdd-20*incbin9, "
	file write csvv "climtas-cdd-20*incbin10, climtas-cdd-20*incbin10, "

	*part 3: gammas, HDD
	file write csvv "climtas-hdd-20*incbin1, climtas-hdd-20*incbin1, "
	file write csvv "climtas-hdd-20*incbin2, climtas-hdd-20*incbin2, "
	file write csvv "climtas-hdd-20*incbin3, climtas-hdd-20*incbin3, "
	file write csvv "climtas-hdd-20*incbin4, climtas-hdd-20*incbin4, "
	file write csvv "climtas-hdd-20*incbin5, climtas-hdd-20*incbin5, "
	file write csvv "climtas-hdd-20*incbin6, climtas-hdd-20*incbin6, "
	file write csvv "climtas-hdd-20*incbin7, climtas-hdd-20*incbin7, "
	file write csvv "climtas-hdd-20*incbin8, climtas-hdd-20*incbin8, "
	file write csvv "climtas-hdd-20*incbin9, climtas-hdd-20*incbin9, "
	file write csvv "climtas-hdd-20*incbin10, climtas-hdd-20*incbin10"

	*part 3.5: thrice interacted gammas
	if (strpos("`model'`submodel_name'","lininter") > 0) {
		file write csvv "," 
		file write csvv "loggdppc-shifted*year*incbin1, loggdppc-shifted*year*incbin1, "
		file write csvv "loggdppc-shifted*year*incbin2, loggdppc-shifted*year*incbin2, "
		file write csvv "loggdppc-shifted*year*incbin3, loggdppc-shifted*year*incbin3, "
		file write csvv "loggdppc-shifted*year*incbin4, loggdppc-shifted*year*incbin4, "
		file write csvv "loggdppc-shifted*year*incbin5, loggdppc-shifted*year*incbin5, "
		file write csvv "loggdppc-shifted*year*incbin6, loggdppc-shifted*year*incbin6, "
		file write csvv "loggdppc-shifted*year*incbin7, loggdppc-shifted*year*incbin7, "
		file write csvv "loggdppc-shifted*year*incbin8, loggdppc-shifted*year*incbin8, "
		file write csvv "loggdppc-shifted*year*incbin9, loggdppc-shifted*year*incbin9, "
		file write csvv "loggdppc-shifted*year*incbin10, loggdppc-shifted*year*incbin10 "
	}

	**Part 4: gammas, lgdppc**

	file write csvv ","
	file write csvv "loggdppc-shifted*incbin1, loggdppc-shifted*incbin1, "
	file write csvv "loggdppc-shifted*incbin2, loggdppc-shifted*incbin2, "
	file write csvv "loggdppc-shifted*incbin3, loggdppc-shifted*incbin3, "
	file write csvv "loggdppc-shifted*incbin4, loggdppc-shifted*incbin4, "
	file write csvv "loggdppc-shifted*incbin5, loggdppc-shifted*incbin5, "
	file write csvv "loggdppc-shifted*incbin6, loggdppc-shifted*incbin6, "
	file write csvv "loggdppc-shifted*incbin7, loggdppc-shifted*incbin7, "
	file write csvv "loggdppc-shifted*incbin8, loggdppc-shifted*incbin8, "
	file write csvv "loggdppc-shifted*incbin9, loggdppc-shifted*incbin9, "
	file write csvv "loggdppc-shifted*incbin10, loggdppc-shifted*incbin10"
	
	file write csvv _n
end

// write out gammas (coefficient values) for a given coefficient name given the model specification and product
// returns coefficient list 
program define write_gammas, sclass
syntax , model(string) grouping_test(string) clim_data(string) product(string) bknum(string) [ coef_term(string) ] coefficientlist(string) last_coef_term(string)
	
	assert inlist("`last_coef_term'", "TRUE", "FALSE")
	
	forval g=1/10 {
		
		if (substr("`coef_term'", -1, 1) == "I") {				
			get_income_group, model("`model'") grouping_test("`grouping_test'") product("`product'") bknum("`bknum'") g(`g')
			local lg = `r(lg)'
			return clear
		}
		else {
			local lg = ""
		}

		get_product_regression_index, product("`product'")
		local pg = `r(pg)'
		return clear

		local coefstub "c.indp`pg'#c.indf1#c.FD_`coef_term'`lg'temp"
		
		forval k=1/2 {
			
			local coef_name "`coefstub'`k'_`clim_data'"
			
			cap local beta = _b[`coef_name'] 
			
			// make up for inconsistent naming -- reason for inconsistent naming is local character length got too long when _GMFD attached at the end
			if _rc == 111 | _rc == 198 {
				local coef_name "`coefstub'`k'"
				local beta = _b[`coef_name']
			} 

			local coefficientlist = "`coefficientlist' `coef_name'"
			file write csvv " `beta'"
			
			if (`g' == 10 & `k' == 2 & "`last_coef_term'" == "TRUE") {
				file write csvv "" _n
			}
			else {
				file write csvv ","
			}
		}	
	}

	sreturn local coef_list "`coefficientlist'"
end

// write out variance covariance matrix 
// inputs coefficientlist output from write_gammas -- list of coefficients in order written 
program define write_vcv
syntax , coefficientlist(string) num_coefficients(integer)

	*TO-DO: remove this for the .csv file
	file write csvv "gammavcv" _n
				
	foreach coef_row in `coefficientlist' {
		
		//keep track of which coefficient writing in row, specifically keeping track of when writing last coefficient in each row
		local vcv_counter = 0

		foreach coef_col in `coefficientlist' {
			
			//get covariance (this is inefficient )
			matselrc e(V) VCV, row(`coef_row') col(`coef_col')	
			local vcv = el(VCV, 1, 1)
			file write csvv "`vcv'"
			
			//write new line or comma depending on where you are in loop
			local vcv_counter = `vcv_counter' + 1 

			if (`vcv_counter' < `num_coefficients') {
				file write csvv ","
			}
			else if (`vcv_counter' == `num_coefficients') {
				file write csvv "" _n
			}
			else {
				di "I didn't fall into either category, ie there was a hiccup!!!!!! counter: `num_coefficients' vcv counter: `vcv_counter'"
				assert(1 == 0)
			}
		}
	}	
end

// load spec csv

program define load_spec_csv, rclass
syntax , specpath(string) model(string)
	
	// load data and clean for desired model
	import delimited using `specpath'/projection_specifications.csv, varnames(1) clear
	pause
	keep if model_name == "`model'"
	
	// count number of coefficients for that model
	count
	local num_coefficients = `r(N)'

	return scalar nc = `num_coefficients'	
end

// write csvv
program define write_csvv, sclass
syntax , datapath(string) outpath(string) root(string) model(string) clim_data(string) spec_stem(string) grouping_test(string) product(string) bknum(string) zero_case(string) issue_case(string) data_type(string)
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// part a.1: create locals for dataset and ster file
	local data "`datapath'/`clim_data'_TINV_clim_regsort.dta"
	local ster "`root'/sters/`spec_stem'_`model'.ster"
	
	// part a.2: insheet projection spec csv and write list of coefficients 
	
	load_spec_csv , specpath("`root'/2_projection/0_packages_programs_inputs/projection_set_up") model("`model'")
	local num_coefficients = `r(nc)'
	return clear

	local coef_term_list ""

	forvalues nn = 1(1)`num_coefficients' {
		local coef_add = coefficient_names[`nn']
		local coef_term_list = "`coef_term_list' `coef_add'"
	}

	di "coefficient list retrieved: `coef_term_list'"

	// each coefficient has 10 income deciles and 2 poly orders 
	local num_coefficients = `num_coefficients' * 20

	///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// part b: load ster file and store relevant information 
	use "`data'", clear 
	estimate use "`ster'"
	ereturn display
	
	estimates describe using "`ster'"
	local num_observations = `e(N)'
	local residualvcv = `e(rmse)' * `e(rmse)' 

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// part c: initiate csvv file for writing
	local output "`outpath'/`model'"
	local csvv "`output'/`spec_stem'_OTHERIND_`product'_`model'.csvv"
	
	cap mkdir "`output'"
	file open csvv using "`csvv'", write replace

	di "csvv initiated: `csvv'"

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// part d: write headers

	di "Writing csvv header..."
	di "`model'"
	pause
	write_csvv_header , model("`model'") clim_data("`clim_data'") spec_stem("`spec_stem'") product("`product'") num_coefficients(`num_coefficients') num_observations(`num_observations') ma_inc("MA15")

	di "Writing climate variables..."
	write_climvar_header , model("`model'")

	di "Writing covariates..."
	write_covar_header , model("`model'")
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	// part e: write coefficients

	di "Writing gammas..."

	file write csvv "gamma" _n
	local coefficientlist = " " //create list with each coefficient stored in csvv
	local counter = 0
	local last_coef_term "FALSE"

	foreach coef_term in "" `coef_term_list' {

		di "Writing coef term: `coef_term'..."
		
		local counter = `counter' + 20
		
		if `num_coefficients' == `counter' local last_coef_term "TRUE"

		write_gammas , model("`model'") grouping_test("`grouping_test'") clim_data("`clim_data'") product("`product'") bknum("`bknum'") coef_term("`coef_term'") coefficientlist("`coefficientlist'") last_coef_term("`last_coef_term'")
		
		local coefficientlist `s(coef_list)' 
		return clear
	}
	
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// part f: write gamma vcv
	// note this could be seriously sped up -- if anyone is interested in improving by all meands

	di "Writing vcv..."
	
	write_vcv , coefficientlist("`coefficientlist'") num_coefficients(`num_coefficients')

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	// part g: close csvv after adding in residualvcv

	file write csvv "residvcv" _n
	file write csvv "`residualvcv'" _n
				
	file close csvv

	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	sreturn local coef_list "`coefficientlist'"
end



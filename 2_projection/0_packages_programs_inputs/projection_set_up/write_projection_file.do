/*


Purpose: Generate projection, extraction and aggregation configs to use with James's generate.py, aggregate.py and quantiles.py in the impact-calculations repo

Program parameters:
note -- definitions are common across functions in this file... if they aren't sorry

product: "other_energy" "electricity"
proj_type: "median" "diagnostics"
break_data: path to break dataset produced with 0_make_dataset/1_construct_regression_ready_data.do 
proj_model: Projection Model ("TINV_clim")
config_output: root of path for generated config storage
proj_mode: "_dm" "_hilo" "" -- delta method, hot cold and normal
brief_output: "TRUE" outputs just rebased values in delta method output
proj_output: where the projection results are going to land
do_farmers: "true" "false" "always"
ssp_list: 'SSP3' or ['SSP2', 'SSP4']
single_folder: name of diagnostic folder 
median_folder: name of median output folder
csvv_path: location of csvv on server config file is setup for
partition: "savio3" "savio2_bigmem" for running projections on BRC
price_scen: "-price014" "-*" 
geo_level: "-aggregated" (global impacts) "-levels" (ir level impacts)
uncertainty: "climate" "full" ""
unit: "-damage" ($) "-damagepc" ($/pc) "-impactpc" (kwh pc) "-impact" (kwh)
csvv: csvv file name without the .csvv tag at the end of the string
extraction_output: where the projections results getting extracted go 
evalqvals: which quantiles you want to extract

*/

** Part 1: these programs support programs in part 2... the code is referenced by multiple programs in part 2 so i felt the need to make them into a function

//this is probably just overcomplicating things but preserving James's name shift to document that there is a big difference between the two configs
program define get_config_tag, sclass
syntax , proj_model(string)

	if strpos("`proj_model'", "clim") {
		local config_tag = "hddcddspline"
	}
	else {
		local config_tag = "hddcdd"
	}

	sreturn local ctag "`config_tag'"
end

program define output_prep
syntax , file_list(string)
	foreach file_name in `file_list' {

		cap mkdir "`file_name'"
		cd "`file_name'"

	}
end

program define get_model_config_name, sclass
syntax , [ proj_mode(string) ] proj_model(string) product(string)
	//there is a model config specifc
	get_config_tag , proj_model("`proj_model'")
	local config_tag `s(ctag)'
	return clear

	//hilo needs a different model config then the other projection mode options
	local proj_mode_tt = "`proj_mode'"
	
	if strpos("`proj_mode'","hilo") == 0 {
		local proj_mode_tt = ""
	}

	local model_config_name = "`config_tag'_OTHERIND_`product'`proj_mode_tt'.yml"
	sreturn local mcn "`model_config_name'"
end

program define get_run_config_name, sclass
syntax , proj_model(string) [ proj_mode(string) ] product(string) proj_type(string)

	di "Retrieving config tag..."
	
	//there is a model config specifc
	get_config_tag , proj_model("`proj_model'")
	local config_tag `s(ctag)'
	return clear

	local run_config_name = "energy-`proj_type'-`config_tag'_OTHERIND_`product'`proj_mode'.yml"

	sreturn local rcn "`run_config_name'"
end

program define get_impacts_folder, sclass
syntax , proj_model(string)
	if strpos("`proj_model'", "clim") {
		local impact_folder = "impacts-blueghost"
	}
	else {
		local impact_folder = "impacts-rover"
	}

	sreturn local ifol "`impact_folder'"
end

program define get_output_path, sclass
syntax , proj_model(string)
	
	//there is an impacts folder specific to model type
	get_impacts_folder , proj_model("`proj_model'")
	local impact_folder `s(ifol)'
	return clear
	
	local proj_output = "`impact_folder'"

	sreturn local po "`proj_output'"
end

program define get_config_server_path, sclass
syntax , config_output(string)
	get_repo_root 
	local repo_root `s(rr)'
	return clear

	local config_server_path = substr("`config_output'", strpos("`config_output'","-") - 6, .)
	local config_server_path = "`repo_root'/`config_server_path'"
	sreturn local csp "`config_server_path'" 
end

program define get_income_bin_cuts, sclass
syntax , break_data(string)
	qui use "`break_data'", clear 
	qui drop if gpid==.
	qui duplicates drop gpid, force
	keep gpid maxInc_gpid
	local INCbin= "[ -inf,"
	forval i=1/9 {
		preserve
			qui keep if gpid==`i'
			qui tostring maxInc_gpid, force replace format(%12.3f)
			local subin=maxInc_gpid[1]
			local INCbin="`INCbin' `subin',"
		restore
	}
	local INCbin="`INCbin' inf ]"
	display "`INCbin'"
	sreturn local ib "`INCbin'"
end

program define get_weighting_parameter, sclass
syntax , unit(string) [ price_scen(string) ] product(string)

	local price_data "social/baselines/energy"

	// assign price data name/path based on price data type (iam or cil)
	// also assigns locals for growth rate and if scenario asks for peak electricity pricing
	if (strpos("`price_scen'", "rcp") > 0) {

		// confirms not in a cil made price scenario
		assert (strpos("`price_scen'", "price") == 0)

		local price_data = "`price_data'/`price_scen'_Prices_COMPILE.dta"
		local pricing = "price" // no peak pricing scenario for iams
	}
	else if (strpos("`price_scen'", "price") != 0) {

		local growth_rate = substr("`price_scen'",strpos("`price_scen'","0"),.)	
		local pricing = substr("`price_scen'",1,strpos("`price_scen'","0") - 1)

		// make exception for -0,27% growth
		if strpos("`price_scen'", "0027") > 0{
			local growth_rate = "m0027"
			local pricing = "price"
		}

		local price_data = "`price_data'/IEA_Price_FIN_Clean_gr`growth_rate'_GLOBAL_COMPILE.dta"
	

	}

	if (strpos("`unit'", "damage") > 0) {
		local weighting_parameter = "levels-weighting: population * `price_data':country:year:`product'compile_`pricing'"
	}
	else {
		local weighting_parameter = "weighting: population"
	}

	sreturn local w "`weighting_parameter'"
end

program define get_weighting_numerator, sclass
syntax , unit(string) price_scen(string) product(string) 
	
	// get price data path and specific variable extracted
	di "Fetching weighting parameter for use in awn..."	
	get_weighting_parameter , unit("`unit'") price_scen("`price_scen'") product("`product'")
	local weighting_parameter = "`s(w)'"
	return clear

	di "Restricting string length to what is needed..."
	local weighting_numerator = substr("`weighting_parameter'", strpos("`weighting_parameter'", "population"), .)
	
	sreturn local awn "aggregate-weighting-numerator: `weighting_numerator'"
end

program define get_weighting_denominator, sclass
syntax , unit(string)

	if (strpos("`unit'", "pc") > 0) {
		local weighting_denominator = "population" 
	}
	else {
		local weighting_denominator = "sum-to-1"
	}

	sreturn local awd "aggregate-weighting-denominator: `weighting_denominator'"
end

program define write_2product_results_root 
syntax , product_list(string) csvv(string) [ proj_mode(string) ] uncertainty(string) proj_output(string)
	
	* TO-DO: fixing a bug in clim_data, delete when done

	di "parsing stem..."
	local stem = substr("`csvv'", 1,strpos("`csvv'","OTHERIND") + length("OTHERIND"))
	di "stem: `stem'"
	di "parsing model..."
	local proj_model = substr("`csvv'", strpos("`csvv'","TINV"), .)
	di "model: `proj_model'"
	di "parsing climate data..."
	*local clim_data = substr("`csvv'", strpos("`csvv'","clim") + length("clim"), 4)
	local clim_data "GMFD"
	di "climate data: `clim_data'"
	
	di "writing results roots..."
	file write yml "results-root:" _n

	foreach product in `product_list' {
		file write yml "  `stem'`product'_`proj_model'.*: `proj_output'/median_OTHERIND_`product'_`proj_model'_`clim_data'`proj_mode'" _n
	}

	if ("`uncertainty'" == "full") {
		di "writing deltamethod roots..."
		file write yml "deltamethod:" _n
		foreach product in `product_list' {
			file write yml "  `stem'`product'_`proj_model'.*: `proj_output'/median_OTHERIND_`product'_`proj_model'_`clim_data'_dm" _n
		}
	}
	di "roots written."
end

program get_evalqvals, sclass
syntax , uncertainty(string)

	if inlist("`uncertainty'", "climate") {
		local evalqvals "['mean', 0.05, 0.95]"
	} 
	else if inlist("`uncertainty'", "full") {
		local evalqvals "['mean', .5, 0.05, 0.17, 0.83, 0.95, 0.10, 0.90, 0.75, 0.25]"
	} 
	else {
		local evalqvals ""
	}

	sreturn local evqvs "`evalqvals'"
end



program define get_repo_root, sclass
	local repo_root "${REPO}"
	sreturn local rr "`repo_root'"
end


** Part 2: these programs write the files necessary for projection and aggregation

program define write_run_config
syntax , product(string) proj_type(string) [ proj_mode(string) ] break_data(string) [ median_folder(string) ] [ single_folder(string) ] proj_model(string) config_output(string)  do_farmers(string) ssp_list(string)
	
	di "Executing write_run_config program..."

	//have not set up hilo projection for income spline model
	assert(strpos("`proj_model'", "clim") > 0 & strpos("`proj_mode'", "hilo") == 0)

	//get path to projection output

	di "Retrieving output path..."

	get_output_path , proj_model("`proj_model'") 
	local proj_output `s(po)'
	return clear

	//retrieve run config name..
	
	di "Retrieving run config name..."

	get_run_config_name, proj_model("`proj_model'") proj_mode("`proj_mode'") product("`product'") proj_type("`proj_type'")
	local run_config_name `s(rcn)'
	return clear

	//retrieve model config name

	di "Retrieving model config name..."

	get_model_config_name , proj_mode("`proj_mode'") proj_model("`proj_model'") product("`product'")
	local model_config_name `s(mcn)'
	return clear

	//retrieve model config path on server

	di "Retrieving model config path on server of interest..."

	get_config_server_path ,  config_output("`config_output'") 
	local config_server_path `s(csp)'
	return clear

	//retrieve loggdppc-delta == loggdppc upper bound for lareg income group 1 
	if (strpos("`proj_model'", "clim")) {
		qui use "`break_data'", clear 
		qui keep if largegpid_`product' == 1 
		qui tostring maxInc_largegpid_`product', force replace format(%12.3f)
		local loggdppc_delta_`product' = maxInc_largegpid_`product'[1]
	}

	//generate file path for config output

	di "Setting up output path for config getting written..."

	output_prep , file_list(" `config_output' run `proj_type' ")

	file open yml using "`run_config_name'", write replace
	file write yml "module: `config_server_path'/model/`model_config_name'" _n
		
	**Model config files**
	if "`proj_type'"=="median" {
		file write yml "mode: `proj_type'" _n
		file write yml "outputdir: `proj_output'/`median_folder'`proj_mode'" _n
	}
	else if "`proj_type'"=="diagnostics" {
		file write yml "mode: writecalcs" _n
		file write yml "outputdir: `proj_output'" _n
		file write yml "singledir: `single_folder'`proj_mode'" _n
	}
		
	**Up till now, we cut short running time of median/montecarlo valuation of 6 categories by only run full-adapted**
	file write yml "do_farmers: `do_farmers'" _n
	file write yml "do_historical: true" _n
	
	if (strpos("`proj_mode'", "dm") > 0) {
		file write yml "deltamethod: yes" _n
	}
	else {
		file write yml "deltamethod: no" _n
	}

		
	if "`proj_type'"=="median" {
		file write yml "only-ssp: `ssp_list'" _n 
	}

	file write yml "econcovar:" _n
	file write yml "   class: mean" _n
	file write yml "   length: 15" _n
	file write yml "climcovar:" _n
	file write yml "   class: mean" _n
	file write yml "   length: 15" _n
	file write yml "loggdppc-delta: `loggdppc_delta_`product''" _n
	
	if (strpos("`proj_mode'", "dm") > 0) {
		file write yml "timeout: 30" _n
	}
	if("`proj_model'" == "TINV_clim_lininter_double"){
		file write yml "yearcovarscale: 2" _n
	}
	if("`proj_model'" == "TINV_clim_lininter_half"){
		file write yml "yearcovarscale: 0.5" _n
	}

	file close yml
end

program define write_aggregate_config
syntax ,  product(string)  proj_type(string) proj_model(string) unit(string) [ price_scen(string) ] [ proj_mode(string) ] config_output(string)  [ single_folder(string) ] [ median_folder(string) ]
	
	// set up locals relevant to units in program

	if (strpos("`unit'", "damage") > 0) local price_scen_tag = "-`price_scen'"

	if (strpos("`unit'", "damagepc") > 0) local pc = "pc"

	// get path to projection output

	di "Retrieving output path..."

	get_output_path , proj_model("`proj_model'") 
	local proj_output `s(po)'
	return clear

	// there is an impacts folder specific to model type

	di "Retrieving impact folder where projection will be output..."

	get_impacts_folder , proj_model("`proj_model'")
	local impact_folder `s(ifol)'
	return clear

	// weighting or levels-weighting depends on the unit and the price scenarion

	di "Retrieving weighting parameter..."
	get_weighting_parameter , unit("`unit'") price_scen("`price_scen'") product("`product'")
	local weighting "`s(w)'"
	return clear

	if (strpos("`unit'", "damage") > 0) {

		// aggregate-weighting-numerator -- not relevant for unit == impactpc and not built out for unit == impact

		di "Retrieving aggregate-weighting-numerator parameter..."
		get_weighting_numerator , unit("`unit'") price_scen("`price_scen'") product("`product'")
		local aggregate_weighting_numerator "`s(awn)'"
		return clear
		
		// aggregate-weighting-denominator -- not relevant for unit == impactpc and not built out for unit == impact

		di "Retrieving aggregate-weighting-denominator parameter..."
		get_weighting_denominator , unit("`unit'")
		local aggregate_weighting_denominator "`s(awd)'"
		return clear
	
		// infix -- not relevant for unit == impactpc and not built out for unit == impact

		di "Retrieving infix parameter..."

		local infix_parameter "infix: `price_scen'`pc'"
	}

	// assign rcp local -- if price scenario is rcp specific then gets that rcp if not then gets rcp85

	if strpos("`price_scen'", "rcp") > 0 {
		local rcp = substr("`price_scen'", strpos("`price_scen'", "rcp"), 5)
	}
	if ("`rcp'" != "rcp45") {
		local rcp "rcp85"
	} 

	// there is a model config specifc

	di "Retrieving config tag..."

	get_config_tag , proj_model("`proj_model'")
	local config_tag `s(ctag)'
	return clear

	// generate file path for config output

	di "Setting up file paths for config writing..."

	output_prep , file_list(" `config_output' aggregate `proj_type' ")

	file open yml using "energy-aggregate-`proj_type'-`config_tag'`price_scen_tag'`pc'_OTHERIND_`product'`proj_mode'.yml", write replace
	
	**Model config files**
	if "`proj_type'"=="median" {
		file write yml "outputdir: outputs/energy_pixel_interaction/`impact_folder'/`median_folder'`proj_mode'" _n
		file write yml "`weighting'" _n 
	}
	else if "`proj_type'"=="diagnostics" {
		file write yml "outputdir: outputs/energy_pixel_interaction/`impact_folder'" _n
		file write yml "`weighting'" _n
		file write yml "targetdir: `proj_output'/`single_folder'`proj_mode'/`rcp'/CCSM4/high/SSP3" _n
	}

	if strpos("`unit'", "damage") > 0 {
		file write yml "`aggregate_weighting_numerator'" _n
		file write yml "`aggregate_weighting_denominator'" _n
		file write yml "`infix_parameter'" _n
	}

	if strpos("`price_scen'", "rcp") > 0 {
		file write yml "rcp: `rcp'" _n
	} 
	* add an option to aggregate only fulladapt and histclim
	* for projections other than main model point estimate
	if !(("`proj_type'"!="median") & (strpos("`proj_model'", "lininter") == 0)) {
		file write yml "only-farmers: ['', 'histclim']" _n
	}
	* updated: we now want to aggregate all SSPs
	* file write yml "ssp: SSP3"

	file close yml
end

program define write_model_config
syntax , product(string) proj_type(string) [ proj_mode(string) ] break_data(string) csvv(string) proj_model(string) config_output(string) csvv_path(string) [ brief_output(string) ]
	
	//have not set up hilo projection for income spline model
	assert(strpos("`proj_model'", "clim") > 0 & strpos("`proj_mode'", "hilo") == 0)

	**generate file path for config output
	

	// create output path and cd to destination

	di "Setting up file paths for config writing..."

	output_prep , file_list(" `config_output' model ")

	**Read income bin cuts for energy**

	di "Retriving string of income bin cuts..."

	get_income_bin_cuts , break_data("`break_data'")
	local INCbin `s(ib)'
	return clear

	**Get model config name

	di "Getting model config name..."

	get_model_config_name , proj_mode("`proj_mode'") proj_model("`proj_model'") product("`product'")
	local model_config_name `s(mcn)'
	return clear

	di "Model config name: `model_config_name'"
	di "Current wd: `c(pwd)'"

	**Write configs**
	file open yml using "`model_config_name'", write replace
		
	file write yml "timerate: year" _n
	
	if (strpos("`proj_mode'", "hilo") == 0) {

		di "Writing model config for not hilo projection..."

		file write yml "climate: [ tas, tas-poly-2, tas-cdd-20, tas-cdd-20-poly-2, tas-hdd-20, tas-hdd-20-poly-2 ]" _n
		file write yml "models:" _n
			
		local filename=`"  - csvvs: "`csvv_path'/`csvv'.csvv""' 
		file write yml `"`filename'"' _n
		file write yml "    covariates:" _n
	    file write yml "      - incbin.country: `INCbin'" _n
			
		if (strpos("`proj_model'", "lininter") > 0) {
			file write yml "      - year*incbin.country: `INCbin'" _n
		}
		
		file write yml "      - climtas-cdd-20" _n
		file write yml "      - climtas-hdd-20" _n
	    file write yml "      - climtas-cdd-20*incbin.country: `INCbin'" _n
	    file write yml "      - climtas-hdd-20*incbin.country: `INCbin'" _n

	    if (strpos("`proj_model'","clim") > 0 ) {
	    	file write yml "      - loggdppc-shifted.country*incbin.country: `INCbin'" _n
	    }
	    if (strpos("`proj_model'","lininter") > 0 ) {
	    	file write yml "      - loggdppc-shifted.country*year*incbin.country: `INCbin'" _n
	    }
		
		if (strpos("`proj_model'","ui") > 0) {
			file write yml "      - loggdppc" _n
			file write yml "      - loggdppc*incbin.country: `INCbin'" _n
		}
			
			
		file write yml "    clipping: false" _n
		file write yml "    description: Change in energy usage driven by a single day's mean temperature" _n
	    file write yml "    depenunit: kWh/pc" _n
	    file write yml "    specifications:" _n
	    file write yml "      tas:" _n
	    file write yml "        description: Uninteracted term." _n
	    file write yml "        indepunit: C" _n
	    file write yml "        functionalform: polynomial" _n
	    file write yml "        variable: tas" _n
	    file write yml "      hdd-20:" _n
	    file write yml "        description: Below 20C days." _n
	    file write yml "        indepunit: C" _n
	    file write yml "        functionalform: polynomial" _n
	    file write yml "        variable: tas-hdd-20" _n
	    file write yml "      cdd-20:" _n
	    file write yml "        description: Above 20C days." _n 
	    file write yml "        indepunit: C" _n
	    file write yml "        functionalform: polynomial" _n
	    file write yml "        variable: tas-cdd-20" _n
		
	    if ("`brief_output'" == "TRUE") {
			file write yml "    calculation:" _n
			file write yml "      - Sum:" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: tas" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: hdd-20" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: cdd-20" _n
			file write yml "        - unshift: false" _n
			file write yml "      - Rebase:" _n
			file write yml "          unshift: false" _n
	    }
	    else {
			file write yml "    calculation:" _n
			file write yml "      - Sum:" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: tas" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: hdd-20" _n
		    file write yml "        - YearlyApply:" _n
		    file write yml "            model: cdd-20" _n
			file write yml "      - Rebase" _n
		}
	  
	  	file close yml
	}
	else {

		di "Writing model config for hilo projection..."

		file write yml "climate: " _n
		file write yml " - tas-lo = tas * tas.step(20, [1, 0])" _n
		file write yml " - tas-hi = tas * tas.step(20, [0, 1])" _n
		file write yml " - tas-lo-poly-2 = tas-poly-2 * tas.step(20, [1, 0])" _n
		file write yml " - tas-hi-poly-2 = tas-poly-2 * tas.step(20, [0, 1])" _n
		file write yml " - tas-lo-20 = 20 * tas.step(20, [1, 0])" _n
		file write yml " - tas-hi-20 = 20 * tas.step(20, [0, 1])" _n
		file write yml " - tas-lo-20-poly-2 = 400 * tas.step(20, [1, 0])" _n
		file write yml " - tas-hi-20-poly-2 = 400 * tas.step(20, [0, 1])" _n
		file write yml " - tas-cdd-20" _n
		file write yml " - tas-cdd-20-poly-2" _n
		file write yml " - tas-hdd-20" _n
		file write yml " - tas-hdd-20-poly-2" _n
		file write yml "models:" _n
		
		local filename=`"  - csvvs: "`csvv_path'/`csvv'""' 
		file write yml `"`filename'"' _n
		file write yml "    covariates:" _n
		file write yml "      - incbin.country: `INCbin'" _n
		file write yml "      - climtas-cdd-20" _n
		file write yml "      - climtas-hdd-20" _n
		file write yml "      - climtas-cdd-20*incbin.country: `INCbin'" _n
		file write yml "      - climtas-hdd-20*incbin.country: `INCbin'" _n
		file write yml "    clipping: false" _n
		file write yml "    description: Change in energy usage driven by a single day's mean temperature" _n
		file write yml "    depenunit: kWh/pc" _n
		file write yml "    specifications:" _n
		file write yml "      tas-lo:" _n
		file write yml "        description: Uninteracted term." _n
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-lo" _n
		file write yml "        coeffvar: tas" _n
		file write yml "      tas-hi:" _n
		file write yml "        description: Uninteracted term." _n
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-hi" _n
		file write yml "        coeffvar: tas" _n
		file write yml "      tas-lo-20:" _n
		file write yml "        description: Uninteracted term." _n
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-lo-20" _n
		file write yml "        coeffvar: tas" _n
		file write yml "      tas-hi-20:" _n
		file write yml "        description: Uninteracted term." _n
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-hi-20" _n
		file write yml "        coeffvar: tas" _n
		file write yml "      hdd-20:" _n
		file write yml "        description: Below 20C days." _n
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-hdd-20" _n
		file write yml "      cdd-20:" _n
		file write yml "        description: Above 20C days." _n 
		file write yml "        indepunit: C" _n
		file write yml "        functionalform: polynomial" _n
		file write yml "        variable: tas-cdd-20" _n
		file write yml "    calculation:" _n
		file write yml "      - Sum:" _n
		file write yml "        - YearlyApply:" _n
		file write yml "            label: tas-lo" _n
		file write yml "            model: tas-lo" _n
		file write yml "        - ConstantScale:" _n
		file write yml "            - YearlyApply:" _n
		file write yml "                label: tas-lo-20" _n
		file write yml "                model: tas-lo-20" _n
		file write yml "            - -1.0" _n
		file write yml "        - YearlyApply:" _n
		file write yml "            label: tas-hi" _n
		file write yml "            model: tas-hi" _n
		file write yml "        - ConstantScale:" _n
		file write yml "            - YearlyApply:" _n
		file write yml "                label: tas-hi-20" _n
		file write yml "                model: tas-hi-20" _n
		file write yml "            - -1.0" _n
		file write yml "        - YearlyApply:" _n
		file write yml "            label: hdd-20" _n
		file write yml "            model: hdd-20" _n
		file write yml "        - YearlyApply:" _n
		file write yml "            label: cdd-20" _n
		file write yml "            model: cdd-20" _n
		file write yml "      - Rebase" _n
		file close yml
	}
end


program define write_extraction_config
syntax , [ product(string) ] [ two_product(string) ] [ product_list(string) ] [ proj_mode(string) ] [ median_folder(string) ] [ price_scen(string) ] geo_level(string) uncertainty(string) unit(string) proj_model(string) [ clim_data(string) ] config_output(string) [ csvv(string) ] [ csvv_path(string) ] extraction_output(string) [ evalqvals(string) ]

	// getting local name alterations together for reference later on

	local gl_tt = subinstr("`geo_level'","-","",.)
	local u_tt = subinstr("`unit'", "-", "", .)
	local ps_tt = subinstr("`price_scen'","-","",.)

	//only set up to write extraction configs for medians
	local proj_type = "median"
	local stem = substr("`csvv'", 1, strpos("`csvv'","OTHERIND") + length("OTHERIND"))

	//set up locals relevant to units in program

	if (strpos("`unit'", "damagepc") > 0) local pc = "pc"

	// set up locals for writing extraction dependent on uncertainty included in output

	if inlist("`uncertainty'", "climate", "full") {
		local file_organize = "[ssp, rcp]"
		local output_format = "edfcsv"
	} 
	else {
		local file_organize = "[ssp, region]"
		local output_format = "valuescsv"
	}

	// for checks argument -- assign which adaptation scenarios are relevant (at the moment checks writing is commented out so this logic is irrelevant)

	if ((strpos("`unit'", "damage") > 0) | ! inlist("`uncertainty'", "climate", "full")) {
		local adaptation_list " -histclim "
		local adapt_scen_count 2
	} 
	else {
		local adaptation_list " -histclim -incadapt -noadapt "
		local adapt_scen_count 4
	}

	// get results-root

	get_output_path , proj_model("`proj_model'")
	local proj_output `s(po)'
	return clear

	local results_root "`proj_output'/`median_folder'"

	// get output directory

	local output_dir "`extraction_output'"

	di "unit: `unit' uncertainty: `uncertainty'"

	if ((strpos("`unit'", "damage") > 0) & !inlist("`uncertainty'", "climate", "full")) {
		local output_dir = "`output_dir'/`ps_tt'`pc'"
	} 
	else if ((strpos("`unit'", "impact") > 0) & !inlist("`uncertainty'", "climate", "full")) {
		local output_dir = "`output_dir'/`u_tt'"
	}

	// get multiimpact vcv and setup two_product tag
	* TO-DO: corrected bug here, removed -fixed, need to confirm it's correct
	if ( "`two_product'" == "TRUE" ) {
		local vcv "`csvv_path'/`stem'`proj_model'.csv"
		local product "total_energy"
	}

	// restrict rcp getting extracted
	
	if strpos("`price_scen'", "rcp") > 0 {
		local only_rcp = substr("`price_scen'", strpos("`price_scen'", "rcp"), 5)
	} 
	else {
		local only_rcp = "null"
	}

	// if not damages and impactpc is the unit and geo level is "level" then the tag on netcdfs should be "" not "-level"

	if (strpos("`unit'", "impactpc") > 0 & strpos("`geo_level'", "level") > 0) {
		local gl_tag = ""
	} 
	else {
		local gl_tag = "`geo_level'"
	}

	//set up path and wd for writing extraction config
	
	di "Setting up file paths for extraction config writing..."

	output_prep , file_list(" `config_output' `u_tt' `ps_tt' `uncertainty' `gl_tt' `proj_type' ")


	***************************************************************************************
	* Part 2: Open file and set local names based on parameters passed into program
	**************************************************************************************

	file open yml using "energy-extract`unit'`gl_tag'`price_scen'-`proj_type'_OTHERIND_`product'`proj_mode'.yml", write replace

	*****************************************************************************
	* Part 3: Write file
	*****************************************************************************

	**Directory containing the impacts results tree
	di "writing results root and deltamethod root if necessary"
	if ("`two_product'" != "TRUE") {
		
		di "Writing single product roots..."
		file write yml "results-root: `results_root'`proj_mode'"_n
		if "`uncertainty'" == "full" file write yml "deltamethod: `results_root'_dm" _n
		di "roots written."
	}
	else {

		di "Writing total_energy product roots..."
		write_2product_results_root , product_list("`product_list'") csvv("`csvv'") proj_mode("`proj_mode'") uncertainty("`uncertainty'") proj_output("`proj_output'")
		
		//only need to write out vcv if want full uncertainty
		if ("`uncertainty'" == "full" | strpos("`proj_mode'", "dm") > 0) {
			file write yml "multiimpact_vcv: "
			file write yml "`vcv'" _n
		}
		
		di "roots written."
	}
	di "all roots written no matter the spec!"

	**Directory to write output files and Create separate output files - different organizer if extract values or quantiles
	file write yml "output-dir: `output_dir'" _n
	file write yml "file-organize: `file_organize'" _n
	
    **Calculate values over the Monte Carlo results?
	if "`proj_type'" == "median" file write yml "do-montecarlo: no" _n

	**Perform operations for only one RCP or realization?
	if ( inlist("`product'","other_energy","electricity") ) {
		file write yml "only-rcp: `only_rcp'" _n
	}

	**Which GCM models should we include?  List or all
	file write yml "only-models: all" _n
	
	**Which IAM
	file write yml "only-iam: null" _n

	if (strpos("`proj_mode'", "dm") & "`uncertainty'" != "full") {
		file write yml "deltamethod: true" _n
	}

	**What file(s) should be required
	**as of now, we shorten the projection by cutting inc and no adapt files for 6-categories but keep them for COMPILE**
	**in the future they shall all be refilled in**
	// have commented this out for right now with the hopes that we can pass this in through the bash script

	// uncomment if you want to add checks into the config
	/* 	file write yml "checks: ["
	
	local counter = 0

	foreach adapt_scen in "" `adaptation_list' {
		local counter = `counter' + 1
		if `counter' == `adapt_scen_count' local end_tag = ""
		else local end_tag = ", "
		file write yml "'`csvv'`adapt_scen'`price_scen'`pc'`gl_tag'.nc4'`end_tag'"
	}

	file write yml "]" _n */


	**Which column to read from the files (the final result is 'rebased')
	file write yml "column: rebased" _n

	if inlist("`uncertainty'", "climate", "full") {
		**Quantiles 
		file write yml "evalqvals: `evalqvals'" _n
	}

	**Format for the output
	file write yml "output-format: `output_format'" _n
	
	file close yml
end


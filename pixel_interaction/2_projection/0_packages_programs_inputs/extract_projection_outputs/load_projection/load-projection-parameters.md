# Possible Parameters to feed into data querying functions (load.median() and the future load.single())

#### **proj_mode**: type of projection ie delta method or point estimate
* options: "" (point-estimate), _dm (delta method) required: yes
#### **uncertainty**: amount of uncertainty reflected in data 
* options: full, values, and climate required: yes
#### **region**: region querying data for
#### **geo_level**: region unit 
* options:aggregated (ir agglomeration), levels (single ir) required:yes
#### **rcp**: rcp scenario
* options: rcp85, rcp45 required: yes if uncertainty does not equal values
#### **iam**: iam scenario
* options: high, low required: no
#### **price_scen** dollarized damages price scenario 
* (for energy) options: price014, price0, price03, etc. required: yes, if unit == damage*
#### **ssp**: ssp scenario
* options: SSP* (choose your favorite one) required: yes
#### **spec**: type of projection (ie fuel type or crop)
* (for energy) options: OTHERIND_electricity, OTHERIND_other_energy, OTHERIND_total_energy required: yes
#### **sector**: sector querying data for 
* required: yes
#### **yearlist**: list of years wanted in queried data 
* Default: as.character(seq(1980,2100,1)) 
#### **conda_env**: the user's conda environment for calling quantiles.py
* required: yes
#### **adapt_scen**: desired adaptation scenario  
* options: fulladapt, incadapt, noadapt required:yes
#### **unit**: type of impacts querying 
* options:damagepc, impactpc, damage, impact (functionality for impact currently untested) required: yes
#### **code.path.getter**: name of function for fetching your sector's bash extraction script path
* Default: get.energy.code.paths ... required for non-energy sectors
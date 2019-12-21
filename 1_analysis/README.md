# Folder Structure

`uninteracted_regression` - Code for estimating and plotting the global average energy-temperature response function. Section A.6 outlines this piece of analysis.

`decile_regression` - Code for estimating and plotting the energy-temperature response relationship for each decile of in sample GDP per-capita. Equation 3 on page 16 outlines this piece of analysis.

`interacted_regression` - Code for estimating and plotting energy-temperature response heterogeneity by income and long-run climate. Section A.7 outlines this piece of analysis.

# Folder Contents

Within each directory there are at least two pieces of code:
1. `stacked.do` - estimates the energy-temperature reponse function
2. `plot_stacked.do` - plots the energy-temperature response function

`interacted_regression` also contains `plot_time_marginal_effect.do`. This code is used to produce plots which illustrate how temperature responses change across time in the Tech Trends model. 

# Run Instructions

In order to run codes, please change the macro `$root` at the top of the codes to the location of this repo on your computer. 
Note, the input datasets for codes in this analysis are generated in the [0_make_dataset](https://gitlab.com/ClimateImpactLab/Impacts/energy-code-release/tree/master/0_make_dataset) section of this repo

1. Run `1_uninteracted_regression.do` to estimate and plot the global average energy-temperature response.
	* ***Code Inputs***: `energy-code-release/data/GMFD_TINV_clim_regsort.dta` -- used for response estimation and plotting
	* ***Code Outputs***:
	    * Regression output  
    		* `energy-code-release/sters/FD_global_TINV_clim.ster`
    		* `energy-code-release/sters/FD_FGLS_global_TINV_clim.ster`
		* Figures
	    	* `energy-code-release/figures/figA5_product_overlay_TINV_clim_global.pdf` (Figure A.5 in the paper)
		    * `energy-code-release/figures/figA5_product_overlay_TINV_clim_global_noSE.pdf`


2. Run `2_decile_regression.do` to estimate and plot the energy-temperature response for each decile of in sample GDP per-capita
	* ***Code Inputs***: `energy-code-release/data/GMFD_TINV_clim_regsort.dta` -- used for response estimation and plotting
	* ***Code Outputs***:
	    * Regression output  
		    * `energy-code-release/sters/FD_income_decile_TINV_clim.ster`
		    * `energy-code-release/sters/FD_FGLS_income_decile_TINV_clim.ster`
    	* Figures
            * `energy-code-release/figures/fig1a_product_overlay_income_decile_TINV_clim.pdf` (Figure 1.a in the paper)
		    * `energy-code-release/figures/fig1a_product_overlay_income_decile_TINV_clim_noSE.pdf`


3. Run `3_interacted_regression.do` to estimate and plot the energy-temperature response heterogeneity by income and long-run climate for the main (`TINV_clim`), excluding imputed data (`EX`), most recent decade (`decinter`), and tech trends model (`lininter`)
	* ***Code Inputs***: 
		* `energy-code-release/data/GMFD_TINV_clim_regsort.dta` -- used for main, most recent decade, and tech trend models response estimation and plotting
		* `energy-code-release/data/GMFD_TINV_clim_EX_regsort.dta` -- used for excluding imputed data response estimation and plotting
		* `energy-code-release/data/break_data_TINV_clim.dta` -- used for plotting all outputs
	* ***Code Outputs***:
	    * Regression output  
    		* `energy-code-release/sters/FD_inter_TINV_clim.ster`
    		* `energy-code-release/sters/FD_FGLS_inter_TINV_clim.ster` (main model ster file)
    		* `energy-code-release/sters/FD_inter_TINV_clim_EX.ster`
    		* `energy-code-release/sters/FD_FGLS_inter_TINV_clim_EX.ster` (excluding imputed data model ster file)
    		* `energy-code-release/sters/FD_inter_TINV_clim_lininter.ster`
    		* `energy-code-release/sters/FD_FGLS_inter_TINV_clim_lininter.ster` (tech trend model ster file)
    		* `energy-code-release/sters/FD_inter_TINV_clim_decinter.ster`
    		* `energy-code-release/sters/FD_FGLS_inter_TINV_clim_decinter.ster` (most recent decade ster file)
		* Figures
        	* `energy-code-release/figures/fig1b_*_interacted_TINV_clim.pdf` (Figure 1.b in the paper) 
    		* `energy-code-release/figures/fig1b_*_interacted_TINV_clim_noSE.pdf`
    		* `energy-code-release/figures/figA13_*_interacted_main_model_TINV_clim_overlay_model_EX.pdf` 
    		* `energy-code-release/figures/figA13_*_interacted_main_model_TINV_clim_overlay_model_EX_noSE.pdf` (Figure A.13 in the paper)
    		* `energy-code-release/figures/figA14_*_interacted_main_model_TINV_clim_overlay_model_decinter.pdf` 
    		* `energy-code-release/figures/figA14_*_interacted_main_model_TINV_clim_overlay_model_decinter_noSE.pdf` (Figure A.14 in the paper)
    		* `energy-code-release/figures/figA15a_ME_time_TINV_clim_lininter_*.pdf` (Figure A.15a) 
    		* `energy-code-release/figures/figA15b_*_interacted_main_model_TINV_clim_overlay_model_lininter.pdf` 
    		* `energy-code-release/figures/figA15b_*_interacted_main_model_TINV_clim_overlay_model_lininter_noSE.pdf` (Figure A.15b in the paper)

# FGLS Procedure

* In order to address differential data quality across reporting regimes, we employ inverse variance weighting in all regressions. 
* Details of this can be found in Section A.5.3; "Inverse Variance Weighting".
* The overall approach is to first run a regression without FGLS, in order to save the residuals.
* We then use these residuals to calculate the FGLS weights that are applied in second stage regressions.

### Non Pop-Weighted Regression - We implement this procedure in the `interacted` model and the `decile` model

* In regressions that are not population weighted, we construct the FGLS weight for an observation within a regime $`i`$ as:
$` \frac{1}{V_i} `$
* $` V_i `$ is the variance of the residual within regime $` i `$.
* This procedure applies to regressions in the `interacted_regression` and `decile_regression` folders in this directory. 

### Pop-Weighted Regression - We implement this procedure in the `uninteracted` model

* For pop-weighted regressions, we need to account for the fact that our residuals in the first stage regression have already had weights applied to them.
* Therefore, we construct the FGLS weight for an observation $` j `$ within a regime $` i `$ as: $` w^{i}_{j} = w_{j} \frac{1}{\omega_i} `$
* $` w_{j} `$ is the population weight assigned to observation $` j `$ in the first stage regression. 
* $` \omega_i `$ is sample variance of the weighted first stage residuals, within regime $` i `$. 
* This procedure applies to regressions in the `uninteracted_regression` folder in this directory. 

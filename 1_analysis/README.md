# Run Instructions


# Folder Structure

`uninteracted_regression` - Code for estimating and plotting the global average dose-response function. Section A.6 outlines this piece of analysis.

`decile_regression` - Code for estimating and plotting the dose-response relationship for each decile of in sample GDP per-capita. Equation 3 on page 16 outlines this piece of analysis.

`interacted_regression` - Code for estimating and plotting dose-response heterogeneity by income and long-run climate. Section A.7 outlines this piece of analysis.

# Folder Contents

Within each directory there are at least two pieces of code:
1. `stacked.do` - estimates the dose-reponse function
2. `plot_stacked.do` - plots the dose-response function

`interacted_regression` also contains `plot_time_marginal_effect.do`. This code is used to produce plots which illustrate how temperature responses change across time in the Tech Trends robustness model. 

# FGLS Procedure

* In order to address differential data quality across reporting regimes, we employ inverse variance weighting in all regressions. 
* Details of this can be found in Section A.5.3; "Inverse Variance Weighting".
* The overall approach is to first run a regression without FGLS, in order to save the residuals.
* We then use these residuals to calculate the FGLS weights that are applied in second stage regressions.

### Non Pop-Weighted Regression

* In regressions that are not population weighted, we construct the FGLS weight for an observation within a regime $`i`$ as:
$` \frac{1}{V_i} `$
* $`V_i`$ is the variance of the residual within regime $`i`$.
* The applies to regressions the `interacted_regression` and `decile_regression` folders in this directory. 

### Pop-Weighted Regression

* For pop-weighted regressions, we need to account for the fact that our residuals in the first stage regression have already had weights applied to them.
* Therefore, we construct the FGLS weight for an observation $`j`$ within a regime $`i`$ as: $`w^{i}_{j} = w_{j} \frac{1}{\omega_i}`$
* $`w_{j}`$ is the population weight assigned to observation $`j`$ in the first stage regression. 
* $`\omega_i`$ is sample variance of the weighted first stage residuals, within regime $`i`$. 
* This procedure applies to regressions in the `uninteracted_regression` folder in this directory. 




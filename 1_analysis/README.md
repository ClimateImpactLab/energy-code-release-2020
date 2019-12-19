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

## Pop-Weighted Regression

## Non Pop-Weighted Regression
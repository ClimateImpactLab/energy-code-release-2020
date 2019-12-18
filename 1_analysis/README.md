# Run Instructions


# Folder Structure

`uninteracted_regression` - Code for estimating and plotting the global average dose-response function outlined in section A.6

`decile_regression` - Code for estimating and plotting the 

`interacted_regression` - Code for estimating and plotting dose-response heterogeneity by income and long-run climate outlined in section A.7

Within each directory there are at least two pieces of code:
1. `stacked.do` - estimates the dose-reponse function
2. `plot_stacked.do` - plots the dose-response function

`interacted_regression` also contains `plot_time_marginal_effect.do`. This code is used to produce plots which illustrate how temperature responses change across time in the Tech Trends robustness model. 
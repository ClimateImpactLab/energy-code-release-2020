# This script loads in GCM level mean and standard deviations, and outputs random draws from 
# the uncertainty space 

# set seed for replicability:
set.seed(123)

# This function takes in a csv that contains means and variances of 
# each GCMs projected global impact for a given year. 
# Outputs a long dataframe for damage function estimation, plotting, and 
# uncertainty calculations

take_draws = function(price, ssp, fuel, )
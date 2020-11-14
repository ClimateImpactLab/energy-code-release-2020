# Fetch gcm weights using the function James uses
# call from R with the following code:
# library(reticulate)
# setwd(../prospectus-tools/gcp/extract/)
# source_python(paste0(dm_testing,'/fetch_weight.py'))
# weight = fetch_weight('ccsm4', 'rcp45')

from lib.weights import get_weights

def fetch_weight(gcm, rcp):
	weight_dict = get_weights(rcp)
	weight = weight_dict[gcm.lower()]
	return weight
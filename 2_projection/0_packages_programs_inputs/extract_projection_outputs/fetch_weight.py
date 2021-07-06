# Fetch gcm weights using the function James uses
# call from R with the following code:
# library(reticulate)
# setwd(../prospectus-tools/gcp/extract/)
# source_python(paste0(dm_testing,'/fetch_weight.py'))
# weight = fetch_weight('ccsm4', 'rcp45')

import os, csv
import numpy as np
from statsmodels.distributions.empirical_distribution import StepFunction

import os, csv
import numpy as np
from statsmodels.distributions.empirical_distribution import StepFunction

def get_weights(rcp):
    weights = get_weights_april2016(rcp)
    weights.update(get_weights_march2018(rcp))

    return weights

def get_weights_april2016(rcp):
    weights = {}

    with open('/shares/gcp/climate/BCSD/SMME/SMME-weights/' + rcp + '_2090_SMME_edited_for_April_2016.tsv', 'rU') as tsvfp:
        reader = csv.reader(tsvfp, delimiter='\t')
        header = next(reader)
        for row in reader:
            model = row[1].split('_')[0].strip('*').lower()
            weight = float(row[2])
            weights[model] = weight

    if rcp == 'rcp45':
        weights["pattern4"] = 0 # Explicitly remove (so no messages)

    return weights

def get_weights_march2018(rcp):
    weights = {}

    with open('/shares/gcp/climate/BCSD/SMME/SMME-weights/' + rcp + '_SMME_weights.tsv', 'rU') as tsvfp:
        reader = csv.reader(tsvfp, delimiter='\t')
        header = next(reader)
        for row in reader:
            model = row[1].strip('*').lower()
            if '_' in model:
                model = 'surrogate_' + model
            weight = float(row[2])
            weights[model] = weight

    if rcp == 'rcp45':
        weights["surrogate_gfdl-esm2g_06"] = 0 # Explicitly remove (so no messages)
            
    return weights


def fetch_weight(gcm, rcp):
	weight_dict = get_weights(rcp)
	weight = weight_dict[gcm.lower()]
	return weight
import pandas as pd
import xarray as xr
import os


def get_filter_mask(CLIMATE_V2 = False, CLIMATE_V2p1 = False, CLIMATE_V1 = False):
    

    os.getcwd() 
    if CLIMATE_V2 or CLIMATE_V2p1:
        filters_fp = (
            '{}/climate/parameters/parameter_filters_rwf_tau4_iptcriteria_v2.1_newiptemissions.nc'.format(os.path.dirname(os.path.realpath(__file__)))) 

        with xr.open_dataset(filters_fp) as filters_ds:
            #print(filters_ds)
            the_mask = (filters_ds.rwf_mask
                             & filters_ds.tau4_mask
                             & filters_ds.ipt_time_to_dT_lt_0_passing_mask)
            return the_mask
    elif CLIMATE_V1:
        # read in old filters:
        filtered_parameter_indices = pd.read_csv(
            'climate/parameters/filtered_parameter_indices.csv', 
            index_col=0)

        with xr.Dataset(filtered_parameter_indices) as filters_ds:
            filters_ds.rename({'dim_0':'simulation'})
            the_mask = filters_ds.ipt_dT_lt_0
            return the_mask
    else:
        raise NotImplementedError


def get_parameters(filtered=True, array=True, CLIMATE_V2 = False, CLIMATE_V2p1 = False, CLIMATE_V1 = False):
    """ if array is False, return the xr.DataArray. Haven't used the DataArray version much. """
     
    if CLIMATE_V2 or CLIMATE_V2p1:
        
        with xr.open_dataset(
            # This file is part of the git repo
            '{}/climate/parameters/original_parameter_samples_with_rwf_v2_2019-02-01-22-50-59.nc'.format(os.path.dirname(os.path.realpath(__file__)))) as params_ds:

            if filtered:
                climate_params = params_ds.drop('rwf').where(get_filter_mask(CLIMATE_V2, CLIMATE_V2p1, CLIMATE_V1),drop=True).to_array(dim='parameter')#.T.values
            else:
                climate_params = params_ds.drop('rwf').to_array(dim='parameter')#.T.values
                
            if array:
                return climate_params.T.values
            else:
                return climate_params

    elif CLIMATE_V1:
        with xr.open_dataset('{}/climate/parameters/original_parameter_samples.nc'.format(os.path.dirname(os.path.realpath(__file__)))) as params_ds:
            
            if filtered:
                climate_params = params_ds.where(get_filter_mask(CLIMATE_V2, CLIMATE_V2p1, CLIMATE_V1)).to_array(dim='parameter')#.T.values
            else:
                climate_params = params_ds.to_array(dim='parameter')#.T.values
            
            if array:
                return climate_params.T.values
            else:
                return climate_params
    else:
        raise NotImplementedError
        
    
def get_median_climate_params(CLIMATE_V2 = False, CLIMATE_V2p1 = False, CLIMATE_V1 = False):
    
    cp = get_parameters(filtered=True, 
    	array=False, 
    	CLIMATE_V2 = CLIMATE_V2, 
    	CLIMATE_V2p1 = CLIMATE_V2p1, 
    	CLIMATE_V1 = CLIMATE_V1)
    
    return cp.quantile(0.5,dim='simulation')
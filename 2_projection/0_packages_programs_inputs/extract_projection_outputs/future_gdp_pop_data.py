# adapted from mortality valuation code
# check to make sure population interpolation is happening how you want it to be
import sys ; sys.path.append(".")
import numpy as np
import pandas as pd
import metacsv
from impactlab_tools.utils import files
import os
from impactcommon.exogenous_economy import gdppc, provider

## Takes landscan2011 and fills in where no pop (held constant at 2011)

def get_missing_pop(df, dfir, lspop):
    tmp = dfir.merge(df.loc[(df.year == 2015) & (df.ssp == 'SSP3')], how = 'left', on = ['region', 'iso'])
    tmp = tmp.loc[np.isnan(tmp['pop']),'region']
    tmplist = []
    for reg in tmp:
        for ssp in df.ssp.unique():
            yvect = df.year.unique()
            series = np.repeat(lspop.loc[lspop.hierid == reg,'lspopzeros'], yvect.size)
            svect = np.repeat(ssp, yvect.size)
            rvect = np.repeat(reg, yvect.size)
            isovect = np.repeat(lspop.loc[lspop.hierid == reg,'ISO'], yvect.size)
            tmpdf = pd.DataFrame({'year':yvect, 'region':rvect,  'pop':series, 'ssp':svect, 'iso':isovect})
            tmplist.append(tmpdf)
    dfp = pd.concat(tmplist,sort = False)
    return dfp

## Get population for all impact regions

def get_pop():

    lspop = pd.read_csv(files.sharedpath('social/processed/LandScan2011/gcpregions.csv'), header = 17)

    dfir = metacsv.read_csv(files.sharedpath("regions/hierarchy_metacsv.csv"))
    dfir = dfir.loc[dfir.is_terminal].reset_index(drop=True)
    dfir.drop(['parent-key', 'name', 'alternatives', 'is_terminal', 'gadmid', 'agglomid', 'notes'],axis=1,inplace=True)
    dfir.rename(columns={'region-key':'region'}, inplace=True)
    dfir['iso'] = dfir.region.apply(lambda x: x[:3])
    
    df = pd.read_csv(files.sharedpath('social/baselines/population/merged/population-merged.all.csv'))
    
    df.rename(columns={'value':'pop'}, inplace=True)
    df['iso'] = df.region.apply(lambda x: x[:3])
    df.drop(['index'], axis=1, inplace=True)
    df = df.loc[df.year>2005]

    dff = df.append(get_missing_pop(df,dfir,lspop), sort = False).sort_values(['region','year']).reset_index(drop=True)
    
    return dff

# get gdp pc for all impact regions

def get_gdppc_all_regions(model, ssp):
    
    print(model+" "+ssp)
    os.chdir(os.getenv("REPO") + '/impact-calculations')
    moddict = {'high' : 'OECD Env-Growth', 'low' : 'IIASA GDP'}
    df = metacsv.read_csv(files.sharedpath("regions/hierarchy_metacsv.csv"))
    tmplist = []
    yvect = np.arange(2010, 2101)
    svect = np.repeat(ssp, yvect.size)
    mvect = np.repeat(moddict[model], yvect.size)
    provider = gdppc.GDPpcProvider(model,ssp)
    
    for ii in np.where(df.is_terminal)[0]:
        series = provider.get_timeseries(df['region-key'][ii])
        rvect = np.repeat(df['region-key'][ii], yvect.size)
        tmp = pd.DataFrame({'region':rvect, 'year':yvect, 'gdppc':series, 'ssp':svect, 'model':mvect})
        tmplist.append(tmp)
    
    dfg = pd.concat(tmplist, sort = False)
    
    return dfg

# create a global gdp time series -- input data frame output from get_gdppc_all_regions
# this whole situation could be made smarter :)... go for it if you are tryna

def convert_global_gdp(df,ssp):
    df['year_floor'] = df.year/5
    df['year_floor'] = df.year_floor.round()
    df['year_floor'] = df.year_floor*5
    df = df.astype({'year_floor':'int64'})
    pop = get_pop().rename(columns={'year':'year_floor'})
    pop = pop.loc[pop.ssp == ssp]
    df2 = df.merge(pop, on = ['region', 'year_floor','ssp'], how = 'left')
    df2['gdp'] = df2['pop']*df2['gdppc']
    dff = df2[['gdp','ssp','year']].groupby(['ssp','year']).sum()
    return dff



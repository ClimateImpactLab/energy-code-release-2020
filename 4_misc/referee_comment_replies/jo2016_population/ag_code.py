# coding: utf-8

# Creator: Greg Dobbels, gdobbels@uchicago.edu
# Date last modified: 07/18/2018
# Last modified by: 
# Purpose: 
#   Intersect all rasters in `raster_dir` with `shp_file` using 
#   `stat` (eg. "sum" or "median") to aggregate pixels and save
#   output as a csv in `out_dir`

# purpose: to aggregate the gridded pop to IR level

from pprint import pprint
import fiona
from rasterstats import zonal_stats
import csv
import sys,os
import pandas as pd
import unicodedata

out_dir = "/home/liruixue/temp/"
shp_file = "/shares/gcp/climate/_spatial_data/world-combo-new-nytimes/new_shapefile.shp"
raster_dir = "/home/liruixue/temp/GeoTIFF/SSP3_GeoTIFF/total/GeoTIFF/"
stat = "sum"

#out_dir = os.getcwd()
filename = shp_file.split('/')[-1].replace('.shp','')
outfile = out_dir + '/' + filename + '_irrigated_area.csv'

def to_ascii(str):
    return unicodedata.normalize('NFKD', str).encode('ascii', 'ignore').decode('ascii')



def collect_stats(shp, rasters, stat):
    shp_stats = []
    with fiona.open(shp, 'r') as adm_layer:
        shp_stats.append(list(adm_layer[0]['properties'].keys()))
        shp_stats[0].extend(['raster', stat + '_value'])
       
        for raster in rasters:
            print('calculating ' + stat + ' irrigated area from ' + raster) 
            shp_stats.extend(get_stats(adm_layer,  raster, stat))   
    return shp_stats



def get_stats(adm_layer, raster, stat):
    rasterfile = raster_dir + raster
    stats = []
    i = 0
    j = 0
    for region in adm_layer:
        i += 1
        region_stats = [to_ascii(unicode(x)) for x in list(region['properties'].values())]
        region_stats.append(raster[:-4])
        region_stats.append(zonal_stats(region, rasterfile, stats=[stat])[0][stat])   
        stats.append(region_stats)
        if i % 1000 == 0:
            j += 1000
            print('calculated ' + str(j) + ' of ' + str(len(adm_layer)) + ' regions')
    return stats
        

def write_csv(outfile, shp_stats):
    with open(outfile, 'w') as csvfile:
        outwriter = csv.writer(csvfile, lineterminator='\n')
        for row in shp_stats:
            outwriter.writerow(row)
            
            

rasters = []
for filename in os.listdir(raster_dir):
    if filename.endswith('.asc') or filename.endswith('.tif') :
        rasters.append(filename)
        

write_csv(outfile, collect_stats(shp_file, rasters, stat))
print('complete')



results = pd.read_csv("/home/liruixue/temp/new_shapefile_irrigated_area.csv")
results["year"] = results.raster.apply(lambda x: x[-4:])
results = results[["hierid","year","sum_value"]]
results.sort_values(by = ["hierid","year"], inplace = True)
results = results.fillna(0)
results.to_csv("/home/liruixue/temp/pop.csv", index = False)


results[results.year == "2010"].sort_values(by = ["sum_value"])




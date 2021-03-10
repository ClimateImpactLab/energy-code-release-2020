# coding: utf-8
from __future__ import print_function
import os
import sys
import subprocess
import getpass
import fiona
from collections import OrderedDict
from shapely.geometry import shape, mapping
from shapely.prepared import prep
from shapely import speedups
from rtree.index import Index
from rasterstats import zonal_stats
import time
import pandas as pd
from joblib import Parallel, delayed
from itertools import islice, repeat, starmap, takewhile
#from tqdm import tqdm
# compatibility with either python 2 or python 3
try:
    from itertools import imap, ifilterfalse
except ImportError:
    # Python 3...
    imap = map
    from itertools import filterfalse as ifilterfalse



def chunker(n, iterable):  # n is size of each chunk; last chunk may be smaller
    '''
    Manages memory by breaking up long lists/iterables into chunks.
    
    Parameters
    ----------

    n : int
        number of items per chunk
        
    iterable : iter
        iterable to be looped over
    '''
    return takewhile(bool, imap(tuple, starmap(islice, repeat((iter(iterable), n)))))


def copy_spatial_data(to, spatial_dir, shapefile_subdir, shapefile_name=None):
    '''
    Used only when run on the Savio cluster, this function copies the necessary
    data from shackleton/norgay to the group and scratch locations for processing
    
    Parameters
    ----------
    
    to : str
        'savio' to scp shapefile files from shackleton to savio, 'shackleton'
        to rscyn all the files created back to shackleton
        
    spatial_dir : str
        location of _spatial_data directory on savio
        
    shapefile_subdir : str
        subdirectory of _spatial_data that contains the shapefile
        
    shapefile_name : str
        name of the shapefile (only required when copying from shackleton to savio)
    
    '''
    try:
        with open(os.path.expanduser('~/.ssh/.sacagawea_username'), 'r') as f:
            shack_user = f.read().strip('\n')
    except:
        print('Please place your shackleton username in the file ~/.ssh/.sacagawea_username')
        raise
    if to == 'savio':
        try:
            os.makedirs(spatial_dir + '/' + shapefile_subdir)
        except OSError:
            if not os.path.isdir(spatial_dir + '/' + shapefile_subdir):
                raise
        if not os.path.isfile(spatial_dir + '/' + shapefile_subdir + '/' + shapefile_name + '.shp'):
            COMMAND = 'scp -i $HOME/.ssh/savio_sacagawea ' + shack_user + '@sacagawea.gspp.berkeley.edu:' + shapefile_subdir + '/' + shapefile_name + '.* ' + spatial_dir + '/' + shapefile_subdir
            HOST = "dtn"
            # Ports are handled in ~/.ssh/config since we use OpenSSH
            ssh = subprocess.Popen(["ssh", HOST, COMMAND],
                                   shell=False,
                                   stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE)
            result = ssh.stdout.readlines()
            if result == []:
                error = ssh.stderr.readlines()
                print("ERROR: {}".format(error), file=sys.stderr)
            else:
                print(result)
    elif to == 'sacagawea':
        COMMAND = 'rsync -uaqvze "ssh -i $HOME/.ssh/savio_sacagawea" ' + spatial_dir + '/' + shapefile_subdir + ' ' + shack_user + '@sacagawea.gspp.berkeley.edu:' + shapefile_subdir
        HOST = "dtn"
        # Ports are handled in ~/.ssh/config since we use OpenSSH
        ssh = subprocess.Popen(["ssh", HOST, COMMAND],
                               shell=False,
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)
        result = ssh.stdout.readlines()
        if result == []:
            error = ssh.stderr.readlines()
            print("ERROR: {}".format(error), file=sys.stderr)
        else:
            print(result)
        

def gen_segment_weights(init_dict):
    '''
    '''
    tic0 = time.time()
        
    clim = init_dict['clim']
    weightlist = init_dict['weightlist']
    shapefile_name = init_dict['shapefile_name']
    shapefile_dir = init_dict['shapefile_location']
    id_fields = init_dict['numeric_id_fields'] + init_dict['string_id_fields']
    shp_id = init_dict['shp_id']
    keep_features = init_dict['keep_features']
    drop_features = init_dict['drop_features']
    n_jobs = init_dict['n_jobs']
    verbose = init_dict['verbose']
    use_existing_segment_shp = init_dict['use_existing_segment_shp']
    filter_ocean_pixels = init_dict['filter_ocean_pixels']
    
    if init_dict['run_location'] == 'shackleton':
        spatial_dir = '/mnt/norgay_gcp/climate/_spatial_data'
    elif init_dict['run_location'] == 'sacagawea':
        spatial_dir = '/shares/gcp/climate/_spatial_data'
    elif init_dict['run_location'] == 'savio':
        spatial_dir = '/global/home/groups/co_laika/climate/_spatial_data'
        copy_spatial_data('savio', spatial_dir, shapefile_subdir, shapefile_name)
    elif init_dict['run_location'] == 'aeod':
        spatial_dir = 'G:/climate/_spatial_data'
    else:
        spatial_dir = '/shares/gcp/climate/_spatial_data'

    if 'grid_region_match_method' in init_dict:
        match_method = init_dict['grid_region_match_method']
        if match_method not in ['segment', 'overlap', 'centroid']:
            match_method = 'segment'
    else:
        match_method = 'segment'
        
    print('')
    
    # full path to the administrative shapefile
    shapefile_location = shapefile_dir
    adminSHP = shapefile_dir + '/{}.shp'.format(shapefile_name)
    
    # full path to the grid shapefile
    grids = {'BEST':'1deg', 'UDEL':'p5deg', 'ERAI':'p25deg', 'GMFD':'p25deg', 'BCSD':'p25deg'}
    gridSHP = spatial_dir + '/climate_grids/{}/{}_{}_grid.shp'.format(clim, clim, grids[clim])
    
    # full path to the intersected shapefile
    intersect_dir = shapefile_location + '/grid_intersected'
    try:
        os.makedirs(intersect_dir)
    except OSError:
        if not os.path.isdir(intersect_dir):
            raise
    segmentSHP = intersect_dir + '/{}_{}_grid_{}.shp'.format(shapefile_name, clim, match_method)    

    
    ##### Call functions #####
    
    print('')
    print('===== BEGIN INTERSECTION OF {} ({}) AND {}.shp ====='.format(clim, grids[clim], shapefile_name))
    print('')
    
    if use_existing_segment_shp and os.path.isfile(segmentSHP):
        print('Skipping intersection (segment shapefile already exists).')
        print('')
    else:
        intersect_grid_and_admin(adminSHP, gridSHP, segmentSHP, id_fields, keep_features, drop_features, n_jobs, verbose, filter_ocean_pixels, match_method=match_method)
    
    seg_df, allweights = calculate_weights(segmentSHP, id_fields, weightlist, shp_id, spatial_dir)
    
    write_segment_weights(seg_df, clim, shapefile_name, shapefile_location, allweights, match_method)
    
    if init_dict['run_location'] == 'savio':
        copy_spatial_data('sacagawea', spatial_dir, shapefile_subdir)    
    
    toc0 = time.time()
    print('')
    print('===== DONE =====')
    print('TOTAL TIME: {:.2f}s'.format(toc0-tic0))
    print('')    
    
    return

def intersect_grid_and_admin(adminSHP, gridSHP, segmentSHP, id_fields, keep_features=None, drop_features=None, n_jobs=1, verbose=2, filter_ocean_pixels=False, match_method='segment'):
    '''
    
    '''
    try:
      basestring
    except NameError:
      basestring = str
    # ## Intersect regions with grid
    # for large regions, break up into chunks to improve memory
    if n_jobs > 1:
        chunksize = n_jobs
    else:
        n_jobs = 1
        chunksize = 8
    tic = time.time()
    print('Intersecting...')

    with fiona.open(adminSHP, 'r') as admin_layer:
        with fiona.open(gridSHP, 'r') as grid_layer:
            
            grid_index = create_grid_index(grid_layer, filter_ocean_pixels)
            
            # Create a schema for the new shapefile that will hold the intersected
            # features. Must be saved to a shapefile so that zonal stats can be calculated.
            schema = {'geometry': 'Polygon',
                      'properties': OrderedDict([('ID', 'int:10'),
                                                 ('pix_cent_x', 'float:24.15'),
                                                 ('pix_cent_y', 'float:24.15')])}
#                                                 ('centroid', 'int:1')])}
            for prop in id_fields:
                schema['properties'][prop] = admin_layer.schema['properties'][prop]
            
            # filter features from admin layer by either dropping or keeping features
            # based on a list of values for a particular property (more than one
            # property/list can be specified)
            t0 = time.time()
            print('---Selecting admin features')
            if keep_features is not None:
                for prop, values in keep_features.items():
                    admin_layer = filter(lambda x: x['properties'][prop] in values, admin_layer)
            if drop_features is not None:
                for prop, values in drop_features.items():
                    admin_layer = filter(lambda x: x['properties'][prop] not in values, admin_layer)
            print('---DONE: {:.2f}s'.format(time.time()-t0))
            
            ##### FIND INTERSECTION #####
            # Loops through admin features and for each finds list of pixels that
            # are nearby using rtree spatial index, converts these to shapely
            # geometries, and then uses a "prepared" admin geometry to find the list
            # of pixels that *actually* intersect the admin feature.
            print('***Initializing parallel worker pool')
            with Parallel(n_jobs=n_jobs, verbose=verbose) as parallelize:
                segment_features = []
                tic1 = time.time()
                print('---Looping through admin features')
                for admin_feat in admin_layer:
                    try:
                        name = ' - '.join([admin_feat['properties'][prop] if isinstance(admin_feat['properties'][prop], basestring) else str(admin_feat['properties'][prop]) for prop in id_fields])
                    except:
                        name = str(admin_feat['id'])
                    print('------Beginning {}'.format(name))
                    tic2 = time.time()
                    admin_geom = shape(admin_feat['geometry'])
                    if not admin_geom.is_valid:
                        print('INVALID GEOMETRY, BUFFERING...')
                        admin_geom = admin_geom.buffer(0)
                    near_grid_ids = list(grid_index.intersection(admin_geom.bounds))
                    near_grid_geoms = [shape(grid_layer[int(fid)]['geometry']) for fid in near_grid_ids]
                    admin_prepped = prep(admin_geom)
                    # first, get list of all pixels that intersect
                    intersect_list = filter(admin_prepped.intersects, near_grid_geoms)
                    # then, get list of pixels that are completely interior
                    interior_list = filter(admin_prepped.contains, intersect_list)
                    new_segments = []
                    for chunk in chunker(chunksize, interior_list):
                        admin_segments = parallelize(delayed(gen_segment)(grid_geom, admin_geom, admin_feat['properties'], id_fields, interior=True) for grid_geom in chunk)
                        #admin_segments = [gen_segment(grid_geom, admin_geom, admin_feat['properties'], id_fields, interior=True) for grid_geom in chunk]
                        new_segments += admin_segments
                    # then, get list of pixels that intersect partially
                    boundary_list = ifilterfalse(admin_prepped.contains, intersect_list)
                    # process in chunks to limit memory
                    for chunk in chunker(chunksize, boundary_list):
                        admin_segments = parallelize(delayed(gen_segment)(grid_geom, admin_geom, admin_feat['properties'], id_fields, interior=False, match_method=match_method) for grid_geom in chunk)
                        new_segments += admin_segments
                    # to make centroid method similar to JW's code, need to
                    # find closes grid point for small regions with no internal
                    # centroid
                    segment_features += new_segments
                    toc2 = time.time()
                    print('------DONE: {:.2f}s'.format(toc2-tic2))
                    print('---')
                toc1 = time.time()
                print('---DONE: {:.2f}s'.format(toc1-tic1))

        
    # Write list of intersected/segment features to shapefile
    tic2 = time.time()
    print('---Writing to shapefile')
    with fiona.open(segmentSHP, 'w', 'ESRI Shapefile', schema) as segment_layer:
        seg_id = 0
        for segment_feat in segment_features:
            if segment_feat is not None:
                seg_id += 1
                segment_feat['properties']['ID'] = seg_id
                segment_layer.write(segment_feat)
    toc2 = time.time()
    print('---DONE: {:.2f}s'.format(toc2-tic2))
    
    toc = time.time()
    print('DONE: {:.2f}s'.format(toc-tic))


def calculate_weights(segmentSHP, id_fields, weightlist, shp_id, spatial_dir='/mnt/norgay_gcp/climate/_spatial_data'):
    '''
    Given a shapefile (with field names) and a list of weights, calculate zonal
    statistics for each region in the shapefile based on the raster data 
    associated with each weight.
    
    Parameters
    ----------
    
    segmentSHP : str
    
    
    id_fields : str
    
    
    weightlist : list
    
    
    spatial_dir : str
    
    '''
    # ## Calculate zonal statistics
    tic = time.time()
    print('Calculating zonal stats...')

    # add raster files here for different weights to be calculated
    rasterfile = {}
    rasterfile['nl'] = spatial_dir + '/raster_data/_nightlights/F182012.v4c_web.avg_vis.tif'
    rasterfile['pop'] = spatial_dir + '/raster_data/_landscan/lspop2011.flt'
    rasterfile['crop'] = spatial_dir + '/raster_data/_sage/anycrop_Geotiff/cropland2000_area.tif'
    rasterfile['wheat'] = spatial_dir + '/raster_data/_sage/wheat_HarvAreaYield_Geotiff/wheat_HarvestedAreaFraction.tif'
    
    # different weights can be added if a rasterfile of the appropriate type is available
    allweights = ['area'] + weightlist
    
    # produces list of dicts containing 'count' and 'mean' for each segment
    stats = {}
    for wt in weightlist:
        stats[wt] = zonal_stats(segmentSHP, rasterfile[wt])
    
    # ## Combine properties
    ii = 0
    segments = []
    with fiona.open(segmentSHP, 'r') as segment_layer:
        for segment_feat in segment_layer:
            props = {}
            geom3 = shape(segment_feat['geometry'])
            props['area'] = geom3.area
            for wt in weightlist:
                if stats[wt][ii]['mean'] is not None:
                    props[wt] = stats[wt][ii]['count'] * stats[wt][ii]['mean']
                else:
                    props[wt] = 0
            for prop in id_fields + ['pix_cent_x', 'pix_cent_y']:
                props[prop] = segment_feat['properties'][prop]
            segments += [props]
            ii += 1
    
    # ## Calculate weights
    seg_df = pd.DataFrame(segments)
    tot_df = seg_df.groupby(id_fields).transform('sum')[allweights]
    tot_df.columns = [wt + 'total' for wt in allweights]
    seg_df = pd.concat([seg_df, tot_df], axis=1)
    for wt in allweights:
        seg_df[wt+'wt'] = seg_df[wt] / seg_df[wt+'total']
    seg_df['shpid'] = shp_id
    
    toc = time.time()
    print('DONE: {:.2f}s'.format(toc-tic))
    return seg_df, allweights
    

def write_segment_weights(seg_df, clim, shapefile_name, shapefile_location, allweights, match_method):
    tic = time.time()
    print('Writing...')
    output_dir = shapefile_location + '/segment_weights'
    try:
        os.makedirs(output_dir)
    except OSError:
        if not os.path.isdir(output_dir):
            raise
    weightsuff = '_'.join(allweights)
    seg_df.to_csv(output_dir + '/{}_{}_grid_{}_weights_{}.csv'.format(shapefile_name, clim, match_method, weightsuff), index=False, encoding='utf-8')
    toc = time.time()
    
    print('DONE: {:.2f}s'.format(toc-tic))


def create_grid_index(grid_layer, filter_ocean_pixels=False, norgay_dir='/mnt/norgay_gcp'):
    '''
    
    '''
    if filter_ocean_pixels:
        oceanSHP = norgay_dir + '/climate/_spatial_data/WORLD/OCEAN/ne_10m_ocean.shp'
        
        print('---Constructing spatial index of pixels (excluding ocean pixels)')
        tic1 = time.time()
        # Turn the grid layer into a list of features/geometries
        # This is mostly done for the "filter ocean pixels" part, and could probably
        # be simplified a bit and turned into a function
        with fiona.open(oceanSHP, 'r') as ocean_layer:
            ocean_feature = ocean_layer[0]
            ocean_prepped = prep(shape(ocean_feature['geometry']))
        
        grid_index = Index()
        for feat in grid_layer:
            fid = int(feat['id'])
            geom = shape(feat['geometry'])
            if not ocean_prepped.contains(geom):
                grid_index.insert(fid, geom.bounds)
        
        toc1 = time.time()
        print('---DONE: {:.2f}s'.format(toc1-tic1))
    else:
        # Uses rtree to make a spatial index of grid features for quick searching
        # IF filtering ocean pixels helps, it's by making this index shorter
        # and even faster to search
        print('---Constructing spatial index of pixels')
        tic1 = time.time()
        grid_index = Index()
        for feat in grid_layer:
            fid = int(feat['id'])
            geom = shape(feat['geometry'])
            grid_index.insert(fid, geom.bounds)
        toc1 = time.time()
        print('---DONE: {:.2f}s'.format(toc1-tic1))
    
    return grid_index

def gen_segment(grid_geom, admin_geom, admin_props, id_fields, interior=False, match_method='segment'):
    '''
    Takes a grid shape and an admin shape, finds their intersection, and returns
    a feature with properties indicating the pixel centroid and the fields that
    uniquely identify the admin feature along with the geometry of the intersection,
    as long as the intersection has area.
    
    If this file is run with the `n_jobs` variable set to something greater
    than 0, this function will run in parallel over a list of grid shapes that
    potentially intersect the same admin shape
    
    Parameters
    ----------

    grid_geom : shapely geometry
        a single feature from the "grid" layer, converted into a geometry using
        shapely.geometry.shape

    admin_geom : shapely geometry
        a single feature from the "admin" layer, converted into a geometry using
        shapely.geometry.shape

    admin_props : dict
        properties of the admin feature that are to be copied to the resulting
        feature that represents the intersection of the admin and grid features
    
    id_field_map : dict
        mapping from old field names used for the admin feature to new field
        names used for the intersection feature
        
    interior : bool
        True if grid_geom is entirely contained by admin_geom. This skips the 
        intersection and is thus much faster.
    
    '''
    if interior == True:
        seg_geom = grid_geom
        centroid = 1
    else:
        if match_method == 'segment':
            seg_geom = admin_geom.intersection(grid_geom)
        elif match_method == 'centroid':
            if admin_geom.contains(grid_geom.centroid):
                seg_geom = grid_geom
            else:
                return None
        elif match_method == 'overlap':
            seg_geom = grid_geom
#        centroid = int(admin_geom.contains(grid_geom.centroid))
    if seg_geom.geom_type in ['Polygon', 'MultiPolygon']:
        pix_bounds = grid_geom.bounds
        pix_cent_x = (pix_bounds[0] + pix_bounds[2]) / 2.
        pix_cent_y = (pix_bounds[1] + pix_bounds[3]) / 2.
        props = {'pix_cent_x': pix_cent_x,
                 'pix_cent_y': pix_cent_y}
        for prop in id_fields:
            props[prop] = admin_props[prop]
        return {'properties': props, 'geometry': mapping(seg_geom)}


#def find_nearest_centroid():
    

def main(init_dict):
    """
    
    init_dict : dict
        must be composed of the following keys
        
        run_location : str
        
        n_jobs : int
        
        verbose : int
        
        clim : str
        
        shapefile_location : str
            sub-directory of /mnt/norgay_gcp/climate/_spatial_data
        
        shapefile_name : str
        
        shp_id : str
        
        numeric_id_fields : list
        
        string_id_fields : list
        
        weightlist : list
            elements must be one of 'pop', 'area', 'crop', or 'nl'
        
        use_existing_segment_shp : bool
        
        filter_ocean_pixels : bool
        
        keep_features : dict
        
        drop_features : dict

    """
    speedups.enable()

    gen_segment_weights(init_dict)

if __name__ == '__main__':
    
    try:
        with open(sys.argv[1],  'r') as init_file:
            init_dict = eval(init_file.read())
    except:
        print('Invalid input file. Program terminating.')
        sys.exit()
    
    main(init_dict)

# plot time series 

rm(list = ls())
source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}
pacman::p_load(ggplot2, 
               dplyr,
               readr, 
               DescTools,
               RColorBrewer)


# Set paths
DB = "/mnt/CIL_energy"

DB_data = paste0(DB, "/code_release_data_pixel_interaction")
root =  "/home/liruixue/repos/energy-code-release-2020"
output = paste0(root, "/figures")

# Source time series plotting codes
source(paste0("/home/liruixue/repos/post-projection-tools/", "/timeseries/ggtimeseries.R"))



library(data.table)
library(ncdf4)
library(easyNCDF)

#' Converts the N-dimensional array data of a netcdf into a flat, tabular data.
#' @param nc_file character. The full path to the netcdf file, including '.nc4'. 
#' @param impact_var character. The name(s) of the variable(s) containing the values to pull out of the netcdf. If multiple, should be a vector. 
#' @param dimvars list of named characters. The list represents the dimensions of the `impact_var` array stored in the netcdf. The list ordering (see below) and names should be consistent 
#' with that of the netcdf. In addition, each character should have a name. This is because usually, in a netcdf, the dimensions of the variables have their 'values' (or 'names') stored in unidimensional variables, separately. For example, 
#' if there is in the set of variables of the netcdf a variable response[region, year] (a matrix), then there will be also a variable region[region] and year[year]. But those 
#' could also be regions[region] and years[year]. That is, the name of the dimension 'as a variable' is not necessarily the name of the dimension 'as a dimension'. Therefore, 
#' in the 'dimvars' list, each value is the name of the dimension 'as a VARIABLE', and each value's name is the name of the dimension 'as a DIMENSION'. The latter is the one 
#' used as an additional column in the subsequent tabular data. 
#' 
#' One painful point is to know what the ordering is. ncdump -h doesn't show the actual one (for example it might show response(region, year) while the true ordering is (year, region)). There
#' are two solutions here : 1/ trial and error until you get the right order 2/ use the easyNCDF:::NcReadDims() function to get the true ordering. 
#' @param to.data.frame logical. If TRUE, returns a data.frame. 
#' @param print.nc logical. If TRUE, prints nc_file. 
#' @param convert_all logical. Should I try to force a type conversion for all the columns of the tabular data? Careful, this is slow.
#' 
#' @return a data frame or a data table which is a flat, tabular representation of the netcdf's requested variables. this means the table will have 
#' (length(dimvars) + length(impact_var)) columns, and the product of the dimensions length as number of rows. If a datatable, names of `dimvars` are used as keys.
nc_to_DT <- function(nc_file, impact_var='rebased', dimvars=list(region='regions', year='year'), to.data.frame=FALSE, print.nc=TRUE, convert_all=FALSE){

  if(print.nc) print(nc_file)
  nc <- nc_open(nc_file)

  #verifying that dimvars matches the dimensionality of the netcdf
  dims_attr <- sapply(X=impact_var, FUN=function(x) NcReadDims(nc_file, var_names=x), simplify = FALSE)
  dims_attr <- lapply(X=dims_attr, FUN=function(x) x[names(x)!='var'])
  dimchecks <- lapply(X=dims_attr, function(x) identical(names(x), names(dimvars)))
  if(!all(unlist(dimchecks))) stop("dimvars doesn't match the dimension names of all the variables requested, either in the ordering or the actual content")
  
  #pull the values
  values <- sapply(X=impact_var, FUN=function(x) NcToArray(file_to_read=nc_file, vars_to_read=x), simplify = FALSE)
  values <- lapply(X=values, function(x) adrop.sel(x, omit=which(names(dim(x)) %in% names(dimvars))))

  #pull the dimension 'values' (or 'names')
  dimvalues <- sapply(X=dimvars, FUN=function(x) c(ncvar_get(nc, x)), simplify = FALSE)

  #close because who knows what can happen
  nc_close(nc)

  #assign dimension values to dimension names of the data array
  values <- Map(function(x) {dimnames(x) <- dimvalues; x}, values) #for a reason I ignore, Map() works, but not apply(). 

  #convert the array into tabular data (each dimension becomes a column)
  if(length(dimvars)<=2){ #this is faster I think, so keep that method for N=2
    tabular_values <- lapply(X=values, FUN=function(x) as.data.table(as.table(t(x))))
    tabular_values <- lapply(X=impact_var, FUN=function(x) setnames(tabular_values[[x]], 'N', x))
  } else { 
    tabular_values <- lapply(X=values, FUN=function(x) as.data.table(as.data.frame.table(x, stringsAsFactors=FALSE)))
    #tabular_values <- lapply(X=tabular_values, FUN=function(x) setnames(x, names(x)[names(x)!='Freq'], names(dimvars)))
    tabular_values <- lapply(X=impact_var, FUN=function(x) setnames(tabular_values[[x]], 'Freq', x))
  }

  lapply(tabular_values, function(x) setkeyv(x, names(dimvars)))

  tabular_values <- Reduce(merge, tabular_values)

  if(convert_all){ #this is relatively slow, so not the default behavior. It forces a type conversion for all variables (e.g. what can be integer becomes integer)
    tabular_values <- tabular_values[,lapply(X=.SD, FUN=function(x) type.convert(x, as.is=TRUE))]
  } else {
    if('year' %in% names(tabular_values)) tabular_values <- tabular_values[,year:=as.integer(year)][]
  }

  setkeyv(tabular_values, names(dimvars))
  
  if(to.data.frame) tabular_values <- as.data.frame(tabular_values) 

  return(tabular_values)

}


#' Selectively drop singleton dimensions in an array.
#' @param x array. 
#' @param omit integer. vector of indexes of the singleton dimensions to not drop. 
#' 
#' @return the array x without its singleton dimensions, except those indicated by omit. 
adrop.sel <- function(x, omit){
  ds <- dim(x)
  dv <- ds == 1 & !(seq_along(ds) %in% omit)
  abind:::adrop(x, dv)
}



get_plot_df_by_fuel_jo2016 = function(fuel, DB_data) {
  
  df_jo2016_rcp45 = nc_to_DT(nc_file=paste0("/shares/gcp/outputs/energy_pixel_interaction/",
  "impacts-blueghost/median_OTHERIND_", fuel, 
  "_TINV_clim_GMFD/median/rcp45/CCSM4/high/SSP3/FD_FGLS_inter_OTHERIND_", fuel, 
  "_TINV_clim-jo2016-aggregated.nc4"), 
  impact_var="rebased") %>% mutate(rcp = "rcp45")

  df_jo2016_rcp85 = nc_to_DT(nc_file=paste0("/shares/gcp/outputs/energy_pixel_interaction/",
  "impacts-blueghost/median_OTHERIND_", fuel, 
  "_TINV_clim_GMFD/median/rcp85/CCSM4/high/SSP3/FD_FGLS_inter_OTHERIND_", fuel, 
  "_TINV_clim-jo2016-aggregated.nc4"), 
  impact_var="rebased") %>% mutate(rcp = "rcp85")


  df_jo2016_rcp45_hist = nc_to_DT(nc_file=paste0("/shares/gcp/outputs/energy_pixel_interaction/",
  "impacts-blueghost/median_OTHERIND_", fuel, 
  "_TINV_clim_GMFD/median/rcp45/CCSM4/high/SSP3/FD_FGLS_inter_OTHERIND_", fuel, 
  "_TINV_clim-histclim-jo2016-aggregated.nc4"), 
  impact_var="rebased") %>% mutate(rcp = "rcp45") %>%
  rename(hist = rebased)

  df_jo2016_rcp85_hist = nc_to_DT(nc_file=paste0("/shares/gcp/outputs/energy_pixel_interaction/",
  "impacts-blueghost/median_OTHERIND_", fuel, 
  "_TINV_clim_GMFD/median/rcp85/CCSM4/high/SSP3/FD_FGLS_inter_OTHERIND_", fuel, 
  "_TINV_clim-histclim-jo2016-aggregated.nc4"), 
  impact_var="rebased") %>% mutate(rcp = "rcp85") %>%
  rename(hist = rebased)


  df_jo2016_rcp45 = merge(df_jo2016_rcp45, df_jo2016_rcp45_hist, by = c("year","region","rcp")) %>%
    mutate(mean = rebased - hist) %>%
    select(-c("rebased","hist"))
  df_jo2016_rcp85 = merge(df_jo2016_rcp85, df_jo2016_rcp85_hist, by = c("year","region","rcp")) %>%
    mutate(mean = rebased - hist) %>%
    select(-c("rebased","hist"))


  df_jo2016 <- rbind(df_jo2016_rcp45, df_jo2016_rcp85) %>%
    filter(region == "", year >= 2010)  %>%
    mutate(fuel = fuel, type = "jo2016_pop") %>%
    select(-region)
  
  df_main = read_csv(paste0(DB_data, "/projection_system_outputs/time_series_data/CCSM4_single/", 
              "main_model_single-", fuel, "-SSP3-high-fulladapt-impact_pc.csv"))



  df <- rbind(df_jo2016, df_main) %>%
    mutate(legend = paste0(type,"_", rcp))
  
  return(df)

}


plot_and_save_appendix_I1 = function(fuel, DB_data, output){
  
  df = get_plot_df_by_fuel_jo2016(fuel = fuel, DB_data = DB_data)
  p = ggplot() +
    geom_line(data = df, aes(x = year, y = mean, color = rcp, linetype = type)) +
    scale_colour_manual(values=c("blue", "red", "steelblue", "tomato1")) +
    scale_linetype_manual(values=c("dashed", "solid"))+
    scale_x_continuous(breaks=seq(2010, 2100, 10))  +
    geom_hline(yintercept=0, size=.2) +
    scale_alpha_manual(name="", values=c(.7)) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank(), 
          axis.line = element_line(colour = "black")) +
    ggtitle(paste0(fuel, "-SSP3-CCSM4-High")) +
    ylab("Impacts (GJ PC)") + xlab("")
  
  ggsave(p, file = paste0(output, 
                          "/fig_Appendix-G1_jo2016-global_", fuel, "_timeseries_impact-pc_CCSM4-SSP3-high.pdf"), 
                          width = 8, height = 6)
  return(p)
}

####### not done #######
p = plot_and_save_appendix_I1(fuel = "electricity", DB_data = DB_data, output = output)
p = plot_and_save_appendix_I1(fuel = "other_energy", DB_data = DB_data, output = output)




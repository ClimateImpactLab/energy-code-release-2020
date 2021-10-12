# This script contains 2 functions:

# load.map() loads map shapefile, and returns a dataframe 
# join.plot.map() joins your impact-region level data to the map & plots the data

# Updated 4 Jun 2019 by Trinetta Chong 
#---------------------------------------------------------------------------------------------
#Packages to install: 
#install.packages(c("rgdal", "rgeos", "raster", "rnaturalearth", "RColorBrewer", "scales")) #packages specific to this mapping code

#Arguments

#load.map()
# Optional Arguments
#*shploc: the directory on Sacagawea which contains the shapefile, if you're running it from your local system, you need to put in your own path (default = "/shares/gcp/climate/_spatial_data/world-combo-new-nytimes")
#*shpname: the name of the shapefile (default: "new_shapefile")

#join.plot.map()

#Essential Argurments
##*map.df: the map dataframe obtained from running load.map() 
##*df: your data, it should have only one observation per impact region (dataframe with <=24378 rows)
##*df.key: variable in your dataframe that identifies each spatial unit (string character, default: "hierid")
##*map.key: variable in shapefile df that identifies each spatial unit (string character, default: "id")
##*plot.var: variable to be plotted in map (string character)
##*topcode: limit color bar and mapping to a specified range of values (default: F)
##*topcode.ub: value of upper limit on color bar (numeric,e.g. 0.005 default: NULL)
##*round.minmax: number of digits to round your minimum/maximum value to (in the caption) (default: 4)
##*color.scheme: 
  #* "div" - diverging e.g. negative values in blue to lightgrey for zero to positive values in red  (string character, default: blue to grey to red) 
  #* "seq" - sequential, e.g. minimum value in light blue to maximum value in dark blue (string character, default: blues)
  #* "cat" - categorical e.g. blue for category 1, red for category 2 (string character, default: 2 categories, one in blue, one in red )
##*colorbar.title: title of colorbar (string character)
##*map.title: title of map (string character)

# Optional Arguments
# barwidth: how wide the color bar will be (default: 100mm)
#*topcode.lb: value of lower limit on color bar (numeric, default: -topcode.ub)
#*rescale_val: scale values for color bar (numeric vector)
#* "div" - default: `c(topcode.lb, 0, topcode.ub)` middle color takes on the value of zero 
#* "seq" or "cat" - default: NULL
#*breaks_labels_val (only for "div" or "seq"): set frequency of ticks on color bar (numeric vector, default: `seq(topcode.lb, topcode.ub, topcode.ub/5)``
#*breaks_labels_val_cat (only for "cat"): label of each factor on color legend (string vector, e.g. `c("Group1", "Group2", Group3")` default: `levels(shp_plot$mainvar_lim)`
#*color.values: colors on color bar
#* "div" - string vector, default: rev(c("#d7191c", "#fec980", "#ffedaa","grey95", "#e7f8f8", "#9dcfe4", "#2c7bb6"))
#* "seq" - string vector, default: `c("#2c7bb6", "#d7191c")` ()
#* "cat" - string vector default: `c("#2c7bb6", "purple4") because Barney
#*na.color: color of IRs with NA values (string character, default: "grey85")
#*lakes.color: color of waterbodies on map (string character, default: "white")

# Load in the required packages, installing them if necessary 
if(!require("pacman")){install.packages(("pacman"))}

pacman::p_load(ggplot2,         # ggplot
                dplyr,          # left_join, filter
                magrittr,       # %>%
                rgdal,          # readOGR, spTransform
                rgeos,          # gBuffer      
                raster,         #area
                rnaturalearth,  #lakes10
                RColorBrewer,   #get hex codes for R color palettes
                scales,         #rescale
                maps            # cities database
                )

#---------------------------------------------------------------------------------------------

# function to load map and put into dataframe
REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))

load.map <- function(shploc = paste0(DATA, "/climate/_spatial_data/world-combo-new-nytimes"), 
                     shpname = "new_shapefile", map.crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"){
print("loading world shapefile, this might take a few minutes, since it's a large file...")

#list of water bodies to exclude from map (Great lakes & Lake Victoria & Antarctica)
lakeslist <- list("CA-","ATA")

#load Climate impact lab  impact-region map
shp_master <- readOGR(dsn = shploc, layer = shpname, stringsAsFactors = FALSE) %>% #read shapefile
  spTransform(CRS(map.crs)) %>% #set crs
  gBuffer(byid=TRUE, width=0) #remove gaps between IR polygons by setting buffer=0
area <- data.frame(id = shp_master$hierid, area_sqkm = (raster::area(shp_master) / 1000000)) #calculate area of each IR from sq meters to sq km & put into df
shp_master <- fortify(shp_master,region="hierid")  %>% #set spatial data as df
  left_join(area, by = c("id")) %>% #join area data to shp_master
  filter(!(id %in% lakeslist)) #drop Caspian sea, Great lakes, Lake Victoria, Antarctica from map
print("----------map loaded-----------")
return(shp_master)
}

  #---------------------------------------------------------------------------------------------
  
  #function to join data to map and plot
join.plot.map <- function(map.df = NULL, df = NULL, df.key = "hierid", map.key = "id", plot.var = NULL, round.minmax = 4, 
                            topcode = F, topcode.ub = NULL, topcode.lb = NULL,
                            color.scheme = NULL, rescale_val = NULL,
                            limits_val = NULL, breaks_labels_val = NULL,
                            breaks_labels_val_cat = levels(shp_plot$mainvar_lim), 
                            bar.width = unit(100, units = "mm"),
                            colorbar.title = NULL, map.title = NULL, na.color = "grey85", lakes.color = "white",
                            color.values = NULL, minval = NULL, maxval = NULL, plot.lakes = T, 
                            map.crs = "+proj=robin +lon_0=0 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs"){
    
    print(paste0("joining data to world shapefile by: ",map.key, " and ", df.key))
    shp_plot <- left_join(map.df, df, by = setNames(nm = map.key, df.key)) #join map to dataframe
    
    shp_plot['mainvar'] <- shp_plot[plot.var] #identify variable for plotting
    
    #identify IRs that don't have values
    na.df <- dplyr::filter(shp_plot, is.na(mainvar))
    
    print("setting parameters for plotting...")
    
    #recode limits so it takes max color if it exceeds +-value
    if (topcode){ 
      print("plotting topcoded map... ")
      if (is.null(topcode.lb)){ #if user didn't specify topcode.lb value, set default
        topcode.lb <- -topcode.ub
      }

      shp_plot$mainvar_lim <- squish(shp_plot$mainvar, c(topcode.lb, topcode.ub))
      # ifelse(shp_plot$mainvar>topcode.ub, topcode.ub, shp_plot$mainvar) #+value
      
      # shp_plot$mainvar_lim <- ifelse(shp_plot$mainvar_lim<topcode.lb, topcode.lb, shp_plot$mainvar_lim) #-value
      limits_val = c(topcode.lb, topcode.ub)
      if(is.null(breaks_labels_val)){
        breaks_labels_val = seq(topcode.lb, topcode.ub, abs(topcode.ub-topcode.lb)/5)
      }
      } else { #no topcoding
        shp_plot$mainvar_lim <- shp_plot$mainvar
        
        maxi = max(shp_plot$mainvar, na.rm=TRUE)
        mini = min(shp_plot$mainvar, na.rm=TRUE)

        topcode.ub <- ifelse(maxi >= 1, ceiling(maxi), maxi)
        topcode.lb <- ifelse(mini <= -1, ceiling(mini), mini)
        
        bound = max(abs(topcode.ub), abs(topcode.lb))

        if (sign(topcode.ub) == sign(topcode.lb) | topcode.ub == 0 | topcode.lb == 0) {
          limits_val = ifelse(topcode.ub > 0, yes=list(c(0, bound)), no=list(c(-bound, 0)))[[1]]
          if(is.null(breaks_labels_val)){
            breaks_labels_val = ifelse(topcode.ub > 0, list(seq(0, bound, bound/5)), list(seq(-bound, 0, bound/5)))[[1]]
          }
        } else {
          limits_val = round(c(-bound, bound), round.minmax)
          if(is.null(breaks_labels_val)){
            breaks_labels_val = round(seq(-bound, bound, 2*bound/5), round.minmax)
          }
        }     
    }
    
    #set min and max value for caption
    if (is.null(minval)){
    minval <- round(min(shp_plot$mainvar, na.rm = T), digits = round.minmax) 
    }
    if (is.null(maxval)){
    maxval <- round(max(shp_plot$mainvar, na.rm = T), digits = round.minmax) 
    }
    caption_val <- paste0("Min: ", minval, "    Max: ", maxval)
    
    if (color.scheme=="div"){
      #rescale_val <- c(topcode.lb, 0, topcode.ub) #scale value for color bar, middle color "grey95" takes on value ~0 
      if (is.null(color.values)){
      color.values <- rev(c("#d7191c", "#fec980", "#ffedaa","grey95", "#e7f8f8", "#9dcfe4", "#2c7bb6"))
      }
    } else if (color.scheme=="seq"){ #sequential
      if (is.null(color.values)){
      color.values <- rev(c("#c92116", "#ec603f", "#fd9b64","#fdc370", "#fee69b","#fef7d1", "#f0f7d9"))
      }
    } else {
      if (is.null(color.values)){
      color.values <- brewer.pal(6, "Set1")
      }
      shp_plot$mainvar_lim <- as.factor(shp_plot$mainvar_lim)
    }
    
    if (is.null(limits_val)){
      limits_val = round(c(minval, maxval), round.minmax)
    }
    
    if (is.null(breaks_labels_val)){
      breaks_labels_val = round(seq(minval, maxval, abs(maxval)/10), round.minmax)
    }
    
    print("plotting map...")
    
    #plot
    p.map <- ggplot(data = shp_plot, aes(x=long, y=lat)) +
      geom_polygon(aes(group=group, fill=mainvar_lim)) + # IR polygons
      geom_polygon(data = na.df, aes(group=group), fill = na.color) + # NA regions
      #geom_path(color = "black", size=0.1, alpha=1) + #IR outlines
      coord_equal() +
      theme_bw() +     
      theme(plot.title = element_text(hjust=0.5, size = 10), 
            plot.caption = element_text(hjust=0.5, size = 7), 
            legend.title = element_text(hjust=0.5, size = 10), 
            legend.position = "bottom",
            legend.text = element_text(size = 7),
            axis.title= element_blank(), 
            axis.text = element_blank(),
            axis.ticks = element_blank(),
            panel.grid = element_blank(),
            panel.border = element_blank()) +   
      labs(title = map.title, caption = caption_val) 
    
    if (plot.lakes){
      
      #load lakes
      lakes10 <- ne_download(scale = 110, type = 'lakes', category = 'physical') %>%
        spTransform(CRS(map.crs)) %>% #set crs
        fortify(lakes10, region = "name") #set spatial data as df

      lakes <- dplyr::filter(lakes10, lakes10$lat <= max(map.df$lat) & lakes10$lat >= min(map.df$lat) & lakes10$long <= max(map.df$long) & lakes10$long >= min(map.df$long)) #newly subsetted lakes based on limits of map.df
      
      p.map <- p.map + geom_polygon(data = lakes, aes(x=long, y=lat, group=group), fill=lakes.color) # lakes overlay
    }
    
    if(color.scheme=="div" | color.scheme=="seq"){ #need to use scale_fill_gradient for continuous values
      
      p.map <- p.map + scale_fill_gradientn(
        colors = color.values,
        values=rescale(rescale_val),
        na.value = na.color,
        limits = limits_val, #center color scale so white is at 0
        breaks = breaks_labels_val, 
        labels = breaks_labels_val, #set freq of tick labels
        guide = guide_colorbar(title = colorbar.title,
                               direction = "horizontal",
                               barheight = unit(4, units = "mm"),
                               barwidth = bar.width,
                               draw.ulim = F,
                               title.position = 'top',
                               title.hjust = 0.5,
                               label.hjust = 0.5))
      
    } else { #color.scheme=="cat"
      
      p.map <- p.map + scale_fill_manual( #need to use scale_fill_manual for discrete values
        values = color.values,
        name = colorbar.title,
        na.value = na.color, 
        breaks = levels(shp_plot$mainvar_lim), # define each category
        labels = breaks_labels_val_cat) +   
        labs(caption = NULL)  #set the label of each category    
    } 
    
    rm(shp_plot)
    return(p.map)
    
  }
  

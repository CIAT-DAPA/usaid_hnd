# Carlos Navarro 
# CIAT - CCAFS
# November 2012

#############################
#### 01 Plots by months  ####
#############################

# Load libraries
require(rasterVis)
require(maptools)
require(rgdal)

# Set params
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_climatology_v2/average/tif"
oDir <- "D:/cenavarro/hnd_usaid/04_interpolation/performance_v2"
varList <- c("dtr", "tmax", "tmin", "tmean")
# varList <- c("prec", "dtr", "tmax", "tmin", "tmean")
id <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
mask <-"D:/cenavarro/hnd_usaid/04_interpolation/region/ZOI.shp"

# Set libraries
require(raster)
require(maptools)
require(rgdal)

setwd(bDir)
if (!file.exists(oDir)) {dir.create(oDir)}

#Read mask
mask <- readOGR(mask, , layer="ZOI")



for (var in varList){
  
  stk_crop <- stack(paste0(bDir, "/", var, "_", 1:12, ".tif"))
  # stk_crop <- mask(crop(stk, extent(mask)), mask)
  
  
  if (var == "prec"){
    
    stk_crop[which(stk_crop[]>1000)]=1000
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    
    zvalues <- seq(0, 1000, 50) # Define limits
    myTheme <- BuRdTheme() # Define squeme of colors
    myTheme$regions$col=colorRampPalette(c("snow", "blue", "magenta"))(length(zvalues)-1) # Set new colors
    myTheme$strip.border$col = "white" # Eliminate frame from maps
    myTheme$axis.line$col = 'white' # Eliminate frame from maps
    # myTheme=rasterTheme(region=brewer.pal('Blues', n=9))  
    
  } else if ( var == "rhum") {
    
    stk_crop <- stk_crop
    stk_crop[which(stk_crop[]>100)]=100
    stk_crop[which(stk_crop[]<60)]=60
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(60, 100, 5)
    # zvalues <- c(-10, -5, 0, 5, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("burlywood","snow", "deepskyblue", "darkcyan"))(length(zvalues)-1) # Set new colors
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  } else if ( var == "dtr") {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 0)]= 0
    stk_crop[which(stk_crop[]>24)]= 24
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(2, 24, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "snow", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  } else {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< (-8) )]= (-8)
    stk_crop[which(stk_crop[]>36)]= 36
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(-8, 36, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "snow", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  }
  
  tiff(paste(oDir, "/plot_monthly_clim_", var, ".tif", sep=""), width=1000, height=1200, pointsize=8, compression='lzw',res=100)
  
  print(levelplot(plot, at = zvalues, scales = list(draw=FALSE),  xlab="", ylab="", par.settings = myTheme, colorkey = list(space = "bottom")) + layer(sp.polygons(mask)))
  
  dev.off()
  
} 




#############################
#### 02 Plots by seasons ####
#############################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)

# Set params
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_climatology/average/tif"
oDir <- "D:/cenavarro/hnd_usaid/04_interpolation/performance"
varList <- c("prec"), "dtr", "tmax", "tmin", "tmean")
id <- c("djf", "mam", "jja", "son")
mask <- readOGR("D:/cenavarro/hnd_usaid/04_interpolation/region/ZOI.shp", layer= "ZOI")

# Set libraries
require(raster)
require(maptools)
require(rgdal)

setwd(bDir)
if (!file.exists(oDir)) {dir.create(oDir)}

for (var in varList){
  
  stk_crop <- stack(paste0(bDir, "/", var, "_", id, ".tif"))
  # stk_crop <- mask(crop(stk, extent(mask)), mask)
  
  if (var == "prec"){
    
    stk_crop[which(stk_crop[]>2000)]=2000
    
    plot <- setZ(stk_crop, id)
    names(plot) <- toupper(id)
    
    zvalues <- seq(0, 2000, 100) # Define limits
    myTheme <- BuRdTheme() # Define squeme of colors
    myTheme$regions$col=colorRampPalette(c("orange", "snow", "blue", "darkblue","magenta"))(length(zvalues)-1) # Set new colors
    myTheme$strip.border$col = "white" # Eliminate frame from maps
    myTheme$axis.line$col = 'white' # Eliminate frame from maps
    # myTheme=rasterTheme(region=brewer.pal('Blues', n=9))  
    
  } else if ( var == "rhum") {
    
    stk_crop <- stk_crop
    stk_crop[which(stk_crop[]>100)]=100
    stk_crop[which(stk_crop[]<60)]=60
    
    plot <- setZ(stk_crop, id)
    names(plot) <- toupper(id)
    zvalues <- seq(60, 100, 5)
    # zvalues <- c(-10, -5, 0, 5, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("burlywood","snow", "deepskyblue", "darkcyan"))(length(zvalues)-1) # Set new colors
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  } else if ( var == "dtr") {
    
    stk_crop <- stk_crop
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]>20)]= 20
    
    plot <- setZ(stk_crop, id)
    names(plot) <- toupper(id)
    zvalues <- seq(0, 20, 2)
    # zvalues <- c(-10, -5, 0, 5, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 34, 36, 38, 40)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("snow", "yellow", "orange", "red", "darkred"))(length(zvalues)-1) # Set new colors
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
    
  } else {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< (-8) )]= (-8)
    stk_crop[which(stk_crop[]>36)]= 36
    
    plot <- setZ(stk_crop, id)
    names(plot) <- toupper(id)
    zvalues <- seq(-8, 36, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "snow", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  }
  
  tiff(paste(oDir, "/plot_seasons_clim_", var, ".tif", sep=""), width=1200, height=400, pointsize=8, compression='lzw',res=100)
  
  print(levelplot(plot, at = zvalues, scales = list(draw=FALSE), layout=c(4, 1), xlab="", ylab="", par.settings = myTheme, colorkey = list(space = "bottom")) + layer(sp.polygons(mask)))
  
  dev.off()
  
} 
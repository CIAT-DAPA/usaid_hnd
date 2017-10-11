# Carlos Navarro 
# CIAT - CCAFS
# November 2012


#######################################
#### 01 Plots anomalies by seasons ####
#######################################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)

rcpList <- c("rcp26", "rcp85")
baseDir <- "W:/05_downscaling/anomalies_res"
perList <- c("2026_2045", "2046_2065")
varList <- c("prec", "tmin", "tmax")
seasons <- c("djf", "mam", "jja", "son")
id <- c("DJF ", "MAM", "JJA", "SON", 
        "DJF", "MAM", "JJA", "SON")
mask <- readOGR("W:/04_interpolation/region/ZOI.shp", layer= "ZOI")
oDir <- "W:/05_downscaling/evaluation"

for (period in perList) {
  
  for (var in varList){
    
    perSeas <- expand.grid(seasons, rcpList)
    
    stk <- stack(paste0(baseDir, "/", perSeas[,2], "/ensemble/", period, "/", var, "_", perSeas[,1], ".tif"))
    
    stk_crop <- mask(crop(stk, extent(mask)), mask)
    
    if (var == "prec"){
      
      stk_crop[stk_crop > 20] = 20
      stk_crop[stk_crop < (-20)] = (-20)
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(-20, 20, 1) # Define limits
      myTheme <- BuRdTheme() # Define squeme of colors
      myTheme$regions$col=colorRampPalette(c("darkred", "red", "pink", "snow", "deepskyblue", "blue", "darkblue"))(length(zvalues)-1) # Set new colors
      myTheme$strip.border$col = "white" # Eliminate frame from maps
      myTheme$axis.line$col = 'white' # Eliminate frame from maps
      # myTheme=rasterTheme(region=brewer.pal('Blues', n=9))  
      
    } else {
      
      stk_crop <- stk_crop 
      stk_crop[stk_crop >2 ] = 2
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(0, 2, 0.1)
      # zvalues <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4)
      myTheme <- BuRdTheme()
      myTheme$regions$col=colorRampPalette(c("snow","yellow","orange", "red", "darkred"))(length(zvalues)-1)
      myTheme$strip.border$col = "white"
      myTheme$axis.line$col = 'white'
      # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
      
    } 
    
    tiff(paste(oDir, "/plot_seasons_", var, "_", period, ".tif", sep=""), width=1300, height=800, pointsize=8, compression='lzw',res=150)
    
    print(levelplot(plot, at = zvalues, scales = list(draw=FALSE), names.attr=rep("", 8), layout=c(4, 2), xlab="", ylab="", par.settings = myTheme, colorkey = list(space = "bottom")) + layer(sp.polygons(mask))) # + layer(sp.polygons(geotopo, fill='white', alpha=0.3)))
    
    dev.off()
    
  } 
}




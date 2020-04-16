# Carlos Navarro 
# CIAT - CCAFS
# May 2018


#######################################
#### 01 Plots anomalies by seasons ####
#######################################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)

rcpList <- c("rcp26", "rcp45", "rcp60", "rcp85")
baseDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/anomalies_ens_v2"
perList <- c("2020_2049", "2040_2069", "2070_2099")
perListMod <- c("2030s", "2050s", "2080s")
varList <- c("dtr") # c("tmin", "tmax", "tmean", "prec", "dtr", "wsmean", "rsds") 
# varList <- c("tmean", "dtr")
seasons <- c("djf", "mam", "jja", "son", "ann")
id <- rep(c("DEF ", "MAM", "JJA", "SON", "ANUAL"), length(perList))
mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Departamentos.shp")
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Escenarios/evaluation"

for (rcp in rcpList) {
  
  perSeas <- expand.grid(seasons, perList)
  
  for (var in varList){
    
    stk <- stack(paste0(baseDir, "/", rcp, "/", perSeas[,2], "/", var, "_", perSeas[,1], ".tif"))
    stk_crop <- mask(crop(stk, extent(mask)), mask)
    
    if (var == "prec"){
      
      unit = "%"
      stk_crop[stk_crop > 30] = 30
      stk_crop[stk_crop < (-30)] = (-30)
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(-30, 30, 1) # Define limits
      myTheme <- BuRdTheme() # Define squeme of colors
      myTheme$regions$col=colorRampPalette(c("darkred", "red", "pink", "snow", "deepskyblue", "blue", "darkblue"))(length(zvalues)-1) # Set new colors
      myTheme$strip.border$col = "white" # Eliminate frame from maps
      myTheme$axis.line$col = 'white' # Eliminate frame from maps
      # myTheme=rasterTheme(region=brewer.pal('Blues', n=9))  
      
    } else if (var == "dtr") {
      
      unit = "°C"
      stk_crop <- stk_crop 
      stk_crop[stk_crop > 5 ] = 5
      stk_crop[stk_crop < 1 ] = 1
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(1, 5, 0.2)
      # zvalues <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4)
      myTheme <- BuRdTheme()
      myTheme$regions$col=colorRampPalette(c("yellow","orange", "red", "darkred"))(length(zvalues)-1)
      myTheme$strip.border$col = "white"
      myTheme$axis.line$col = 'white'
      # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
      
    } else if (var == "rsds") {
      
      unit = "Wm-2"
      stk_crop <- stk_crop 
      stk_crop[stk_crop > 7 ] = 7
      stk_crop[stk_crop < -3 ] = -3
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(-3, 7, 0.5)
      # zvalues <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4)
      myTheme <- BuRdTheme()
      myTheme=rasterTheme(region=rev(brewer.pal('PuOr', n=10)))
      myTheme$regions$col=colorRampPalette(c("#2d004b","#8073ac", "#f7f7f7", "#fee0b6", "#fdb863", "#e08214", "#b35806", "#7f3b08"))(length(zvalues)-1)
      myTheme$strip.border$col = "white"
      myTheme$axis.line$col = 'white'
      
    } else if (var == "wsmean") {
      
      unit = "m/s"
      stk_crop <- stk_crop 
      stk_crop[stk_crop > 0.5 ] = 0.5
      stk_crop[stk_crop < -0.5 ] = -0.5
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(-0.4, 0.4, 0.1)
      # zvalues <- c(0, 0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3, 3.5, 4)
      myTheme <- BuRdTheme()
      myTheme=rasterTheme(region=brewer.pal('BrBG', n=10))
      # myTheme$regions$col=colorRampPalette(c("yellow","orange", "red", "darkred"))(length(zvalues)-1)
      myTheme$strip.border$col = "white"
      myTheme$axis.line$col = 'white'
      # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
      
      
    }else {
      
      unit = "°C"
      stk_crop <- stk_crop 
      stk_crop[stk_crop > 5.2 ] = 5.2
      stk_crop[stk_crop < 0.5 ] = 0.5
      
      plot <- setZ(stk_crop, id)
      names(plot) <- id
      
      zvalues <- seq(0.5, 5.2, 0.1)
      # zvalues <- classIntervals(5, n = 25, style = "equal")
      myTheme <- BuRdTheme()
      myTheme$regions$col=colorRampPalette(c("yellow","orange", "red", "darkred"))(length(zvalues)-1)
      myTheme$strip.border$col = "white"
      myTheme$axis.line$col = 'white'
      # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
      
    } 
    
    tiff(paste(oDir, "/plot_seasons_", var, "_", rcp, ".tif", sep=""), width=2600, height=1000, pointsize=8, compression='lzw',res=200)
    
    print(levelplot(plot, at = zvalues,  
                    scales = list(draw=FALSE), 
                    names.attr=rep("", length(id)), 
                    layout=c(5, 3), 
                    main=list(paste(c("            DEF", "                           MAM", "                                        JJA", "                                                       SON", "                                                                      ANUAL", paste0("                               ", unit)), 
                                    sep=""),side=1,line=0.5, cex=0.8),
                    xlab="", 
                    ylab=list(paste(rev(perListMod), sep="        "), line=1, cex=0.9, fontface='bold'), 
                    par.strip.text=list(cex=0),
                    par.settings = myTheme, 
                    colorkey = list(space = "right", width=1.2, height=1)
    )
    + layer(sp.polygons(mask, lwd=0.8))
    )
    
    dev.off()
    
  }
  
}

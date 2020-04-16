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
bDir <- "D:/cenavarro/hnd_pnud/interpolations/average"
oDir <- "D:/cenavarro/hnd_pnud/interpolations/performance"
varList <- c("prec", "dtr", "tmax", "tmin", "tmean")
id <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
# mask <-readOGR("D:/cenavarro/hnd_pnud/region/Limites_Honduras_v3.shp",layer="Limites_Honduras_v3")
mask <- readOGR("D:/cenavarro/hnd_pnud/region/Limites_Departamentos.shp")

# Set libraries
require(raster)
require(maptools)
require(rgdal)

setwd(bDir)
if (!file.exists(oDir)) {dir.create(oDir)}

for (var in varList){
  
  stk_crop <- stack(paste0(bDir, "/", var, "_", 1:12, ".tif"))
  # stk_crop <- mask(crop(stk, extent(mask)), mask)
  
  if (var == "prec"){
    
    stk_crop[which(stk_crop[]>500)]=500
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    
    zvalues <- seq(0, 500, 25) # Define limits
    myTheme <- BuRdTheme() # Define squeme of colors
    myTheme$regions$col=colorRampPalette(c("khaki1", "skyblue1", "blue", "darkblue", "darkmagenta"))(length(zvalues)-1) # Set new colors
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
    stk_crop[which(stk_crop[]< 2)]= 2
    stk_crop[which(stk_crop[]>18)]= 18
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(2, 18, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("blue", "yellow", "orange", "orangered", "red"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  } else {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 8 )]= 8
    stk_crop[which(stk_crop[]>38)]= 38
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(8, 38, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  }
  
  # Save to file
  tiff(paste(oDir, "/plot_monthly_clim_", var, "_v2.tif", sep=""), width=2400, height=1200, pointsize=8, compression='lzw',res=200)
  print(levelplot(plot, at = zvalues, scales = list(draw=FALSE), layout=c(4, 3), xlab="", ylab="", par.settings = myTheme, 
                  colorkey = list(space = "right", width=1.2, height=1)
                  ) 
        + layer(sp.polygons(mask, lwd=0.8))
        )
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
library(grid)

# Set params
bDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/average_v2"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/performance_v2"
varList <- c("prec", "tmean", "dtr", "tmax", "tmin")
id <- c("djf", "mam", "jja", "son")
id_mod <-c("DEF", "MAM", "JJA", "SON")
# mask <-readOGR("D:/cenavarro/hnd_pnud/region/Limites_Honduras_v3.shp",layer="Limites_Honduras_v3")
mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Departamentos.shp")

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
    
    stk_crop[which(stk_crop[]>1300)]=1300
    
    plot <- setZ(stk_crop, id_mod)
    names(plot) <- toupper(id_mod)
    
    zvalues <- seq(0, 1400, 50) # Define limits
    myTheme <- BuRdTheme() # Define squeme of colors
    myTheme$regions$col=colorRampPalette(c("khaki1", "skyblue1", "blue", "darkblue", "darkmagenta"))(length(zvalues)-1) # Set new colors
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
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 2)]= 2
    stk_crop[which(stk_crop[]>18)]= 18
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(2, 18, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("blue", "yellow", "orange", "orangered", "red"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
    
  } else {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 8 )]= 8
    stk_crop[which(stk_crop[]>38)]= 38
    
    plot <- setZ(stk_crop, id_mod)
    names(plot) <- id_mod
    zvalues <- seq(8, 38, 2)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  }
  
  tiff(paste(oDir, "/plot_seasons_clim_", var, ".tif", sep=""), width=1800, height=1200, pointsize=8, compression='lzw',res=200)
  
  print(levelplot(plot, at = zvalues, 
                  scales = list(draw=FALSE), 
                  layout=c(2, 2),
                  xlab="", 
                  ylab="", 
                  par.settings = myTheme, 
                  # margin=F,
                  colorkey = list(space = "bottom", width=1.2, height=1, labels=list(cex=1.2)))
        + layer(sp.polygons(mask, lwd=0.8))
        )
       
  if (var == "prec"){
    grid.text(expression("mm"), 0.2, 0, hjust=5.7, vjust=-6.5, gp=gpar(fontsize=12))  
  } else {
    grid.text(expression("°C"), 0.2, 0, hjust=8, vjust=-6.0, gp=gpar(fontsize=12))  
  }
  
   
  dev.off()
  
} 





##########################
#### 03 Annual Plots  ####
##########################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)
library(grid)

# Set params
bDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/average_v2"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/performance_v2"
varList <- c("prec", "tmean", "tmax", "tmin")
id <- c("ANN")
id_mod <-c("ANN")
# mask <-readOGR("D:/cenavarro/hnd_pnud/region/Limites_Honduras_v3.shp",layer="Limites_Honduras_v3")
mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Departamentos.shp")

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
    
    stk_crop[which(stk_crop[]>3200)]=3200
    
    plot <- setZ(stk_crop, id_mod)
    names(plot) <- toupper(id_mod)
    
    zvalues <- seq(0, 3200, 100) # Define limits
    myTheme <- BuRdTheme() # Define squeme of colors
    myTheme$regions$col=colorRampPalette(c("khaki1", "skyblue1", "blue", "darkblue", "darkmagenta"))(length(zvalues)-1) # Set new colors
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
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 2)]= 2
    stk_crop[which(stk_crop[]>18)]= 18
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(2, 18, 2)
    # zvalues <- c(-8, -4, 0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("blue", "yellow", "orange", "orangered", "red"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
    
  } else {
    
    stk_crop <- stk_crop / 10
    stk_crop[which(stk_crop[]< 8 )]= 8
    stk_crop[which(stk_crop[]>38)]= 38
    
    plot <- setZ(stk_crop, id)
    names(plot) <- id
    zvalues <- seq(8, 38, 2)
    myTheme <- BuRdTheme()
    myTheme$regions$col=colorRampPalette(c("darkblue", "yellow", "orange", "red", "darkred"))(length(zvalues)-1)
    myTheme$strip.border$col = "white"
    myTheme$axis.line$col = 'white'
    # myTheme=rasterTheme(region=brewer.pal('YlOrRd', n=9))  
    
  }
  
  tiff(paste(oDir, "/plot_annual_clim_", var, ".tif", sep=""), width=1800, height=1200, pointsize=8, compression='lzw',res=200)
  
  print(levelplot(plot, at = zvalues, 
                  scales = list(draw=FALSE), 
                  # layout=c(2, 2), 
                  xlab="", 
                  ylab="", 
                  par.settings = myTheme, 
                  margin=F,
                  colorkey = list(space = "bottom", width=1.2, height=1, labels=list(cex=1.2)))
        + layer(sp.polygons(mask, lwd=0.8))
  )
  
  if (var == "prec"){
    grid.text(expression("mm"), 0.2, 0, hjust=5.7, vjust=-8, gp=gpar(fontsize=12))  
  } else {
    grid.text(expression("°C"), 0.2, 0, hjust=8, vjust=-6.5, gp=gpar(fontsize=12))  
  }
  
  
  dev.off()
  
} 

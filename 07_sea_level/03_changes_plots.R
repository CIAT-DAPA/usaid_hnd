# Carlos Navarro 
# CIAT - CCAFS
# November 2012


#######################################
#### 01 Plots anomalies by periods ####
#######################################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)
require(viridis)

rcpList <- c("rcp45", "rcp85")
rcpList_names <- c("RCP 4.5", "RCP 8.5")

baseDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar/anomalies"
perList <- c("2026_2045", "2046_2065", "2076_2095")
var <- "zos"
id <- c("2030s ", "2050s", "2070s", 
        "2030s ", "2050s", "2070s"
)
# mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Honduras_v3.shp")
mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Climate & Geodata/AdminBoundaries/Global/10m/10m-admin-0-countries.shp")
mask_eez <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar/Limite_Marino/eez.shp")
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar/evaluation"


perXrcp <- expand.grid(perList, rcpList)

stk <- stack(paste0(baseDir, "/", perXrcp[,2], "/ensemble/", var, "_", perXrcp[,1], "_avg.asc")) *1000
# stk_crop <- mask(crop(stk, extent(mask)), mask)

unit = "mm"

plot <- setZ(stk, id)
names(plot) <- id

zvalues <- seq(-100, 300, 10) # Define limits
myTheme <- BuRdTheme() # Define squeme of colors
myTheme$regions$col=colorRampPalette(c("darkred", "red", "#edf8b1", "#c7e9b4", "#7fcdbb", "#41b6c4", "#1d91c0", "#225ea8", "#253494", "#081d58"))(length(zvalues)-1) # Set new colors
myTheme$strip.border$col = "white" # Eliminate frame from maps
myTheme$axis.line$col = 'white' # Eliminate frame from maps
# myTheme=rasterTheme(region = rev(cividis(10)))
# myTheme=rasterTheme(region=brewer.pal('YlGnBu', n=9))

tiff(paste(oDir, "/changes_sea_level_", var, "_v3.tif", sep=""), width=2200, height=1200, pointsize=8, compression='lzw',res=200)

print(levelplot(plot, at = zvalues,  
                scales = list(draw=FALSE), 
                names.attr=rep("", length(id)), 
                layout=c(3, 2), 
                main=list(paste(c("                       2030s", 
                                  "                                                        2050s", 
                                  "                                                                                        2080s", 
                                  paste0("                                        ", unit)), 
                                sep=""),side=1,line=0.5, cex=0.8),
                xlab="", 
                ylab=list(paste(rev(rcpList_names), sep="        "), line=1, cex=0.9, fontface='bold'), 
                par.strip.text=list(cex=0),
                par.settings = myTheme, 
                colorkey = list(space = "right", width=1.2, height=1)
)

+ layer(sp.polygons(mask_eez, lwd=0.8, col = "yellow"))
+ layer(sp.polygons(mask, lwd=0.8))
)

dev.off()



# Carlos Navarro 
# CIAT - CCAFS
# July 2017


# Set params
bDir <- "D:/cenavarro/hnd_pnud/interpolations/average"
oDir <- bDir
varList <- c("dtr", "tmax", "tmin", "tmean", "prec")
mask <-readOGR("D:/cenavarro/hnd_pnud/region/Limites_Honduras_v3.shp",layer="Limites_Honduras_v3")

# Set libraries
require(raster)
require(maptools)
require(rgdal)

# # Temporal dir for raster library
# if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
# rasterOptions(tmpdir= paste0(oDir, "/tmp"))

setwd(bDir)
# if (!file.exists(oDir)) {dir.create(oDir)}

for (i in 1:length(varList)){
  
  cat("Croping ", varList[i], "/n")
  var <- varList[i] 
  
  rsStk <- stack(paste0(var, "_", 1:12, ".asc"))
  
  if (!file.exists(paste0(oDir, "/", var, "_", 12, ".tif"))) {
    
    #rsCrop <- resample(crop(rsStk, extent(mask)), mask)
    rsMask <- mask(crop(rsStk, extent(mask)), mask)
    
    if (var == "prec"){
      rsMask <- round(rsMask, digits = 0)
    } else if (var == "rhum"){
      rsMask <- round(rsMask * 100, digits = 0)
    } else if (var == "dtr") {
      rsMask[which(rsMask[]<2)]=2
      rsMask <- round(rsMask * 10, digits = 0)
    } else {
      rsMask <- round(rsMask * 10, digits = 0)
    }
    
    for (i in 1:12){
      
      oTif <- paste0(oDir, "/", var, "_", i, ".tif")
      tifWrite <- writeRaster(rsMask[[i]], oTif, format="GTiff", overwrite=T, datatype='INT2S')
      cat(paste0(" ", var, "_",i, " cut done/n"))
      
    }
  }
}

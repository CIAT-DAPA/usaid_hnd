# Carlos Navarro 
# CIAT - CCAFS
# July 2017

# Set params
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_yearly/average"
oDir <- paste0(bDir, "/tif")
years <- 1990:2014
varList <- c("dtr", "tmax", "tmin", "tmean")
# varList <- c("prec")
mask <-"D:/cenavarro/hnd_usaid/04_interpolation/region/ZOI.shp"

# Temporal dir for raster library
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

cut_mask <- function(bDir="", oDir="", yr="", varList="", mask=""){
  
  # Set libraries
  require(raster)
  require(maptools)
  require(rgdal)
  
  mask <- readOGR(mask, , layer="ZOI")
  
  setwd(bDir)
  if (!file.exists(oDir)) {dir.create(oDir)}
  
  # for (yr in years){
  
  for (i in 1:length(varList)){
    
    cat("Croping ", varList[i], yr, "/n")
    var <- varList[i] 
    
    rsStk <- stack(paste0(var, "_", yr, "_", 1:12, ".asc"))
    
    # if (!file.exists(paste0(oDir, "/", var, "_", yr, "_", 12, ".tif"))) {
    
    # rsCrop <- resample(crop(rsStk, extent(mask)), mask)
    rsMask <- mask(crop(rsStk, extent(mask)), mask)
    
    if (var == "prec"){
      rsMask <- round(rsMask, digits = 0)
    } else if (var == "rhum"){
      rsMask <- round(rsMask * 100, digits = 0)
    } else {
      rsMask <- round(rsMask * 10, digits = 0)
    }
    
    for (i in 1:12){
      
      oTif <- paste0(oDir, "/", var, "_", yr, "_", i, ".tif")
      tifWrite <- writeRaster(rsMask[[i]], oTif, format="GTiff", overwrite=T, datatype='INT2S')
      cat(paste0(" ", var, "_",i, " cut done/n"))
      
    }
  }
  
  
}


## Parameters ###
sfStop()
library(snowfall)
sfInit(parallel=T,cpus=12) #initiate cluster

# Export functions
sfExport("cut_mask")

#export variables
sfExport("bDir")
sfExport("oDir")
sfExport("varList")
sfExport("mask")

control <- function(i) { #define a new function
  
  # Set libraries
  require(raster)
  require(maptools)
  require(rgdal)
  
  cat(" .> ", paste("\t Year ", i, sep=""), "\t processing!\n")
  cut_mask(bDir, oDir, i, varList, mask)
  
}

system.time(sfSapply(as.vector(years), control))


#stop the cluster calculation
sfStop()





### For whole period


# Set params
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_climatology/average"
oDir <- paste0(bDir, "/tif")
varList <- c("dtr", "prec", "tmax", "tmin", "tmean")
mask <-readOGR("D:/cenavarro/hnd_usaid/04_interpolation/region/ZOI.shp",layer="ZOI")

# Set libraries
require(raster)
require(maptools)
require(rgdal)

# Temporal dir for raster library
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

setwd(bDir)
if (!file.exists(oDir)) {dir.create(oDir)}

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

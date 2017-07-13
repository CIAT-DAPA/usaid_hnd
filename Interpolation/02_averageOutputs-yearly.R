# Carlos Navarro
# CCAFS / CIAT
# October 2016

###########################
#### 01 Average folds  ####
###########################

require(raster)

# Set params
varList <- c("rain")
# varList <- c("rain", "tmin", "tmax")#
bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_yearly"
oDir <- paste0(bDir, "/average")
nfolds <- 25

# Set oDir
if (!file.exists(oDir)) {dir.create(oDir, recursive = TRUE)}

# Temporal dir for raster library
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

for (i in 1:length(varList)){
  
  var <- varList[i] 
  if (var == "rain"){
    years <- 2002:2015
    varmod <- "prec"
  } else {
    years <- 1990:2014
    varmod <- var
  }
  
  iDir <- paste0(bDir, "/", var)

  for (yr in years){
    
    for (mth in 1:12) {
      
      cat("Averaging over", varmod, yr, mth, "\n")
      
      oAvg <- paste(oDir, "/", varmod,"_", yr, "_", mth, ".asc", sep="")
      
      if (!file.exists(oAvg)) {
        
        mthStack <- stack(paste(iDir, "/", yr, "/fold-",1:nfolds, "/tile-1/", varList[i], "_", mth, ".asc", sep=""))
        
        if (varList[i] == "rain"){
          mthStack[which(mthStack[]<0)]=0
        }
        
        cat("Mean Stack\n")
        meanRaster <- mean(mthStack)
        
        # cat("Mean Std\n")
        # fun <- function(x) { sd(x) }
        # stdRaster <- calc(mthStack, fun)
        
        cat("Writing\n")
        writeRaster(meanRaster, oAvg, format="ascii", overwrite=T)
        # writeRaster(stdRaster, paste(oDir, "/", var, "_", mth, "_std.asc", sep=""), format="ascii", overwrite=F)
        
      }
      
      #If run was successful then erase .cov file, and zip asciigrids
      
     #cat("Run was successful, compressing garbage \n")
    #  for (fold in 1:nfolds){
     #   asc <- paste(iDir, "/", yr, "/fold-", fold, "/tile-1/", varList[i], "_", mth, ".asc", sep="")
      #  zip <- paste(iDir, "/", yr, "/fold-", fold, "/tile-1/", varList[i], "_", mth, ".zip", sep="")
       # system(paste("7za a -tzip ", zip, asc))
        #file.remove(asc)
      }
      
    }
    
  }
    
}



##############################
#### 02 Tmean, dtr Calcs  ####
##############################

require(raster)

bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_yearly/average"
years <- 1990:2014
oDir <- bDir

for (yr in years){
  
  for(mth in 1:12){
    
    cat("Calculate tmean and drt", yr, mth, "\n")
    
    tmax <- raster(paste0(bDir, "/tmax_", yr, "_", mth, ".asc"))
    tmin <- raster(paste0(bDir, "/tmin_", yr, "_", mth, ".asc"))
    
    tmean <- (tmax + tmin) / 2
    dtr <- (tmax - tmin)
    
    writeRaster(tmean, paste(oDir, "/tmean_", yr, "_", mth, ".asc", sep=""), format="ascii", overwrite=T)
    writeRaster(dtr, paste(oDir, "/dtr_", yr, "_", mth, ".asc", sep=""), format="ascii", overwrite=T)
    
  }
  
}


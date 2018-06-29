require(raster)
require(maptools)
library(rgeos)
library(rgdal)

iDir <- "D:/cenavarro/hnd_pnud/interpolations"
oDir <- "D:/cenavarro/hnd_pnud/interpolations/average"

varList <- c("rain","tmin", "tmax")

## Average of all folds
if (!file.exists(oDir)) {dir.create(oDir, recursive = TRUE)}

for (i in 1:length(varList)){
 
  var <- varList[i] 
  
  for (mth in 1:12) {
    
    cat("Averaging over", var, mth, "\n")
    if (!file.exists(paste(oDir, "/", var, "_", mth, ".asc", sep=""))) {
      
      mthStack <- stack(paste(iDir, "/", varList[i], "/fold-", 1:25, "/tile-1/", varList[i], "_", mth, ".asc", sep=""))
      
      if (varList[i] == "rain"){
        var <- "prec"
        mthStack[which(mthStack[]<0)]=0
#         mthStack[which(mthStack[]>1400)]=1400
      }
        
      cat("Mean Stack\n")
      meanRaster <- mean(mthStack)
      
      # cat("Mean Std\n")
      # fun <- function(x) { sd(x) }
      # stdRaster <- calc(mthStack, fun)
      
      cat("Writing\n")
      writeRaster(meanRaster, paste(oDir, "/", var,"_", mth, ".asc", sep=""), format="ascii", overwrite=T)
      # writeRaster(stdRaster, paste(oDir, "/", var, "_", mth, "_std.asc", sep=""), format="ascii", overwrite=F)
      
    }
    
  }
  
}


## Mean temperature calculation
cat("Calculate tmean\n")

for(mth in 1:12){
  
  tmax <- raster(paste0(oDir, "/tmax_", mth,".asc"))
  tmin <- raster(paste0(oDir, "/tmin_", mth,".asc"))
  tmean <- (tmax + tmin) / 2
  dtr <- (tmax - tmin)
  
  writeRaster(dtr, paste(oDir, "/dtr_", mth, ".asc", sep=""), format="ascii", overwrite=T)
  writeRaster(tmean, paste(oDir, "/tmean_", mth, ".asc", sep=""), format="ascii", overwrite=T)
  
}




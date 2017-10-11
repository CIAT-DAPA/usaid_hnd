### Author: Carlos Navarro c.e.navarro@cgiar.org
### Date: August 2017
# 
# rcp <- "rcp26"
# source("02-CMIP5_GCM_Downscaling.R")

# Load libraries
require(raster)
require(ncdf)
require(maptools)
require(rgdal)

# Load parameters
bDir  <- "W:/05_downscaling"
bslDir <- "W:/04_interpolation/outputs_climatology_v2/average"
mask <- raster("W:/04_interpolation/region/v3/mask.nc")
varList <- c("prec", "tmin", "tmax")
# rcpList <- c("rcp26", "rcp45", "rcp60", "rcp85")
perList <- c("2016_2035", "2026_2045", "2036_2055", "2046_2065")

for (var in varList){
  
  ### Load baseline
  #   bsl <- stack(paste0(bslDir, "/", var, "_", 1:12, ".asc"))
  
  #   for (rcp in rcpList){
  
  gcmList <- list.dirs(paste0(bDir, "/anomalies_res/", rcp), recursive = FALSE, full.names = FALSE)
  gcmList <- gcmList [! gcmList %in% "ensemble"]
  
  for (gcm in gcmList) {
    
    for (period in perList) {
      
      anomDir <- paste0(bDir, "/anomalies_res/", rcp, "/", gcm, "/", period)
      oDir <- paste0(bDir, "/downscaled/", rcp, "/", gcm, "/", period)
      if (!file.exists(oDir)) {dir.create(oDir, recursive=T)}
      
      cat("Donwscaling process over ", rcp, gcm, var, period, "\n")
      
      oDwl <- paste0(oDir, "/", var, ".nc")
      
      if (!file.exists(oDwl)){
        
        ## Load anomalies
        anom <- stack(paste0(anomDir, "/", var, ".nc"))
        
        #           if (var == "prec"){
        # 
        #             centroids=rasterToPoints(anom)
        #             df <- data.frame(centroids)
        #             
        #             value=df[,3]
        #             
        #             
        #             qdev=quantile(value,conf,na.rm=T)
        #             qdev=data.frame(id=names(qdev), values=unname(qdev), stringsAsFactors=FALSE)
        #             
        #             values(anomNc) <- ifelse(values(anomNc) >=qdev$values, qdev$values, values(anomNc)) 
        #             
        #             
        #           } else {
        #             anomNc <- futAvgNc - curAvgNc  
        #           }
        
        if (var == "prec"){
          del <- bsl * abs( 1 + anom)
        } else {
          del <- ( bsl + anom ) * 10
        }
        
        #           del_msk <- crop(del, extent(mask))
        #           del_msk <- mask(del_msk, mask)
        #           
        writeRaster(del, oDwl, overwrite=F)
        
        
      }
      
      
      if (var == "tmax"){
        
        cat("Donwscaling process over ", rcp, gcm, "tmean", "\n")
        
        ## Calcular temperatura media
        
        oTmean <- paste0(oDir, "/tmean",".nc")
        oDtr <- paste0(oDir, "/dtr",".nc")
        
        if (!file.exists(oDtr)){
          del_tx <- stack(paste0(oDir, "/tmax", ".nc"))
          del_tn <- stack(paste0(oDir, "/tmin", ".nc"))
          del <- (del_tx + del_tn) / 2
          dtr <- (del_tx - del_tn)
          
          #     del <- crop(del, extent(mask))
          #     del <- mask(del, mask)
          writeRaster(del, oTmean)
          writeRaster(dtr, oDtr)
          
        }
        
      }
      
      
    }
    
  }
  
  #   }  
  
  cat("Ensemble over: ", rcp, "\n")
  varList <- c("prec", "tmin", "tmax", "tmean", "dtr")
  
  setwd(paste(bDir, "/downscaled/", rcp, sep=""))
  
  for (period in perList) {
    
    oDirEns <- paste0(bDir, "/downscaled_ensemble/", rcp, "/", period)
    if (!file.exists(oDirEns)) {dir.create(oDirEns, recursive=T)}
    
    if (!file.exists(paste(oDirEns, "/", var, "_12_sd.tif", sep=""))) {
      
      for (mth in 1:12){
        
        fun <- function(x,y) { raster(x, band=y) }
        gcmStack <- stack(lapply(paste0(gcmList, "/", period, "/", var, ".nc"), FUN=fun, y=mth))
        
        gcmMean <- mean(gcmStack)
        fun_std <- function(x) { sd(x) }
        gcmStd <- calc(gcmStack, fun_std)
        
        if (var == "prec"){
          gcmMean <- gcmMean * 100
          gcmStd <- gcmStd * 100
        } else {
          gcmMean <- gcmMean * 10
          gcmStd <- gcmStd * 10
        }
        
        gcmMean <- writeRaster(gcmMean, paste(oDirEns, "/", var, "_", mth, '.tif',sep=''), format="GTiff", overwrite=T, datatype='INT2S')
        gcmStd <- writeRaster(gcmStd, paste(oDirEns, "/", var, "_", mth, "_sd.tif", sep=""), format="GTiff", overwrite=T, datatype='INT2S')
        
        
      }
      
    }
    
    
  }
  
  
  
  cat("Seasonal Calcs ensemble over: ", rcp, "\n")
  varList <- c("prec", "tmin", "tmax", "tmean", "dtr")
  
  # List of seasons
  seasons <- list("djf"=c(12,1,2), "mam"=3:5, "jja"=6:8, "son"=9:11, "ann"=1:12)
  
  for (period in perList) {
    
    oDirEns <- paste0(bDir, "/downscaled_ensemble/", rcp, "/", period)
    
#     for (var in varList){
      
      # Load averages files 
      iAvg <- stack(paste(oDirEns,'/', var, "_", 1:12, ".tif",sep=''))
      
      # Loop throught seasons
      for (i in 1:length(seasons)){
        
        
        if (!file.exists(paste(oDirEns,'/', var, "_", names(seasons[i]), '.tif',sep=''))){ 
          
          cat("Calcs ", var, names(seasons[i]), "\n")
          
          if (var == "prec"){
            
            sAvg = calc(iAvg[[c(seasons[i], recursive=T)]],fun=function(x){sum(x,na.rm=any(!is.na(x)))})
            
          } else {
            
            sAvg = calc(iAvg[[c(seasons[i], recursive=T)]],fun=function(x){mean(x,na.rm=T)})
            
          }
          
          writeRaster(sAvg, paste(oDirEns,'/', var, "_", names(seasons[i]), '.tif',sep=''),format="GTiff", overwrite=T, datatype='INT2S')
          
        }
        
      } 
      
#     }  
    
  }
  
}


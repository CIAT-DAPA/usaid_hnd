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
bDir  <- "D:/cenavarro/hnd_pnud/downscaling/anomalies_v2"
bslDir <- "S:/observed/gridded_products/terra-climate/30yr_1981_2010"
bslDir_out <- "D:/cenavarro/hnd_pnud/interpolations/average_v2"
dDir <- "D:/cenavarro/hnd_pnud/downscaling/downscaled_v2"
mask <- readOGR("D:/cenavarro/hnd_pnud/region/Limites_Honduras_v3.shp")
varList <- c("rsds", "wsmean") # "tmin", "tmax", prec
# rcpList <- c("rcp26", "rcp45", "rcp60", "rcp85")
rcp <- "rcp26"
perList <- c("2020_2049", "2040_2069", "2070_2099")


for (var in varList){
  
  if (!file.exists(paste0(bslDir_out, "/", var, "_12.tif"))){
    
    ### Load baseline
    bsl <- stack(paste0(bslDir, "/", var, "_", 1:12, ".tif"))
    bsl <- mask(bsl, mask)
    bsl <- crop(bsl, extent(mask))
    
    for (i in 1:12){
      oBsl <- paste0(bslDir_out, "/", var, "_", i,".tif")
      writeRaster(bsl[[i]], oBsl, format="GTiff", overwrite=T, datatype='INT2S')  
    }
    
  }
  
  bsl <- stack(paste0(bslDir_out, "/", var, "_", 1:12, ".tif"))
  
  # gcmList <- list.dirs(paste0(bDir, "/", rcp), recursive = FALSE, full.names = FALSE)
  gcmList <- c("csiro_mk3_6_0", "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "giss_e2_r", "ipsl_cm5a_lr", 
               "miroc_esm", "miroc_esm_chem", "miroc_miroc5", "mohc_hadgem2_es", "mri_cgcm3", "nimr_hadgem2_ao")
  gcmList <- gcmList [! gcmList %in% "ensemble"]
  
  for (gcm in gcmList) {
    
    for (period in perList) {
      
      anomDir <- paste0(bDir, "/", rcp, "/", gcm, "/", period)
      oDir <- paste0(dDir, "/", rcp, "/", gcm, "/", period)
      if (!file.exists(oDir)) {dir.create(oDir, recursive=T)}
      
      cat("Donwscaling process over ", rcp, gcm, var, period, "\n")
      
      if (!file.exists(paste0(oDir, "/", var, "_12.tif"))){
        
        ## Load anomalies
        anom <- stack(paste0(anomDir, "/", var, "_res.nc"))
        anom <- resample(anom, bsl)
        
        if (var == "prec"){
          del <- bsl * abs( 1 + anom)
        } else if (var == "rsds") {
          del <- bsl + ( anom )
        } else if (var == "wsmean") {
          del <- ( bsl + anom ) * 10
        } else {
          del <- bsl + ( anom * 10 )
        }
        
        for (i in 1:12){
          oDwl <- paste0(oDir, "/", var, "_", i,".tif")
          writeRaster(del[[i]], oDwl, format="GTiff", overwrite=T, datatype='INT2S')  
        }
        
        
        
      }
      
      
      # if (var == "tmax"){
      #   
      #   cat("Donwscaling process over ", rcp, gcm, "tmean", "\n")
      #   
      #   ## Calcular temperatura media
      #   for (i in 1:12){
      #     
      #     oTmean <- paste0(oDir, "/tmean_", i,".tif")
      #     oDtr <- paste0(oDir, "/dtr_", i,".tif")
      #     
      #     if (!file.exists(oDtr)){
      #       del_tx <- stack(paste0(oDir, "/tmax_", i, ".tif"))
      #       del_tn <- stack(paste0(oDir, "/tmin_", i, ".tif"))
      #       del <- (del_tx + del_tn) / 2
      #       dtr <- (del_tx - del_tn)
      #       
      #       #     del <- crop(del, extent(mask))
      #       #     del <- mask(del, mask)
      #       writeRaster(del, oTmean, format="GTiff", overwrite=T, datatype='INT2S')
      #       writeRaster(dtr, oDtr, format="GTiff", overwrite=T, datatype='INT2S')
      #       
      #     }
      #   }
      #   
      # }
      
      
    }
    
  }
  
}  

  
cat("Ensemble over: ", rcp, "\n")


for (var in varList){

  setwd(paste(dDir, "/", rcp, sep=""))
  
  for (period in perList) {
    
    oDirEns <- paste0(dDir, "_ens/", rcp, "/", period)
    if (!file.exists(oDirEns)) {dir.create(oDirEns, recursive=T)}
    
    if (!file.exists(paste(oDirEns, "/", var, "_12_sd.tif", sep=""))) {
      
      for (mth in 1:12){
        
        gcmStack <- stack(paste0(gcmList, "/", period, "/", var, "_",mth, ".tif"))
        
        gcmMean <- mean(gcmStack)
        fun_std <- function(x) { sd(x) }
        gcmStd <- calc(gcmStack, fun_std)
        
        if (var == "prec"){
          gcmMean <- gcmMean 
          gcmStd <- gcmStd 
        } else {
          gcmMean <- gcmMean 
          gcmStd <- gcmStd 
        }
        
        gcmMean <- writeRaster(gcmMean, paste(oDirEns, "/", var, "_", mth, '.tif',sep=''), format="GTiff", overwrite=T, datatype='INT2S')
        gcmStd <- writeRaster(gcmStd, paste(oDirEns, "/", var, "_", mth, "_sd.tif", sep=""), format="GTiff", overwrite=T, datatype='INT2S')
        
        
      }
      
    }
    
    
  }
  
  
  
  cat("Seasonal Calcs ensemble over: ", rcp, "\n")
  # varList <- c("prec", "tmin", "tmax", "tmean", "dtr")
  
  # List of seasons
  seasons <- list("djf"=c(12,1,2), "mam"=3:5, "jja"=6:8, "son"=9:11, "ann"=1:12)
  
  for (period in perList) {
    
    oDirEns <- paste0(dDir, "_ens/", rcp, "/", period)
    
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



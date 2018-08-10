##################################################################
### Calcs secundary variables (rsds, wsmean) for monthly timestep
### Author: Carlos Navarro
### CIAT-CCAFS
##################################################################

require(raster)
require(ncdf)
library(attempt)

dirgcm <-  "T:/gcm/cmip5/raw/monthly"
dirout <- "D:/cenavarro/hnd_pnud/downscaling/anomalies_v2"
mask <- "D:/cenavarro/hnd_pnud/region/hnd_msk.nc"
ens <- "r1i1p1"
rcpList <- c("rcp26", "rcp45", "rcp60", "rcp85")
basePer <- "1981_2010"
futPer <- c("2020_2049", "2040_2069", "2070_2099")
var <- "rsds"   #'rsds'
varmod <- "rsds"
gcmList <- c(
             "bcc_csm1_1","bcc_csm1_1_m", "cesm1_cam5", "csiro_mk3_6_0", "fio_esm",
             "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "giss_e2_r", "ipsl_cm5a_lr",
             "miroc_esm", "miroc_esm_chem", "miroc_miroc5", "mohc_hadgem2_es",
             "mri_cgcm3", "ncar_ccsm4", "ncc_noresm1_m", "nimr_hadgem2_ao"
             )
#gcmlist <-  list.dirs(paste0(dirgcm,"/", rcp), recursive = FALSE, full.names = FALSE) 
bbox <- extent(raster(mask))
cdopath <- "D:/cenavarro/CDO/cdo.exe"

for (gcm in gcmList){
  
  for(rcp in rcpList){
    
    if (rcp == "historical"){dirrcp <- paste0(dirgcm, "/", rcp)} else {dirrcp <- paste0(dirgcm, "/", rcp)}
    
    for (period in futPer){
      
      dirtempHist <- paste0(dirout,"/historical/", basename(gcm))
      # dirnorm<- paste0(dirout,"/historical/", basename(gcm),"/1981_2005")
      dirtempFut = paste0(dirout,'/',rcp,"/", basename(gcm))
      dirnorm2 <- paste0(dirout,'/',rcp,"/", basename(gcm),"/", period)
      
      if (!file.exists(paste0(dirnorm2,'/',varmod,'_res.nc'))) {
        
        Hncvar <- list.files(path=paste0(dirgcm, "/historical/", gcm, "/r1i1p1"), pattern=paste0(var, "_Amon*"), full.names=TRUE)
        ncvar <- list.files(path=paste0(dirrcp, "/", gcm, "/r1i1p1"), pattern=paste0(var, "_Amon*"), full.names=TRUE)    
        
        sYr <- strsplit(period, '_')[[1]][1]
        eYr <- strsplit(period, '_')[[1]][2]
        
        if (length(ncvar) > 0 && length(Hncvar) > 0){
          
          cat(basename(gcm),"historical",'\n')
          
          
          if (!file.exists(dirtempHist)) {dir.create(dirtempHist, recursive=T)}    
          # if (!file.exists(dirnorm)) {dir.create(dirnorm, recursive=T)}
          
          ncsel_h = paste0(dirtempHist, "/historical_", var, "_1981_2005_day_sely.nc")
          nccut_h = paste0(dirtempHist, "/historical_", var, "_1981_2005_day_cut.nc")
          # ncmon_h = paste0(dirtempHist, "/historical_", var, "_1981_2005_day_mon.nc")
          ncnor_h = paste0(dirtempHist, "/historical_", var, "_1981_2005_day_ymon.nc")
          # ncres_h = paste0(dirnorm, "/historical_", var, "_1981_2005_day_nor.nc")
          
          if (!file.exists(ncnor_h)) {
            
            # try_catch(
            system(paste(cdopath, " -seldate,1981-01-01,2005-12-31 ", Hncvar, " ", ncsel_h, sep=""))
            # .e = ~ stop(.x))
            
            system(paste(cdopath, " sellonlatbox,",bbox@xmin+360-5,",",bbox@xmax+360+5,",",bbox@ymin-5,",",bbox@ymax+5," ", ncsel_h, " ", nccut_h,sep=""))
            # system(paste(cdopath, " monavg ",nccut_h, " ", ncmon_h,sep=""))
            system(paste(cdopath, " ymonavg ",nccut_h, " ", ncnor_h,sep=""))
            # system(paste(cdopath, " remapbil,",ncmask,' ',ncnor_h, " ", ncres_h,sep=""))
            # system(paste(cdopath, " splitmon ",ncnor_h, " ", dirtempHist,'/',var,'_',sep=""))
            
            # file.remove(ncsel_h)
            # file.remove(nccut_h)
            # file.remove(ncmon_h)
            
          }
          
          cat(basename(gcm),rcp,'\n')
          
          if (!file.exists(dirtempFut)) {dir.create(dirtempFut, recursive=T)}  
          if (!file.exists(dirnorm2)) {dir.create(dirnorm2, recursive=T)}  
          
          ncsel=paste0(dirtempFut, "/",rcp,"_", var, "_", period, "_day_sely.nc")
          nccut=paste0(dirtempFut, "/",rcp,"_", var, "_", period, "_day_cut.nc")
          # ncmon=paste0(dirtempFut, "/",rcp,"_", var, "_", period, "_day_mon.nc")
          ncnor=paste0(dirtempFut, "/",rcp,"_", var, "_", period, "_day_ymon.nc")
          # ncres=paste0(dirnorm2, "/",rcp,"_", var, "_", period, "_day_nor.nc")
          
          if (!file.exists(ncnor)) {
            
            # try_catch(
            system(paste(cdopath, " -seldate,", sYr, "-01-01,", eYr, "-12-31 ", ncvar, " ", ncsel, sep=""))
            # .e = ~ stop(.x))
            
            system(paste(cdopath, " sellonlatbox,",bbox@xmin+360-5,",",bbox@xmax+360+5,",",bbox@ymin-5,",",bbox@ymax+5," ", ncsel, " ", nccut,sep=""))
            # system(paste(cdopath, " monavg ",nccut, " ", ncmon,sep=""))
            system(paste(cdopath, " ymonavg ",nccut, " ", ncnor,sep=""))
            
            file.remove(ncsel)
            file.remove(nccut)
            # file.remove(ncmon)
            
          }
          # if (!file.exists(ncres)) {
          #   system(paste(cdopath, " remapbil,",ncmask,' ',ncnor, " ", ncres,sep=""))
          # }
          # if (!file.exists(paste0(dirtempFut,'/',var,'_12.nc'))) {
          #   system(paste("cdo splitmon ",ncnor, " ", dirtempFut,'/',var,'_',sep=""))
          # }
          
          cat('..Change',basename(gcm),rcp, period,'\n')
          diranom <- dirnorm2
          if (!file.exists(diranom)) {dir.create(diranom, recursive=T)}  
          
          stk <- stack()
          mon=c(paste0(0,1:9),10:12)
          if (!file.exists(paste0(diranom,'/',varmod,'_res.nc'))) {
            
            for(i in 1:12){
              
              hist=stack(ncnor_h)[[i]]
              fut= stack(ncnor)[[i]]
              #         histP=rasterToPoints(hist)
              #         futP=rasterToPoints(fut)
              #         summary(futP[,3]-histP[,3])
              
              if(res(fut) != res(hist)){
                hist <- resample(hist, fut)
              }
              
              if (var == "prec"){
                anom=(fut-hist)/hist  
              } else {
                anom=fut-hist
              }
              
              xmin(anom) <- xmin(anom) - 360
              xmax(anom) <- xmax(anom) - 360
              
              #         extent(anom) <- extent(bbox@xmin,bbox@xmax,bbox@ymin,bbox@ymax)
              
              stk <- stack(stk, anom)
            }
            
            stk <- resample(stk, raster(mask))
            out <- writeRaster(stk, paste0(diranom,'/',varmod,'_res.nc'), format="CDF", overwrite=T)
            
          }
          
          file.remove(ncnor)
          # file.remove(ncnor_h)
          
        }      
        
      }
      
    }
    
  }
  
}

# 
# for(rcp in rcpList){
# 
#   for(i in 1:12){
# 
#     # ens<-ens[which(file.exists(ens))]
#     ensemble=mean(stack(paste0(dirout,'/anomalies/',rcp,'/',gcmlist,'/',var, "_",i,'.nc')))
#     direns=paste0(dirout,'/anomalies/',rcp,'/ensemble')
#     if (!file.exists(direns)) {dir.create(direns, recursive=T)}
#     out=writeRaster(ensemble, paste0(direns,'/',var,'_',i,'.asc'))
#   }
# }

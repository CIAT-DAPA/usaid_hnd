### Calculate climatology mean and anomalies
### Author: Carlos Navarro c.e.navarro@cgiar.org
### Date: August 2018

# Load libraries
require(raster)
require(ncdf)
require(maptools)
require(rgdal)

# Parameters
iDir <- "T:/gcm/cmip5/ocean"
rcpList <- c("rcp45", "rcp85")
ens <- "r1i1p1"
var <- "zos"
cdopath <- "cdo"
ctr <- "hnd"
bbox <- extent(-93, -80, 9, 20)
periodList <- c("2020_2049", "2040_2069", "2070_2099")
period_h <- "1996_2015"
oDir <- "D:/Workspace/hnd_pnud/sea_level"
obsDir <- "W:/08_sea_level/baseline"
ctr_mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Honduras_v3.shp")

# GCM list with original and modified names
gcmList <- c("csiro_mk3_6_0", "giss_e2_r", "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "ipsl_cm5a_lr", "miroc_miroc5", "mohc_hadgem2_es", "mri_cgcm3", "ncc_noresm1_m")
gcmList_mod <- c("CSIRO-Mk3-6-0", "GISS-E2-R", "GFDL-CM3", "GFDL-ESM2G", "GFDL-ESM2M", "IPSL-CM5A-LR", "MIROC5", "HadGEM2-ES", "MRI-CGCM3","NorESM1-M")

# Set obaervation path
obs <- paste0(obsDir, "/dataset-duacs-rep-global-merged-allsat-phy-l4_zos.nc")

# Calculate anomalies for observations
cat("\n= Anomalies Sea level heigth =\n")
cat("\n  > Historical ", gcm, "\n")

# Load observations and create mask
oDir_bsl <- paste0(oDir, "/anomalies/baseline") 

nc_obs <- stack(obs)
mask <- paste0(oDir_bsl, "/targetgrid.nc")
if(!file.exists(mask)){
  writeRaster(nc_obs[[1]]*0+1, mask)
}

sYrOb <- strsplit(period_h, '_')[[1]][1]
eYrOb <- strsplit(period_h, '_')[[1]][2]

nc_obs_sel <- paste0(oDir_bsl, "/", var, "_omon_", period_h, "_", ctr, ".nc")
nc_obs_avg <- paste0(oDir_bsl, "/", var, "_yavg_", period_h, "_", ctr, ".nc") 
nc_obs_cli <- paste0(oDir_bsl, "/", var, "_cli_", period_h, "_", ctr, ".nc")

if( !file.exists(nc_obs_cli)){
  system(paste(cdopath, " -seldate,", sYrOb ,"-01-01,", eYrOb, "-12-31 ", obs, " ", nc_obs_sel, sep=""))
  system(paste(cdopath, " yearavg ", nc_obs_sel, " ", nc_obs_avg, sep=""))
  system(paste(cdopath, " ymonavg ", nc_obs_avg, " ", nc_obs_cli, sep=""))
}

# Anomalies from GCMs

for(rcp in rcpList){
  
  for(g in 1:length(gcmList_mod) ){
    
    cat("\n  >", rcp, gcm, "\n")
    
    # Set in and out directories
    iDir_h <- paste0(iDir, "/historical/", gcmList_mod[g], "/", ens)
    iDir_f <- paste0(iDir, "/", rcp, "/", gcmList_mod[g], "/", ens)
    oDir_anom <- paste0(oDir, "/anomalies/", rcp, "/", gcmList[g])
    if (!file.exists(oDir_anom)) {dir.create(oDir_anom, recursive=T)}  
    
    # NetCDF paths for historical conditions for each GCM
    nc_h <- list.files(path=iDir_h, pattern=paste0(var, "_Omon_", gcmList_mod[g], "_historical_", ens, "*"), full.names=TRUE)[1]
    nc_f <- list.files(path=iDir_f, pattern=paste0(var, "_Omon_", gcmList_mod[g], "_", rcp, "_", ens, "*"), full.names=TRUE)[1]

    nc_h_sel <- paste0(iDir_h, "/", var, "_omon_1996_2005.nc") 
    nc_f_sel <- paste0(iDir_h, "/", var, "_omom_2006_2015_", rcp, ".nc")
    nc_h_mrg <- paste0(iDir_h, "/", var, "_omom_1996_2015_", rcp, ".nc")
    nc_h_cut <- paste0(iDir_h, "/", var, "_omom_1996_2015_", rcp, "_", ctr, ".nc")
    nc_h_avg <- paste0(iDir_h, "/", var, "_yavg_1996_2015_", rcp, "_", ctr, ".nc") 
    nc_h_cli <- paste0(iDir_h, "/", var, "_cli_1996_2015_", rcp, "_", ctr, ".nc")
    
    # Cut by dates and calculate time-series and average for historical conditions
    if(!file.exists(nc_h_cli) ){
      system(paste(cdopath, " -seldate,1996-01-01,2005-12-31 ", nc_h, " ", nc_h_sel, sep=""))
      system(paste(cdopath, " -seldate,2006-01-01,2015-12-31 ", nc_f, " ", nc_f_sel, sep=""))
      system(paste(cdopath, " mergetime ", nc_h_sel, " ", nc_f_sel, " ", nc_h_mrg, sep=""))
      system(paste(cdopath, " sellonlatbox,", bbox@xmin+360-5,",",bbox@xmax+360+5,",",bbox@ymin-5,",",bbox@ymax+5," ", nc_h_mrg, " ", nc_h_cut, sep=""))
      system(paste(cdopath, " yearavg ", nc_h_cut, " ", nc_h_avg, sep=""))
      system(paste(cdopath, " ymonavg ", nc_h_avg, " ", nc_h_cli, sep=""))
    }

    # NetCDF paths for future conditions for each GCM
    nc_f_sel <- paste0(iDir_f, "/", var, "_omon_2006_2100.nc")
    nc_f_cut <- paste0(iDir_f, "/", var, "_omom_2006_2100_", rcp, "_", ctr, ".nc")
    nc_f_avg <- paste0(iDir_f, "/", var, "_yavg_2006_2100_", rcp, "_", ctr, ".nc") 
    
    # Cut by dates and calculate time-series and average for future conditions
    if(!file.exists(nc_f_avg)){
      system(paste(cdopath, " -seldate,2006-01-01,2100-12-31 ", nc_f, " ", nc_f_sel, sep=""))
      system(paste(cdopath, " sellonlatbox,", bbox@xmin+360-5,",",bbox@xmax+360+5,",",bbox@ymin-5,",",bbox@ymax+5," ", nc_f_sel, " ", nc_f_cut, sep=""))
      system(paste(cdopath, " yearavg ", nc_f_cut, " ", nc_f_avg, sep=""))
    }

    for(period in periodList){
    
      sYr <- strsplit(period, '_')[[1]][1]
      eYr <- strsplit(period, '_')[[1]][2]
      
      nc_f_avg_per <- paste0(iDir_f, "/", var, "_yavg_", sYr, "_", eYr, "_", rcp, "_", ctr, ".nc")
      nc_f_cli_per <- paste0(iDir_f, "/", var, "_cli_", sYr, "_", eYr, "_", rcp, "_", ctr, ".nc")
      nc_f_cli_per_r <- paste0(iDir_f, "/", var, "_cli_", sYr, "_", eYr, "_", rcp, "_", ctr, "_res.nc")
      
      system(paste(cdopath, " -selyear,", sYr, "/", eYr, " ",  nc_f_avg, " ", nc_f_avg_per, sep=""))
      system(paste(cdopath, " ymonavg ", nc_f_avg_per, " ", nc_f_cli_per, sep=""))
      
      # Calculate anomalies
      nc_anom_ts <- stack(nc_f_avg_per) - raster(nc_h_cli)
      nc_anom_avg <- stack(nc_f_cli_per) - raster(nc_h_cli) 
      
      #Resample and Calculate anomalies
      nc_anom_ts_res <- mask (resample( nc_anom_ts, raster(extent(nc_obs), resolution=res(nc_obs)[1] ) ), raster(mask) )
      nc_anom_avg_res <- mask (resample( nc_anom_avg, raster(extent(nc_obs), resolution=res(nc_obs)[1] ) ), raster(mask) )
      
      xmin(nc_anom_ts_res) <- xmin(nc_anom_ts_res) -360
      xmax(nc_anom_ts_res) <- xmax(nc_anom_ts_res) -360
      
      xmin(nc_anom_avg_res) <- xmin(nc_anom_avg_res) - 360
      xmax(nc_anom_avg_res) <- xmax(nc_anom_avg_res) - 360
      
      cat('..Change',basename(gcm),rcp, period,'\n')
      
      writeRaster(nc_anom_ts_res, paste0(oDir_anom, "/", var, "_", sYr, "_", eYr, "_ts.nc"))
      writeRaster(nc_anom_avg_res, paste0(oDir_anom, "/", var, "_", sYr, "_", eYr, "_avg.nc"))

    }
    
  }  
  
}
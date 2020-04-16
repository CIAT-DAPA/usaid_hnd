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
periodList <- c("2026_2045", "2046_2065", "2076_2095")
period_h <- "1996_2015"
# oDir <- "D:/Workspace/hnd_pnud/sea_level"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar"
obsDir <- "W:/08_sea_level/baseline"
ctr_mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Honduras_v3.shp")

# GCM list with original and modified names
gcmList <- c("csiro_mk3_6_0", "giss_e2_r", "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "ipsl_cm5a_lr", "miroc_miroc5", "mohc_hadgem2_es", "mri_cgcm3", "ncc_noresm1_m")
gcmList_mod <- c("CSIRO-Mk3-6-0", "GISS-E2-R", "GFDL-CM3", "GFDL-ESM2G", "GFDL-ESM2M", "IPSL-CM5A-LR", "MIROC5", "HadGEM2-ES", "MRI-CGCM3","NorESM1-M")

# Set obaervation path
obs <- paste0(obsDir, "/dataset-duacs-rep-global-merged-allsat-phy-l4_zos.nc")



########################################
# Calculate anomalies for observations #
########################################

cat("\n= Anomalies Sea level heigth =\n")
cat("\n  > Historical ", gcm, "\n")

# Load observations and create mask
oDir_bsl <- paste0(oDir, "/anomalies/baseline") 
if (!file.exists(oDir_bsl)) {dir.create(oDir_bsl, recursive=T)} 
oDir_bsl_asc <- paste0(oDir, "/anomalies/baseline/_asc") 
if (!file.exists(oDir_bsl_asc)) {dir.create(oDir_bsl_asc, recursive=T)} 

nc_obs <- stack(obs)
mask <- paste0(oDir_bsl, "/targetgrid.nc")
mask_rs <- raster(mask)
if(!file.exists(mask)){
  mask_i <- nc_obs[[1]]*0+1
  xmin(mask_i) <- xmin(mask_i) -360
  xmax(mask_i) <- xmax(mask_i) -360
  writeRaster(mask_i, mask, overwrite=T)
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

nc_obs_anom <- paste0(oDir_bsl, "/", var, "_anom_", period_h, "_", ctr, ".nc")
if(!file.exists(nc_obs_anom)){
  nc_obs_avg_anom <- stack(nc_obs_avg) - raster(nc_obs_cli)
  xmin(nc_obs_avg_anom) <- xmin(nc_obs_avg_anom) -360
  xmax(nc_obs_avg_anom) <- xmax(nc_obs_avg_anom) -360
  writeRaster(nc_obs_avg_anom, nc_obs_anom)
}


#Write asciis
cat("\n  > Writing asciis files\n")
yrs_obs <- sYrOb:eYrOb

if(!file.exists(paste0(oDir_bsl_asc, "/", var, "_", eYrOb, ".asc")) ){
  
  nc_obs_anom_stk <- stack(nc_obs_anom)
  
  for(i in 1:nlayers(nc_obs_anom_stk)){
    
    writeRaster(nc_obs_anom_stk[[i]], paste0(oDir_bsl_asc, "/", var, "_", yrs_obs[i], ".asc") )
    
  }
  
}


################################
# Calculate Anomalies for GCMs #
################################

for(rcp in rcpList){
  
  for(g in 1:length(gcmList_mod) ){
    
    cat("\n  >", rcp, gcmList_mod[g], "\n")
    
    # Set in and out directories
    iDir_h <- paste0(iDir, "/historical/", gcmList_mod[g], "/", ens)
    iDir_f <- paste0(iDir, "/", rcp, "/", gcmList_mod[g], "/", ens)
    oDir_anom <- paste0(oDir, "/anomalies/", rcp, "/", gcmList[g])
    if (!file.exists(oDir_anom)) {dir.create(oDir_anom, recursive=T)}  
    oDir_anom_asc <- paste0(oDir, "/anomalies/", rcp, "/", gcmList[g], "/_asc")
    if (!file.exists(oDir_anom_asc)) {dir.create(oDir_anom_asc, recursive=T)}  
    
    
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
    # Previosly rotated raster
    if(!file.exists(nc_h_cli) ){
      system(paste(cdopath, " -seldate,1996-01-01,2005-12-31 ", nc_h, " ", nc_h_sel, sep=""))
      system(paste(cdopath, " -seldate,2006-01-01,2015-12-31 ", nc_f, " ", nc_f_sel, sep=""))
      system(paste(cdopath, " mergetime ", nc_h_sel, " ", nc_f_sel, " ", nc_h_mrg, sep=""))
      if(file.exists(nc_h_mrg) ){ file.remove(nc_h_sel); file.remove(nc_f_sel) }
      system(paste(cdopath, " sellonlatbox,", bbox@xmin-5,",",bbox@xmax+5,",",bbox@ymin-5,",",bbox@ymax+5," ", nc_h_mrg, " ", nc_h_cut, sep=""))
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
      system(paste(cdopath, " sellonlatbox,", bbox@xmin-5,",",bbox@xmax+5,",",bbox@ymin-5,",",bbox@ymax+5," ", nc_f_sel, " ", nc_f_cut, sep=""))
      system(paste(cdopath, " yearavg ", nc_f_cut, " ", nc_f_avg, sep=""))
    }

    #Calculate anomalies for whole period
    nc_anom_out <- paste0(oDir_anom, "/", var, "_2006_2100_ts.nc")
    if (!file.exists(nc_anom_out)){
      nc_anom <- stack(nc_f_avg) - raster(nc_h_cli)
      nc_anom_res <- mask (resample( nc_anom, raster(extent(mask_rs), resolution=res(mask_rs)[1] ) ), mask_rs )
      writeRaster(nc_anom_res, nc_anom_out)
    }
    
    #Write asciis
    cat("\n  > Writing asciis files\n")
    if(!file.exists(paste0(oDir_anom_asc, "/", var, "_2100.asc")) ){
      
      yrs <- 2006:2100
      nc_anom_ts_stk <- stack(nc_anom_out)
      
      for(j in 1:nlayers(nc_anom_ts_stk)){
        
        writeRaster(nc_anom_ts_stk[[j]], paste0(oDir_anom_asc, "/", var, "_", yrs[j], ".asc") )
        
      }
      
    }
    
    # Calculate anomalies by periods
    for(period in periodList){
    
      sYr <- strsplit(period, '_')[[1]][1]
      eYr <- strsplit(period, '_')[[1]][2]
      
      nc_f_avg_per <- paste0(iDir_f, "/", var, "_yavg_", sYr, "_", eYr, "_", rcp, "_", ctr, ".nc")
      nc_f_cli_per <- paste0(iDir_f, "/", var, "_cli_", sYr, "_", eYr, "_", rcp, "_", ctr, ".nc")
      
      if(!file.exists(nc_f_cli_per)){
        system(paste(cdopath, " -selyear,", sYr, "/", eYr, " ",  nc_f_avg, " ", nc_f_avg_per, sep=""))
        system(paste(cdopath, " ymonavg ", nc_f_avg_per, " ", nc_f_cli_per, sep=""))
      }
      
      # Calculate anomalies
      nc_anom_ts_out <- paste0(oDir_anom, "/", var, "_", sYr, "_", eYr, "_ts.nc")
      nc_anom_avg_out <- paste0(oDir_anom, "/", var, "_", sYr, "_", eYr, "_avg.nc")
      
      if(!file.exists(nc_anom_avg_out)){
        
        nc_anom_ts <- stack(nc_f_avg_per) - raster(nc_h_cli)
        nc_anom_avg <- stack(nc_f_cli_per) - raster(nc_h_cli) 
        
        #Resample and Calculate anomalies
        nc_anom_ts_res <- mask (resample( nc_anom_ts, raster(extent(mask_rs), resolution=res(mask_rs)[1] ) ), mask_rs )
        nc_anom_avg_res <- mask (resample( nc_anom_avg, raster(extent(mask_rs), resolution=res(mask_rs)[1] ) ), mask_rs )
        
        # if (gcmList_mod[g] == "CSIRO-Mk3-6-0" || gcmList_mod[g] == "GISS-E2-R"){
        #   
        #   xmin(nc_anom_ts_res) <- xmin(nc_anom_ts_res) -360
        #   xmax(nc_anom_ts_res) <- xmax(nc_anom_ts_res) -360
        #   
        #   xmin(nc_anom_avg_res) <- xmin(nc_anom_avg_res) - 360
        #   xmax(nc_anom_avg_res) <- xmax(nc_anom_avg_res) - 360
        #   
        # }
        
        cat('..Change',basename(gcmList[g]),rcp, period,'\n')
        
        writeRaster(nc_anom_ts_res, nc_anom_ts_out)
        writeRaster(nc_anom_avg_res, nc_anom_avg_out)
        
      }
    
    }
    
  }  
  
  # Ensemble
  cat("\n  > Calculating ensemble \n")
  oDir_rcp <- paste0(oDir, "/anomalies/", rcp)
  oDir_ens <- paste0(oDir, "/anomalies/", rcp, "/ensemble")
  if (!file.exists(oDir_ens)) {dir.create(oDir_ens, recursive=T)}
  
  yrs <- 2006:2100
  for(yr in yrs) {
    
    if(!file.exists(paste0(oDir_ens, "/", var, "_", yr, "_avg.asc"))){
      nc_anom_stk_yr <- stack(paste0(oDir_rcp, "/", gcmList, "/_asc/", var, "_", yr, ".asc"))
      
      nc_anom_yr_avg <- mean(nc_anom_stk_yr, na.rm=TRUE)
      nc_anom_yr_min <- min(nc_anom_stk_yr, na.rm=TRUE)
      nc_anom_yr_max <- max(nc_anom_stk_yr, na.rm=TRUE)
      nc_anom_yr_std <- calc(nc_anom_stk_yr, fun = function(x) { sd(x, na.rm = T) })
      nc_anom_yr_q10 <- calc(nc_anom_stk_yr, fun = function(x) {quantile(x,probs = c(.1,.9),na.rm=TRUE)} )
      
      writeRaster(nc_anom_yr_avg, paste0(oDir_ens, "/", var, "_", yr, "_avg.asc"))
      writeRaster(nc_anom_yr_min, paste0(oDir_ens, "/", var, "_", yr, "_min.asc"))
      writeRaster(nc_anom_yr_max, paste0(oDir_ens, "/", var, "_", yr, "_max.asc"))
      writeRaster(nc_anom_yr_std, paste0(oDir_ens, "/", var, "_", yr, "_std.asc"))
      writeRaster(nc_anom_yr_q10[[1]], paste0(oDir_ens, "/", var, "_", yr, "_q10.asc"))
      writeRaster(nc_anom_yr_q10[[2]], paste0(oDir_ens, "/", var, "_", yr, "_q90.asc")) 
    }
    
  }
  
  
  for(period in periodList){
    
    if(!file.exists(paste0(oDir_ens, "/", var, "_", period, "_avg.asc"))){
      
      nc_anom_stk_cli <- stack(paste0(oDir_rcp, "/", gcmList, "/", var, "_", period, "_avg.nc"))
      
      nc_anom_cli_avg <- mean(nc_anom_stk_cli, na.rm=TRUE)
      nc_anom_cli_min <- min(nc_anom_stk_cli, na.rm=TRUE)
      nc_anom_cli_max <- max(nc_anom_stk_cli, na.rm=TRUE)
      nc_anom_cli_std <- calc(nc_anom_stk_cli, fun = function(x) { sd(x, na.rm = T) })
      nc_anom_cli_q10 <- calc(nc_anom_stk_cli, fun = function(x) {quantile(x,probs = c(.1,.9),na.rm=TRUE)} )
      
      writeRaster(nc_anom_cli_avg, paste0(oDir_ens, "/", var, "_", period, "_avg.asc"))
      writeRaster(nc_anom_cli_min, paste0(oDir_ens, "/", var, "_", period, "_min.asc"))
      writeRaster(nc_anom_cli_max, paste0(oDir_ens, "/", var, "_", period, "_max.asc"))
      writeRaster(nc_anom_cli_std, paste0(oDir_ens, "/", var, "_", period, "_std.asc"))
      writeRaster(nc_anom_cli_q10[[1]], paste0(oDir_ens, "/", var, "_", period, "_q10.asc"))
      writeRaster(nc_anom_cli_q10[[2]], paste0(oDir_ens, "/", var, "_", period, "_q90.asc")) 
    }
    
    
  }
  
}
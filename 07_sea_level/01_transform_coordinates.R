### Transform GCMs to lon lat catersian coordinates
### Author: Carlos Navarro c.e.navarro@cgiar.org
### Date: August 2018

iDir <- "T:/gcm/cmip5/ocean"
rcpList <- c("historical", "rcp45", "rcp85")
ens <- "r1i1p1"
var <- "zos"
basegrid <- paste0(iDir, "/targetgrid.nc")

if (!file.exists(basegrid) ){
  writeRaster(raster(xmn=-180, xmx=180, ymn=-90, ymx=90, res=1), paste0(iDir, "targetgrid.nc") )
  # system(paste0('cdo griddes ',  paste0(iDir, "targetgrid.nc"), " > ", paste0(iDir, "targetgrid.txt") ) )
}


gcmList <- c(
  "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "ipsl_cm5a_lr",
  "miroc_miroc5", "mohc_hadgem2_es", "mri_cgcm3", "ncc_noresm1_m"
)

# Not readable
# "ncar_ccsm4", "miroc_esm", "miroc_esm_chem"

# Not exists
# "bcc_csm1_1","bcc_csm1_1_m", "cesm1_cam5", "nimr_hadgem2_ao", "fio_esm"

# Not need transformation
# "csiro_mk3_6_0", "giss_e2_r"

gcmList_mod <- c(
  "GFDL-CM3",
  "GFDL-ESM2G",
  "GFDL-ESM2M",
  "HadGEM2-ES",
  "IPSL-CM5A-LR",
  "MIROC5",
  "MRI-CGCM3",
  "NorESM1-M"
)


for(rcp in rcpList){
  
  for(gcm in gcmList_mod){
    
    cat(rcp, gcm, "\n")
    
    iDir_gcm <- paste0(iDir, "/", rcp , "/", gcm, "/", ens)
    iDir_raw <- paste0(iDir, "/", rcp , "/", gcm, "/", ens, "/original-data")
    
    nc <- list.files(path=iDir_gcm, pattern=paste0(var, "*"), full.names=TRUE)[1]
    
    if (!file.exists( iDir_raw )) {dir.create(iDir_raw, recursive=T)}  
    
    if (!file.exists( paste0(iDir_raw, "/", basename(nc) )) ) {
      
      file.copy(nc, paste0(iDir_raw, "/", basename(nc) ))
      system(paste0('cdo remapbil,', basegrid, ' ',  paste0(iDir_raw, "/", basename(nc) ),' ',nc),intern=TRUE)
      cat(rcp, gcm, " projected\n")
      
    } 
    
  }
  
}


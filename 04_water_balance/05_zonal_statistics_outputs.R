### Zonal statistical 

# Load libraries
require(raster)
require(ncdf)
require(maptools)
require(rgdal)

# Arguments
iDir <- "W:/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather"
varLs <- c("sstor") #, "aet", "eprec", "perc", "runoff", "sstor")  

oDir <- "W:/06_Analysis/Extracts_MicroCuencas"
mask <- "W:/06_Analysis/Extracts_MicroCuencas/mask/MicroCuencas_ZOI.shp"
yi <- "1991"
yf <- "2014"

# Temporal folder for raster calculations
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

# For monthly timescale (average)
for (var in varLs){

  # Raster stack
  rs_stk <- stack(paste0(iDir, "/", var, "/",  var, "_month_", 1:12, ".tif"))
  
  # Dissagregate for smallers polygons 
#   rs_stk_diss <- disaggregate(rs_stk, fact=c(4, 4))
  
  # Convert polygons to raster with an specific ID
  poly <- readOGR(mask, "MicroCuencas_ZOI") 
  rs_stk_crop <- crop(rs_stk, extent(poly))
  extent(rs_stk_crop) <- extent(poly)
  poly_rs <- rasterize(poly, rs_stk_crop[[1]], 'HydroID')
  
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, poly_rs, 'mean')
  
  # Write the outputs
  write.csv(rs_zonal, paste0(oDir, "/mth_avg_timeline_", var, ".csv"), row.names=F)
  
}



# For yearly-monthly timescale 

# Get combination of year-month
yr_mth <- expand.grid(1:12, yi:yf)

for (var in varLs){
  
  # Raster stack
  rs_stk <- stack(paste0(iDir, "/", var, "/", yr_mth[,2], "/", var, "_", yr_mth[,2], "_", 1:12, ".tif"))
  
  # Dissagregate for smallers polygons 
#   rs_stk_diss <- disaggregate(rs_stk, fact=c(4, 4))
  
  # Convert polygons to raster with an specific ID
  poly <- readOGR(mask, "MicroCuencas_ZOI") # does not work  with final slash '/' 
  rs_stk_crop <- crop(rs_stk, extent(poly))
  extent(rs_stk_crop) <- extent(poly)
  poly_rs <- rasterize(poly, rs_stk_crop[[1]], 'HydroID')
  
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, poly_rs, 'mean')
  
  # Write the outputs
  write.csv(rs_zonal, paste0(oDir, "/mth_yearly_timeline_", var, ".csv"), row.names=F)
  
}



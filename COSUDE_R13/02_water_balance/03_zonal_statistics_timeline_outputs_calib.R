### Zonal statistical (mean) at yearly-monthly timescale by microwatershed of an output variable involved into the water balance
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com
### Contribution: Carlos Navarro <c.e.navarro@cgiar.org>
### Parallelization code lines taken and modified from: http://fabiolexcastrosig.blogspot.com.co/2017/04/realizar-extraccion-por-mascara-en-r.html

# Load libraries
require(raster)
require(rgdal)
require(parallel)
require(foreach)
require(doSNOW)

scenario = "run3"

# Output variables of water balance
iDir <- paste0("V:/10_outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/", scenario)
# Possible options: "aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield"
var = "wyield"

# Prefix of the output CSV file
prefix = "mth_yearly_timeline"

oDir <- paste0("V:/06_analysis/Calibration/", scenario)
# Shapefile of microwatersheds 
mask_shp <- paste0("V:/06_analysis/Calibration/mask/Cuencas_Calibracion_Caudal.shp")
# Years of simulation without warm-up year of the water balance
yi <- "2000"
yf <- "2014"
years = yi:yf

months = 1:12

# Temporal folder for raster calculations
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir= paste0(oDir, "/tmp"))

# Configuration of parallelization
#nCores <- detectCores(all.tests = FALSE, logical = TRUE)
ncores = max(1, detectCores() - 1)
cl = makeCluster(ncores)
registerDoSNOW(cl)

# configuration of progress bar
length_run <- length(years)
pb <- txtProgressBar(max = length_run, style = 3)
progress <- function(n) setTxtProgressBar(pb, n) 
opts <- list(progress=progress)


zonalStatistic <- function(var, year, poly_shp, scenario, iDir, months = 1:12, id = "HydroID", math.operation = "mean"){
  
  cat("\n####################################################\n")
  cat(paste0("Analyzing variable ", var, " ......\n"))
  cat("####################################################\n")
  
  # List rasters
  rasters = paste0(iDir, "/", var, "/", year, "/", var, "_", year, "_", months, ".tif")
  
  # Create stack raster
  rs_stk <- stack(rasters)

  
  cat("\tCroping raster stack with mask_shp ......\n")
  # Convert poly_shpgons to raster with a specific ID
  rs_stk_crop <- crop(rs_stk, extent(poly_shp))
  extent(rs_stk_crop) <- extent(poly_shp)
  cat("\tRasterizing microwatersheds ......\n")
  poly_shp_rs <- rasterize(poly_shp, rs_stk_crop[[1]], as.integer(poly_shp@data[id][[1]]))
  #poly_shp_rs <- rasterize(poly_shp, rs_stk_crop[[1]], as.integer(levels(poly_shp@data[id][[1]])))
  
  cat("\tCarrying out the zonal statistic operation ......\n")
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, poly_shp_rs, math.operation)
  
  return(rs_zonal)
  
}

# Read mask_shp and convert it to Spatialpoly_shpgonsDataFrame
poly_shp <- readOGR(mask_shp)

# Execute process in parallel and store the results in the variable data
data = foreach(i = 1:length_run, .packages = c('raster', 'rgdal'), .options.snow=opts, .combine=cbind, .verbose=TRUE) %dopar% {
  
  zonalStatistic(var, years[i], poly_shp, scenario, iDir, months)
  
} 

# Remove repeated columns
final_data = data[,-which(colnames(data) == "zone")[-1]]

# Replaces the word "zone" for "HydroID"
colnames(final_data)[1] = "HydroID"

cat("\tWriting the CSV file ......\n")
# Write the outputs
write.csv(final_data, paste0(oDir, "/", prefix, "_", var, ".csv"), row.names=F)

# It is important to stop the cluster, even when the script is stopped abruptly
stopCluster(cl)
close(pb)

# Delete temp files
unlink(rasterOptions()$tmpdir, recursive=TRUE)

cat("\nDone!!!")
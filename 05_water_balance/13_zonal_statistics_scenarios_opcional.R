### Zonal statistical (mean) by microwatershed-land use/land cover
### Use this script only for the output variable "wyield" at montly timescale
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

# Network drive
net_drive = "Y:"

scenario = "rcp2.6_2030"
# scenario = "baseline"

# Output variables of water balance
iDir <- paste0(net_drive,"/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/", scenario)
var <- "wyield"

oDir <- paste0(net_drive, "/06_analysis/Scenarios/", scenario)
# Shapefile of microwatershed-land use/land cover 
mask_shp <- paste0(net_drive, "/06_analysis/Scenarios/masks/Microcuencas_ZOI_Usos4_Finales.shp")

months = 1:12
prefix = "mth_avg_timeline_microusos"

# Temporal folder for raster calculations
if (!file.exists(paste0(oDir, "/tmp"))) {dir.create(paste0(oDir, "/tmp"), recursive = TRUE)}
rasterOptions(tmpdir = paste0(oDir, "/tmp"))

# Configuration of parallelization
#nCores <- detectCores(all.tests = FALSE, logical = TRUE)
ncores = max(1, detectCores() - 1)
cl = makeCluster(ncores)
registerDoSNOW(cl)

# configuration of progress bar
length_run <- length(months)
pb <- txtProgressBar(max = length_run, style = 3)
progress <- function(n) setTxtProgressBar(pb, n) 
opts <- list(progress=progress)


zonalStatistic <- function(month, var, poly_shp, iDir, id = "HydroID", math.operation = "mean"){
  
  cat("\n####################################################\n")
  cat(paste0("Analyzing month ", month, " ......\n"))
  cat("####################################################\n")
  
  # For monthly timescale
  rs = raster(paste0(iDir, "/", var, "/",  var, "_month_", month, ".tif"))

  cat("\tCroping raster with mask_shp ......\n")
  # Convert polygons to raster with a specific ID
  rs_crop <- crop(rs, extent(poly_shp))
  extent(rs_crop) <- extent(poly_shp)
  cat("\tRasterizing microwatersheds ......\n")
  #poly_shp_rs <- rasterize(poly_shp, rs_stk_crop[[1]], as.integer(levels(poly_shp@data[id][[1]])))
  poly_shp_rs <- rasterize(poly_shp, rs_crop[[1]], as.integer(poly_shp@data[id][[1]]))
  
  cat("\tCarrying out the zonal statistic operation ......\n")
  # Get the zonal statistics
  rs_zonal <- zonal(rs_crop, poly_shp_rs, math.operation)

  return(rs_zonal)
  
}

# Read mask_shp and convert it to Spatialpoly_shpgonsDataFrame
poly_shp <- readOGR(mask_shp) 

# Execute process in parallel and store the results in the variable data
data = foreach(i = 1:length_run, .packages = c('raster', 'rgdal'), .options.snow=opts, .combine=cbind, .verbose=TRUE) %dopar% {
  
  zonalStatistic(months[i], var, poly_shp, iDir, id = "IDMicroUso")
  
} 

# Remove repeated columns
final_data = data[,-which(colnames(data) == "zone")[-1]]

# Set the colum names
colnames(final_data) = c("IDMicroUso", paste0(var, "_month_", months))

cat("\tWriting the CSV file ......\n")
# Write the outputs
write.csv(final_data, paste0(oDir, "/", prefix, "_", var, ".csv"), row.names=F)

# It is important to stop the cluster, even when the script is stopped abruptly
stopCluster(cl)
close(pb)

# Delete temp files
unlink(rasterOptions()$tmpdir, recursive=TRUE)

cat("\nDone!!!")
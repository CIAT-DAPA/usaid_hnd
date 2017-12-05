### Zonal statistical (mean) by microwatershed-land use/land cover for the wettest and driest years
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

scenario = "driest_year"

# Output variables of water balance
iDir <- paste0(net_drive,"/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/baseline")
iFile <- read.csv(paste0(net_drive, "/06_analysis/Scenarios/", scenario, "/", scenario, "_prec.csv"))
varLs <- "wyield"

oDir <- paste0(net_drive, "/06_analysis/Scenarios/", scenario)
# Shapefile of microwatersheds 
mask_shp <- paste0(net_drive, "/06_analysis/Scenarios/masks/Microcuencas_ZOI_Usos4_Finales.shp")
# Unique years of the scenario
years = sort(unique(iFile$Ano))

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
length_run <- length(years)
pb <- txtProgressBar(max = length_run, style = 3)
progress <- function(n) setTxtProgressBar(pb, n) 
opts <- list(progress=progress)


zonalStatistic <- function(year, var, polys, iDir, months = 1:12, id = "HydroID", math.operation = "mean"){
  
  cat("\n####################################################\n")
  cat(paste0("Analyzing year ", year, " ......\n"))
  cat("####################################################\n")
  
  # For monthly timescale
  rasters = paste0(iDir, "/", var, "/", year , "/", var, "_", year, "_", months, ".tif")

  cat("\tCreating raster stack ......\n")
  # Raster stack
  rs_stk <- stack(rasters)

  cat("\tCroping raster stack with mask_shp ......\n")
  # Convert poly_shpgons to raster with a specific ID
  rs_stk_crop <- crop(rs_stk, extent(polys))
  extent(rs_stk_crop) <- extent(polys)
  cat("\tRasterizing microwatersheds ......\n")
  #poly_shp_rs <- rasterize(polys, rs_stk_crop[[1]], as.integer(levels(polys@data[id][[1]])))
  polys_rs <- rasterize(polys, rs_stk_crop[[1]], as.integer(polys@data[id][[1]]))
  
  cat("\tCarrying out the zonal statistic operation ......\n")
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, polys_rs, math.operation)
  
  return(rs_zonal)

}

# Read mask_shp and convert it to Spatialpoly_shpgonsDataFrame
poly_shp <- readOGR(mask_shp) 

# Execute process in parallel and store the results in the variable data
data = foreach(i = 1:length_run, .packages = c('raster', 'rgdal'), .options.snow=opts, .combine=rbind, .verbose=TRUE) %dopar% {
  
  year = years[i]
  hydroids = iFile$HydroID[iFile$Ano == year]
  polys = poly_shp[poly_shp$HydroID %in% hydroids,]
  
  zonalStatistic(year, var, polys, iDir, months, id = "OBJECTID")
  
} 

# Replaces the word "zone" for "HydroID"
colnames(data)[1] = "HydroID"

cat("\tWriting the CSV file ......\n")
# Write the outputs
write.csv(data, paste0(oDir, "/", prefix, "_", var, ".csv"), row.names=F)

# It is important to stop the cluster, even when the script is stopped abruptly
stopCluster(cl)
close(pb)

# Delete temp files
unlink(rasterOptions()$tmpdir, recursive=TRUE)

cat("\nDone!!!")
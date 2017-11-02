### Zonal statistical (mean) by microwatershed of all the variables involved into the water balance
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

# Uncomment the variables to be analyzed
# Input variables of water balance
#iDir <- paste0(net_drive, "/Inputs/WPS/Balance_Hidrico/shared")
#varLs <- c("prec", "tmax", "tmean", "tmin", "eto")
# Output variables of water balance
iDir <- paste0(net_drive,"/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather")
varLs <- c("aet", "eprec", "perc", "runoff", "sstor", "bflow")  
# Define if the variables to be analyzed are inputs (in) or outputs (out) of the water balance
in_or_out = "out"
# Define if timescale is monthly (m) or yearly-monthly (ym)
timescale = "ym"

oDir <- paste0(net_drive, "/06_analysis/Extracts_MicroCuencas")
# Shapefile of microwatersheds 
mask <- paste0(net_drive, "/06_analysis/Extracts_MicroCuencas/mask/MicroCuencas_ZOI_Finales.shp")
# Years of simulation without warm-up year of the water balance
yi <- "1991"
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
length_run <- length(varLs)
pb <- txtProgressBar(max = length_run, style = 3)
progress <- function(n) setTxtProgressBar(pb, n) 
opts <- list(progress=progress)


zonalStatistic <- function(var, mask, in_or_out, timescale = "m", iDir, oDir, months = 1:12, years, id = "HydroID", math.operation = "mean"){
  
  cat("\n####################################################\n")
  cat(paste0("Analyzing variable ", var, " ......\n"))
  cat("####################################################\n")
  
  if (in_or_out == "in" ){

    if (timescale == "m"){
      # For monthly timescale
      rasters = paste0(iDir, "/", var, "/projected/", var, "_month_", months, ".tif")
      prefix = "mth_avg_timeline"
    } else if(timescale == "ym"){
      # For yearly-monthly timescale 
      # Get combination of year-month
      yr_mth <- expand.grid(months, years)
      rasters = paste0(iDir, "/", var, "/projected/", yr_mth[,2], "/", var, "_", yr_mth[,2], "_", months, ".tif")
      prefix = "mth_yearly_timeline"
    } else{ stop("timescale is not an allowed option (m: monthly, ym: yearly-monthly)") }
    
    cat("\tCreating raster stack ......\n")
    # Raster stack
    rs_stk <- stack(rasters)
    
    cat("\tDissagregating raster stack......\n")
    # Dissagregate for smallest polygons
    rs_stk <- disaggregate(rs_stk, fact=c(4, 4))
   }
  else if (in_or_out == "out" ){
    
    if (timescale == "m"){
      # For monthly timescale
      rasters = paste0(iDir, "/", var, "/",  var, "_month_", months, ".tif")
      prefix = "mth_avg_timeline"
    } else if(timescale == "ym"){
      # For yearly-monthly timescale 
      # Get combination of year-month
      yr_mth <- expand.grid(months, years)
      rasters = paste0(iDir, "/", var, "/", yr_mth[,2], "/", var, "_", yr_mth[,2], "_", months, ".tif")
      prefix = "mth_yearly_timeline"
    } else{ stop("timescale is not an allowed option (m: monthly, ym: yearly-monthly)") }
    
    cat("\tCreating raster stack ......\n")
    # Raster stack
    rs_stk <- stack(rasters)
  } else { stop("variables to be analyzed are neither inputs (in) nor outputs (out)") }
  
  cat("\tCroping raster stack with mask ......\n")
  # Convert polygons to raster with a specific ID
  poly <- readOGR(mask) 
  rs_stk_crop <- crop(rs_stk, extent(poly))
  extent(rs_stk_crop) <- extent(poly)
  cat("\tRasterizing microwatersheds ......\n")
  poly_rs <- rasterize(poly, rs_stk_crop[[1]], id)
  
  cat("\tCarrying out the zonal statistic operation ......\n")
  # Get the zonal statistics
  rs_zonal <- zonal(rs_stk_crop, poly_rs, math.operation)
  
  cat("\tWriting the CSV file ......\n")
  # Write the outputs
  write.csv(rs_zonal, paste0(oDir, "/", prefix, "_", var, ".csv"), row.names=F)
  
}

foreach(i = 1:length_run, .packages = c('raster', 'rgdal'), .options.snow=opts) %dopar% {

  zonalStatistic(varLs[i], mask, in_or_out, timescale, iDir, oDir, months, years)
  
} 

# It is important to stop the cluster, even when the script is stopped abruptly
stopCluster(cl)
close(pb)
cat("\nDone!!!")
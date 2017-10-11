library(ggplot2)
library(gstat)
library(sp)
library(maptools)

bDir <- "D:/cenavarro/hnd_usaid/04_interpolation/stations-averages/yearly_pseudost"
sY <- 1990
fY <- 2014
oDir <- "D:/cenavarro/hnd_usaid/04_interpolation/outputs_yearly/average"
var <- "dter"

# List of months
mthLs <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

msk <- raster(paste0("W:/04_interpolation/region/v3/mask"))
xt <- extent(msk)

for (y in sY:fY){
  
  yrdata_info <- read.csv(paste(bDir,"/", var, "_", y, ".csv"  ,sep=""))
  cols <- colnames(yrdata_info) %in% toupper(mthLs)
  
  # Read all files
  yrdata <- subset(read.csv(paste(bDir,"/", var,"_", y, ".csv"  ,sep="")),,cols)
  
  for (i in 1:12){
    
    yrdata_2 <- as.data.frame(yrdata[,i])
    colnames(yrdata_2) <- "DATA"
    yrdata_2$x <- yrdata_info$LONG  
    yrdata_2$y <- yrdata_info$LAT
    
    coordinates(yrdata_2) = ~x + y
        
    x.range <- as.numeric(c(xt@xmin, xt@xmax))  # min/max longitude of the interpolation area
    y.range <- as.numeric(c(xt@ymin, xt@ymax))  # min/max latitude of the interpolation area
    
    # expand points to grid
    grd <- expand.grid(x = seq(from = x.range[1], to = x.range[2], by = res(msk)[1]), y = seq(from = y.range[1], to = y.range[2], by = res(msk)[2]))  
    
    coordinates(grd) <- ~x + y
    gridded(grd) <- TRUE
    
    # Interpolate surface and fix the output:
    idw <- idw(formula = DATA ~ 1, locations = yrdata_2, newdata = grd, idp = 2.0)
#     kridge <- krige(formula = DATA ~ 1, locations = yrdata_2, newdata = grd)

    ## [inverse distance weighted interpolation]
    idw.output = as.data.frame(idw)  # output is defined as a data table
#     kridge.output = as.data.frame(kridge)
    
    outRs <- resample(rasterFromXYZ(idw.output[,1:3], res=res(msk), crs=NA, digits=2), msk)
    outRs <- writeRaster(outRs, paste0(oDir, "/dtridw_", y, "_", i, ".asc"))
#     plot(outRs)    
       
    
  }
  
}

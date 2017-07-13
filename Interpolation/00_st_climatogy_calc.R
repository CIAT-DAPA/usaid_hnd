##########################################################################################
## Purpose: Climatology Calcs
## Author: Carlos Navarro c.e.navarro@cgiar.org
## Date July 2017
##########################################################################################

clim_calc <- function(var="prec",  bDir = "W:/01_weather_stations/hnd_all/monthly-filled", oDir = "Z:/DATA/WP2/01_Weather_Stations/COL", st_loc="S:/observed/weather_station/col-ideam/stations_names.csv", sY=1981, fY=2010){
  
  # Read monthly file
  monthly_var <- read.csv(paste0(bDir, "/monthly_", var, "_all.csv"), header=T)
  
  if(!file.exists(oDir)){dir.create(oDir, recursive = T)}
  
  for (yr in sY:fY){
  
    # Years selection
    monthly_var_yr <- monthly_var[ which(monthly_var$year == yr),]
    
    # Period climatology calc
    monthly_var_yr$year <- NULL
    
    # Fix station names
    st_namescodes <- names(monthly_var_yr)[-1]
    st_codes <- as.data.frame(gsub("X", "", lapply(strsplit(st_namescodes, "_"), `[[`, 1)))
    st_names <- as.data.frame(gsub("X", "", lapply(strsplit(st_namescodes, "_"), `[[`, 2)))
    
    monthly_var_yr_t <- cbind(st_codes, st_names, t(monthly_var_yr)[-1,])
    
    # Add month names
    mths <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
    colnames(monthly_var_yr_t) <- c("national_code", "name_station",  mths)
    
    ## Add station info
    stInfo <- read.csv(st_loc, header=T)
    stInfo_var <- stInfo[ which(stInfo$variable == var),]
    join <- merge(stInfo_var, monthly_var_yr_t, by = c("national_code", "name_station"), all = FALSE)
    
    # Combine info and data
    climData <- cbind(join$national_code, join$INSTITUCIO, join$national_code, join$name_station, "HONDURAS", join$GEO_X, join$GEO_Y, join$ALTITUD, join[,(ncol(join)-11):ncol(join)], 30)
    names(climData) <- c("ID", "SOURCE", "OLD_ID","NAME","COUNTRY","LONG","LAT","ALT","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","NYEARS")
    
    # Write climatology 
    write.csv(unique(climData), paste0(oDir, "/", var, "_", yr, ".csv"), row.names=F)
      
  }
  
}

add_pseudost =function(dDir ="S:/observed/gridded_products/chirps/monthly/world", bDir ="Z:/DATA/WP2/01_Weather_Stations/MERGE/climatology", rDir ="Z:/DATA/WP2/00_zones", oDir="", dst_name ="chrips", sY =1981, fY =2010, var ="prec"){
  
  require(raster)
  require(rgdal)
  require(dismo)
  require(som)
  library(sp)
  library(KernSmooth)
  library(lubridate)
  
  if (var == 'prec'){varmod <- "rain"}else{varmod<-var}
  
  # List of months
  mthLs <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  
  # Create output dir
  if (!file.exists(oDir)) {dir.create(oDir, recursive=T)}
  
  ## Region mask
  mask <- raster(paste0(rDir, "/mask"))
  refExt <- extent(mask)
  
  ## Load original station data to 
  raw_data <- read.csv(paste0(bDir, "/", var, "_", sY, ".csv"))  
  
  # Fit with kernell model
  points <- raw_data
  coordinates(points) <- ~LONG+LAT
  
  est <- bkde2D(coordinates(points), 
                bandwidth=c(1,1), 
                gridsize=c(nrow(mask),ncol(mask)),
                range.x=list(c(xmin(refExt),xmax(refExt)),c(ymin(refExt),ymax(refExt))))
  #   est$fhat[est$fhat<0.00001] <- 0 ## ignore very small values
  
  # create raster
  wgRs = raster(list(x=est$x1,y=est$x2,z=est$fhat)) * 10000
  plot(wgRs)
  
  # Gap mask calcs
  gap <- rasterize(cbind(raw_data$LONG, raw_data$LAT), rs_agg, 1, fun=mean)
  gap[is.na(gap)] <- 0 
  gap[gap==1] <- NA 
  gap <- mask(gap, resample(mask, gap))
  
  # wgRs <- setMinMax(raster(paste0(rDir, "/rg_weigth_1deg_", var, ".tif"))) ## Calc random points based on kernel-density function (computed in ArcGIS)
  wgGap <- mask(1-(wgRs/(maxValue(wgRs)- minValue(wgRs))), resample(gap, wgRs))
  wgGap[wgGap<0.00001] <- 0
  
  # Calculate the density within departaments based on raw_data
  # gapMsk <- mask(setExtent(crop(gap, extent(depLim)), extent(depLim), keepres = F) , depLim)
  denPres <- nrow(raw_data)/length(mask[!is.na(mask)])
  
  if (var == "prec"){
    npts <- 0.3 * length(mask[!is.na(mask)]) * denPres#     
  } else {
    npts <- 0.5 * length(mask[!is.na(mask)]) * denPres#     
  }
  
  pts <- randomPoints(mask(resample(wgGap, mask), mask), n=npts, ext=mask, prob=T)
  alt <- extract(raster(paste0(rDir, "/altitude.tif")), pts)
  alt[is.na(alt)] <- NA
  
  
  #Loop years
  for (yr in sY:fY){
    
    ## Load original station data to 
    raw_data <- read.csv(paste0(bDir, "/", var, "_", yr, ".csv"))  
    
    ## Read reanalysis output data, write in a friendly format
    # Cut border and calc 30yr avg
    if (var == "prec"){
      
      rs_clip <- crop(stack(paste0(dDir, "/v2p0chirps", yr, sprintf("%02d", 1:12), ".bil")), refExt)
      rs_pts <- extract(rs_clip, pts)
      
      if (var == "prec"){
        rs_pts[rs_pts < 0] <- NA  
      } else {
        rs_pts[rs_pts < -50] <- NA  
      }
      
      # Combine info and data
      climData <- as.data.frame(cbind(paste0(dst_name, 1:nrow(pts)), dst_name, paste0(dst_name, 1:nrow(pts)), paste0(dst_name, 1:nrow(pts)), "HND", round(pts, 3), alt, round(rs_pts, 1), "30"))
      names(climData) <- c("ID", "SOURCE", "OLD_ID","NAME","COUNTRY","LONG","LAT","ALT","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","NYEARS")
      
      combClimData <- na.omit(rbind(raw_data, climData))
      write.csv(combClimData,  paste0(oDir, "/", varmod, "_", yr, ".csv"), row.names = F)  
      
      
    } else {
      
      re_temp <- c()
      re_alt <- c()
      re_coords <- c()
      
      for (file in list.files(dDir, full.names = T)){
        
        re_st <- read.csv(file, row.names = NULL)
        names(re_st) <- c("Date", "Longitude", "Latitude", "Elevation", "tmax", "tmin")
        date <- as.Date(re_st$Date,format='%m/%d/%Y')
        
        re_st_sel <- re_st[ which(year(date) == yr),]
        re_st_sel <- aggregate(re_st, list(month(date)),mean)
        
        if (var == "tmax"){
          re_temp <- rbind(re_temp, re_st_sel$tmax)  
        } else {
          re_temp <- rbind(re_temp, re_st_sel$tmin)  
        }
        
        re_alt <- c(re_alt, re_st_sel$Elevation[1])
        re_coords <- rbind(re_coords, cbind(re_st_sel$Longitude[1], re_st_sel$Latitude[1]))
      }
      # rs_clip <- crop(rotate(stack(paste0(dDir, "/", var, "_monthly_ts_agmerra_1980_2010.nc"))[[(1:12)+12*(yr-sY+1)]]), refExt)
      
      # Combine info and data
      climData <- as.data.frame(cbind(paste0(dst_name, 1:nrow(re_temp)), 
                                      dst_name, 
                                      paste0(dst_name, 1:nrow(re_temp)), 
                                      paste0(dst_name, 1:nrow(re_temp)), 
                                      "HND", 
                                      round(re_coords, 3), 
                                      re_alt, 
                                      round(re_temp, 1), 
                                      "30"))
      names(climData) <- c("ID", "SOURCE", "OLD_ID","NAME","COUNTRY","LONG","LAT","ALT","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","NYEARS")
      
      combClimData <- na.omit(rbind(raw_data, climData))
      write.csv(combClimData,  paste0(oDir, "/", varmod, "_", yr, ".csv"), row.names = F)  
      
    }
    
  }
} 

climatology <- function(bDir, var, sY, fY, oDir){
  
  # Read all files
  yrdata <- lapply(paste(bDir,"/", var, "_", sY:fY, ".csv"  ,sep=""), function(x){read.csv(x, header=T)})
  yrdata_avg <- Reduce("+", lapply(yrdata, "[", 9:20)) / length(yrdata)
  
  yrdata_i <- read.csv(paste0(bDir,"/", var, "_", sY, ".csv"))
  climData <- cbind( yrdata_i[,1:8], yrdata_avg, NYEARS=yrdata_i[,21])
  
  write.csv(climData, paste0(oDir, "/", var, "_", sY, "_", fY, ".csv"), row.names=F)
  
}


################################
##########  Wrapp ##############
################################

# Monthly filled
bDir = "W:/01_weather_stations/hnd_all/monthly-filled"
oDir = "W:/04_interpolation/stations-averages/yearly"
st_loc= "W:/01_weather_stations/hnd_all/catalog_stations_filled.csv"
for (var in c("prec","tmin", "tmax")){
  if (var == "prec"){
    sY <- 1981
    fY <- 2015
  } else {
    sY <- 1990
    fY <- 2014
  }
  clim_calc(var,  bDir, oDir, st_loc, sY, fY)
}

# Add pseudo-stations
bDir <- "W:/04_interpolation/stations-averages/yearly"
rDir <- "W:/04_interpolation/region/v2"
oDir <- "W:/04_interpolation/stations-averages/yearly_pseudost"

varList <- c("prec", "tmax", "tmin")
for (var in varList){
  if (var == "prec"){
    sY <- 1981
    fY <- 2015
    dDir <- "S:/observed/gridded_products/chirps/monthly/world"
    dst_name <- "CHIRPS"
  } else {
    sY <- 1990
    fY <- 2014
    dDir <- "W:/04_interpolation/stations-averages/cfsr_st"
    dst_name <- "CFSR"
  }
  
  add_pseudost(dDir, bDir, rDir, oDir, dst_name, sY, fY, var)
}


# 20-yr clim
bDir <- "W:/04_interpolation/stations-averages/yearly_pseudost"
varList <- c("rain", "tmax", "tmin")
sY <- 1991
fY <- 2010
oDir <- "D:/cenavarro/hnd_usaid/04_interpolation/stations-averages/climatology"
for (var in varList){
  climatology(bDir, var, sY, fY, oDir)
}



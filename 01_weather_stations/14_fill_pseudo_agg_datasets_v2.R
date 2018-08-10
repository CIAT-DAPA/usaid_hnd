########################################################################
## Purpose: Merge daily & monthly weather stations in a single csv file 
## Author: Carlos Navarro c.e.navarro@cgiar.org
########################################################################

#############################
### 03- Fill monthly      ###
#############################

fill_dst_mth <- function(var="tmin",  bDir = "Z:/DATA/WP2/01_Weather_Stations/MERGE", oDir = "Z:/DATA/WP2/01_Weather_Stations/MERGE", dDir = "S:/observed/gridded_products/chirps/monthly/world",sY=1986, fY=2005, dst_name=""){
  
  library(raster)
  library(ncdf4)
  # library(dplyr)
  
  # Read monthly and station adn year selection
  st_data <- read.csv(paste0(bDir, "/", var, "_merge.csv"), header=T)
  st_coord <- read.csv(paste0(bDir, "/catalog_merge_temp.csv"), header=T)
  
  # Select period
  st_data_filter <- st_data
  
  ## Return %NA and remove stations with lesser data
  na_per <- function(a,na.rm=T){
    na.x = length(which(is.na(a))) / length(a)
    x = na.x
    return(x)
  }
  
  #   st_data_na <- apply(st_data_filter,2,na_per)
  #   st_data_na_filter <- st_data_filter[,which(as.vector(st_data_na)<=0.50)]
  #   st_data_na_test <- apply(st_data_na_filter,2,na_per)
  
  ## Set coordinates only for the coordinates filtered 
  st_names_filter <- as.matrix(gsub("X", "", names(st_data_filter)[3:length(names(st_data_filter))]))
  st_names_filter <- as.data.frame(unlist(lapply(strsplit(st_names_filter,"_"),"[[",1)))
  colnames(st_names_filter) <- "code"
  st_coord_filter <- merge(st_names_filter, st_coord, by = "code", all=FALSE, sort=F)
  
  # [!duplicated(st_coord$code), ]
  # Read stack and extract points
  if (var == "prec"){
    dts_all <- stack(paste0(dDir, "/v2p0chirps", format(seq(as.Date("1981/01/01"),as.Date("2010/12/31"),"months"), "%Y%m"), ".bil"))  
  } else {
    if (dst_name == "agmerra"){
      dst <- stack(paste0(dDir, "/", var, "_monthly_ts_agmerra_1980_2010.nc"))
      dts_all <- dst[[13:nlayers(dst)]]
    } else if (dst_name == "terraclimate") {
      dst <- stack(paste0(dDir, "/TerraClimate_", var, "_", sY:fY, ".nc"))
      dts_all <- dst
    }
    
  }
  
  
  cat("Extract values stack ", var, "\n")
  if (var == "prec"){
    st_dts_ext <- raster::extract(x=dts_all, y=cbind(st_coord_filter$Lon, st_coord_filter$Lat), method = 'bilinear')  
  } else {
    lonmod <- st_coord_filter$lon
    if (dst_name == "agmerra"){
      lonmod[which(lonmod[]<0)] = lonmod[]+360
    } 
    st_dts_ext <- raster::extract(x=dts_all, y=cbind(lonmod, st_coord_filter$lat), method = 'bilinear')
  }
  
  st_dts <- as.data.frame(t(st_dts_ext))[1:nrow(st_data_filter),]  
  
  # if (var != "prec"){
  #   st_dts <- st_dts/10  
  # }
  
  
  years_months <- st_data_filter[,1:2]
  st_data_filter$year <- NULL
  st_data_filter$month <- NULL
  
  names(st_dts) <- names(st_data_filter)
  st_dts_na = apply(st_dts,2,na_per)
  
  dates <- seq(as.Date(paste0(sY, "/01/01")),as.Date(paste0(fY, "/12/31")),"month")
  months <- months.Date(dates)
  
  add_legend <- function(...) {
    opar <- par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0),
                mar=c(0, 0, 0, 0), new=TRUE)
    on.exit(par(opar))
    plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
    legend(...)
  }
  
  metrics <- c()
  
  # Filling stations
  for (i in 1:ncol(st_dts)){
    
    na_val <- na_per(st_data_filter[,i])
    
    cat("Filling", var, "_", as.character(st_names_filter[i,1]), "\n")
    
    if(st_dts_na[i]==0 && na_val < 0.40){
      
      p_val <- cor.test(st_data_filter[,i], st_dts[,i], alternative = "greater")$p.value
      
      # Set linear model
      data.model = as.data.frame(cbind("y"=st_data_filter[,i], "x"=st_dts[,i]))
      model = lm(data=data.model,formula = y~x)
      rmse <- round(sqrt(mean(resid(model)^2)), 2)
      coefs <- coef(model)
      b0 <- round(coefs[1], 2)
      b1 <- round(coefs[2],2)
      r2 <- round(summary(model)$r.squared, 2)
      
      eqn <- bquote(italic(y) == .(b0) + .(b1)*italic(x) * "," ~~
                      R^2 == .(r2) * "," ~~ RMSE == .(rmse))
      
      new.data = as.data.frame(st_dts[,i])
      names(new.data) = "x"
      
      data_model.p = predict(model, new.data)
      
      if (var == "prec"){
        data_model.p[data_model.p<0] <- 0 
      } 
      
      # Plot comparisson
      tiff(paste0(oDir, "/", var, "_", as.character(st_names_filter[i,1]),".tiff"),compression = 'lzw',height = 10,width = 10,units="in", res=200)
      
      par(mfrow=c(2,1))
      
      if (var == "prec"){
        plot(dates,st_data_filter[,i],lwd=1.5,type="l",xlab="",ylab="Precipitation (mm)")  
      } else {
        plot(dates,st_data_filter[,i],lwd=1.5,type="l",xlab="",ylab="Temperature (C deg)")  
      }
      
      lines(dates,st_dts[,i],col="blue",lty=2,lwd=1)
      lines(dates,data_model.p,col="red",lty=2)
      
      
      plot(st_data_filter[,i],st_dts[,i],xlab="Observed_stations",ylab="dts")
      abline(model,col="red")
      legend('bottomright', legend = eqn, bty = 'n')
      
      add_legend("topright",c("Observed","dts","Model"),
                 horiz=T, bty='n', cex=0.9,lty=c(1,2,2),lwd=c(1.5,1,1),col=c("black","blue","red"))
      
      dev.off()
      
      pos.na = which(is.na(st_data_filter[,i]))
      
      if(na_val < 0.5 && p_val <= 0.05 && r2 >= 0.3){
        st_data_filter[pos.na,i] = as.numeric(data_model.p[pos.na])
      }else {
        st_data_filter[pos.na,i] = as.numeric(st_dts[pos.na,i])
      }
      
    }
    
    
    metrics <- rbind(metrics, cbind(as.character(st_names_filter[i,1]), na_val, p_val, r2))
    
    
  }
  
  colnames(metrics) <- c("St_name", "NA_per", "p_value", "r2")
  
  # Write stations filled
  write.csv(cbind(years_months, st_data_filter), paste0(bDir, "/", var, "_merge_fill_", dst_name,".csv"),row.names = F)
  write.csv(metrics, paste0(bDir, "/", var, "_merge_fill_", dst_name, "_stats.csv"),row.names = F)
  
}


#############################
### 04- Climatology Calcs ###
#############################

clim_calc <- function(var="prec",  bDir = "Z:/DATA/WP2/01_Weather_Stations/MERGE", oDir = "Z:/DATA/WP2/01_Weather_Stations/MERGE", stDir="Z:/DATA/WP2/01_Weather_Stations/MERGE", sY=1981, fY=2010, srtm="", dst_name=""){
  
  # Read monthly file
  #   if (var == "prec"){
  
  monthly_var <- read.csv(paste0(bDir, "/", var, "_merge_fill_", dst_name, ".csv"), header=T) 
  
  #   } else {
  #     monthly_var <- read.csv(paste0(bDir, "/", var, "_monthly_all_amazon.csv"), header=T)  
  #   }
  
  if (!file.exists(oDir)) {dir.create(oDir, recursive = TRUE)}
  
  if (var == "prec"){varmod <- "prec"} else { varmod = "temp"}
  
  ## Climatology aggregation based on NA percent
  avg_var = function(a,na.rm=T){
    na.x = length(which(is.na(a))) / length(a)
    if(na.x>=0.6667){
      x = NA
    }else{
      x = mean(a, na.rm = any(!is.na(a))) 
    }
    return(x)
  }
  
  ## Return %NA
  na_per <- function(a,na.rm=T){
    na.x = length(which(is.na(a))) / length(a)
    x = na.x
    return(x)
  }
  
  # Years selection
  monthly_var <- monthly_var[ which(monthly_var$year >= sY & monthly_var$year <= fY),]
  
  # Period climatology calc
  monthly_avg = aggregate(monthly_var[,3:length(monthly_var)], list(month=monthly_var$month),avg_var)
  na_p <- round( (1- apply(monthly_var[,3:length(monthly_var)], 2, na_per)) * (fY-sY), digits = 0)
  
  # Remove unnecesary columns if exists
  monthly_avg$month <- NULL;  monthly_avg$Month <- NULL;  monthly_avg$year <- NULL
  
  # Transpose
  st_names <- as.data.frame(names(monthly_avg))
  colnames(st_names) <- "code"
  monthly_avg <- cbind(st_names, round(t(monthly_avg), 1))
  
  # Remove all rows with NA
  monthly_avg <- monthly_avg[rowSums(is.na(monthly_avg[,2:ncol(monthly_avg)])) < 12, ]
  
  rownames(monthly_avg) <- NULL
  
  # Add month names
  mths <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  colnames(monthly_avg) <- c("code", mths)
  monthly_avg$code <- unlist(lapply(strsplit(gsub("X", "", monthly_avg$code),"_"),"[[",1))
  
  ## Add station info
  stInfo <- read.csv(paste0(stDir, "/catalog_merge_", varmod, ".csv"), header=T)
  join <- merge(monthly_avg, stInfo, by = "code", all = FALSE, sort=F)
  
  # ## NA percent
  # na_p <- cbind(st_names, na_p)
  # 
  # names(na_p) <- c("code", "NYEARS")
  # na_p$code <-  unlist(lapply(strsplit(gsub("X", "",  na_p$code),"_"),"[[",1))
  
  # Reg selection
  rg_ext <- extent(rg)
  join <- join[ which(join$lon >= xmin(rg_ext) & join$lon <= xmax(rg_ext)),]
  join <- join[ which(join$lat >= ymin(rg_ext) & join$lat <= ymax(rg_ext)),]
  
  # join <- merge(join, na_p, by = "Station", all = FALSE)
  join[is.na(join)] <- -9999.9
  
  join$alt <- raster::extract(x=raster(srtm), y=cbind(join$lon, join$lat), method = 'bilinear')
  join$nyears <- 30
  
  # Combine info and data
  climData <- cbind(join[ , c("code", "inst", "code", "station", "inst","lon", "lat", "alt", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec", "nyears")])
  names(climData) <- c("ID", "SOURCE", "OLD_ID","NAME","COUNTRY","LONG","LAT","ALT","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","NYEARS")
  
  # Write climatology 
  if(var == "prec"){
    write.csv(climData, paste0(oDir, "/rain_", sY, "_", fY, ".csv"), row.names=F)
  } else {
    write.csv(climData, paste0(oDir, "/", var, "_", sY, "_", fY, ".csv"), row.names=F)
  }
  
}


##################################
### 05 - Add Pseudo-stations #####
##################################

add_pseudost =function(dDir ="S:/observed/gridded_products/chirps/monthly/world", bDir ="Z:/DATA/WP2/01_Weather_Stations/MERGE/climatology", rDir ="Z:/DATA/WP2/00_zones", oDir="", dst_name ="chrips", sY =1981, fY =2010, var ="prec", srtm){
  
  require(raster)
  require(rgdal)
  require(dismo)
  require(som)
  library(sp)
  library(KernSmooth)
  
  wDir = "D:/Workspace"
  if (!file.exists(wDir)) {dir.create(wDir, recursive = TRUE)}
  rasterOptions(tmpdir= wDir)
  
  # List of months
  mthLs <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")
  
  # Create output dir
  if (!file.exists(oDir)) {dir.create(oDir, recursive=T)}
  
  ## Region mask
  mask <- crop(raster(srtm), extent(rg)) * 0 + 1
  # depLim <- raster(paste0(rDir, "/rg_poly_amz"))
  refExt <- extent(mask)
  writeRaster(mask, paste0(oDir, "/mask.tif"), overwrite=T)
  
  ## Load original station data to 
  if (var == "prec"){
    raw_data <- read.csv(paste0(bDir, "/rain_", sY, "_", fY, ".csv"))  
  } else {
    raw_data <- read.csv(paste0(bDir, "/", var, "_", sY, "_", fY, ".csv"))  
  }
  
  # Fit with kernell model
  points <- raw_data
  coordinates(points) <- ~LONG+LAT
  
  est <- bkde2D(coordinates(points), 
                bandwidth=c(0.5,0.5), 
                gridsize=c(nrow(mask),ncol(mask)),
                range.x=list(c(xmin(refExt),xmax(refExt)),c(ymin(refExt),ymax(refExt))))
  #   est$fhat[est$fhat<0.00001] <- 0 ## ignore very small values
  
  # create raster
  wgRs = raster(list(x=est$x1,y=est$x2,z=est$fhat)) * 10000
  
  ## Read CHRIPS output data, write in a friendly format
  # Cut border and calc 30yr avg
  if (var == "prec"){
    if (!file.exists(paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_12.tif"))) {
      dir.create(paste0(dDir, "/30yr_", sY, "_", fY), recursive=T)
      for (i in 1:12){
        rs <- mean(stack(paste0(dDir, "/v2p0chirps", sY:fY, sprintf("%02d", i), ".bil")))
        writeRaster(rs, paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_", i, ".tif"), format="GTiff", overwrite=T, datatype='INT2S')
      }
    }
  } else {
    
    if (dst_name == "AGMERRA"){
      if (!file.exists(paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_12.tif"))) {
        dir.create(paste0(dDir, "/30yr_", sY, "_", fY), recursive=T)
        for (i in 1:12){
          rs <- rotate(mean(stack(paste0(dDir, "/", var, "_monthly_ts_agmerra_1980_2010.nc"))[[seq(i + 12, 12*31, 12)]]))
          writeRaster(rs, paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_", i, ".tif"), format="GTiff", overwrite=T) #, datatype='INT2S')
        }
      }
    }
    
    if (dst_name == "terraclimate"){
      
      dir.create(paste0(dDir, "/30yr_", sY, "_", fY), recursive=T)
      for (i in 1:12){
        if (!file.exists(paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_", i, ".tif"))) {
          rs <- mean(stack(paste0(dDir, "/TerraClimate_", var, "_", sY:fY, ".nc"))[[seq(i, 12*(fY-sY+1), 12)]])
          writeRaster(rs, paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_", i, ".tif"), format="GTiff", overwrite=T) #, datatype='INT2S')
        }
      }
      
    }
    
  }
  
  rs_clip <- crop(stack(paste0(dDir, "/30yr_", sY, "_", fY, "/", var, "_", 1:12, ".tif")), refExt)
  rs_agg <- rs_clip
  if (var == "prec"){
    rs_agg <- aggregate(rs_clip, fact=0.1/res(rs_clip)[1])
  }
  rs_agg[rs_agg < 0] <- NA 
  
  # Gap mask calcs
  gap <- rasterize(cbind(raw_data$LONG, raw_data$LAT), rs_agg, 1, fun=mean)
  gap[is.na(gap)] <- 0 
  gap[gap==1] <- NA 
  gap <- mask(gap, resample(mask, gap))
  
  wgRs <- resample(wgRs, rs_agg)
  # wgRs <- setMinMax(raster(paste0(rDir, "/rg_weigth_1deg_", var, ".tif"))) ## Calc random points based on kernel-density function (computed in ArcGIS)
  wgGap <- mask(1-(wgRs/(maxValue(wgRs)- minValue(wgRs))), gap)
  wgGap[wgGap<0.00001] <- 0
  
  # Calculate the density within departaments based on raw_data
  # gapMsk <- mask(setExtent(crop(gap, extent(depLim)), extent(depLim), keepres = F) , depLim)
  denPres <- nrow(raw_data)/length(rs_agg[[1]][!is.na(rs_agg[[1]])])
  
  if (var == "prec"){
    npts <- 0.5 * length(rs_agg[[1]][!is.na(rs_agg[[1]])]) * denPres#     
  } else {
    npts <- 0.4 * length(rs_agg[[1]][!is.na(rs_agg[[1]])]) * denPres#     
  }
  
  if (file.exists(paste0(oDir, "/tmax_", sY, "_", fY, ".csv"))){
    pts <- read.csv(paste0(oDir, "/tmax_", sY, "_", fY, ".csv"), header = T)
    pts <- pts[pts$SOURCE == dst_name,][,6:7]
  } else {
    pts <- as.data.frame(randomPoints(wgGap, n=npts, ext=refExt, prob=T))  
  }
  
  rs_pts <- extract(rs_clip, pts)
  alt <- extract(raster(srtm), pts)
  
  if (var == "prec"){
    rs_pts[rs_pts < 0] <- NA  
  } else {
    rs_pts[rs_pts < -50] <- NA  
  }
  
  alt[is.na(alt)] <- NA
  
  # Combine info and data
  climData <- as.data.frame(cbind(paste0(dst_name, 1:nrow(pts)), dst_name, paste0(dst_name, 1:nrow(pts)), paste0(dst_name, 1:nrow(pts)), "HND", round(pts, 3), alt, round(rs_pts, 1), fY-sY+1))
  names(climData) <- c("ID", "SOURCE", "OLD_ID","NAME","COUNTRY","LONG","LAT","ALT","JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","NYEARS")
  
  combClimData <- na.omit(rbind(raw_data, climData))
  
  if(var == "prec"){
    write.csv(combClimData,  paste0(oDir, "/rain_", sY, "_", fY, "_v2.csv"), row.names = F)  
  } else {
    write.csv(combClimData,  paste0(oDir, "/", var, "_", sY, "_", fY, ".csv"), row.names = F)
  }
  
} 



# 03- Fill monthly dataset
bDir="W:/01_weather_stations/pnud_hnd/merge"
var <- "tmin"
sY=1981
fY=2010
oDir="W:/01_weather_stations/pnud_hnd/merge"
# dst_stk = paste0("S:/observed/gridded_products/cru-ts-v3-21/proces_data/tmn/tmn_", sY:fY, ".nc")
# varList <- c("tmax", "tmin")
# dDir = "S:/observed/gridded_products/chirps/monthly/world"  
# dst_name <- "AGMERRA"
dDir = "S:/observed/gridded_products/terra-climate"
dst_name = "terraclimate"

# for (var in varList){
fill_dst_mth(var, bDir, oDir, dDir, sY, fY, dst_name)
# }


# 04 - Clim calcs
rg=c(-90, -83, 12.3, 16.8)
bDir = "W:/01_weather_stations/pnud_hnd/merge"
oDir = "W:/01_weather_stations/pnud_hnd/merge/climatology"
stDir= "W:/01_weather_stations/pnud_hnd/merge"
dst_name = "terraclimate"
srtm <- "S:/observed/gridded_products/srtm/Altitude_30s/alt" 
varList <- c("tmax", "tmin")
sY = 1981
fY = 2010

for (var in varList){
  clim_calc(var, bDir, oDir, stDir, sY, fY, srtm, dst_name)
}


# 05 - Add pseudo-stations
bDir <- "W:/01_weather_stations/pnud_hnd/merge/climatology"
srtm <- "S:/observed/gridded_products/srtm/Altitude_30s/alt"
oDir <- "W:/01_weather_stations/pnud_hnd/merge/combined"
rg=c(-90, -83, 12.3, 16.8)

sY <- 1981
fY <- 2010
# varList <- c("prec", "tmax", "tmin")

var <- "prec"
dDir <- "S:/observed/gridded_products/chirps/monthly/world"
dst_name <- "CHIRPS"
# dDir <- "U:/cropdata/agmerra/monthly"
# dst_name <- "AGMERRA"
# dDir = "S:/observed/gridded_products/terra-climate"
# dst_name = "terraclimate"

add_pseudost(dDir, bDir, rDir, oDir, dst_name, sY, fY, var, srtm)

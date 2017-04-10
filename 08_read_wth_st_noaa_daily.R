# Julian Ramirez-Villegas
# UoL / CCAFS / CIAT
# December 2011
# Modified by Carlos Navarro (Mar 2017)

stop("error")

# Set libraries
require(raster); require(maptools); require(rgdal)

#Set parameters
src.dir <- "D:/CIAT/_tools/usaid_hnd"
var <- "tmin"
reg <- "hnd"
bDir <- "S:/observed/weather_station/ghcn/raw"; setwd(bDir)
ghcnDir <- paste(bDir,"/daily",sep="")
outDir <- "W:/01_weather_stations/hnd_noaa/daily_raw"

# Load main functions 
source(paste(src.dir,"/GHCND-GSOD-functions.R",sep=""))

# Read stations locations
stations.ghcn <- read.fortran(paste(ghcnDir,"/ghcnd-stations.txt",sep=""), 
                              format=c("A11","F9","F10","F7","1X","A2","1X","A31","A3","1X","A3","I6"))
names(stations.ghcn) <- c("ID","LAT","LON","ALT","STATE","NAME","GSN_FLAG","HCN_FLAG","WMO_ID")

# Create extents
rg.xt <- extent(-90, -82, 12, 17) 

# Make inventory of data (points / day / fit region) [transform all data to suitable format] select stations within 3+degree of interpolation extents
ghcn.rg <- stations.ghcn[which(stations.ghcn$LON>=(rg.xt@xmin-1) & stations.ghcn$LON<=(rg.xt@xmax+1) & stations.ghcn$LAT>=(rg.xt@ymin-1) & stations.ghcn$LAT<=(rg.xt@ymax+1)),]
#plot(ghcn.rg$LON,ghcn.rg$LAT,pch=20,cex=0.7)

# Define initial and final year
yearSeries <- c(1960:2017)


##############################################################################
########################### FOR GHCN-Daily ###################################
##############################################################################

# Create matrix of dates*stations for a given year to then use apply to get the data. 
ghcn.dates <- as.data.frame(matrix(ncol=367,nrow=nrow(ghcn.rg))) #matrix
colnames(ghcn.dates) <- c("ID",1:366) #names of columns
ghcn.dates$ID <- ghcn.rg$ID #stations IDs into dates matrix

# Create output directories
ddir <- paste(ghcnDir,"/ghcnd_all",sep="")
odir <- paste(outDir,"/_primary/ghcnd/ghcn_", reg, "_", var, sep="")
if (!file.exists(odir)) {dir.create(odir, recursive = T)}

#do the snowfall stuff here
library(snowfall)
sfInit(parallel=T,cpus=2) #initiate cluster

#export functions
sfExport("convertGHCND")
sfExport("createBaseMat")
sfExport("leap")
sfExport("getDataGHCN")
sfExport("searchData")

#export variables
sfExport("ddir")
sfExport("odir")
sfExport("bDir")
sfExport("var")

count <- 1
for (id in ghcn.dates$ID) {
  cat(id,paste("(",count," out of ",length(ghcn.dates$ID),")",sep=""),"\n")
  outDir <- paste(odir,"/",id,sep="")
  if (file.exists(outDir)) { #check if files exist in folder
    fl <- list.files(outDir,pattern=".csv")
  } else {
    fl <- 0
  }
  
  # if (length(fl) != 51) {
    controlConvert <- function(i) { #define a new function
      convertGHCND(id,i,var,ddir,odir)
    }
    sfExport("id")
    system.time(sfSapply(as.vector(yearSeries), controlConvert))
  # }
  count <- count+1
}

sfStop()

#ghcn.dates[1,2:(nday+1)] <- wData$PRCP #to put data into complete matrix for that year


#  Merge all years in one single file by station
varLs <- c("prec", "tmax", "tmin")

for(var in varLs){
  stations <- list.dirs(odir, full.names = F, recursive = F)
  stations <- stations[stations != ""]
  outForDir <- paste0(outDir, "/", var, "-per-station")
  if (!file.exists(outForDir)) {dir.create(outForDir, recursive = T)}
  
  for (s in 1:length(stations)){
    
    data <- lapply(paste0(odir, "/", stations[s], "/", yearSeries, ".csv"), function(x){read.csv(x, header=T)})
    
    allyears <- c()
    
    for (j in 1:length(data)){
      
      allyears <- rbind(allyears, cbind(paste0(yearSeries[j], sprintf("%02d", data[[j]]$MONTH), sprintf("%02d", data[[j]]$DOFM)), data[[j]][,4]))
      
    }
    
    cat(" >. Writing", stations[s], var, "\n")
    colnames(allyears) <- c("Date", "Value")
    write.table(allyears, paste0(outForDir, "/", tolower(stations[s]), "_raw_", var, ".txt"), row.names=F, quote=F, sep="\t")
    
  }
  
  # Get metadata from GHCN general catalog
  stations <- as.matrix(stations)
  colnames(stations)  <- "ID"
  summary <- merge(stations,  stations.ghcn, by=c("ID"), all=FALSE)
  summary <- cbind(summary, VAR=var)
  
  # Write catalog file
  if (!file.exists(paste0(outDir, "/stations_catalog_ghcn.csv"))){
    write.csv(summary, paste0(outDir, "/stations_catalog_ghcn.csv"), row.names=F)
  } else {
    write.table(summary, paste0(outDir, "/stations_catalog_ghcn.csv"), append=T, row.names=F, sep=",", col.names = F)
  }
  
}




##############################################################################
########################### FOR GSOD-Daily ###################################
##############################################################################

stop("error")

require(raster); require(maptools); require(rgdal)
src.dir <- "D:/CIAT/_tools/usaid_hnd"
source(paste(src.dir,"/GHCND-GSOD-functions.R",sep=""))

#base dir
bDir <- "S:/observed/weather_station/gsod"; setwd(bDir)
gsodDir <- paste(bDir,"/organized-data",sep="")
odir <- "W:/01_weather_stations/hnd_noaa/daily_raw"
reg <- "amz"

#gsod stations
stations.gsod <- read.csv(paste(gsodDir,"/ish-history.csv",sep=""))
stations.gsod$LON <- stations.gsod$LON/1000; stations.gsod$LAT <- stations.gsod$LAT/1000
stations.gsod$ELEV..1M. <- stations.gsod$ELEV..1M./10

#projection extents
rg.xt <- extent(-90, -82, 12, 17) 

#define initial and final year
yearSeries <- c(1960:2017)

#select stations within 3+degree of interpolation extents
gsod.reg <- stations.gsod[which(stations.gsod$LON>=(rg.xt@xmin-1) & stations.gsod$LON<=(rg.xt@xmax+1)
                                & stations.gsod$LAT>=(rg.xt@ymin-1) & stations.gsod$LAT<=(rg.xt@ymax+1)),]
st_ids <- paste(gsod.reg$USAF,"-",gsod.reg$WBAN,sep="")
usaf_ids <- gsod.reg$USAF
st_loc <- as.data.frame(cbind("Station"=gsod.reg$USAF, "Name"=gsod.reg$STATION.NAME, "Lon"=gsod.reg$LON, "Lat"=gsod.reg$LAT, "Alt"=gsod.reg$ELEV..1M.))

#do the snowfall stuff here
library(snowfall)
sfInit(parallel=T,cpus=1) #initiate cluster

#export functions
sfExport("convertGSOD")
sfExport("createDateGrid")
sfExport("leap")

#export variables
sfExport("bDir")

IDs <- paste("USAF",gsod.reg$USAF,"_WBAN",gsod.reg$WBAN,sep="")

count <- 1
for (yr in yearSeries) {
  cat(yr,paste("(",count," out of ",length(yearSeries),")",sep=""),"\n")
  gdir <- paste(gsodDir,"/",yr,sep="")
  ogdir <- paste(odir,"/_primary/gsod", sep=""); if (!file.exists(ogdir)) {dir.create(ogdir, recursive=T)}
  controlConvert <- function(i) { #define a new function
    convertGSOD(i,yr,gdir,ogdir)
  }
  sfExport("yr"); sfExport("gdir"); sfExport("ogdir")
  system.time(sfSapply(as.vector(IDs), controlConvert))
  count <- count+1
}


#  Merge all years in one single file by station
varLs <- c("prec", "tmax", "tmin")
gsod.reg <- cbind(gsod.reg, ID=st_ids)
summary <- c()

for (s in 1:length(st_ids)){
  
  data <- lapply(list.files(paste0(odir, "/_primary/gsod"), pattern = st_ids[s], full.names = T), function(x){read.csv(x, header=T)})
  if (length(data) > 0){
    for (var in varLs){
      
      allyears <- c()
      
      for (j in 1:length(data)){
        
        date_gsod <- format(as.Date(paste0(data[[j]]$YEAR, sprintf("%02d", data[[j]]$MONTH), sprintf("%02d", data[[j]]$DAY)), format="%Y%m%d"),format="%Y%m%d")
        
        if (var == "prec"){
          value <- as.numeric(data[[j]]$RAIN)
        } else if (var == "tmax") {
          value <- as.numeric(data[[j]]$TMAX)
        } else if (var == "tmin") {
          value <- as.numeric(data[[j]]$TMIN)
        }
        
        st_var <- cbind(date_gsod, value)
        allyears <- rbind(allyears, st_var)  
        
      }
      
      outForDir <- paste0(odir, "/", var, "-per-station")
      if (!file.exists(outForDir)) {dir.create(outForDir, recursive = T)}
      
      cat(" >. Writing", st_ids[s], var, "\n")
      colnames(allyears) <- c("Date", "Value")
      write.table(allyears, paste0(outForDir, "/", tolower(st_ids[s]), "_raw_", var, ".txt"), row.names=F, quote=F, sep="\t")
      
      summary <- rbind(summary, cbind(gsod.reg[which(gsod.reg$ID == st_ids[s]),], VAR=var))
      
    }  
  }
  
  
  
}


# Write catalog file
if (!file.exists(paste0(outDir, "/stations_catalog_gsod.csv"))){
  write.csv(summary, paste0(outDir, "/stations_catalog_gsod.csv"), row.names=F)
} else {
  write.table(summary, paste0(outDir, "/stations_catalog_gsod.csv"), append=T, row.names=F, sep=",", col.names = F)
}


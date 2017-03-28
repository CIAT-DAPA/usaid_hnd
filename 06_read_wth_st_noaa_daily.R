#Julian Ramirez-Villegas
#UoL / CCAFS / CIAT
#December 2011
stop("error")

#Set parameters
src.dir <- "D:/CIAT/_tools/usaid_hnd"
var <- "prec"
bDir <- "S:/observed/weather_station/ghcn/raw"; setwd(bDir)
ghcnDir <- paste(bDir,"/daily",sep="")
outDir <- "W:/01_weather_stations/hnd_noaa/daily_raw"

source(paste(src.dir,"/GHCND-GSOD-functions.R",sep=""))

#read stations locations
stations.ghcn <- read.fortran(paste(ghcnDir,"/ghcnd-stations.txt",sep=""),
                              format=c("A11","F9","F10","F7","1X","A2","1X","A31","A3","1X","A3","I6"))
names(stations.ghcn) <- c("ID","LAT","LON","ALT","STATE","NAME","GSN_FLAG","HCN_FLAG","WMO_ID")
#plot(stations$LON,stations$LAT,pch=20,cex=0.7)

#1. create extents
require(raster); require(maptools); require(rgdal)

#Study Region region
rg.xt <- extent(-90, -82, -17, 12) 

#2. define working gridcell
cellSize <- 1

#3. Make inventory of data (points / day / fit region) [transform all data to suitable format]
#select stations within 3+degree of interpolation extents
ghcn.rg <- stations.ghcn[which(stations.ghcn$LON>=(rg.xt@xmin-3) & stations.ghcn$LON<=(rg.xt@xmax+3)
                               & stations.ghcn$LAT>=(rg.xt@ymin-3) & stations.ghcn$LAT<=(rg.xt@ymax+3)),]

#create matrix of dates*stations for a given year to then use apply to get the data
#define initial and final year
yearSeries <- c(1960:2017)

########################### FOR GHCN-D #######################################
####################################### ######################################
ghcn.dates <- as.data.frame(matrix(ncol=367,nrow=nrow(ghcn.rg))) #matrix
colnames(ghcn.dates) <- c("ID",1:366) #names of columns
ghcn.dates$ID <- ghcn.rg$ID #stations IDs into dates matrix
ddir <- paste(ghcnDir,"/ghcnd_all",sep="")
odir <- paste(outDir,"/ghcn.rg.", var, sep=""); if (!file.exists(odir)) {dir.create(odir)}

#do the snowfall stuff here
library(snowfall)
sfInit(parallel=T,cpus=10) #initiate cluster

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

count <- 1
for (id in ghcn.dates$ID) {
  cat(id,paste("(",count," out of ",length(ghcn.dates$ID),")",sep=""),"\n")
  outDir <- paste(odir,"/",id,sep="")
  if (file.exists(outDir)) { #check if files exist in folder
    fl <- list.files(outDir,pattern=".csv")
  } else {
    fl <- 0
  }
  
  if (length(fl) != 51) {
    controlConvert <- function(i) { #define a new function
      convertGHCND(id,i,ddir,odir)
    }
    sfExport("id")
    system.time(sfSapply(as.vector(yearSeries), controlConvert))
  }
  count <- count+1
}

sfStop()

#ghcn.dates[1,2:(nday+1)] <- wData$PRCP #to put data into complete matrix for that year


# #  Merge all years in one single file
# stations <- list.dirs(odir, full.names = F)
# stations <- stations[stations != ""]
# 
# dates <- seq(as.Date("1960/1/1"), as.Date("2010/12/31"), "days")
# dates = format(dates,"%Y%m%d")
# dates = cbind.data.frame("Date"=dates,"NA")
# 
# mat <- as.data.frame(matrix(NA,366,length(stations)))
# 
# for (s in 1:length(stations)){
#   
#   years <- list.files(paste0(odir, "/", stations[s]), full.names = F)
#   data <- lapply(paste0(odir, "/", stations[s], "/", years), function(x){read.csv(x, header=T)})
#   
#   allyears <- c()
#   
#   for (j in 1:length(data)){
#     
#     allyears <- rbind(allyears, cbind(paste0(strsplit(years[j],".csv")[1], sprintf("%02d", data[[j]]$MONTH), sprintf("%02d", data[[j]]$DOFM)), data[[j]][,4]))
#     
#   }
#   
#   names(allyears) <- c("Date", stations[s])
#   datSt <- merge(dates,allyears[[j]],by="Date",all.x=T)
#   datosprecip[,j]=final[,3]
#   mat[,j] = allyears
#   
# }





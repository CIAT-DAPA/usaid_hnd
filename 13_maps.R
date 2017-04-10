# Created by: Lizeth Llanos
# This script make the selection of good stations
# April 2017

require(raster)
require(grid)
require(ggplot2)
require(rgeos)

# Define variable
variable = "tmax"

# Define input and ouput path
inDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/"
outDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/quality_control/tmax/"


# Load data base with all raw stations catalog with lat and long
data_station = read.csv(paste0(inDir,variable,"_daily_qc.csv"),header = T)
catalog = read.csv("X:/Water_Planning_System/01_weather_stations/catalog_daily.csv",header = T)

# Extract stations names
nomb = substring(names(data_station[,-1:-3]),2,nchar(names(data_station[,-1:-3])))
nomb_s = do.call("rbind",strsplit(nomb,"_"))
name_st = paste0(nomb_s[,2]," (",nomb_s[,1],")")

# Define period from data
dates=seq(as.Date("1980/1/1"), as.Date("2016/12/31"), "days") 

# Summary function
summary_st = t(apply(data_station[-1:-3],2,summary))
summary_st = as.data.frame(cbind(nomb_s, summary_st[,c(1,6,3,4)], round(summary_st[,7]/nrow(data_station),2)))
names(summary_st) = c("cod","name_st","min","max","mediana","media","datos_faltantes")
rownames(summary_st) = NULL

pos = which(catalog$national_code %in% as.numeric(as.character(summary_st$cod)))
summary_st$lat =catalog$latitudeDD[pos]
summary_st$long =catalog$longitudeDD[pos]

write.csv(summary_st,paste0(outDir,"summary_all_st_tmax_qc.csv"),row.names = F,quote = F)

summary_st$datos_faltantes = as.numeric(as.character(summary_st$datos_faltantes))*100

#########################
# Map missing values
#########################

honduras = shapefile("X:/Water_Planning_System/03_geodata/HND_adm/HND_adm1.shp") #Modificar ruta de la ubicación del shapefile
hnd=extent(-84.7,-89.2,12.9,16)
honduras=crop(honduras,hnd)

name ="Porcentaje" ; uplimit <- 0; dwlimit <- 100; step <- 20; low <- "red"; mid <- "yellow"; high <- "blue"; uplimit_size <- 0; dwlimit_size <- 1; step_size <- 0.2; size = 1.2

honduras@data$id <- rownames(honduras@data)
honduras@data$id_dpto <-rep(0,nrow(honduras@data))
honduras@data$id_dpto[c(4,9,11,13,14,15)] <- 1
honduras2 <- fortify(honduras, region="id")
#honduras2<- fortify(honduras, region="id_dpto")
p <- ggplot(honduras2, aes(x=long,y=lat))
p <- p + geom_polygon(aes(fill=hole,group=group),fill="grey 80")
p <- p + scale_fill_manual(values=c("grey 80","grey 80"))
p <- p + geom_path(aes(long,lat,group=group,fill=hole),color="white",size=0.3)

p <- p + geom_point(data=summary_st, aes(x=long, y=lat, map_id=name_st,col=datos_faltantes),size=3)+
  geom_point(data=summary_st,aes(x=long, y=lat),shape = 1,size = 3,colour = "black")

p <- p +scale_color_gradient2(name=name, low = low, mid = mid, high = high,
                              limits=c(uplimit,dwlimit), guide="colourbar",
                              breaks=seq(uplimit,dwlimit,by=step), labels=paste(seq(uplimit,dwlimit,by=step)))

p <- p + coord_equal()
p <- p + theme(legend.key.height=unit(1.7,"cm"),legend.key.width=unit(1,"cm"),
               legend.text=element_text(size=10),
               panel.background=element_rect(fill="white",colour="black"),
               axis.text=element_text(colour="black",size=10),
               axis.title=element_text(colour="black",size=12,face="bold"))

p <- p +labs(title = "Datos faltantes para el período 1980-2016", x = "Longitud", y = "Latitud") 

tiff(paste(outDir,"map_faltantes_tmax",".tif",sep=""), height=2048,width=1500,res=200,
     pointsize=1.5,compression="lzw")
print(p)
dev.off()


#########################
# Barplot missing values by year
#########################


DtSel <- data_station[,colSums(is.na(data_station)) < nrow(data_station)]
DtSel<- DtSel[,(colSums(is.na(DtSel)) / nrow(DtSel)) < 0.66]  

dates <- paste0(data_station$year, sprintf("%02d", data_station$month), sprintf("%02d", data_station$day) )
dates <- as.Date(as.character(dates), format = "%Y%m%d")


posMt = as.data.frame(matrix(NA, nrow(DtSel), ncol(DtSel)-3))
nbreaks <- 5
for(j in 1:ncol(posMt)){ posMt[,j] <- (j - 1) * nbreaks }

# Data transformation
require(reshape)
DtSel <- cbind("Date" = dates, DtSel[,4:ncol(DtSel)] * 0 + posMt)
DtSel_ls <- melt(DtSel, id.vars="Date")
max <- max(DtSel_ls$value, na.rm = T)

  color="steelblue"
  
  
  tiff(paste(outDir, "/temporal_coverage_", variable,"_na.tif", sep=""), width=1500, height = 2500, pointsize=3, compression='lzw',res=150)
  
  p1 <- ggplot(DtSel_ls, aes(x=Date, y=value, group=variable, size=nbreaks)) + geom_line(color=color) +
    scale_y_continuous(breaks=seq(0, max, nbreaks), labels=substring(unique(DtSel_ls$variable),2,nchar(as.character(unique(DtSel_ls$variable)))), expand = c(0, 0)) + 
    labs(y = "Estaciones") + #scale_x_date(date_breaks = "2 years", date_labels = "%Y")+
      theme(legend.position="none")
  print(p1)
  dev.off()  
          
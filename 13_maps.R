# Created by: Lizeth Llanos
# This script make charts for NA data
# April 2017

library(raster)
library(grid)
library(ggplot2)
library(rgeos)
library(reshape)

# Define variable
# variable = "tmax"
 variable = "tmin"
# variable = "prec"


# Define input and ouput path
inDir = "X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_processed/"
outDir = paste0("X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_processed/quality_control/",variable,"/")


# Load data base with all raw stations catalog with lat and long
data_station.ini = read.csv(paste0(inDir,variable,"_daily_qc.csv"),header = T)

catalog = read.csv("X:/Water_Planning_System/01_weather_stations/catalog_daily.csv",header = T)
catalog = catalog[which(catalog$variable==variable),]
catalog = catalog[which(catalog$operator=="ENEE"),]

# Define period from data
dates=seq(as.Date("1990/1/1"), as.Date("2016/12/31"), "days") 

data_station = data_station.ini[which(data_station.ini$year %in% as.numeric(unique(format(dates,"%Y")))),]

# Extract stations names
nomb = substring(names(data_station[,-1:-3]),2,nchar(names(data_station[,-1:-3])))
nomb_s = do.call("rbind",strsplit(nomb,"_"))
name_st = paste0(nomb_s[,2]," (",nomb_s[,1],")")

# Summary function
summary_st = cbind(apply(data_station[,-1:-3],2,min,na.rm=T),apply(data_station[,-1:-3],2,max,na.rm=T),apply(data_station[,-1:-3],2,function(x) sum(is.na(x))/length(x)))
summary_st = as.data.frame(cbind(nomb_s, summary_st))
names(summary_st) = c("cod","name_st","min","max","datos_faltantes")
#pos = which(as.character(summary_st$cod) %in% as.character(catalog$national_code))
summary_st$lat =catalog$latitudeDD
summary_st$long =catalog$longitudeDD

rownames(summary_st) = NULL
write.csv(summary_st,paste0(outDir,"summary_all_st_",variable,"_qc.csv"),row.names = F,quote = F)

summary_st$datos_faltantes = as.numeric(as.character(summary_st$datos_faltantes))*100

#########################
# Map missing values
#########################

map_na = function(summary_st,years,variable,outDir,shape_dir){
  if(variable=="prec"){
    variable_n = "Precipitación"
  }
  if(variable=="tmax"){
    variable_n = "Temperatura máxima"
  }
  if(variable=="tmin"){
    variable_n = "Temperatura mínima"
  }
  
  honduras = shapefile(shape_dir) #Modificar ruta de la ubicación del shapefile
  hnd=extent(-84.7,-89.2,12.9,16)
  honduras=crop(honduras,hnd)
  
  name ="Porcentaje" ; uplimit <- 0; dwlimit <- 100; step <- 10; low <- "green"; mid <- "yellow"; high <- "red"; uplimit_size <- 0; dwlimit_size <- 1; step_size <- 0.1; size = 1.2
  
  honduras@data$id <- rownames(honduras@data)
  #honduras@data$id_dpto <-rep(0,nrow(honduras@data))
  #honduras@data$id_dpto[c(4,9,11,13,14,15)] <- 1
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
  
  p <- p +labs(title = paste0("Datos faltantes para la variable de ",variable_n," en el período ",years), x = "Longitud", y = "Latitud") +
    ylim(12.9,16) + xlim(-89.2,-84.7)
  
  tiff(paste(outDir,"map_faltantes_",variable,"_",years,".tif",sep=""), height=2048,width=1500,res=200,
       pointsize=1.5,compression="lzw")
  print(p)
  dev.off()
}

shape_dir = "X:/Water_Planning_System/03_geodata/HND_adm/HND_adm1.shp"
years = paste0(min(unique(format(dates,"%Y"))),"-",max(unique(format(dates,"%Y"))))

map_na(summary_st,years,variable,outDir,shape_dir)

#########################
# Barplot missing values by year
#########################

barplot_na = function(data_station,outDir){

DtSel <- data_station[,colSums(is.na(data_station)) < nrow(data_station)]
DtSel<- DtSel[,(colSums(is.na(DtSel)) / nrow(DtSel)) < 0.66]  

dates <- paste0(data_station$year, sprintf("%02d", data_station$month), sprintf("%02d", data_station$day) )
dates <- as.Date(as.character(dates), format = "%Y%m%d")


posMt = as.data.frame(matrix(NA, nrow(DtSel), ncol(DtSel)-3))
nbreaks <- 5
for(j in 1:ncol(posMt)){ posMt[,j] <- (j - 1) * nbreaks }

# Data transformation

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
          
}

barplot_na(data_station,outDir)

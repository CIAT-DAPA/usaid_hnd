#######################################################
###Script para organizar inputs para RClimTool
####Lizeth Llanos
#######################################################


# rutOrigen="S:/observed/weather_station/col-ideam/daily-raw/tmax-per-station" #Ruta donde se encuentran los archivos .txt
# rutOrigen="S:/observed/weather_station/col-ideam/daily-raw/tmin-per-station" #Ruta donde se encuentran los archivos .txt
rutOrigen="X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/prec-per-station" #Ruta donde se encuentran los archivos .txt


files <-list.files(rutOrigen,pattern="\\.txt$")
nom.files<-substring(files,1,nchar(files)-13)
#nom.files=as.numeric(nom.files[-length(nom.files)])

idstation=read.csv("X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/stations_catalog.csv",header=T) #Cargar base con código y nombre de la estación
CODIGO=idstation[,2]

where <- match( CODIGO,nom.files)
station_find=nom.files[where[which(!is.na(where))]]
station_find_n1=idstation[which(where!="NA"),1]



x=seq(as.Date("1980/1/1"), as.Date("2015/12/31"), "month") #Definir periodo que se desea analizar

fechas=format(x,"%Y%m")
fechas=cbind.data.frame("Date"=fechas,"NA")

Datos <- lapply(paste(rutOrigen,"/",station_find,"_raw_prec.txt",sep=""),function(x){read.table(x,header=T,sep=" ")})

Rain = Datos
datosprecip=as.data.frame(matrix(NA,nrow(fechas),length(Rain)))



for(j in 1:length(Rain)) {  
  
  old=na.omit(Rain[[j]])
  if(nrow(old)!=0){
    combnew=old[!duplicated(old[,1]),]
  }else{
    combnew = old
  }
  
  
  final=merge(fechas,combnew,by="Date",all.x=T)
  #if(nrow(final)==nrow(datosprecip)){
    datosprecip[,j]=final[,3]
  #}
  
}

year=as.numeric(substr(fechas[,1],1,4))
month=as.numeric(substr(fechas[,1],5,6))
#day=as.numeric(substr(fechas[,1],7,8))


# tmaxfin=cbind(day,month,year,datostmax)
# tminfin=cbind(day,month,year,datostmin)
precipfin=cbind(month,year,datosprecip)

# names(tmaxfin)=c("day","month","year",as.character(station_find_n1))
# names(tminfin)=c("day","month","year",as.character(station_find_n1))
names(precipfin)=c("month","year",as.character(station_find_n1))


#Se guardan los archivos en formato .csv con la info organizada
# write.csv(tmaxfin,paste("tmax_all.csv",sep=""),row.names=F)
# write.csv(tminfin,paste("tmin_all.csv",sep=""),row.names=F)
write.csv(precipfin,paste("hnd_precip_all.csv",sep=""),row.names=F)

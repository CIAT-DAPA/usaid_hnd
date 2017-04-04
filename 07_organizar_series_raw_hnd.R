#######################################################
## Organize data frame with all stations in a specific time period
## Created by: Lizeth Llanos
## March 2017
#######################################################

#Monthly data
rutOrigen="X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/prec-per-station" #Ruta donde se encuentran los archivos .txt
dir.create(paste0(outDir,"monthly_processed"),showWarnings = F)


files <-list.files(rutOrigen,pattern="\\.txt$")
nom.files<-substring(files,1,nchar(files)-13)

idstation=read.csv("X:/Water_Planning_System/01_weather_stations/hnd_dgrh/monthly_raw/stations_catalog.csv",header=T) #Cargar base con código y nombre de la estación
cod=idstation[,2]

where <- match( cod,nom.files)
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

precipfin=cbind(month,year,datosprecip)

names(precipfin)=c("month","year",as.character(station_find_n1))


#Se guardan los archivos en formato .csv con la info organizada
write.csv(precipfin,paste("hnd_precip_all.csv",sep=""),row.names=F)



#Daily data
rutOrigen = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_raw_org/prec-per-station/"
outDir ="X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/prec-per-station/" #Ruta donde se encuentran los archivos .txt
dir.create(paste0(outDir,"daily_processed"),showWarnings = F)


files <-list.files(rutOrigen,pattern="\\.txt$")
nom.files<-substring(files,1,nchar(files)-13)

idstation=read.csv("X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_raw/catalog_daily_dgrh.csv",header=T) #Cargar base con código y nombre de la estación
cod=as.character(idstation$national_code)
not_f = which(is.na(cod))
cod = cod[-not_f]

where <- match( cod,nom.files)
station_find_n=paste0(cod,"_",idstation[-not_f,1])

x=seq(as.Date("1980/1/1"), as.Date("2016/12/31"), "days") #Definir periodo que se desea analizar

fechas=format(x,"%Y%m%d")
fechas=cbind.data.frame("Date"=fechas,"NA")

Datos <- lapply(paste(rutOrigen,cod,"_prec_raw.txt",sep=""),function(x){read.table(x,header=T,sep="\t")})

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
day=as.numeric(substr(fechas[,1],7,8))

precipfin=cbind(day,month,year,datosprecip)

names(precipfin)=c("day","month","year",as.character(station_find_n))


#Se guardan los archivos en formato .csv con la info organizada
write.csv(precipfin,paste("X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/precip_daily_all.csv",sep=""),row.names=F)

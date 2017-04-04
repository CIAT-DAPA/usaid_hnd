#Created by: Lizeth Llanos
#This script merge files with the same name and rename files with the national code
#April 2017
rutOrigen = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/prec-per-station"
files <-list.files(rutOrigen,pattern="\\.txt$")
files = files [-3]
nom.files<-substring(files,1,nchar(files)-13)

idstation= na.omit(read.table("clipboard",header = T))
CODIGO=idstation[,1]

where <- match( CODIGO,nom.files)
station_find=nom.files[where[which(!is.na(where))]]

Datos <- lapply(paste(rutOrigen,"/",station_find,"_prec_raw.txt",sep=""),function(x){read.table(x,header=T,sep="\t")})
names(Datos) = station_find

for (i in 1:25){
  mer  = merge(Datos[[i]],Datos[[i+25]],by = "Date",all.x = T,all.y = T)[,1:2]
  names(mer)[2] = "Value"
 write.table(mer,paste0(rutOrigen,"/",station_find[i],"_prec_raw.txt"),sep = "\t",row.names = F,quote = F)
}


idstation= read.table("clipboard",header = T)
pos = which(is.na(idstation[,1]))
idstation = idstation[-pos,1]

rutOrigen = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/tmax-per-station"
files <-list.files(rutOrigen,pattern="\\.txt$")
files = files[-pos]

file.rename(paste0(rutOrigen,"/",files),paste0(rutOrigen,"/",idstation,"_tmax_raw.txt"))

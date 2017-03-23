## Created by: Lizeth Llanos
## Read daily data from drgh files
## March 2017

dir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_raw/_primary_files/lluvia actualizada 2016"
all_files = list.files(dir, full.names = T)
#file.rename(all_files,paste0(all_files,".txt")) #Run only the first time

Datos <- lapply(all_files,function(x){read.table(x,sep=" ",skip=4,header=F,na.strings = -1)})

x=all_files[1]
rl = readLines(x)[-1:-3]
d_ini = matrix(NA,length(rl),14)

for (i in 1:length(rl)){
 f = strsplit(rl[i],split="\\s+")[[1]]
 if(length(f)>1){
 
   if (length(f)==13){
     d_ini [i,1] = substring(f[1],1,nchar(f[1])-2)
     d_ini [i,2] = substring(f[1],nchar(f[1])-1,nchar(f[1]))
     d_ini [i,3:14] = f[2:13]
   }else{
     d_ini [i,] = f
   }
 }else{
   d_ini [i,] = NA
 }
}
 
d_ini = na.omit(d_ini)
d_ini[which(d_ini=="-1.0")] =NA
d_ini = as.data.frame(d_ini)
d_ini [,3:14] = apply(d_ini[-1:-2],2,as.numeric)
names(d_ini) = c("code", "day",1:12)

library(reshape2)
d_fin = melt(d_ini,id.vars = c("code","day"))

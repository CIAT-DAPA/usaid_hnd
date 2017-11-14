iDir <- "X:/Water_Planning_System/02_hydrological_stations/ENEE/monthly_raw/_primary_files"
sts <- list.files(iDir, pattern = "txt")


library(reshape2)

Datos <- lapply(paste(iDir,"/",sts,sep=""),function(x){read.table(x,header=T,sep="\t",na.strings = c("-","--"," "))})

x = Datos[[11]]
st=sts[11]
org = function(x,st){
  pos = which(x[,1]=="AÑO")
  x_n = x[(pos+1):(nrow(x)-3),-ncol(x)]
  #x_n = x_n[-which(as.character(x_n[,1])==""),]
  names(x_n) = c("year",1:12)
  
  x_m = melt(x_n,id.vars = "year")
  x_m = x_m[order(x_m[,1]),]
  
  names(x_m) = c("year","month","value")
  write.table(x_m,paste0("X:/Water_Planning_System/02_hydrological_stations/ENEE/monthly_raw/hdl-per-station/",st),row.names = F,quote = F,sep = "\t")
}

sapply(1:length(Datos),function(i) org(Datos[[i]],sts[i]))
View(x)

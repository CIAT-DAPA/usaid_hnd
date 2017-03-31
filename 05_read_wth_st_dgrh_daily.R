## Created by: Lizeth Llanos
## Read daily data from drgh files
## March 2017
library(stringr)
library(reshape2)

dir_in = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_raw/_primary_files/lluvia actualizada 2016"
dir_out = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_raw"
var = "prec"


all_files = list.files(dir_in, full.names = T)

#file.rename(all_files,paste0(all_files,".txt")) #Run this line only the first time
#x=all_files[2]
#tryCatch({}, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})

read_files = function(x,dir_out,var){
  tryCatch({
  rl = readLines(x)[-1:-3]
  d_ini = matrix(NA,length(rl),14)
  
  for (i in 1:length(rl)){
    f = strsplit(rl[i],split="\\s+")[[1]]
    
    e = which(f=="-")
    if(length(e)>0){f = f[-e]}
    
   # if(length(f)==13 || length(f)==14){
      
      if (length(f)==13 & nchar(f[1])>6){
        d_ini [i,1] = substring(f[1],1,nchar(f[1])-2)
        d_ini [i,2] = substring(f[1],nchar(f[1])-1,nchar(f[1]))
        d_ini [i,3:14] = f[2:13]
      }
      if(length(f)==14 & nchar(f[1])<=6){

          d_ini [i,] = f
        }
    #}
  }
  
  d_ini = na.omit(d_ini)
  d_ini[which(d_ini=="-1.0")] =NA
  d_ini = as.data.frame(d_ini)
  d_ini [,3:14] = apply(d_ini[,-1:-2],2,as.numeric)
  names(d_ini) = c("code", "day",1:12)
  
  d_fin = melt(d_ini,id.vars = c("code","day"))
  d_fin$year = as.numeric(substring(d_fin[,1],5,6))
  
  if(length(d_fin$year[which(d_fin$year>40)])>1){
    d_fin$year[which(d_fin$year>40)] = as.numeric(paste0(19,d_fin$year[which(d_fin$year>40)]))
  }
  
  if(length(d_fin$year[which(d_fin$year<=40)])>1){
    d_fin$year[which(d_fin$year<=40)] = as.numeric(paste0(20,str_pad(d_fin$year[which(d_fin$year<=40)],2, pad = "0")))
  }
  
  Date = paste0(d_fin$year,str_pad(d_fin$variable, 2, pad = "0"),str_pad(d_fin$day, 2, pad = "0"))
  
  d_write = cbind("Date"= Date,"Value" = d_fin$value)
  
  dir.create(paste0(dir_out,"/",var,"-per-station"),showWarnings = F)
  write.table(d_write,paste0(dir_out,"/",var,"-per-station/",tolower(substring(d_fin[1,1],1,4)),"_raw_",var,".txt"),quote = F,row.names = F, sep = "\t")
  
  cat(paste(substring(d_fin[1,1],1,4),"station done! \n",sep = " "))
  return(substring(d_fin[1,1],1,4))
  }, error=function(e){cat("ERROR :",conditionMessage(e), "\n")})
}


ctg = lapply(1:length(all_files),function(j) read_files(all_files[j],dir_out,var))

#write.csv(do.call("rbind",ctg),"cat.csv",row.names = F,quote = F)

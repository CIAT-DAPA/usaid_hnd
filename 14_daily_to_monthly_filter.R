# 
#  _____        _ _         _          __  __             _   _     _       
# |  __ \      (_) |       | |        |  \/  |           | | | |   | |      
# | |  | | __ _ _| |_   _  | |_ ___   | \  / | ___  _ __ | |_| |__ | |_   _ 
# | |  | |/ _` | | | | | | | __/ _ \  | |\/| |/ _ \| '_ \| __| '_ \| | | | |
# | |__| | (_| | | | |_| | | || (_) | | |  | | (_) | | | | |_| | | | | |_| |
# |_____/ \__,_|_|_|\__, |  \__\___/  |_|  |_|\___/|_| |_|\__|_| |_|_|\__, |
#                    __/ |                                             __/ |
#                   |___/                                             |___/ 
#                

mean22=function(a,na.rm=T){
  na.x=sum(is.na(a))/length(a)
  if(na.x>=0.5){
    x=NA
  }else{x=mean(a,na.rm=T)}
  
  return(x)
} 

sum22=function(a,na.rm=T){
  na.x=sum(is.na(a))/length(a)
  if(na.x>=0.25){
    x=NA
  }else{x=sum(a,na.rm=T)}
  
  return(x)
}


# hr=read.table("clipboard",header = T)
# precip=read.table("clipboard",header = T)
# tmax=read.table("clipboard",header = T)
# tmin=read.table("clipboard",header = T)
inDir = "X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_raw/test/daily_processed/"
outDir = "X:/Water_Planning_System/01_weather_stations/hnd_enee/daily_raw/test/"

tmax = read.csv(paste0(inDir,"tmax_daily_qc.csv"),header = T)
tmin = read.csv(paste0(inDir,"tmin_daily_qc.csv"),header = T)
prec = read.csv(paste0(inDir,"prec_daily_qc.csv"),header = T)
unique(apply(prec,2,class))

monthly_prec = aggregate(prec[-3:-1],list(month=prec$month,year=prec$year),sum22)
monthly_tmax = aggregate(tmax[-3:-1],list(month=tmax$month,year=tmax$year),mean22)
monthly_tmin = aggregate(tmin[-3:-1],list(month=tmin$month,year=tmin$year),mean22)

#aggregate(monthly_precip,list(monthly_precip$Mes),mean,na.rm=T)
dir.create(paste0(outDir,"/monthly_processed"))
dir.create(paste0(outDir,"/monthly_processed/tmax"))
dir.create(paste0(outDir,"/monthly_processed/tmin"))
dir.create(paste0(outDir,"/monthly_processed/prec"))


write.csv(monthly_tmax,paste0(outDir,"/monthly_processed/tmax/monthly_tmax.csv"),row.names = F)
write.csv(monthly_tmin,paste0(outDir,"/monthly_processed/tmin/monthly_tmin.csv"),row.names = F)
write.csv(monthly_prec,paste0(outDir,"/monthly_processed/prec/monthly_prec.csv"),row.names = F)


#Filter stations with na<=0.2
na = function(x) { na = sum(is.na(x))/length(x)
                    return(na)}

na_prec = apply(monthly_prec,2,na)
monthly_prec_f = monthly_prec[,which(na_prec<=0.4)]

#monthly_tmax = monthly_tmax[monthly_tmax$year %in% 1997:2016,]
na_tmax = apply(monthly_tmax,2,na)
monthly_tmax_f = monthly_tmax[,which(na_tmax<=0.4)]

#monthly_tmin = monthly_tmin[monthly_tmin$year %in% 1997:2016,]
na_tmin = apply(monthly_tmin,2,na)
monthly_tmin_f = monthly_tmin[,which(na_tmin<=0.4)]


write.csv(monthly_tmax_f,paste0(outDir,"/monthly_processed/tmax/filter_monthly_tmax.csv"),row.names = F)
write.csv(monthly_tmin_f,paste0(outDir,"/monthly_processed/tmin/filter_monthly_tmin.csv"),row.names = F)
write.csv(monthly_prec_f,paste0(outDir,"/monthly_processed/prec/filter_monthly_prec.csv"),row.names = F)

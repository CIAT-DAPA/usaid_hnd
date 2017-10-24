prec = read.csv("X:\\Water_Planning_System\\01_weather_stations\\hnd_all\\daily-indicators\\daily_prec_all.csv",header=T)
prec = prec[prec$year>=1990 & prec$year<=2014,]

days_y = aggregate(prec$year,list(prec$month,prec$year),length)
days_y$end = days_y$x-4


sum22=function(a,na.rm=T){
  na.x=sum(is.na(a))/length(a)
  if(na.x>=0.5){
    x=NA
  }else{x=sum(a,na.rm=T)}
  
  return(x)
}

final = matrix(NA,300,92)

for (i in 1:300){
  
  to = prec[prec$month==days_y$Group.1[i] & prec$year==days_y$Group.2[i],] 
  to.sum = to[days_y$end[i]:days_y$x[i],]
  final[i,] = apply(to.sum[-3:-1],2,sum22)
  
}

final = as.data.frame(final)
final = cbind(days_y[,1:2],final)
names(final) = names(prec)[-1]


clim = aggregate(final[-2:-1],list(final$month),mean,na.rm=T)

for (j in 1:92){
  pos = which(is.na(final[,j+2]))
  final[pos,j+2] = clim[final[pos,1],j+1]

}

write.csv(final,"X:\\Water_Planning_System\\01_weather_stations\\hnd_all\\daily-indicators\\cum_five_days2.csv",row.names = F)
final_1 = read.csv("X:\\Water_Planning_System\\01_weather_stations\\hnd_all\\daily-indicators\\cum_five_days.csv",header=T)

cod = substring(names(final_1),2,6)[-2:-1]
final2 = t(final_1)[-2:-1,]

for(x in 1:length(unique(final_1$year))){
  to.write = final2[,which(final_1$year==unique(final_1$year)[x])]
  colnames(to.write) = paste0("month_",1:12)
  to.write = cbind("cz_id"= cod, to.write)
  
  write.csv(to.write,paste0("X:\\Water_Planning_System\\01_weather_stations\\hnd_all\\daily-indicators\\5_last_days_month_",unique(final_1$year)[x],".csv"),row.names = F,quote = F)
}

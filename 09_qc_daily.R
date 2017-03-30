################################################################
# QC daily data


inDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/"
outDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/"

#dir.create(paste0(outDir,"daily_processed"),showWarnings = F)

data_station = read.csv(paste0(inDir,"precip_daily_all.csv"),header = T)
nomb = names(data_station[,-1:-3])

apply(data_station,2,summary)
dates=seq(as.Date("1980/1/1"), as.Date("2016/12/31"), "days") #Definir periodo que se desea analizar

graf_line = function(x,y,title,outDir){
  dir.create(paste0(outDir,"daily_processed/line_graph"),showWarnings = F)
  png(paste0(outDir,"daily_processed/line_graph/",title,".png"), width = 10, height = 4,units = 'in',res=200)
  plot(x,y,type="l",xlab="",ylab="Precipitation (mm)",main=title)
  grid()
  dev.off()
  
  cat(paste0("Gráfico de lineas para la estación ",title,"\n"))
}

lapply(1:(ncol(data_station)-3),function(j) graf_line(dates,data_station[,j+3],nomb[j],outDir))


######

# variable = "prec"
# 
# 
# tiff(paste0(nomb[i],"_box_month.tiff"),compression = 'lzw',height = 5,width = 10,units="in", res=200)
# par(mfrow=c(2,1),
#     oma = c(5,4,0,0) + 0.1,
#     mar = c(0,0,1,1) + 1.5)
# boxplot(x~month,range=as.numeric(5),plot=T)
# 
# plot(dates,x,type="l")
# lines(dates,data_station$lim_inf,col="red",lty=2)
# lines(dates,data_station$lim_sup,col="red",lty=2)
# dev.off()


object = data_station

if(svalue(variable)=="precip"){
  dir.create("Control de calidad/precip",showWarnings=F)
  
  
  porcentajes=matrix(0,ncol(object)-3,6)
  
  minim = 0
  maxim = 300
  ric = 10
  
  for(i in 1:(ncol(object)-3))
  {
    
    ##QC filtro grueso definido por el usuario
    out_range = which(object[,i+3] < minim | object[,i+3] >maxim)
    out_range_data = data.frame(out_range,object[out_range,i+3])
    
    if(length(out_range)>0){object[out_range,i+3]<-NA}
    
    
    ##QC datos atípicos con RIC
    x = object[,i+3]
    year = object$year
    month = month.abb[as.numeric(object$month)]
    month = factor(month, levels=month.abb)
    x[x<=0]= NA
    #svalue(ric)
    
    val.na = boxplot(x~month,range=10,plot=T)
    lim_inf.na = c()
    lim_sup.na = c()
    for(j in 1:12){
      lim_inf.na[month==month.abb[j]]=val.na$stats[1,j]
      lim_sup.na[month==month.abb[j]]=val.na$stats[5,j]

    }

    out_atip.na = which(x > lim_sup.na | x < lim_inf.na)
    
    val.na.y = boxplot(x~year,range=10,plot=T)
    #svalue(ric)
    year.nam = as.numeric(val.na.y$names)
    
    
    lim_inf.na.y = c()
    lim_sup.na.y = c()
    for(j in 1:length(year.nam)){
      lim_inf.na.y[year==year.nam[j]]=val.na.y$stats[1,j]
      lim_sup.na.y[year==year.nam[j]]=val.na.y$stats[5,j]
      
    }
    
    out_atip.na.y = which(x > lim_sup.na.y | x < lim_inf.na.y)
    
    out_atip.na_data = data.frame(c(out_atip.na,out_atip.na.y),object[c(out_atip.na,out_atip.na.y),i+3])
    object[c(out_atip.na,out_atip.na.y),i+3]<-NA
    
    out_atip_data = na.omit(cbind(object[c(out_atip,out_atip.y),1:3],object[c(out_atip,out_atip.y),i+3]))
    colnames(out_atip_data)<-c("day","month","year","value")
    
    
    if(nrow(out_atip_data)!=0){
      write.csv_n(out_atip_data,paste("Control de calidad/precip/","atipicos_",station[i],".csv",sep=""),row.names=F)
    }
    ##QC datos consecutivos 
    xc <-data.frame(hasta=cumsum(rle(object[,i+3])$lengths),cant_iguales=rle(object[,i+3])$lengths,valor=rle(object[,i+3])$values)
    xc$desde = xc$hasta -xc$cant_iguales + 1  
    xc <-na.omit(xc)
    xc = xc[xc$valor>0,]
    
    out_cons = c()
    error = xc[xc$cant_iguales>3,] 
    if (nrow(error)>0){
      for (k in 1:nrow(error)) {
        if (k==1){out_cons<-error$desde[k]:error$hasta[k]}
        else{out_cons<-c(out_cons,error$desde[k]:error$hasta[k])}
      }
    }
    
    out_cons_data = data.frame(out_cons,object[out_cons,i+3])
    
    if(length(out_cons)>0){object[out_cons,i+3]<-NA}
    
    #na=descriptna(object[,i+3])
    
    porcentajes[i,]=cbind(round((dim(out_range_data)[1]/dim(tmax)[1])*100,2),round((dim(out_atip_data)[1]/dim(tmax)[1])*100),round((dim(out_cons_data)[1]/dim(tmax)[1])*100,2),
                          round(na/dim(tmax)[1]*100,2))
    
    #######Graficos control de calidad###########
    #paste("Control de calidad/precip/","precip_qc_",station[i],".tiff",sep="")
    tiff("prueba.tiff",compression = 'lzw',height = 7,width = 16,units="in", res=150)
   # x11()
    par(mfrow = c(2,1),
             #oma = c(5,4,0,0) + 0.5,
        mar=c(5.1, 4.1, 4.1, 8.1), xpd=TRUE)
        #,mar=c(5.1, 4.1, 4.1, 8.1), xpd=TRUE)
    
    plot(data_station[,i+3],type="l",col="grey",xaxt="n",xlab="",ylab="Precipitación (mm)",main = nomb[i])
    mtext("before quality control")
    points(out_cons,data_station[out_cons,i+3],col="black",bg="red",cex=0.7,pch=21)
    points(c(out_atip.na.y,out_atip.na),data_station[c(out_atip.na.y,out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
    points(out_range,data_station[out_range,i+3],col="black",bg="green",cex=0.7,pch=21)
    axis(1,at=seq(1,nrow(data_station),1095),labels=seq(min(data_station$year),max(data_station$year),3),las=1,col="black")
    
    legend("topright", inset=c(-0.12,0),c("Consecutivos","Atípicos","Fuera del rango"),
           pch=c(21,21,21),col="black",pt.bg= c("red","purple","green"),bty = "n")
    
    plot(object[,i+3],type="l",col="grey",xaxt="n",xlab="",ylab="Precipitación (mm)",main = nomb[i])
    mtext("after quality control")
    axis(1,at=seq(1,nrow(data_station),1095),labels=seq(min(data_station$year),max(data_station$year),3),las=1,col="black")
    
    
    dev.off()
  }
  
  write.csv_n(object,"Control de calidad/precip_qc.csv",row.names=F)
  dimnames(porcentajes)<-c(list(station),list(c("% Datos fuera del rango","% Datos atípicos","% Datos consecutivos","% Total datos NA")))
  
}




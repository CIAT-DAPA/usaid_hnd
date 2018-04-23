# Created by: Lizeth Llanos
# This script make the quality control for daily data
# April 2017

# Define input and ouput path
inDir = "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_processed/"
outDir = "Z:/Water_Planning_System/01_weather_stations/hnd_copeco/daily_processed/"

# Define variable
variable = "prec"

# Load data base with all raw stations
data_station_prec = read.csv(paste0(inDir,"prec_daily_raw.csv"),header = T)
data_station_tmax = read.csv(paste0(inDir,"tmax_daily_raw.csv"),header = T)
data_station_tmin = read.csv(paste0(inDir,"tmin_daily_raw.csv"),header = T)

# Extract stations names
nomb_prec = substring(names(data_station_prec[,-1:-3]),2,nchar(names(data_station_prec[,-1:-3])))
nomb_s_prec = do.call("rbind",strsplit(nomb_prec,"_"))
name_st_prec = paste0(nomb_s_prec[,2]," (",nomb_s_prec[,1],")")

nomb_tmax = substring(names(data_station_tmax[,-1:-3]),2,nchar(names(data_station_tmax[,-1:-3])))
nomb_s_tmax = do.call("rbind",strsplit(nomb_tmax,"_"))
name_st_tmax = paste0(nomb_s_tmax[,2]," (",nomb_s_tmax[,1],")")

nomb_tmin = substring(names(data_station_tmin[,-1:-3]),2,nchar(names(data_station_tmin[,-1:-3])))
nomb_s_tmin = do.call("rbind",strsplit(nomb_tmin,"_"))
name_st_tmin = paste0(nomb_s_tmin[,2]," (",nomb_s_tmin[,1],")")

# Define period from data
dates=seq(as.Date("1970/1/1"), as.Date("2017/12/31"), "days") 


# Define values for quality control
if(variable=="prec"){
 minim = 0 ;maxim = 600; ric = 20
 
}

if(variable=="tmax"){
  minim = 10 ;maxim = 50; ric = 7; criterio1=15
  
}

if( variable=="tmin"){
  minim = -1 ;maxim = 35; ric = 7; criterio1=15
  
}
# apply(data_station_tmax,2,max,na.rm=T)
# apply(data_station_tmax,2,min,na.rm=T)

# Function for legend outside plot
add_legend <- function(...) {
  opar <- par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0), 
              mar=c(0, 0, 0, 0), new=TRUE)
  on.exit(par(opar))
  plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
  legend(...)
}

# Start qc process
object = data_station_prec

if(variable=="prec"){
  dir.create(paste0(outDir,"quality_control"),showWarnings=F)
  dir.create(paste0(outDir,"quality_control/prec"),showWarnings=F)
  
  
  for(i in 1:(ncol(object)-3))
  {
    tryCatch({ 
    cat(paste0("quality_control para la estación "),name_st_prec[i],"\n")
     
    ##QC filtro grueso definido por el usuario
    out_range = which(object[,i+3] < minim | object[,i+3] >maxim)
    if(length(out_range)>0){object[out_range,i+3]<-NA}
    
    na = sum(is.na(object[,i+3]))/length(object[,i+3])    
    
    if(na<0.95){
      
    ##QC datos atípicos con RIC
    x = object[,i+3]
    year = object$year
    month.abb.s = c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dec")
    month = month.abb.s[as.numeric(object$month)]
    month = factor(month, levels=month.abb.s)
    x[x<=0]= NA
    #svalue(ric)
    
    val.na = boxplot(x~month,range=ric,plot=F)
    lim_inf.na = c()
    lim_sup.na = c()
    for(j in 1:12){
      lim_inf.na[month==month.abb.s[j]]=val.na$stats[1,j]
      lim_sup.na[month==month.abb.s[j]]=val.na$stats[5,j]

    }

    out_atip.na = which(x > lim_sup.na | x < lim_inf.na)
    
    val.na.y = boxplot(x~year,range=ric,plot=F)
    year.nam = as.numeric(val.na.y$names)
    
    
    lim_inf.na.y = c()
    lim_sup.na.y = c()
    for(j in 1:length(year.nam)){
      lim_inf.na.y[year==year.nam[j]]=val.na.y$stats[1,j]
      lim_sup.na.y[year==year.nam[j]]=val.na.y$stats[5,j]
      
    }
    
    out_atip.na.y = which(x > lim_sup.na.y | x < lim_inf.na.y)
    
    dir.create(paste0(outDir,"quality_control/prec/boxplot_graph"),showWarnings = F)
    
    tiff(paste0(outDir,"quality_control/prec/boxplot_graph/",nomb_prec[i],"_",variable,"_box_graph_qc.tiff"),compression = 'lzw',height = 7,width = 10,units="in", res=150)
    par(mfrow = c(1,2),oma = c(0, 0, 2, 0),las=1)
    boxplot(x~year,range=ric,xlab = "Precipitación (mm/día)",horizontal=T,cex.axis=0.8,main = "Distribución anual")
    boxplot(x~month,range=ric,xlab = "Precipitación (mm/día)",horizontal=T,cex.axis=0.8,main = "Distribución mensual")
    title(name_st_prec[i],outer = T)
    dev.off()
    
    object[c(out_atip.na,out_atip.na.y),i+3]<-NA
    
    
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
    
    if(length(out_cons)>0){object[out_cons,i+3]<-NA}
    
     #######Graficos quality_control###########
     
   
    dir.create(paste0(outDir,"quality_control/prec/line_graph"),showWarnings = F)
    tiff(paste0(outDir,"quality_control/prec/line_graph/",nomb_prec[i],"_",variable,"_line_graph_qc.tiff"),compression = 'lzw',height = 7,width = 16,units="in", res=150)
 
        par(mfrow = c(2,1),     # 2x2 layout
        oma = c(2, 2, 0, 0), # two rows of text at the outer left and bottom margin
        mar = c(4, 4, 3, 3), # space for one row of text at ticks and to separate plots
        xpd = NA) 
   
        ylim1 = c(min(data_station_prec[,i+3],na.rm=T) ,max(data_station_prec[,i+3],na.rm=T)+0.5)
        ylim2 = c(min(object[,i+3],na.rm=T) ,max(object[,i+3],na.rm=T)+0.5)
    
    plot(data_station_prec[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Precipitación (mm/día)",main = "Antes del control de calidad",ylim=ylim1,cex.lab=0.8)
    
    mtext(paste0("Estación ",name_st_prec[i]),side=3,outer=T,adj=0,line=-1.3,cex = 1.2) 
    points(out_range,data_station_prec[out_range,i+3],col="black",bg="green",cex=0.7,pch=21)
    points(out_cons,data_station_prec[out_cons,i+3],col="black",bg="red",cex=0.7,pch=21)
    points(c(out_atip.na.y,out_atip.na),data_station_prec[c(out_atip.na.y,out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
    axis(1,at=seq(1,nrow(data_station_prec),366),labels=seq(min(data_station_prec$year),max(data_station_prec$year),1),las=1,col="black",las =2,cex.axis = 0.8)
    axis(2,at=seq(ylim1[1],ylim1[2],50),labels=seq(ylim1[1],ylim1[2],50),las=1,col="black",las =1,cex.axis = 0.8)
    
    
    plot(object[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Precipitación (mm/día)",main = "Después del control de calidad",ylim=ylim2,cex.lab=0.8)
    
    axis(1,at=seq(1,nrow(data_station_prec),366),labels=seq(min(data_station_prec$year),max(data_station_prec$year),1),las=1,col="black",las =2,cex.axis = 0.8)
    axis(2,at=seq(ylim2[1],ylim2[2],20),labels=seq(ylim2[1],ylim2[2],20),las=1,col="black",las =1,cex.axis = 0.8)
    
    add_legend("bottomright", legend=c("Datos consecutivos","Datos atípicos","Datos por fuera del rango"), pch=c(21,21,21), 
               pt.bg= c("red","purple","green"),bty = "n",cex = 0.9,
               horiz=TRUE)
    
    dev.off()
  }
  
  }, error=function(e){cat("ERROR :",name_st_prec[i],conditionMessage(e), "\n")})
  }
  
  
 # names(object)[-3:-1] = nomb_prec
  write.csv(object,paste0(outDir,"prec_daily_qc.csv"),row.names = F,quote = F)
   
}

object = data_station_tmax

if(variable=="tmax"){
  dir.create(paste0(outDir,"quality_control"),showWarnings=F)
  dir.create(paste0(outDir,"quality_control/tmax"),showWarnings=F)
  
  for(i in 1:(ncol(object)-3))
  {
    cat(paste0("quality_control para la estación "),name_st_tmax[i],"\n")
    
    ##QC filtro grueso definido por el usuario
    out_range = which(object[,i+3] < minim | object[,i+3] >maxim)
    if(length(out_range)>0){object[out_range,i+3]<-NA}
    
    ##QC filtro consistencia interna tmax<tmin
     out_int = which(object[,i+3]<data_station_tmin[,i+3])
     object[out_int,i+3]<-NA
     
    na = sum(is.na(object[,i+3]))/length(object[,i+3])    
    
    if(na<0.95){
      
      ##QC datos atípicos con RIC
      x = object[,i+3]
      year = object$year
      month.abb.s = c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dec")
      month = month.abb.s[as.numeric(object$month)]
      month = factor(month, levels=month.abb.s)
     
     
      
      val.na = boxplot(x~month,range=10,plot=F)
      lim_inf.na = c()
      lim_sup.na = c()
      for(j in 1:12){
        lim_inf.na[month==month.abb[j]]=val.na$stats[1,j]
        lim_sup.na[month==month.abb[j]]=val.na$stats[5,j]
        
      }
      
      out_atip.na = which(x > lim_sup.na | x < lim_inf.na)
      
      val.na.y = boxplot(x~year,range=10,plot=F)
      year.nam = as.numeric(val.na.y$names)
      
      
      lim_inf.na.y = c()
      lim_sup.na.y = c()
      for(j in 1:length(year.nam)){
        lim_inf.na.y[year==year.nam[j]]=val.na.y$stats[1,j]
        lim_sup.na.y[year==year.nam[j]]=val.na.y$stats[5,j]
        
      }
      
      out_atip.na.y = which(x > lim_sup.na.y | x < lim_inf.na.y)
      
      dir.create(paste0(outDir,"quality_control/tmax/boxplot_graph"),showWarnings = F)
      
      tiff(paste0(outDir,"quality_control/tmax/boxplot_graph/",nomb_tmax[i],"_",variable,"_box_graph_qc.tiff"),compression = 'lzw',height = 7,width = 10,units="in", res=150)
      par(mfrow = c(1,2),oma = c(0, 0, 2, 0),las=1)
      boxplot(x~year,range=10,xlab = "Temperatura máxima (°C)",horizontal=T,cex.axis=0.8,main = "Distribución anual")
      boxplot(x~month,range=10,xlab = "Temperatura máxima (°C)",horizontal=T,cex.axis=0.8,main = "Distribución mensual")
      title(name_st_tmax[i],outer = T)
      dev.off()
      
      object[c(out_atip.na,out_atip.na.y),i+3]<-NA
      
      
      
      ##QC saltos mayor a umbral definido por el usuario
      out_salt = which(abs(diff(object[,i+3]))>=as.numeric(criterio1))
      out_salt.n = unique(sort(c(out_salt,out_salt+1)))
      object[out_salt.n,i+3]<-NA
      
      ##QC datos consecutivos 
      xc <-data.frame(hasta=cumsum(rle(object[,i+3])$lengths),cant_iguales=rle(object[,i+3])$lengths,valor=rle(object[,i+3])$values)
      xc$desde = xc$hasta -xc$cant_iguales + 1  
      xc <-na.omit(xc)
       
      out_cons = c()
      error = xc[xc$cant_iguales>3,] 
      if (nrow(error)>0){
        for (k in 1:nrow(error)) {
          if (k==1){out_cons<-error$desde[k]:error$hasta[k]}
          else{out_cons<-c(out_cons,error$desde[k]:error$hasta[k])}
        }
      }
      
      if(length(out_cons)>0){object[out_cons,i+3]<-NA}
      
      #######Graficos quality_control###########
      
      dir.create(paste0(outDir,"quality_control/tmax/line_graph"),showWarnings = F)
      tiff(paste0(outDir,"quality_control/tmax/line_graph/",nomb_tmax[i],"_",variable,"_line_graph_qc.tiff"),compression = 'lzw',height = 7,width = 16,units="in", res=150)
      
      par(mfrow = c(2,1),     # 2x2 layout
          oma = c(2, 2, 0, 0), # two rows of text at the outer left and bottom margin
          mar = c(4, 4, 3, 3), # space for one row of text at ticks and to separate plots
          xpd = NA) 
      
      ylim1 = c(min(data_station_tmax[,i+3],na.rm=T) ,max(data_station_tmax[,i+3],na.rm=T)+1)
      ylim2 = c(min(object[,i+3],na.rm=T) ,max(object[,i+3],na.rm=T)+1)
      
      plot(data_station_tmax[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Temperatura máxima (°C)",main = "Antes del control de calidad",ylim=ylim1,cex.lab=0.8)
      
      mtext(paste0("Estación ",name_st_tmax[i]),side=3,outer=T,adj=0,line=-1.3,cex = 1.2) 
      points(out_range,data_station_tmax[out_range,i+3],col="black",bg="green",cex=0.7,pch=21)
      points(out_cons,data_station_tmax[out_cons,i+3],col="black",bg="red",cex=0.7,pch=21)
      points(c(out_atip.na.y,out_atip.na),data_station_tmax[c(out_atip.na.y,out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
      points(out_salt.n,data_station_tmax[out_salt.n,i+3],col="black",bg="turquoise1",cex=0.7,pch=24)
      #points(out_int,tmax[out_int,i+3],col="black",bg="tan3",cex=0.7,pch=21)
      
      axis(1,at=seq(1,nrow(data_station_tmax),366),labels=seq(min(data_station_tmax$year),max(data_station_tmax$year),1),las=1,col="black",las =2,cex.axis = 0.8)
      axis(2,at=seq(ylim1[1],ylim1[2],10),labels=seq(ylim1[1],ylim1[2],10),las=1,col="black",las =1,cex.axis = 0.8)
      
      
      plot(object[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Temperatura máxima (°C)",main = "Después del control de calidad",ylim=ylim2,cex.lab=0.8)
      
      axis(1,at=seq(1,nrow(data_station_tmax),366),labels=seq(min(data_station_tmax$year),max(data_station_tmax$year),1),las=1,col="black",las =2,cex.axis = 0.8)
      axis(2,at=seq(ylim2[1],ylim2[2],5),labels=seq(ylim2[1],ylim2[2],5),las=1,col="black",las =1,cex.axis = 0.8)
      
      add_legend("bottomleft", legend=c("Datos consecutivos","Datos atípicos","Datos por fuera del rango","Saltos consecutivos"), pch=c(21,21,21,24), 
                 pt.bg= c("red","purple","green","turquoise1","tan3"),bty = "n",cex = 0.9,text.width=c(0.085,0.3,0.235,0.3),
                 horiz=TRUE)
      
      dev.off()
    }
    
  }
  #names(object)[-3:-1] = nomb_tmax
  write.csv(object,paste0(outDir,"tmax_daily_qc.csv"),row.names = F,quote = F)
  
}

object = data_station_tmin

if(variable=="tmin"){
  dir.create(paste0(outDir,"quality_control"),showWarnings=F)
  dir.create(paste0(outDir,"quality_control/tmin"),showWarnings=F)
  
  for(i in 1:(ncol(object)-3))
  {
    cat(paste0("quality_control para la estación "),name_st_tmin[i],"\n")
    
    ##QC filtro grueso definido por el usuario
    out_range = which(object[,i+3] < minim | object[,i+3] >maxim)
    if(length(out_range)>0){object[out_range,i+3]<-NA}
    
    ##QC filtro consistencia interna tmin<tmin
    out_int = which(object[,i+3]<data_station_tmin[,i+3])
    object[out_int,i+3]<-NA
    
    na = sum(is.na(object[,i+3]))/length(object[,i+3])    
    
    if(na<0.95){
      
      ##QC datos atípicos con RIC
      x = object[,i+3]
      year = object$year
      month.abb.s = c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dec")
      month = month.abb.s[as.numeric(object$month)]
      month = factor(month, levels=month.abb.s)
      
      
      
      val.na = boxplot(x~month,range=10,plot=F)
      lim_inf.na = c()
      lim_sup.na = c()
      for(j in 1:12){
        lim_inf.na[month==month.abb[j]]=val.na$stats[1,j]
        lim_sup.na[month==month.abb[j]]=val.na$stats[5,j]
        
      }
      
      out_atip.na = which(x > lim_sup.na | x < lim_inf.na)
      
      val.na.y = boxplot(x~year,range=10,plot=F)
      year.nam = as.numeric(val.na.y$names)
      
      
      lim_inf.na.y = c()
      lim_sup.na.y = c()
      
      for(j in 1:length(year.nam)){
        lim_inf.na.y[year==year.nam[j]]=val.na.y$stats[1,j]
        lim_sup.na.y[year==year.nam[j]]=val.na.y$stats[5,j]
        
      }
      
      out_atip.na.y = which(x > lim_sup.na.y | x < lim_inf.na.y)
      
      dir.create(paste0(outDir,"quality_control/tmin/boxplot_graph"),showWarnings = F)
      
      tiff(paste0(outDir,"quality_control/tmin/boxplot_graph/",nomb_tmin[i],"_",variable,"_box_graph_qc.tiff"),compression = 'lzw',height = 7,width = 10,units="in", res=150)
      par(mfrow = c(1,2),oma = c(0, 0, 2, 0),las=1)
      boxplot(x~year,range=10,xlab = "Temperatura máxima (°C)",horizontal=T,cex.axis=0.8,main = "Distribución anual")
      boxplot(x~month,range=10,xlab = "Temperatura máxima (°C)",horizontal=T,cex.axis=0.8,main = "Distribución mensual")
      title(name_st_tmin[i],outer = T)
      dev.off()
      
      object[c(out_atip.na,out_atip.na.y),i+3]<-NA
      
      
      ##QC saltos mayor a umbral definido por el usuario
      out_salt = which(abs(diff(object[,i+3]))>=as.numeric(criterio1))
      out_salt.n = unique(sort(c(out_salt,out_salt+1)))
      object[out_salt.n,i+3]<-NA
      
      ##QC datos consecutivos 
      xc <-data.frame(hasta=cumsum(rle(object[,i+3])$lengths),cant_iguales=rle(object[,i+3])$lengths,valor=rle(object[,i+3])$values)
      xc$desde = xc$hasta -xc$cant_iguales + 1  
      xc <-na.omit(xc)
      
      out_cons = c()
      error = xc[xc$cant_iguales>3,] 
      if (nrow(error)>0){
        for (k in 1:nrow(error)) {
          if (k==1){out_cons<-error$desde[k]:error$hasta[k]}
          else{out_cons<-c(out_cons,error$desde[k]:error$hasta[k])}
        }
      }
      
      if(length(out_cons)>0){object[out_cons,i+3]<-NA}
      
      #######Graficos quality_control###########
      
      dir.create(paste0(outDir,"quality_control/tmin/line_graph"),showWarnings = F)
      tiff(paste0(outDir,"quality_control/tmin/line_graph/",nomb_tmin[i],"_",variable,"_line_graph_qc.tiff"),compression = 'lzw',height = 7,width = 16,units="in", res=150)
      
      par(mfrow = c(2,1),     # 2x2 layout
          oma = c(2, 2, 0, 0), # two rows of text at the outer left and bottom margin
          mar = c(4, 4, 3, 3), # space for one row of text at ticks and to separate plots
          xpd = NA) 
      
      ylim1 = c(min(data_station_tmin[,i+3],na.rm=T) ,max(data_station_tmin[,i+3],na.rm=T)+1)
      ylim2 = c(min(object[,i+3],na.rm=T) ,max(object[,i+3],na.rm=T)+1)
      
      plot(data_station_tmin[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Temperatura máxima (°C)",main = "Antes del control de calidad",ylim=ylim1,cex.lab=0.8)
      
      mtext(paste0("Estación ",name_st_tmin[i]),side=3,outer=T,adj=0,line=-1.3,cex = 1.2) 
      points(out_range,data_station_tmin[out_range,i+3],col="black",bg="green",cex=0.7,pch=21)
      points(out_cons,data_station_tmin[out_cons,i+3],col="black",bg="red",cex=0.7,pch=21)
      points(c(out_atip.na.y,out_atip.na),data_station_tmin[c(out_atip.na.y,out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
      points(out_salt.n,data_station_tmin[out_salt.n,i+3],col="black",bg="turquoise1",cex=0.7,pch=24)
      #points(out_int,tmin[out_int,i+3],col="black",bg="tan3",cex=0.7,pch=21)
      
      axis(1,at=seq(1,nrow(data_station_tmin),366),labels=seq(min(data_station_tmin$year),max(data_station_tmin$year),1),las=1,col="black",las =2,cex.axis = 0.8)
      axis(2,at=seq(ylim1[1],ylim1[2],10),labels=round(seq(ylim1[1],ylim1[2],10),0),las=1,col="black",las =1,cex.axis = 0.8)
      
      
      plot(object[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Temperatura máxima (°C)",main = "Después del control de calidad",ylim=ylim2,cex.lab=0.8)
      
      axis(1,at=seq(1,nrow(data_station_tmin),366),labels=seq(min(data_station_tmin$year),max(data_station_tmin$year),1),las=1,col="black",las =2,cex.axis = 0.8)
      axis(2,at=seq(ylim2[1],ylim2[2],5),labels=round(seq(ylim2[1],ylim2[2],5),0),las=1,col="black",las =1,cex.axis = 0.8)
      
      add_legend("bottomleft", legend=c("Datos consecutivos","Datos atípicos","Datos por fuera del rango","Saltos consecutivos"), pch=c(21,21,21,24), 
                 pt.bg= c("red","purple","green","turquoise1","tan3"),bty = "n",cex = 0.9,text.width=c(0.085,0.3,0.235,0.3),
                 horiz=TRUE)
      
      dev.off()
    }
    
    names(object)[i+3] = nomb_tmax[i]
  }
  #names(object)[-3:-1] = nomb_tmax
  write.csv(object,paste0(outDir,"tmin_daily_qc.csv"),row.names = F,quote = F)
  
}





# graf_line = function(x,y,title,outDir){
#   dir.create(paste0(outDir,"daily_processed/line_graph"),showWarnings = F)
#   png(paste0(outDir,"daily_processed/line_graph/",title,".png"), width = 10, height = 4,units = 'in',res=200)
#   plot(x,y,type="l",xlab="",ylab="Precipitation (mm)",main=title)
#   grid()
#   dev.off()
#   
#   cat(paste0("Gráfico de lineas para la estación ",title,"\n"))
# }

#lapply(1:(ncol(data_station)-3),function(j) graf_line(dates,data_station[,j+3],nomb[j],outDir))


######

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


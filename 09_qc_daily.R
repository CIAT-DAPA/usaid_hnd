# Created by: Lizeth Llanos
# This script make the quality control for daily data
# April 2017

# Define input and ouput path
inDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/"
outDir = "X:/Water_Planning_System/01_weather_stations/hnd_dgrh/daily_processed/"

# Load data base with all raw stations
data_station = read.csv(paste0(inDir,variable,"_daily_raw.csv"),header = T)

# Extract stations names
nomb = substring(names(data_station[,-1:-3]),2,nchar(names(data_station[,-1:-3])))
nomb_s = do.call("rbind",strsplit(nomb,"_"))
name_st = paste0(nomb_s[,2]," (",nomb_s[,1],")")

# Define period from data
dates=seq(as.Date("1980/1/1"), as.Date("2016/12/31"), "days") 

# Define variable
variable = "prec"

# Define range of variable
minim = 0
maxim = 300
ric = 10


# Function for legend outside plot
add_legend <- function(...) {
  opar <- par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0), 
              mar=c(0, 0, 0, 0), new=TRUE)
  on.exit(par(opar))
  plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
  legend(...)
}

# Start qc process
object = data_station

if(variable=="prec"){
  dir.create(paste0(outDir,"quality_control"),showWarnings=F)
  dir.create(paste0(outDir,"quality_control/prec"),showWarnings=F)
   
  for(i in 1:(ncol(object)-3))
  {
    cat(paste0("quality_control para la estación "),name_st[i],"\n")
    na = sum(is.na(object[,i+3]))/length(object[,i+3])    
    if(na<0.95){
      
    
    ##QC filtro grueso definido por el usuario
    out_range = which(object[,i+3] < minim | object[,i+3] >maxim)
    
    if(length(out_range)>0){object[out_range,i+3]<-NA}
    
    
    ##QC datos atípicos con RIC
    x = object[,i+3]
    year = object$year
    month.abb.s = c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dec")
    month = month.abb.s[as.numeric(object$month)]
    month = factor(month, levels=month.abb.s)
    x[x<=0]= NA
    #svalue(ric)
    
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
    
    dir.create(paste0(outDir,"quality_control/prec/boxplot_graph"),showWarnings = F)
    
    tiff(paste0(outDir,"quality_control/prec/boxplot_graph/",nomb[i],"_",variable,"_box_graph_qc.tiff"),compression = 'lzw',height = 7,width = 10,units="in", res=150)
    par(mfrow = c(1,2),oma = c(0, 0, 2, 0),las=1)
    boxplot(x~year,range=10,xlab = "Precipitación (mm/día)",horizontal=T,cex.axis=0.8,main = "Distribución anual")
    boxplot(x~month,range=10,xlab = "Precipitación (mm/día)",horizontal=T,cex.axis=0.8,main = "Distribución mensual")
    title(name_st[i],outer = T)
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
    tiff(paste0(outDir,"quality_control/prec/line_graph/",nomb[i],"_",variable,"_line_graph_qc.tiff"),compression = 'lzw',height = 7,width = 16,units="in", res=150)
 
        par(mfrow = c(2,1),     # 2x2 layout
        oma = c(2, 2, 0, 0), # two rows of text at the outer left and bottom margin
        mar = c(4, 4, 3, 3), # space for one row of text at ticks and to separate plots
        xpd = NA) 
   
        ylim1 = c(min(data_station[,i+3],na.rm=T) ,max(data_station[,i+3],na.rm=T)+0.5)
        ylim2 = c(min(object[,i+3],na.rm=T) ,max(object[,i+3],na.rm=T)+0.5)
    
    plot(data_station[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Precipitación (mm/día)",main = "Antes del control de calidad",ylim=ylim1,cex.lab=0.8)
    
    mtext(paste0("Estación ",name_st[i]),side=3,outer=T,adj=0,line=-1.3,cex = 1.2) 
    points(out_range,data_station[out_range,i+3],col="black",bg="green",cex=0.7,pch=21)
    points(out_cons,data_station[out_cons,i+3],col="black",bg="red",cex=0.7,pch=21)
    points(c(out_atip.na.y,out_atip.na),data_station[c(out_atip.na.y,out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
    axis(1,at=seq(1,nrow(data_station),366),labels=seq(min(data_station$year),max(data_station$year),1),las=1,col="black",las =2,cex.axis = 0.8)
    axis(2,at=seq(ylim1[1],ylim1[2],50),labels=seq(ylim1[1],ylim1[2],50),las=1,col="black",las =1,cex.axis = 0.8)
    
    
    plot(object[,i+3],type="l",col="grey",xaxt="n",yaxt="n",xlab="",ylab="Precipitación (mm/día)",main = "Después del control de calidad",ylim=ylim2,cex.lab=0.8)
    
    axis(1,at=seq(1,nrow(data_station),366),labels=seq(min(data_station$year),max(data_station$year),1),las=1,col="black",las =2,cex.axis = 0.8)
    axis(2,at=seq(ylim2[1],ylim2[2],20),labels=seq(ylim2[1],ylim2[2],20),las=1,col="black",las =1,cex.axis = 0.8)
    
    add_legend("bottomright", legend=c("Datos consecutivos","Datos atípicos","Datos por fuera del rango"), pch=c(21,21,21), 
               pt.bg= c("red","purple","green"),bty = "n",cex = 0.9,
               horiz=TRUE)
    
    dev.off()
  }
  
  }
  names(object)[-3:-1] = nomb
  write.csv(object,paste0(outDir,"prec_daily_qc.csv"),row.names = F,quote = F)
   
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


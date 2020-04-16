# Created by: Lizeth Llanos
# Quality Control monthly data
# March 2017


inDir = "C:/Users/lllanos/Desktop/all plot/"
outDir = "C:/Users/lllanos/Desktop/all plot/"
variable = "prec"
variable = "tmax"
variable = "tmin"

dir.create(paste0(outDir,"quality_control"),showWarnings = F)
dir.create(paste0(outDir,"quality_control/",variable),showWarnings = F)
data_station=read.csv(paste0(inDir,variable,"_merge_fill.csv"),header = T)
nomb=names(data_station[,-1:-2])
nomb_prec = substring(nomb,2,nchar(nomb))
nomb_s_prec = do.call("rbind",strsplit(nomb_prec,"_"))
name_st = paste0(nomb_s_prec[,2]," (",nomb_s_prec[,1],")")

apply(data_station,2,summary)
dates=seq(as.Date("1981/1/1"), as.Date("2010/12/31"), "month") #Definir periodo que se desea analizar

ylabs = "Temperatura máxima"
ylabs = "Precipitiación (mm)"
graf_line = function(x,y,title, ylabs){
  
    
  png(paste0(outDir,"quality_control/",variable,"/",title,".png"), width = 10, height = 4,units = 'in',res=200)
  plot(x,y,type="l",xlab="",ylab= ylabs,main=title)
  grid()
  dev.off()
  
}

lapply(1:(ncol(data_station)-2),function(j) graf_line(dates,data_station[,j+2],name_st[j],ylabs))



######
x = data_station[,i+2]
year = x$year
month = month.abb[as.numeric(data_station$month)]
month = factor(month, levels=month.abb)

if (variable== "prec") { #Si la variable es precipitación se omiten los 0
  x[x<=0]= NA
}

val = boxplot(x~month,range=as.numeric(2.5),plot=F)

for(j in 1:12){
  data_station$lim_inf[month==month.abb[j]]=val$stats[1,j]
  data_station$lim_sup[month==month.abb[j]]=val$stats[5,j]
  
}

tiff(paste0(nomb[i],"_box_month.tiff"),compression = 'lzw',height = 5,width = 10,units="in", res=200)
par(mfrow=c(2,1),
    oma = c(5,4,0,0) + 0.1,
    mar = c(0,0,1,1) + 1.5)
boxplot(x~month,range=as.numeric(2.5),plot=T)

plot(dates,x,type="l")
lines(dates,data_station$lim_inf,col="red",lty=2)
lines(dates,data_station$lim_sup,col="red",lty=2)
dev.off()






for (i in 1:(ncol(data_station)-2)){
  data_station[,i+2] = as.numeric(sub(",", ".", data_station[,i+2], fixed = TRUE))
}

variable <-"prec" #Definir variable como "prec" "tmax" "tmin" "srad" "rhum" "sbright"

vref <-read.csv("vref_QC.csv",header = T)
vref <-vref[vref$var==variable,]

#QC rango de referencia
QC_rango = function(data_station,vref,variable=variable){
  
  for (i in 1:(ncol(data_station)-2)){
    vref.na=which(data_station[,i+2] < as.numeric(vref[2]) | data_station[,i+2] >as.numeric(vref[3]))
    data_station[vref.na,i+2] = NA
    
    print(i)
  }
  
  
  print("QC_rangos OK")
  
  
  #QC datos consecutivos
  
  for (i in 1:(ncol(data_station)-2)){
    
    x <-data.frame(hasta=cumsum(rle(data_station[,i+2])$lengths),cant_iguales=rle(data_station[,i+2])$lengths,valor=rle(data_station[,i+2])$values)
    x$desde = x$hasta -x$cant_iguales + 1  
    x <-na.omit(x)
    if (variable== "prec") { #Si la variable es precipitación se omiten los 0
      x = x[x$valor>0,]
    }
    
    
    error = x[x$cant_iguales>as.numeric(vref[4]),] 
    if (nrow(error)>0){
      for (k in 1:nrow(error)) {
        if (k==1){vref.na<-error$desde[k]:error$hasta[k]}
        else{vref.na<-c(vref.na,error$desde[k]:error$hasta[k])}
      }
      data_station[vref.na,i+2] = NA
      
      
    }
    print(i)
  }
  
  
  print("QC_consec OK")
  
  
  
  #QC datos con saltos
  
  
  
  for (i in 1:(ncol(data_station)-2)){
    x = data_station[,i+2]
    year = data_station$year
    month = month.abb[as.numeric(data_station$month)]
    month = factor(month, levels=month.abb)
    
    if (variable== "prec") { #Si la variable es precipitación se omiten los 0
      x[x<=0]= NA
    }
    
    val = boxplot(x~month,range=as.numeric(vref[6]),plot=F)
    
    for(j in 1:12){
      data_station$lim_inf[month==month.abb[j]]=val$stats[1,j]
      data_station$lim_sup[month==month.abb[j]]=val$stats[5,j]
      
    }
    
    out_m = which(x > data_station$lim_sup | x < data_station$lim_inf)  
    
    
    
    tiff(paste0(dpto,"/",nomb[i],"_box_month.tiff"),compression = 'lzw',height = 5,width = 10,units="in", res=200)
    par(mfrow=c(2,1),
        oma = c(5,4,0,0) + 0.1,
        mar = c(0,0,1,1) + 1.5)
    boxplot(x~month,range=as.numeric(vref[6]),plot=T)
    
    plot(dates,x,type="l")
    lines(dates,data_station$lim_inf,col="red",lty=2)
    lines(dates,data_station$lim_sup,col="red",lty=2)
    dev.off()
    
    
    
  }
  
  print("QC_out OK")
  
  write.csv(data_station,paste0(dpto,"/prec_all_qc.csv"),row.names = F)
}


QC_rango(data_station,vref,variable=variable)


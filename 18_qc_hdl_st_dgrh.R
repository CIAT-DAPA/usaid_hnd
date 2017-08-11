# Created by: Lizeth Llanos
# This script make the quality control for hydrological daily data
# August 2017

hdl = read.csv("X:\\Water_Planning_System\\02_hydrological_stations\\daily_processed\\hdl_daily_raw.csv")

for(i in 1:26){

tiff(paste0("X:\\Water_Planning_System\\02_hydrological_stations\\daily_processed\\line_graph\\",names(hdl[i+3]),"_line_graph.tiff"),compression = 'lzw',height = 5,width = 10,units="in", res=250)

plot(hdl[,i+3],type="l",col="grey",xaxt="n",xlab="",ylab=expression(paste("Caudal diario ",(m^3/seg))),main = paste(names(hdl[i+3])),cex.lab=0.8)
#points(c(out_atip.na),hdl[c(out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
axis(1,at=seq(1,nrow(hdl),366),labels=seq(min(hdl$year),max(hdl$year),1),las=1,col="black",cex.axis = 1)
grid()

dev.off()

}

ric = 7

for(i in 1:26){
  
x = hdl[,i+3]
year = hdl$year
month.abb.s = c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dec")
month = month.abb.s[as.numeric(hdl$month)]
month = factor(month, levels=month.abb.s)
x[x<0]= NA
#svalue(ric)

val.na = boxplot(x~month,range=ric,plot=F)
lim_inf.na = c()
lim_sup.na = c()
for(j in 1:12){
  lim_inf.na[month==month.abb.s[j]]=val.na$stats[1,j]
  lim_sup.na[month==month.abb.s[j]]=val.na$stats[5,j]
}

out_atip.na = which(x > lim_sup.na | x < lim_inf.na)
    
tiff(paste0("X:\\Water_Planning_System\\02_hydrological_stations\\daily_processed\\outlier_graph/",names(hdl[i+3]),"_box_graph_qc.tiff"),compression = 'lzw',height = 7,width = 10,units="in", res=150)
par(mfrow = c(2,1),oma = c(0, 0, 2, 0),las=1)
boxplot(x~month,range=ric,ylab = expression(paste("Caudal diario ",(m^3/seg))),horizontal=F,cex.axis=0.8,main = " ",cex.lab=0.8)

plot(hdl[,i+3],type="l",col="grey",xaxt="n",xlab="",ylab=expression(paste("Caudal diario ",(m^3/seg))),cex.lab=0.8)
points(c(out_atip.na),hdl[c(out_atip.na),i+3],col="black",bg="purple",cex=0.7,pch=21)
axis(1,at=seq(1,nrow(hdl),366),labels=seq(min(hdl$year),max(hdl$year),1),las=1,col="black",cex.axis = 1)
grid()

title(paste(names(hdl[i+3])),outer = T)

dev.off()

write.csv(hdl[c(out_atip.na),c(1:3,(i+3))],paste0("X:\\Water_Planning_System\\02_hydrological_stations\\daily_processed\\outlier_graph/",names(hdl[i+3]),"_out.csv"),row.names = F,quote = F)

rm(out_atip.na,val.na,lim_inf.na,lim_sup.na)
gc(reset = TRUE)

}


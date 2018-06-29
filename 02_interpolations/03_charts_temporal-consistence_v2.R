# Carlos Navarro 
# CIAT - CCAFS
# 15-11-2012

# Boxplots 
require("raster")

bDir <- "D:/cenavarro/hnd_pnud/interpolations"
oDir <- "D:/cenavarro/hnd_pnud/interpolations/performance"

varList <- c("rain", "tmin", "tmax")
ntiles <- 1

for (vn in varList){
  
  metrics <- c()
  
  for (f in 1:25){
    
    for (t in 1:length(ntiles)){
      
      #Crossvalide data metrics
      cat("Accuracy metrics \n")
      
      metric_i <- read.csv(paste0(bDir, "/", vn, "/fold-", f, "/tile-", t, "/", vn, "_metrics.csv"))
      
    }
    
    metrics <- rbind(metrics, metric_i)
  }
  
  write.csv(metrics, paste(oDir, "/", vn, "_clim_metrics.csv", sep=""))
}




setwd(oDir)

id_rain <- read.csv(paste("rain_clim_metrics.csv", sep=""))
id_tmax <- read.csv(paste("tmax_clim_metrics.csv", sep=""))
id_tmin <- read.csv(paste("tmin_clim_metrics.csv", sep=""))
oPlot <- paste0(oDir, '/skill_clim.tif') 

mth_lb = c("Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
# windowsFonts(A=windowsFont("Cambria"))

# Combine everything in one single plot
tiff(oPlot, width=1300, height=900, pointsize=8, compression='lzw',res=150)
par(mfrow=c(2,3), oma=c(0,0,1,0))

# rsq

rsq_prec_max <- max(id_rain$R2.TEST)
# tiff('fig-3c-rsq_prec_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_rain$R2.TEST ~ id_rain$MONTH,xlab='Mes',ylab='R2',pch=20,cex=1.1,ylim=c(0,1), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
title("Precipitación", line = 1)
# text(x=11.9, y=0.98,"C", pos=4, cex=1.1.4)
grid()
lines(c(0,13),c(1 *.5, 1 *.5),col='red',lty=2)
lines(c(0,13),c(1 *.75,1 *.75),col='red')
legend("topleft", c("A"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()


rsq_tmax_max <- max(id_tmax$R2.TEST)

# tiff('fig-3d-rsq_tmean_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_tmax$R2.TEST ~ id_tmax$MONTH,xlab='Mes',ylab='R2',pch=20,cex=1.1,ylim=c(0,1), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# text(x=11.9, y=0.98,"D", pos=4, cex=1.1.4)
title("Temperatura Máxima", line = 1)
grid()
lines(c(0,13),c(1 *.5, 1 *.5),col='red',lty=2)
lines(c(0,13),c(1 *.75,1 *.75),col='red')
legend("topleft", c("B"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()


rsq_tmin_max <- max(id_tmin$R2.TEST)

# tiff('fig-3d-rsq_tmean_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_tmin$R2.TEST ~ id_tmin$MONTH,xlab='Mes',ylab='R2',pch=20,cex=1.1,ylim=c(0,1), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# text(x=11.9, y=0.98,"D", pos=4, cex=1.1.4)
title("Temperatura Mínima", line = 1)
grid()
lines(c(0,13),c(1 *.5, 1 *.5),col='red',lty=2)
lines(c(0,13),c(1 *.75,1 *.75),col='red')
legend("topleft", c("C"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()


# rmse 
# In precipitation is better to use ER

rmse_prec_max <- max(id_rain$RMSE.TEST)

# tiff('fig-3e-rmse_prec_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_rain$RMSE.TEST ~ id_rain$MONTH,xlab='Mes',ylab='ECM (mm/mes)',pch=20,cex=1.1,ylim=c(0,rmse_prec_max), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# text(x=11.9, y=0.98,"E", pos=4, cex=1.1.4)
grid()
lines(c(0,13),c(rmse_prec_max *.5, rmse_prec_max *.5),col='red',lty=2)
lines(c(0,13),c(rmse_prec_max *.75,rmse_prec_max *.75),col='red')
legend("topleft", c("D"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()

# 
# re_prec_max <- max(id_rain$RE.TEST)
# 
# # tiff('fig-3e-re_prec_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
# par(mar=c(4,4,2,1))
# boxplot(id_rain$RE.TEST ~ id_rain$MONTH,xlab='Mes',ylab='ER',pch=20,cex=1.1,ylim=c(0,re_prec_max), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# # text(x=11.9, y=0.98,"E", pos=4, cex=1.1.4)
# grid()
# lines(c(0,13),c(re_prec_max *.5, re_prec_max *.5),col='red',lty=2)
# lines(c(0,13),c(re_prec_max *.75,re_prec_max *.75),col='red')
# legend("topleft", c("D"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# # dev.off()


rmse_tmin_max <- max(id_tmin$RMSE.TEST)/10
rmse_tmax_max <- max(id_tmax$RMSE.TEST)/10

# tiff('fig-3f-rmse_tmean_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_tmax$RMSE.TEST/10 ~ id_tmax$MONTH,xlab='Mes',ylab='EMC (ºC)',pch=20,cex=1.1,ylim=c(0,0.5), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# text(x=11.9, y=0.98,"F", pos=4, cex=1.1.4)
grid()
lines(c(0,13),c(rmse_tmax_max *.5, rmse_tmax_max *.5),col='red',lty=2)
lines(c(0,13),c(rmse_tmax_max *.75,rmse_tmax_max *.75),col='red')
legend("topleft", c("E"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()


# tiff('fig-3f-rmse_tmean_monthly.tif',width=600, height=600,pointsize=8,compression='lzw',res=150)
par(mar=c(4,4,2,1))
boxplot(id_tmin$RMSE.TEST/10 ~ id_tmin$MONTH,xlab='Mes',ylab='EMC (ºC)',pch=20,cex=1.1,ylim=c(0,0.5), naMonth=(mth_lb), cex.axis=0.9, col="gray90")
# text(x=11.9, y=0.98,"F", pos=4, cex=1.1.4)
grid()
lines(c(0,13),c(rmse_tmin_max *.5, rmse_tmin_max *.5),col='red',lty=2)
lines(c(0,13),c(rmse_tmin_max *.75,rmse_tmin_max *.75),col='red')
legend("topleft", c("F"), box.lty=0, bg="transparent", cex = 2, yjust= 0.5, inset=c(-0.03,0))
# dev.off()

dev.off()

# Carlos Navarro 
# CIAT - CCAFS
# May 2018


###############################################
#### 01 Plots annual cycle current, future ####
###############################################

# Load libraries
require(raster)
require(rasterVis)
require(maptools)
require(rgdal)
library(grid)

baseDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Interpolacion/average"
downDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Escenarios/downscaled_ens"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Escenarios/evaluation/by_regions"

rcp <- "rcp45"
perList <- c("2020_2049", "2040_2069", "2070_2099")
regions <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/03_Interpolacion/region/Regiones_Desarrollo_prj_v2.shp")
varLs <- c("prec", "tmean")

mt <- c()

if(!file.exists(paste0(oDir, "/monthly_data_regions.csv"))){
  
  
  for (i in 1:length(as.vector(regions$REGION)) ){
    
    for (var in varLs){
      
      rg <- regions[regions$REGION == as.vector(regions$REGION)[i], ]
      
      perMths <- expand.grid(1:12, perList)
      names(perMths) <- c("Month", "Period")
      
      stk <- stack(c(stack(paste0(baseDir, "/", var, "_", 1:12, ".tif")), 
                     paste0(downDir, "/", rcp, "/", perMths[,2], "/", var, "_", perMths[,1], ".tif"))
      )
      
      stk_sd <- stack(paste0(downDir, "/", rcp, "/", perMths[,2], "/", var, "_", perMths[,1], "_sd.tif"))
      
      if(var != "prec"){
        stk <- stk / 10
        stk_sd <- stk_sd / 10
      }
      
      stk_crop <- crop(mask(stk, rg), extent(rg))
      stk_sd_crop <- crop(mask(stk_sd, rg), extent(rg))
      
      mt <- rbind(mt, cbind(rbind(as.data.frame(cbind(Month=1:12, Period="1981_2010")), perMths), 
                            as.vector(regions$REGION)[i], 
                            var, 
                            cellStats(stk_crop, stat='median', na.rm=TRUE), 
                            c(rep("NA", 12), cellStats(stk_sd_crop, stat='median', na.rm=TRUE))
      )
      )
      
    }
  }
  
  names(mt) <- c("Month", "Period", "Region", "Variable","Median", "STD")
  write.csv(mt, paste0(oDir, "/monthly_data_regions.csv"), row.names = F)
  
  
}



mthData <- read.csv(paste0(oDir, "/monthly_data_regions.csv"), header = T)

for (i in 1:length(as.vector(regions$REGION)) ){

  mthData_rg <- mthData[mthData$Region == as.vector(regions$REGION)[i], ]
  ## Make a funtion to create the error bar
  
  mth_lb = c("Ene", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")
  
  error.bar <- function(x, y, upper, lower=upper, length=0.1,...){
    arrows(x, y+upper, x, y-lower, angle=90, code=3, length=0.05, ...)
  }
  
  ## Load the climate information
  ## Current Precipitation  
  rr = mthData_rg[mthData_rg$Variable == "prec" & mthData_rg$Period == "1981_2010", ]
  r.means = as.vector(rr$Median)
  
  ## Future Precipitation
  rr2030 = mthData_rg[mthData_rg$Variable == "prec" & mthData_rg$Period == "2020_2049", ]
  rr.means2030 = as.vector(rr2030$Median)
  rr.sd2030  =as.vector(rr2030$STD)
  
  rr2050 = mthData_rg[mthData_rg$Variable == "prec" & mthData_rg$Period == "2040_2069", ]
  rr.means2050 = as.vector(rr2050$Median)
  rr.sd2050  =as.vector(rr2050$STD)
  
  rr2080 = mthData_rg[mthData_rg$Variable == "prec" & mthData_rg$Period == "2070_2099", ]
  rr.means2080 = as.vector(rr2080$Median)
  rr.sd2080  =as.vector(rr2080$STD)
  
  
  ## Load the climate information
  ## Current Precipitation  
  tm = mthData_rg[mthData_rg$Variable == "tmean" & mthData_rg$Period == "1981_2010", ]
  t.means = as.vector(tm$Median)
  
  ## Future Precipitation
  tm2030 = mthData_rg[mthData_rg$Variable == "tmean" & mthData_rg$Period == "2020_2049", ]
  tm.means2030 = as.vector(tm2030$Median)
  
  tm2050 = mthData_rg[mthData_rg$Variable == "tmean" & mthData_rg$Period == "2040_2069", ]
  tm.means2050 = as.vector(tm2050$Median)
  
  tm2080 = mthData_rg[mthData_rg$Variable == "tmean" & mthData_rg$Period == "2070_2099", ]
  tm.means2080 = as.vector(tm2080$Median)
  
  ##Precipitation bar Plot
  yy <- matrix(c(r.means,rr.means2030, rr.means2050, rr.means2080),4,12,byrow=TRUE)
  sdtotal <- matrix(c(rep(NA, 12),rr.sd2030, rr.sd2050, rr.sd2080),4,12,byrow=TRUE)*0.5
  
  
  tiff(paste(oDir, "/plot_", as.vector(regions$REGION)[i], "_trends.tif", sep=""), width=1024, height=600,pointsize=8,compression='lzw',res=150)
  
  par(mar=c(7,4,1,4)+ 0.1)
  
  if (i == 13 || i == 15){
    barx2 <- barplot(yy, beside=T, axes=F, col=c("lightblue","steelblue1", "steelblue3", "steelblue4"), ylim=c(0,max(yy)+100), axis.lty=1, xlab="", ylab="", 
                     cex.axis=0.8, names.arg=mth_lb, tcl=-0.3, cex.names=0.8)
    error.bar(barx2,yy,sdtotal)
    axis(2, ylim=c(0,max(yy)+100), col="black", lwd=1, cex.axis=0.8)
  } else {
    barx2 <- barplot(yy, beside=T, axes=F, col=c("lightblue","steelblue1", "steelblue3", "steelblue4"), ylim=c(0,max(yy)+50), axis.lty=1, xlab="", ylab="", 
                     cex.axis=0.8, names.arg=mth_lb, tcl=-0.3, cex.names=0.8)
    error.bar(barx2,yy,sdtotal)
    axis(2, ylim=c(0,max(yy)+50), col="black", lwd=1, cex.axis=0.8)
  }

  
  ##Plot current and future temperature  
  par(new=TRUE)  
  plot(t.means,axes=FALSE,ann=FALSE,type="n",ylim=c(0,round(max(tm.means2080) + 0.5)),ylab="", xlab="", cex.lab=0.8, cex.axis=0.8)
  
  axis(4, tcl=-0.3, cex.axis=0.8, ylim=c(0,round(max(tm.means2080) + 0.5)))
  
  mtext(2, text="Precipitación (mm/mes)", line=2.5) 
  mtext(4,text="Temperatura (°C)", line=2.5)
  mtext(1,text="Mes",line=2.5)
  
  legend_order <- matrix(1:8,ncol=4,byrow = TRUE)
  
  par(xpd=TRUE)
  legend("bottom", 
         inset=c(0, -0.28),
         c("Precipitación Histórica", "Precipitación 2050",
           "Temperatura Histórica", "Temperatura 2050",
           "Precipitación 2030", "Precipitación 2080", 
           "Temperatura 2030", "Temperatura 2080")[legend_order], 
         fill=c("lightblue","steelblue1", "steelblue3", "steelblue4", 0, 0, 0 , 0),
         border = c("black","black", "black", "black", 0, 0, 0 , 0), 
         bty="n", 
         lty=c(NA,NA, NA, NA, 2,1,1,1), 
         col=c("red","yellow", "orange", "red"), 
         lwd=c(NA,NA,NA, NA, 1.5,1.5,1.5,1.5), 
         merge = T, 
         ncol=4, 
         cex = 0.9
         )
  
  par(new=TRUE)
  points(spline(t.means),lty=2, type="l",col="red",lwd=1.5)
  points(spline(tm.means2030), type="l",col="yellow",lwd=1.5)
  points(spline(tm.means2050), type="l",col="orange",lwd=1.5)
  points(spline(tm.means2080), type="l",col="red",lwd=1.5)
  
  # grid(NA, 6)
  box()
  
  dev.off()
  
    
}

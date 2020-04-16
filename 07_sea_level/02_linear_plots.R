### PLot sea level anomalies
### Author: Carlos Navarro c.e.navarro@cgiar.org
### Date: August 2018

# Load libraries
require(raster)
require(ncdf)
require(maptools)
require(rgdal)
require(ggplot2)

# Parameters
rcpList <- c("baseline","rcp45", "rcp85")
var <- "zos"
cdopath <- "cdo"
ctr <- "hnd"
dts <- "duacs"
bbox <- extent(-93, -80, 9, 20)
period_h <- "1996_2015"
period_f <- "2006_2100"
iDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar"
oDir <- "D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar/evaluation"
# ctr_mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/02_Interpolacion/region/Limites_Honduras_v3.shp")
lim_mask <- readOGR("D:/OneDrive - CGIAR/CIAT/Projects/hnd-pnud-ciat-escenarios/04_Nivel_Mar/Limite_Marino/eez_buf1_proj.shp")

# GCM list with original and modified names
gcmList <- c("csiro_mk3_6_0", "giss_e2_r", "gfdl_cm3", "gfdl_esm2g", "gfdl_esm2m", "ipsl_cm5a_lr", "miroc_miroc5", "mohc_hadgem2_es", "mri_cgcm3", "ncc_noresm1_m")


sYrOb <- as.numeric(strsplit(period_h, '_')[[1]][1])
eYrOb <- as.numeric(strsplit(period_h, '_')[[1]][2])

sYrFu <- as.numeric(strsplit(period_f, '_')[[1]][1])
eYrFu <- as.numeric(strsplit(period_f, '_')[[1]][2])

if (!file.exists(oDir)) {dir.create(oDir, recursive=T)}  

##############################
# Plots and stats by regions
##############################
for (r in 1:length(as.vector(lim_mask$geoname)) ){
  
  anomVals <- c()
  
  rg <- lim_mask[lim_mask$geoname == as.vector(lim_mask$geoname)[r], ]
  rg_name <- paste(rg$geoname)
  

  for(rcp in rcpList){

    if(rcp == "baseline"){

      cat("\n  >", rcp, dts, "\n")

      iDir_b <- paste0(iDir, "/anomalies/", rcp)
      anom_b <- paste0(iDir_b, "/", var, "_anom_", period_h, "_", ctr, ".nc")

      anom_b_stk <- stack(anom_b)



      rg <- lim_mask[lim_mask$geoname == as.vector(lim_mask$geoname)[r], ]
      rg_name <- paste(rg$geoname)
      # plot(rg, add=T)

      anom_b_stk_msk <- mask(anom_b_stk, rg)
      anom_b_stk_msk_vals <- cellStats(anom_b_stk_msk, stat='mean', na.rm=TRUE) * 1000 #mm

      anomVals <- rbind(anomVals, cbind(rcp, sYrOb:eYrOb, rg_name, dts, anom_b_stk_msk_vals))


    } else {


      for(g in 1:length(gcmList) ){

        cat("\n  >", rcp, gcmList[g], "\n")

        iDir_f <- paste0(iDir, "/anomalies/", rcp, "/", gcmList[g])
        anom_f <- paste0(iDir_f, "/", var, "_", period_f, "_ts.nc")

        anom_f_stk <- stack(anom_f)




        # plot(rg, add=T)

        anom_f_stk_msk <- mask(anom_f_stk, rg)
        anom_f_stk_msk_vals <- cellStats(anom_f_stk_msk, stat='mean', na.rm=TRUE) * 1000 #mm

        anomVals <- rbind(anomVals, cbind(rcp, sYrFu:eYrFu, rg_name, gcmList[g], anom_f_stk_msk_vals))




      }

    }


  }

  colnames(anomVals) <- c("RCP", "Year", "EEZ", "GCM", "Value")

  anomVals <-  as.data.frame(anomVals)
  anomVals <- anomVals[!(anomVals$RCP == "baseline" & as.numeric(as.vector(anomVals$Year)) > 2012),]
  anomVals <- anomVals[!(anomVals$RCP != "baseline" & as.numeric(as.vector(anomVals$Year)) < 2010),]

  write.csv(anomVals, paste0(oDir, "/anom_stats_", rg_name, ".csv"), row.names = F)

  anomVals <- read.csv(paste0(oDir, "/anom_stats_", rg_name, ".csv"), header=T)
  # anomVals[complete.cases(anomVals), ]
  
  anomVals_mean <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) mean(x, na.rm=T))
  anomVals_max <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) max(x, na.rm=T))
  anomVals_min <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) min(x, na.rm=T))
  anomVals_p25 <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) quantile(x, probs = 0.25, na.rm=T))
  anomVals_p75 <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) quantile(x, probs = 0.75, na.rm=T))
  anomVals_p10 <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) quantile(x, probs = 0.10, na.rm=T))
  anomVals_p90 <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) quantile(x, probs = 0.90, na.rm=T))
  anomVals_std <- aggregate(anomVals$Value, by=list(RCP=anomVals$RCP, YEAR=anomVals$Year), FUN = function(x) sd(x, na.rm=T))
  
  anomVals_sts <- cbind(anomVals_mean[,1:2], MEAN=anomVals_mean[,3], MAX=anomVals_max[,3], MIN=anomVals_min[,3], 
                        P25=anomVals_p25[,3], P75=anomVals_p75[,3], P10=anomVals_p10[,3], P90=anomVals_p90[,3], 
                        MEANSTDMIN=(anomVals_mean[,3]-(1.5*anomVals_std[,3])), MEANSTDMAX=(anomVals_mean[,3] + (1.5*anomVals_std[,3]) ) )
  
  # anomPlot <- paste0(oDir, "/", rg_name, "_minmax.tif")
  # 
  # p <- ggplot() +
  #   geom_ribbon(data=anomVals_sts, aes(x=YEAR, ymin=MIN, ymax=MAX, fill=factor(RCP), alpha=0.3), size=0.2) +
  #   geom_line(data=anomVals_sts, aes(x=YEAR, y=MEAN, colour=factor(RCP)), size=1) +
  #   theme(panel.background = element_rect(fill = 'gray92'), legend.title=element_blank()) +
  #   theme_bw() + 
  #   guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
  #   scale_color_manual(values=c("black","red3", "blue3"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5")) + 
  #   scale_fill_manual(values=c("black","#F8766D", "#619CFF"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5"), name="fill") +
  #   theme(legend.position="bottom", legend.direction = 'horizontal', legend.key = element_rect(size = 5), legend.key.size = unit(1, 'lines')) +
  #   ylim(-70, 400) + 
  #   # ggtitle(regmod) +
  #   labs(x="Fecha (años)", y="Anomalía (mm)")
  # 
  # tiff(anomPlot, width=800, height=800, pointsize=8, compression='lzw',res=150)
  # plot(p)
  # dev.off()

  anomPlotP <- paste0(oDir, "/", rg_name, "_p25-75.tif")

  p <- ggplot() +
    geom_ribbon(data=anomVals_sts, aes(x=YEAR, ymin=P25, ymax=P75, fill=factor(RCP), alpha=0.3), size=0.2) +
    geom_line(data=anomVals_sts, aes(x=YEAR, y=MEAN, colour=factor(RCP)), size=1) +
    theme(panel.background = element_rect(fill = 'gray92'), legend.title=element_blank()) +
    theme_bw() +
    guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
    scale_color_manual(values=c("black","red3", "blue3"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5")) +
    scale_fill_manual(values=c("black","#F8766D", "#619CFF"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5"), name="fill") +
    theme(legend.position="bottom", legend.direction = 'horizontal', legend.key = element_rect(size = 5), legend.key.size = unit(1, 'lines')) +
    ylim(-70, 400) + 
    labs(x="Fecha (años)", y="Anomalía (mm)")

  tiff(anomPlotP, width=800, height=800, pointsize=8, compression='lzw',res=150)
  plot(p)
  dev.off()

  # anomPlotP <- paste0(oDir, "/", rg_name, "_p10-90.tif")
  # 
  # p <- ggplot() +
  #   geom_ribbon(data=anomVals_sts, aes(x=YEAR, ymin=P10, ymax=P90, fill=factor(RCP), alpha=0.2), size=0.2) +
  #   geom_line(data=anomVals_sts, aes(x=YEAR, y=MEAN, colour=factor(RCP)), size=1) +
  #   theme(panel.background = element_rect(fill = 'gray92'), legend.title=element_blank()) +
  #   theme_bw() +
  #   guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
  #   scale_color_manual(values=c("black","red3", "blue3"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5")) +
  #   scale_fill_manual(values=c("black","#F8766D", "#619CFF"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5"), name="fill") +
  #   theme(legend.position="bottom", legend.direction = 'horizontal', legend.key = element_rect(size = 5), legend.key.size = unit(1, 'lines')) +
  #   ylim(-70, 400) + 
  #   labs(x="Fecha (años)", y="Anomalía (mm)")
  # 
  # tiff(anomPlotP, width=800, height=800, pointsize=8, compression='lzw',res=150)
  # plot(p)
  # dev.off()
  # 
  # anomPlotStd <- paste0(oDir, "/", rg_name, "_1_5std.tif")
  # 
  # p <- ggplot() +
  #   geom_ribbon(data=anomVals_sts, aes(x=YEAR, ymin=MEANSTDMIN, ymax=MEANSTDMAX, fill=factor(RCP), alpha=0.2), size=0.2) +
  #   geom_line(data=anomVals_sts, aes(x=YEAR, y=MEAN, colour=factor(RCP)), size=1) +
  #   theme(panel.background = element_rect(fill = 'gray92'), legend.title=element_blank()) +
  #   theme_bw() +
  #   guides(fill=guide_legend(title=NULL), color=guide_legend(title=NULL), alpha=FALSE) +
  #   scale_color_manual(values=c("black","red3", "blue3"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5")) +
  #   scale_fill_manual(values=c("black","#F8766D", "#619CFF"), labels = c("Línea Base", "RCP 4.5", "RCP 8.5"), name="fill") +
  #   theme(legend.position="bottom", legend.direction = 'horizontal', legend.key = element_rect(size = 5), legend.key.size = unit(1, 'lines')) +
  #   ylim(-70, 400) + 
  #   labs(x="Fecha (años)", y="Anomalía (mm)")
  # 
  # tiff(anomPlotStd, width=800, height=800, pointsize=8, compression='lzw',res=150)
  # plot(p)
  # dev.off()

  
}
  

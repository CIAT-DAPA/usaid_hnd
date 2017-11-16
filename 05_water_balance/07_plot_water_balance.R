### Plot resulting variables of the water balance
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

# Load libraries
library(raster)
library(rgdal)
library(RColorBrewer)
library(rasterVis)
library(sp)

# Network drive
net_drive = "Y:"

# Arguments
iDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather")
varLs <- c("aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield")
varRs <- c("Evapotranspiración Real", "Precipitacón Efectiva", "Percolación", "Escorrentía Superficial", "Humedad del Suelo", "Flujo Base", "Aporte de Agua")
dicVar <- vector(mode="list", length=length(varLs))
names(dicVar) = varLs

for (i in 1:length(varLs)){
  dicVar[[i]] <- varRs[i]
}

oDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/maps")
mask <- paste0(net_drive, "/06_analysis/Extracts_MicroCuencas/mask/Microcuencas_ZOI_Finales.shp")

# read microwatersheds
poly <- shapefile(mask)

# define symbology of blues
mytheme = rasterTheme(region = brewer.pal(9, "Blues"))

# For monthly timescale (average)
for (var in varLs){
  
  # Raster stack
  rs_stk <- stack(paste0(iDir, "/", var, "/",  var, "_month_", 1:12, ".tif"))
  
  cat(var, "\n")

  # create raster stack
  rs_stk_crop <- crop(rs_stk, extent(poly))
  extent(rs_stk_crop) <- extent(poly)
  names(rs_stk_crop) = month.name
  #plot(rs_stk_crop)
  
  # plot title
  plot.title = paste0(dicVar[var], " (mm)\n2000-2014")
  
  # Guardar plot como Tiff. Cambiar el nombre de la imagen
  image = file.path(oDir, paste0(var, "_monthly.tiff"))
  tiff(
    file = image,
    width = 4000,
    height = 2800,
    res = 300)

  # scales=list(draw=FALSE) for no labels
  print(levelplot(rs_stk_crop, scales=list(draw=FALSE), par.settings=mytheme, main=plot.title))

  dev.off()
  
}
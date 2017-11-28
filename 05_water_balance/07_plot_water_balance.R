### Plot resulting variables of the water balance
### Note: Do not use variable names that could be functions or masked variables of packages (e.g. "mask", "poly")
### Author: Jefferson Valencia Gomez
### email: j.valencia@cgiar.org, jefferson.valencia.gomez@gmail.com

# Load libraries
require(raster)
require(rgdal)
require(maptools)
require(rasterVis)

# Network drive
net_drive = "Y:"

# Arguments
iDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/thornthwaite_and_mather/final")
varLs <- c("aet", "eprec", "perc", "runoff", "sstor", "bflow", "wyield")
varRs <- c("Evapotranspiración Real", "Precipitacón Efectiva", "Percolación", "Escorrentía Superficial", "Humedad del Suelo", "Flujo Base", "Aporte de Agua")
dicVar <- vector(mode="list", length=length(varLs))
names(dicVar) = varLs

for (i in 1:length(varLs)){
  dicVar[[i]] <- varRs[i]
}

oDir <- paste0(net_drive, "/Outputs/WPS/Balance_Hidrico/maps/final")
mask_shp <- paste0(net_drive, "/06_analysis/Scenarios/masks/ZOI.shp")

months = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")

# read microwatersheds
poly_shp <- readOGR(mask_shp, layer= "ZOI")
# poly_shp <- getData('GADM', country='Honduras', level=1)

# define symbology of blues
mytheme = rasterTheme(region = brewer.pal(9, "Blues"))
mytheme$strip.border$col = "white"  # Eliminate frame from maps
mytheme$axis.line$col = 'white'  # Eliminate frame from maps

# For monthly timescale (average)
for (var in varLs){
  
  # Raster stack
  rs_stk <- stack(paste0(iDir, "/", var, "/",  var, "_month_", 1:12, ".tif"))
  
  cat(var, "\n")

  # create raster stack
  #rs_stk_crop = mask(crop(rs_stk, extent(poly)), poly)
  rs_stk_crop <- crop(rs_stk, extent(poly_shp))
  extent(rs_stk_crop) <- extent(poly_shp)
  names(rs_stk_crop) = months
  #plot(rs_stk_crop)
  
  # plot title
  plot.title = paste0(dicVar[var], " (mm)\n2000-2014")
  
  # Guardar plot como Tiff. Cambiar el nombre de la imagen
  image = file.path(oDir, paste0(var, "_monthly.tiff"))
  tiff(
    file = image,
    width = 4000,
    height = 2800,
    res = 300,
    compression ='lzw')

  # scales=list(draw=FALSE) for no labels
  lvl.plot = levelplot(rs_stk_crop, scales=list(draw=FALSE), par.settings=mytheme, main=plot.title, colorkey = list(space = "bottom"))
  
  print(lvl.plot  + layer(sp.polygons(poly_shp)))

  dev.off()
 
  # Delete temp files
  unlink(rasterOptions()$tmpdir, recursive=TRUE)
}
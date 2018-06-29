# Mask preparation

oDir <- "D:/cenavarro/pnud_hnd/region"

wcl_v2 <- raster("S:/observed/gridded_products/worldclim/Global_30s_v2/prec_1.tif")
hnd_adm0 <- readOGR("D:/cenavarro/pnud_hnd/region/HND_adm0.shp", layer="HND_adm0")

hnd_ext <- crop(wcl_v2, extent(hnd_adm0)) * 0 + 1
hnd_msk <- mask(hnd_ext, hnd_adm0)

writeRaster(hnd_ext, paste0(oDir, "/", "hnd_ext.tif"))
writeRaster(hnd_ext, paste0(oDir, "/", "hnd_ext.nc"))

writeRaster(hnd_msk, paste0(oDir, "/", "hnd_msk.tif"))
writeRaster(hnd_msk, paste0(oDir, "/", "hnd_msk.nc"))

import arcpy, os, glob

in_dir = r"\\dapadfs\workspace_cluster_6\Ecosystem_Services\Water_Planning_System\Inputs\WPS\Balance_Hidrico\shared\prec"
out_dir = os.path.join(in_dir, "projected")
arcpy.env.overwriteOutput = True

os.system("cls")

directories = os.listdir(in_dir)

if directories[-1] == "projected":
    directories = directories[:-1]


def folder_exists(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)


folder_exists(out_dir)

sr_in = arcpy.SpatialReference("WGS 1984")
sr_out = arcpy.SpatialReference("WGS 1984 UTM Zone 16N")
wildcard = "*.asc"

for folder in directories:
    print "\t**" + folder + "**"
    rasters = glob.glob(os.path.join(in_dir, folder) + "\\" + wildcard)
    for raster in rasters:
        raster_name = (raster.split("\\")[-1]).split(".")[0]
        print raster_name
        arcpy.DefineProjection_management(raster, sr_in)  # Comment/Disable this line
        folder_exists(os.path.join(out_dir, folder))
        arcpy.ProjectRaster_management(raster, os.path.join(out_dir, folder, raster_name + ".tif"), sr_out, "BILINEAR", "1000", "#", "#", sr_in)


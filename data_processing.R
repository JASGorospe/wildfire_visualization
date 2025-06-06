# Title: Canadian Wildfire Visualization - Pre-processing Script
# Contributor: Julia Gorospe
# Created: 2025-05-12
# Updated: 2025-06-06
# R version 4.3.2 (2023-10-31)
# Platform: aarch64-apple-darwin20 (64-bit)
# Running under: macOS Monterey 12.5.1

# Libraries ---------------------------------------------------------------------------------------
library(tidyverse) # version 2.0.0
library(leaflet) # version 2.0.4.1
library(sf)
library(raster)
library(terra)
library(rmapshaper)
library(geojsonsf)

# Data Prep ---------------------------------------------------------------------------------------

# FIRE DATA ---
# URL for NFDB_poly.shp dataset: https://cwfis.cfs.nrcan.gc.ca/downloads/nfdb/fire_poly/current_version/ 

# load wildfire data
fires_raw <- read_sf("~/Documents/Projects/Wildfires/NFDB_poly/NFDB_poly_20210707.shp",
                 query = "SELECT * from NFDB_poly_20210707 WHERE YEAR >= 1990") %>% # limit records
  st_zm(.) %>%  # remove 3rd dimension
  st_transform(., 4326)   # convert from NAD83 to WGS84

# pick relevant columns
fires <- fires_raw %>% 
  dplyr::select(1, 2, 4, 5, 7, 10, 11, 13, 27)

# reduce the number of coordinates in the polygons
fires_simp <- fires %>% 
  ms_simplify(., sys = TRUE, method = NULL, keep = 0.6, weight = 0.7) %>% 
  st_make_valid()

# calculate centroids
fires_coord <- fires_simp %>%
  st_centroid() %>% 
  mutate(longitude = unlist(map(.$`_ogr_geometry_`,1)),
         latitude = unlist(map(.$`_ogr_geometry_`,2)))

# merge centroids into the dataframe with polygons
fires_clean <- fires_simp %>% 
  cbind(fires_coord[,c("latitude", "longitude")]) %>% 
  dplyr::select(everything(),
         geometry = X_ogr_geometry_,
         centroid = X_ogr_geometry_.1) %>% 
  group_by(FIRE_ID, YEAR) %>% 
  slice_max(SIZE_HA) %>% 
  ungroup() %>% 
  # remove any duplicate reports
  distinct(FIRE_ID, YEAR, SIZE_HA, .keep_all = TRUE) %>% 
  # create unique id and transform size column
  mutate(ID = paste0(FIRE_ID, ";", YEAR),
         SIZE_HA_SQRT = sqrt(.$SIZE_HA)+1,
         SIZE_HA_CBRT = sign(.$SIZE_HA)*abs(.$SIZE_HA)^(1/3))

# store file
save(fires_clean, file = "fires_clean.rda")



# POPULATION DATA ---
# URL for SEDAC population density data: https://data.ghg.center/browseui/index.html#sedac-popdensity-yeargrid5yr-v4.11/

# load population rasters
path <- "~/Documents/Projects/Wildfires/population_data"
files <- list.files(path = path, pattern = "*.tif", full.names = TRUE)
pop_stack <- stack(files)

# take average of the five layers
pop_ave <- mean(pop_stack)

# crop to Canada
can <- read_sf("~/Documents/Projects/Wildfires/ca.json")
pop_can <- mask(pop_ave, can)
newext <- extent(-150, 30, -42, 85)
pop_can <- raster::crop(pop_can, newext)
plot(pop_can)

writeRaster(pop_can, "~/Documents/Projects/Wildfires/pop_can.tif", format = "GTiff")

# save as a single file



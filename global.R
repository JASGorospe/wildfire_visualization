# Title: Canadian Wildfire Visualization - Global
# Contributor: Julia Gorospe
# Created: 2025-05-12
# Updated: 2025-06-06
# R version 4.3.2 (2023-10-31)
# Platform: aarch64-apple-darwin20 (64-bit)
# Running under: macOS Monterey 12.5.1

# Libraries ---------------------------------------------------------------------------------------

# trouble-shooting Mac PATH error: https://stackoverflow.com/questions/76929900/cannot-install-r-packages-on-rstudio-macbook-pro-m1-chip
# Sys.setenv(PATH = paste("/usr/bin:/bin:/usr/sbin:/sbin", Sys.getenv("PATH"), sep=":"))

library(rsconnect) # version 1.2.1
library(shiny) # version 1.8.0
library(shinyjs) # show/hide function
library(bslib) # 0.6.1
library(bsicons)
library(shinyWidgets)
library(htmltools)
library(htmlwidgets)
library(tidyverse) # version 2.0.0
library(zoo)
library(plotly) # version 4.10.4
library(shinycssloaders)
library(leaflet) # version 2.0.4.1
library(leaflegend)
#library(leaflet.esri)
library(sf)
library(raster)
library(rmapshaper)

# Set Options -------------------------------------------------------------------------------------


# Data Prep ---------------------------------------------------------------------------------------

# load fire data
load("fires_clean.rda")

fires <- fires_clean %>% 
  mutate(CAUSE = case_when(CAUSE == "n/a" ~ "U",
                           CAUSE == "Re" ~ "U",
                           TRUE ~ CAUSE))

# calculate summaries for time trends
# summary <- fires %>% 
#   st_drop_geometry() %>%
#   filter(YEAR > 2003, # missing all of MB's REP_DATE
#          !is.na(REP_DATE)) %>% 
#   group_by(YEAR, MONTH) %>% 
#   summarise(num_fires = n(),
#             size_fires = sum(SIZE_HA)) %>% 
#   ungroup() %>% 
#   complete(YEAR, MONTH, fill = list(num_fires = 0,
#                                     size_fires = 0)) %>% 
#   #mutate(time = as.yearmon(paste(YEAR, MONTH), "%Y %m"))
#   mutate(DAY = "01",
#          time = as.Date(paste(YEAR, MONTH, DAY), "%Y %m %d"))




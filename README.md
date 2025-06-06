# Canadian Wildfire Visualization

### Description
This repository contains the code behind an interactive Shiny application exploring geographic and temporal trends in Canadian wildfires between 1990 and 2020.

![Screenshot 2025-06-06 at 2 27 20 PM](https://github.com/user-attachments/assets/b50c75f0-cc90-4d9a-9791-43f4e15a0345)

The published site can be accessed at: [jast-dashboards.shinyapps.io/canadian_wildfire_visualization/](https://jast-dashboards.shinyapps.io/canadian_wildfire_visualization/)


### Purpose
This project is a portfolio piece designed to demonstrate the following skills:

* General data wrangling
* Manipulation of spatial data using GIS tools (sf and terra)
* Use of R scripting language
* Visual storytelling with data
* Mapping both feature and image spatial data
* Intuitive interactive dashboard design
* Clean coding practices


### Files
**data_processing.R:** contains script to filter and simplify the wildfire polygons, calculate centroids for each fire, remove duplicate records, and generate any values required for visualization - data processing is completed outside of the shiny app to improve loading speed and the overall user experience of app performance

**app_wildfires.R:** contains the shiny app structure, page layout and stylistic theming\
**global.R:** loads libraries and data used across all modules in the app\
**map.R:** contains the ui and server for the map tab of the shiny app including code for all of the elements visiable of the page, reactivity to handle user inputs, and the Leaflet map and Plotly plot design and functionality


### Data Sources
The wildfire dataset behind this project is a compilation of records collected by the Canadian Forest Services from multiple Canadian fire management agencies. Given the harmonization process, it is not a comprehensive resource but rather the most extensive dataset available at the national level. 

**Wildfire Data:** Natural Resources Canada, Canadian Forest Service. Canadian National Fire Database – Agency Fire Data. https://cwfis.cfs.nrcan.gc.ca/ha/nfdb \
**Temperature Data:** Environment and Climate Change Canada. Meteorological Service of Canada GeoMet-Climate WMS. https://eccc-msc.github.io/open-data/msc-geomet/readme_en/ \
**Land Cover Data:** Natural Resources Canada, Canada Centre for Remote Sensing. Landcover 2015. https://geoappext.nrcan.gc.ca/arcgis/rest/services/FGP/canada_landcover_2015_en/MapServer 

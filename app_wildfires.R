# Title: Canadian Wildfire Visualization
# Contributor: Julia Gorospe
# Created: 2025-05-12
# Updated: 2025-06-06
# R version 4.3.2 (2023-10-31)
# Platform: aarch64-apple-darwin20 (64-bit)
# Running under: macOS Monterey 12.5.1

# Published at: https://jast-dashboards.shinyapps.io/canadian_wildfire_visualization/


# UI -------------------------------------------------------------------------------------------

source("global.R", local = TRUE)$value
source("map.R", local = TRUE)$value
#source("trends.R", local = TRUE)$value


ui <- page_navbar(

  theme = bs_theme(bootswatch = "darkly",
                   primary = "#780116",
                   sucess = "#db7c26") %>% 
    bs_add_rules(
      list(
        ".navbar-brand {font-size: 150%; font-weight:bold;}",
        ".nav-link {text-align:center; padding-right:10px; padding-left:10px; font-size:125% ;}",
        ".card-header-tabs .nav-item .nav-link:hover {color: #db7c26 !important;}",
        ".leaflet-control-layers-expanded { background: #adb5bd !important;}"
      )
    ),
  
  
  title = "Canadian Wildfires",
  
  nav_spacer(),
  nav_panel("Map", mapUI("map")),
  #nav_panel("Trends", trendsUI("trends")),
  nav_panel(shiny::icon("circle-info"), 
            
            HTML("<p style = 'margin: 20px 40px;'>
                 <b>Data Sources</b><br>
                 Wildfire data: <br>Canadian Forest Service. 2021. Canadian National
            Fire Database – Agency Fire Data. Natural Resources Canada, Canadian Forest Service, Northern Forestry
            Centre, Edmonton, Alberta. https://cwfis.cfs.nrcan.gc.ca/ha/nfdb<br><br>
                 Temperature data: <br>Meteorological Service of Canada GeoMet-Climate WMS. Environment and Climate Change Canada. <br><br>
                 Land cover data: <br>Government of Canada; Natural Resources Canada; Canada Centre for Remote Sensing. https://geoappext.nrcan.gc.ca/arcgis/rest/services/FGP/canada_landcover_2015_en/MapServer.<br><br><br>
                 
                 <b>Data Manipulation</b><br>
                 To reduce the size of the wildfire dataset, records were limited to years since 1990, duplicates were removed, and wildfire boundaries similified.<br><br>
                 To visualize the relative size of fires meaningfully, fire size in Hectares underwent cubic transformation at smaller scale and square root transformation at larger scale.<br><br><br>
                 
                 <b>Dashboard Development</b><br>
                 The dashboard functionality was developed using Shiny for R, with style and design provided via the bslib framework and bootswatch theming. The map was built using Leaflet for R - other interactive plots were generated with plotly.<br><br>
                 <b>Author</b>: Julia Gorospe<br>
                 Code underlying this Shiny application can be found at: https://github.com/JASGorospe/wildfire_visualization
                 </p>")
  )
)


server <- function(input, output, session) {
  
  mapServer("map")
  #trendsServer("trends")

}

shinyApp(ui, server)
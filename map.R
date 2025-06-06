# UI -----------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------


mapUI <- function(id) {
  
  ns <- NS(id)
  
  useShinyjs()

  layout_sidebar(
    
    # styling of slider
    tags$head(
      tags$style(HTML(
      ".js-irs-0 .irs-bar {
        background: transparent;
        border: #3498db;
      }
      .js-irs-0 .irs-handle {
        background-color: #adb5bd;
      }
    "))
    ),

    sidebar = sidebar(
      width = "25%",
      
      # selections
      card(
        card_header(HTML("<b>Selections</b>")),
        card_body(
          sliderInput(inputId = ns("year"),
                      label = "Year:",
                      min = min(fires$YEAR), max = max(fires$YEAR),
                      value = min(fires$YEAR),
                      sep = "",
                      width = "95%"),
          prettyCheckboxGroup(inputId = ns("cause"),
                              label = "Reported cause of fire:",
                              choices = list("Lightning" = "L", "Human" = "H", "Prescribed Burn" = "H-PB", "Unknown" = "U"),
                              selected = list("Lightning" = "L", "Human" = "H", "Prescribed Burn" = "H-PB", "Unknown" = "U"),
                              icon = icon("check"),
                              status = "primary"
          )
        )
      ),
      
      # selection counter
      value_box(
        style = "background-color: #444444;",
        title = NULL,
        value = textOutput(ns("count")),
        p("wildfires selected"),
        showcase = bs_icon("fire"),
        showcase_layout = showcase_left_center(width = 0.2)
      )
      
    ),
    
    # map
    tags$style(type = "text/css", paste0("#",ns('map')), "{height: calc(100vh - 80px) !important;}"),
    padding = '0px',
    leafletOutput(ns("map")) %>% 
      withSpinner(),
    
    # trend plots
    absolutePanel(
      top = 20, left = "auto", right = 20, bottom = "auto",
      width = 360, height = "auto", draggable = TRUE,
      navset_card_tab(
        height = 320,
        full_screen = FALSE,
        nav_spacer(),
        nav_panel(
          style = "background: #444444",
          "Number of Fires",
          plotlyOutput(outputId = ns("plot_num"))
        ),
        nav_panel(
          "Area Burned",
          plotlyOutput(outputId = ns("plot_size"))
        )
      ),
      style = "background: transparent;"
    )
    
  )
} 


# Server -------------------------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------

# server
mapServer <- function(id) {
  
  moduleServer(id, function(input, output, session) {
    
    output$count <- renderText({nrow(fires_react())})
    
    summary <- fires %>% 
      st_drop_geometry() %>%
      group_by(YEAR) %>% 
      summarise(num_fires = n(),
                size_fires = sum(SIZE_HA)) %>% 
      ungroup() %>% 
      arrange(YEAR) %>%
      mutate(roll_num = rollmeanr(num_fires, 3, fill = NA),
             roll_size = rollmeanr(size_fires, 3, fill = NA))
    
    output$plot_num <- renderPlotly({
      summary %>% 
        plot_ly() %>%
        add_trace(x = ~YEAR, y = ~num_fires,
                  type = 'bar', color = I("#db7c26"),
                  name = "Count") %>%
        add_lines(x=~YEAR, y = ~roll_num, 
                  line = list(color = "#f3f3f3"),
                  hoverinfo = "none",
                  name = "3-year moving average") %>% 
        layout(title= "Annual Overall Trend",
               xaxis = list(title = "Year"),
               yaxis = list(title = "Number of Fires"),
               showlegend = FALSE,
               plot_bgcolor  = "transparent",
               paper_bgcolor = "transparent",
               font = list(color = "lightgrey")) %>% 
        config(displayModeBar = FALSE)
    }) 
    
    
    output$plot_size <- renderPlotly({
      m <- lm(size_fires~YEAR, data = summary)
      summary %>% 
        plot_ly() %>%
        add_trace(x = ~YEAR, y = ~size_fires,
                  type = 'bar', color = I("#db7c26"),
                  name = "Ha") %>%
        add_lines(x=~YEAR, y = ~roll_size, 
                  line = list(color = "#f3f3f3"),
                  hoverinfo = "none",
                  name = "3-year moving average") %>% 
        layout(title= "Annual Overall Trend",
               xaxis = list(title = "Year"),
               yaxis = list(title = "Size (Hectares)"),
               showlegend = FALSE,
               plot_bgcolor  = "transparent",
               paper_bgcolor = "transparent",
               font = list(color = "lightgrey")) %>% 
        config(displayModeBar = FALSE)
    })  
    
    
    fires_react <- reactive({
      fires %>% 
        filter(
          YEAR == input$year,
          CAUSE %in% input$cause
        )
    })

    # background map
    output$map <- renderLeaflet({
      leaflet(options = leafletOptions(worldCopyJump = TRUE, minZoom = 2, zoomControl = FALSE, preferCanvas = TRUE)) %>% 
        addProviderTiles("CartoDB.DarkMatter") %>% 
        hideGroup(c("Mean Annual Temperature (1986-2005)", "Land Cover (2015)")) %>% 
        setView(lng = -100, lat = 62, zoom = 3.5)
    })
    
    # layer on polygons/markers/popups based on inputs
    observe({
      
      # land cover legend: https://geoappext.nrcan.gc.ca/arcgis/rest/services/FGP/LandCover_EN/MapServer/legend
      landcover_classes <- c(
        "Temperate or sub-polar needleleaf forest", 
        "Sub-polar taiga needleleaf forest",
        "Temperate or sub-polar broadleaf deciduous forest",
        "Mixed forest",
        "Temperate or sub-polar shrubland",
        "Temperate or sub-polar grassland",
        "Sub-polar or polar shrubland–lichen–moss",
        "Sub-polar or polar grassland–lichen–moss",
        "Sub-polar or polar barren–lichen–moss",
        "Wetland ",
        "Cropland",
        "Barren land",
        "Urban and built-up",
        "Water", 
        "Snow and ice"
        )
      landcover_colours <- c(
        "#003D00", 
        "#949C70", 
        "#148C3D",
        "#5C752B", 
        "#B38A33",
        "#E1CF8A",
        "#9C7554",
        "#BAD48F",
        "#A8ABAE",
        "#6BA38A",
        "#FFFF00",
        "#A8ABAE",
        "#DC2126",
        "#4C70A3",
        "#FFFFFF")
      
      
      myradius <- if (is.null(input$map_zoom)) {
        fires_react()$SIZE_HA_SQRT/50*(3.5)
      } else {
        case_when(input$map_zoom <=6 ~ fires_react()$SIZE_HA_SQRT/50*(input$map_zoom), 
                  input$map_zoom >6 ~ fires_react()$SIZE_HA_CBRT/30*(input$map_zoom*5))
      }

      
      leafletProxy("map") %>%
        #clearShapes() %>%
        clearMarkers() %>%
        removeTiles(c("TM", "LC")) %>% 
        addWMSTiles("https://geo.weather.gc.ca/geomet-climate?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=DCS.TM.RCP45.YEAR.1986-2005_PCTL50&CRS=EPSG:4326&BBOX=30,-150,85,-42&WIDTH=1800&HEIGHT=1200&FORMAT=image/png",
                    layers = "DCS.TM.RCP45.YEAR.1986-2005_PCTL50",
                    options = WMSTileOptions(format = "image/png", transparent = TRUE, opacity = 0.5),
                    attribution = "ECCC DCS",
                    layerId = "TM",
                    group = "Mean Annual Temperature (1986-2005)") %>% 
        addWMSTiles("https://geoappext.nrcan.gc.ca/arcgis/services/FGP/canada_landcover_2015_en/MapServer/WMSServer",
                    layers = "0",  # Layer ID for the 2015 Land Cover of Canada
                    options = WMSTileOptions(format = "image/png", transparent = TRUE, opacity = 0.5),
                    attribution = "© Natural Resources Canada",
                    layerId = "LC",
                    group = "Land Cover (2015)") %>%
        # addLegend(colors = landcover_colours, labels = landcover_classes,
        #           title = "Land Cover of Canada 2015",
        #           position = "bottomright",
        #           layerId = "LClegend",
        #           group = "Land Cover  (2015)") %>%
        addCircleMarkers(data = fires_react(), ~longitude, ~latitude,
                         radius = ~myradius,
                         #radius = 10,
                         color="#c32f28",
                         weight = 1,
                         stroke = TRUE,
                         fillOpacity = 0.6,
                         popup = paste0("<br><b>Fire ID</b>: ", fires_react()$FIRE_ID,
                                        "<br><b>Year</b>: ", fires_react()$YEAR,
                                        "<br><b>Size</b>: ", round(fires_react()$SIZE_HA,2), " Ha"),
                         layerId = fires_react()$ID,
                         group = "Fires") %>% 
        addLayersControl(overlayGroups = c("Mean Annual Temperature (1986-2005)", "Land Cover (2015)"),
                         position = "bottomleft",
                         options = layersControlOptions(collapsed = FALSE))
        
        
    })
    
    # add legend based on overlayGroup
    
    
    # add polygon on click
    observeEvent(input$map_marker_click, {
      
      if (is.null(input$map_marker_click)) {
        return()
      }
      
      # generate static dataframe to populate polygons on click
      polygon_react <- isolate(fires_react())
      
      click_data <- reactive({
        polygon_react %>% 
          filter(ID == input$map_marker_click$id)
      })
      
      leafletProxy("map") %>%
        #setView(input$map_marker_click$lng, input$map_marker_click$lat, zoom = click_data()$zoom) %>%
        addPolygons(data = click_data(),
                    stroke = TRUE,
                    color = "#363538",
                    opacity = 1,
                    layerId = "clicked",
                    weight = 1,
                    fillColor = ~I("#f7b538"),
                    fillOpacity = 0.6,
                    highlightOptions = highlightOptions(color = "#db7c26", weight = 2, bringToFront = TRUE, opacity = 1))
      
    })
    
    observeEvent(input$map_click, {
      leafletProxy("map") %>% 
        #setView(input$map_click$lng, input$map_click$lat, zoom = input$map_zoom - 1) %>% 
        removeShape(layerId = "clicked")
    })
    
    observeEvent(input$map_shape_click, {
      removeShape(leafletProxy("map"), layerId = "clicked")
    })
    
   
  })
  
}
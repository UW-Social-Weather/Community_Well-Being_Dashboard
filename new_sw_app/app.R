library(shiny)
library(maps)
library(mapproj)
library(leaflet)
library(sp)
library(tidyverse)
library(rgeos)
library(rgdal)
library(maptools)
library(dplyr)
library(scales)
library(readxl)
library(plotly)
library(DT)
library(mapview)
library(webshot)

# load the data necessary for the project
data <- readRDS("./03_final_data/16_final_data_for_maps.RDS") 

# load all of the files containing the county shapefiles
counties.map <- readRDS("./03_final_data/17_county_shapefile.RDS")

# load label table
label_table <- read_xlsx("./03_final_data/label_table.xlsx")
health_vars <- label_table$label[1:10]

# load lat/long coordinate data
coordinate_data <- readRDS("./03_final_data/18_prepped_lat_long_data_states.RDS")
state_vars <- coordinate_data$state_name

# load the county level lat/long coordinate data
county_coordinates <- readRDS("./03_final_data/19_prepped_lat_long_data_counties.RDS")

# Define UI  ----
ui <- fluidPage(
  
  titlePanel(h1("Community Well-Being Dashboard", align = "center")),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Map county-level well-being indicators."),
      
      selectInput("var", 
                  label = "Choose a variable to display:",
                  choices = health_vars,
                  selected = "Gross Domestic Product"),
      
      # I want the input year to change based on the variable available
      selectInput("range",
                  label = "Year of interest:",
                  choices = NULL,
                  selected = NULL),
      
      # Select the state of interest to focus on
      selectInput("state",
                  label = "Select state:",
                  choices = state_vars,
                  selected = state_vars[1]),
      
      # Select the county of interest to focus on
      selectInput("county",
                  label = "Select county:",
                  choices = NULL,
                  selected = "Select County")
      ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("View Map", verbatimTextOutput("mapview"),
                 fluidRow(column(width = 12, "Use the left panel to filter data according to year and location. 
                                 Please note that data are not currently available for every county and every year.", 
                                 style='text-align:center')),
                 div(downloadButton(outputId = "dl",
                                 label = "Download map as png",
                                 icon = shiny::icon("camera")),
                     style="float:right"),
                 leafletOutput("mymap")),
        
        tabPanel("View Trends", verbatimTextOutput("trendview"),
                 fluidRow(column(width = 12, "Use the left panel to filter data according to variable and location.
                                 Please note that data are not currently available for every county and every year.",
                                 style='text-align:center')),
                 br(),
                 plotlyOutput("lineplot")),
        
        tabPanel("Data Sources for the Dashboard", verbatimTextOutput("about"),
                 fluidRow(column(width = 12, "The data used in this dashboard was retrieved from the sources listed below.",
                                 style ="text_align:center")),
                 dataTableOutput("aboutTable")), 
        )
      )
  )
)

# Define server logic ----
server <- function(input, output, session) {

  myData <- reactive({
    x <- input$var 
    years_available <- label_table %>% filter(label==x)
    
  })
  
  # determine which county variables will appear in the inputlist
  # NOTE: Might be better to use the underlying data as this could help ensure there are counties with data shown in the list!
  myCounties <- reactive({
    y <- input$state
    counties_available <- county_coordinates %>% filter(state_name==y)
  })


    observe({
      updateSelectInput(session, "range",
                        label = "Year of interest:",
                        choices = seq(myData()$start_year, myData()$end_year, by=myData()$by),
                        # choices = c(myData()$start_year:myData()$end_year),
                        selected = myData()$end_year)
  })
    
    observe({
      updateSelectInput(session, "county",
                        label = "Select county:",
                        choices = unique(myCounties()$county_name),
                        selected = "Select County")
    })
    
    foundational.map <- reactive({
      
      # these are the inputs that are required to properly plot the data
      req(input$range)
      req(input$state)
      
      long = as.numeric(county_coordinates %>% filter(state_name==input$state & county_name==input$county) %>% select(long))
      lat  = as.numeric(county_coordinates %>% filter(state_name==input$state & county_name==input$county) %>% select(lat))
      zoom = as.numeric(county_coordinates %>% filter(state_name==input$state & county_name==input$county) %>% select(zoom))
      
      # subset data according to year
      data_subset <- data %>% filter(year==input$range)
      
      # merge subsetted year data with spatial data
      leafmap <- sp::merge(counties.map, data_subset, by="GEOID")
      
      # set the unit descriptions in a reactive way
      popupData <- reactive({
        x <- input$var
        years_available <- label_table %>% filter(label==x)
        
      })
      
      # this will determine which variable gets plotted
      var <- switch(input$var,
                    "Strength of Local Economy" = leafmap$gdp,
                    "School Enrollment" = leafmap$child_enrollment,
                    "Vulnerability to Disasters" = leafmap$risk_score,
                    "Food Insecurity" = leafmap$fi_rate,
                    "Days with Clean Air" = leafmap$good_aqi,
                    "Incarcerated Population" = leafmap$total_jail_pop,
                    "Income Inequality" = leafmap$top_to_bottom_ratio,   
                    "Affordable Housing" = leafmap$aaa_per100,
                    "Emergency Department Visits"=leafmap$emergency_visits,
                    "People Living Alone" = leafmap$pop_liv_alone)
      
      
      # Format popup data for leaflet map.
      popup_dat <- paste0("<strong>County: </strong>", leafmap$county_name,
                          "<br><strong>State: </strong>", leafmap$state_name,
                          "<br><strong>Definition: </strong>", popupData()$description, 
                          "<br><strong>Value: </strong>", round(var, digits = popupData()$round_dig),
                          "<br><strong>Unit of measurement: </strong>", popupData()$type)
      
      pal <- colorQuantile("YlGnBu", NULL, n=4)
      
      
      leaflet(data = leafmap) %>%
        addTiles() %>%
        # setView(-95, 39, 4) %>%
        setView(long, lat, zoom=zoom) %>%
        addPolygons(fillColor = ~pal(var),
                    # fillColor = ~pal(var),
                    fillOpacity = 0.8,
                    color = "#BDBDC3",
                    weight = 1,
                    popup = popup_dat) %>%
        addLegend("bottomright",  # location
                  pal = pal,     # palette function
                  values = ~as.numeric(var),
                  title = paste0(input$var, "\n", "County Quartiles"))
    })
  
    
  output$mymap <- renderLeaflet({
    

    foundational.map()
    # pal <- colorNumeric(
    #   palette = "YlGnBu",
    #   domain = var
    # )
    
    
    ############################################# draw map #############################################
    
    
    
    
    # leaflet(data = leafmap) %>%
    #   addTiles() %>%
    #   # setView(-95, 39, 4) %>%
    #   setView(long, lat, zoom=zoom) %>%
    #   addPolygons(fillColor = ~pal(var),
    #               # fillColor = ~pal(var),
    #               fillOpacity = 0.8,
    #               color = "#BDBDC3",
    #               weight = 1,
    #               popup = popup_dat) %>%
    #   addLegend("bottomright",  # location
    #             pal = pal,     # palette function
    #             values = ~as.numeric(var),
    #             title = paste0(input$var, "\n", "County Quartiles"))
    
    })
  
  ##################### save map as pdf
  user.created.map <- reactive({
    
    foundational.map()
    
    # # store same map in a reactive expression
    # leaflet(data = leafmap) %>%
    #   addTiles() %>%
    #   # setView(-95, 39, 4) %>%
    #   setView(long, lat, zoom=zoom) %>%
    #   addPolygons(fillColor = ~pal(var),
    #               # fillColor = ~pal(var),
    #               fillOpacity = 0.8,
    #               color = "#BDBDC3",
    #               weight = 1,
    #               popup = popup_dat) %>%
    #   addLegend("bottomright",  # location
    #             pal = pal,     # palette function
    #             values = ~as.numeric(var),
    #             title = paste0(input$var, "\n", "County Quartiles"))
  })
  
  output$dl <- downloadHandler(
    filename = paste0(Sys.Date(), "_customLeafletmap", ".png"), 
    content = function(file) {
      mapshot(x = user.created.map(), 
              file = file, 
              cliprect = "viewport", # the clipping rectangle matches the height & width from the viewing port
              selfcontained = TRUE # when this was not specified, the function for produced a PDF of two pages: one of the leaflet map, the other a blank page.
      )
    } # end of content() function
  ) # end of downloadHandler() function
  
 
  ############################################# plot trends ###########################################
  output$lineplot <- renderPlotly({
    
    req(input$state)
    req(input$var)
    
    # keep only columns of interest
    data_wide <- data %>% select(-c("GEOID", "name", "state_alpha_code"))
    
    # reshape the data to be long format
    data_long <- data_wide %>% pivot_longer(cols = !c(state_name, county_name, year), 
                                            names_to = "variable",
                                            values_to = "value")
    
    # merge labels from label table
    plot_labels <- label_table %>% select(label, variable, type)
    
    # merge labels onto the data
    data_long <- merge(data_long, plot_labels, by="variable")
    
    # filter the data --manually first
    test <- data_long %>% filter(state_name == input$state & label == input$var)
    # test <- data_long %>% filter(state_name == "Alabama" & label == "Strength of Local Economy")
    
    # drop na values
    test <- test %>% filter(!is.na(value))
    
    # order data according to year
    
    # plot the trend line
    # plot_ly(test, x=~year, y=~value, type='scatter', mode='line')
    plot_ly(test, x = ~year) %>% 
      add_lines(y = ~ value, name = test$county_name, mode = 'lines', connectgaps = FALSE, visible='legendonly') %>%
        layout(title=paste0("Trends in ", unique(test$label)),
               legend = list(title = list(text='<b> Select Counties Below </b>')),
               xaxis = list(title = "Year",
                            type = "date",
                            dtick = "M12"),
               yaxis = list(title = paste0(unique(test$type))),
               modebar = list(orientation = "h")) %>%
      config(displayModeBar = TRUE,
             displaylogo = FALSE,
             modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d", "autoScale2d", "pan2d", "hoverClosestCartesian", "hoverCompareCartesian", "zoom2d", "resetScale2d"))
    
    # see here for more info on the legend: https://plotly.com/python/legend/?_ga=2.82607006.949993209.1671831637-1341308099.1669755242
    # see here for how to download an image of the map: https://stackoverflow.com/questions/44259716/how-to-save-a-leaflet-map-in-shiny
    
  })
  
  ################## Create an about table using the label table #########################################
  output$aboutTable <- DT::renderDataTable({
    
    aboutTable <- label_table %>% 
      filter(Domain!="NA") %>%
      select(Domain, Subdomain, label, description, type, start_year, end_year, Source) %>%
      rename(Variable=label,
             Description=description,
             Measurement=type)
    
    # create new year-range variable
    aboutTable$Range <- paste0(aboutTable$start_year, " - ", aboutTable$end_year)
    
    # subset final columns of interset
    aboutTable <- aboutTable %>% 
      select(Domain, Subdomain, Variable, Description, Measurement, Range, Source)
     
  }) 
}

# this merges the ui above with the html index file
ui <- htmlTemplate(
  filename = "www/index.html",
  what_if_ui = ui
)

shinyApp(ui = ui, server = server)
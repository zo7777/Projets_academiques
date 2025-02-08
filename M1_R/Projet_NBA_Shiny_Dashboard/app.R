library(shiny)
library(tidyverse)
library(shinydashboard)

ui <- source('./ui.R')
server <- source('./server.R')

shinyApp(ui, server)
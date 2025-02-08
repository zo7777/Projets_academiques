library(shiny)
library(plotly)
library(tidyverse)
library(colourpicker)
library(rAmCharts)

#source("script.R")$value
source("functions.R")

final <- read_csv("data/final_players.csv")|> select(-1)
tableau <- read_csv("data/final_team.csv")|> select(-1)

ui <- shinyUI(
  # navbarPage
  navbarPage("NBA Dashboard",
             theme = bslib::bs_theme(bootswatch = "quartz"),
             # premier onglet "Joueurs"
             tabPanel("Joueurs",
                      sidebarLayout(
                        sidebarPanel(
                          # choix des variables
                          selectInput(
                            inputId = "select_variable",
                            label = "Choisir une statistique :",
                            choices = colnames(final)[4:11],
                            selected = colnames(final)[1],
                            multiple = FALSE
                          ),
                          # choix du joueur
                          selectInput(
                            inputId = "select_player",
                            label = "Joueur :",
                            choices = famous_players(final, 19), 
                            selected = "Kevin Durant",
                            multiple = FALSE
                          ),
                          # choix de la saison
                          selectInput(
                            inputId = "select_season",
                            label = "Saison :",
                            choices = arrange(final[,2], SEASON), 
                            selected = c("2022","2021"),
                            multiple = T
                          ),
                          # définition du type de graphe
                          radioButtons(
                            inputId = "type_graph",
                            label = "Type du graphique",
                            choices = c("Diagramme en barres" = "bar",
                                        "Nuage de points et lignes" = "scatter"),
                            selected = "Nuage de points et lignes"
                          ),
                          
                          # ligne horizontale
                          hr(),
                          h6("Données synthétiques du joueur"),
                          
                          # format rendu des données
                          radioButtons(
                            inputId = "format",
                            label = "Choisir le format :",
                            choices = c("Comma Separated Value" = "csv",
                                        "Python JSON" = "json",
                                        "Microsoft Excel" = "xlsx"),
                            selected = "Comma Separated Value"
                          ),
                          # bouton de téléchargement
                          downloadButton(
                            outputId = "download_file",
                            label = "Télécharger",
                            style = "background-color: cornflowerblue; color: white"
                          )
                          
                        ),
                        
                        mainPanel(
                          tabsetPanel(
                            type = "tabs",
                            tabPanel(
                              "Visualisation",
                              br(),
                              plotlyOutput("players_graph"),
                              # saut de ligne
                              hr(),
                              h5("Statistiques par match et par saison saison du joueur"),
                              tableOutput("lastseason")
                            ),
                            tabPanel(
                              "Jeu de données",
                              br(),
                              dataTableOutput("data")
                            )
                          )
                        )
                      )
             ),
             
             # second onglet Visualisation
             tabPanel("Equipes", 
                      fluidRow(
                        column(width=4,
                               wellPanel(
                                 selectInput(inputId = "equipes", label = "Equipe : ", choices = unique(tableau$NICKNAME)),
                                 selectInput(inputId = "saison", label = "Saison : ", choices = unique(tableau$SEASON)),
                                 selectInput(inputId = "stats", label = "Stats : ", choices = colnames(tableau)[4:20]),
                                 colourInput(inputId = "color", label = "Couleur :", value = "#F2EC30")
                                 
                               )
                        ),
                        column(width=8,
                               tabsetPanel(id="viz",
                                           tabPanel("Visualisation",
                                                    br(),
                                                    plotlyOutput("Plot"),
                                                    div(textOutput("stats"), align = "center"),
                                                    hr(),
                                                    amChartsOutput("distPlot"),
                                                    div(textOutput("equipes"), align = "center")
                                           ),
                                           tabPanel("Tableau des statistiques",
                                                    br(),
                                                    dataTableOutput("tab")
                                                    ),
                                           tabPanel("Classement des équipes",
                                                    br(),
                                                    dataTableOutput("ranking")
                                           )
                               )
                        )
                      )
             )
  )
)

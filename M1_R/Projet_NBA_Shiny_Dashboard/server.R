library(shiny)
library(plotly)
library(rAmCharts)
library(DT)

# Importations des bases de données 
final <- read_csv("data/final_players.csv")|> select(-1)
tableau <- read_csv("data/final_team.csv")|> select(-1)
rank <- read_csv("data/rank.csv")|> select(-1)

server <- function(input, output, session) {
  don <- reactive({
    final |> 
      filter(PLAYER_NAME == input$select_player)
  })
  
  player_career <- reactive({
    don() |> 
      group_by(SEASON) |>
      summarise("Nom du joueur" = input$select_player,
                Points = mean(Points),
                Passes = mean(Passes_décisives),
                Rebonds = mean(Rebonds),
                Interceptions = mean(Interceptions),
                Contres = mean(Contres),
                "Balles Perdues" = mean(Balles_Perdues)) |> 
      filter(SEASON %in% input$select_season) |> 
      rename("Saison" = SEASON)
  })
  
  output$players_graph <- renderPlotly(
    don() |> 
      select(SEASON, var = input$select_variable, NICKNAME) |> 
      plot_ly(x = ~SEASON, y = ~var, color = ~NICKNAME, colors =c("coral","darkolivegreen1","aliceblue"),
              type = input$type_graph, mode = 'line', connectgaps = F) |> 
      layout(title = paste("Evolution moyenne des statistiques de", input$select_player),
             legend=list(title=list(text='<b> Equipes </b>')),
             xaxis = list(title = "Saisons"),
             font = list(
               family = "arial",
               size = 12,
               color = 'azure'),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)",
             yaxis = list(title = input$select_variable))
  )
  
  output$lastseason <- renderTable(
    player_career()
  )
  
  output$download_file <- downloadHandler(
    # nom du fichier téléchagé
    filename = function() {
      gsub(" ", "", paste(input$select_player,".",input$format))
      },
    # sauvegarde
    content = function(file) {
      write.csv(player_career(), file, row.names = F)
    }
  )
  
  # affiche le jeu de données
  output$data <- renderDataTable(
    datatable(final,
              caption = htmltools::tags$caption(
                style = 'caption-side: top; text-align: left; color: black',
                'Tableau de donnees: ', htmltools::em('statistiques des joueurs de la NBA')
              ),
              filter="top",
              options=list(pageLength=20,scrollX=T)
    )
  )
  
  # serveur équipe
  data <- reactive({
    tab <- as.data.frame(t(tableau[which(tableau$NICKNAME==input$equipes
                                         & tableau$SEASON==input$saison),]))
    tab <- as.data.frame(tab[4:20,])
    tab$`tab[4:20, ]` <- as.numeric(tab$`tab[4:20, ]`)
    tab$stats <- tab$`tab[4:20, ]`
    row.names(tab) <- colnames(tableau)[4:20]
    tab
  })
  
  donnee <- reactive({
    tableau |> 
      filter(NICKNAME == input$equipes)
  })
  
  # création du classement des équipes
  rang <- reactive({
    rang <- rank |> 
      filter(SEASON == input$saison) |>
      select(-c(STANDINGSDATE,ARENA,ABBREVIATION,YEARFOUNDED,CITY,ARENACAPACITY,
                OWNER,DLEAGUEAFFILIATION,GENERALMANAGER)) |>
      arrange(-W_PCT)  
    rang <- rang |> mutate(RANKING = 1:nrow(rang)) |> 
      select(-RANKING)
  })
  
  output$Plot <- renderPlotly({
    donnee() |> 
      select(saison = SEASON, var = input$stats, NICKNAME) |> 
      plot_ly(x = ~saison, y = ~var, line=list(color=input$color),
              type = "scatter", mode = 'lines') |> 
      layout(title = paste("Evolution des", input$stats, "de l'equipe", input$equipes),
             xaxis = list(title = "Saisons"),
             yaxis = list(title = input$stats),
             font = list(
               family = "arial",
               size = 12,
               color = 'azure'),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)")
  })
  
  output$distPlot <- renderAmCharts({
    x <- data() 
    # affiche le diagramme en barres des équipes
    amBarplot(data = x, y = "stats", labelRotation = -90,
              show_values = F, export = T, zoom = T,
              main = paste("Barplot des stats de l'equipe", input$equipes , "pour l'annee ", input$saison)
    )
  })
  
  # table
  output$tab <- renderDataTable({
    datatable(tableau,
              caption = htmltools::tags$caption(
                style = 'caption-side: top; text-align: left; color: black',
                'Tableau de donnees: ', htmltools::em('stats des equipes de la NBA')
              ),
              filter="top",
              options=list(pageLength=20,scrollX=T)
    )
  }) 
  
  output$ranking <- renderDataTable({
    datatable(rang(),
              caption = htmltools::tags$caption(
                style = 'caption-side: top; text-align: left; color: black',
                'Tableau: ', htmltools::em(paste('rang des equipes de la NBA en ',as.character(input$saison)))
              ),
              filter="top",
              options=list(pageLength=nrow(rang()),scrollX=T)
    )
  })
  
  # Rafraîchit la sortie Shiny toutes les 5 secondes
  autoInvalidate <- reactiveTimer(5000, session)
  
  observe({
    autoInvalidate()
    invalidateLater(0, session)
  })
}
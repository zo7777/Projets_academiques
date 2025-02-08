# Définitions de fonctions pour le serveur.R ou ui.R

famous_players <- function(data, criteria){
  players_lst <- data |> 
    group_by(PLAYER_NAME) |> 
    summarise("Points"=mean(Points))|> 
    filter(Points >= criteria)|> 
    select(PLAYER_NAME)
  return(players_lst)
}


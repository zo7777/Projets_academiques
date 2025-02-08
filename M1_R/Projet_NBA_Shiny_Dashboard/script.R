library(tidyverse)
library(rstudioapi)
getwd()
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

details <- read.csv("data/games_details.csv",header = T, sep = ",")
details <- na.omit(details)
# View(details)
games <- read.csv("data/games.csv", header = T, sep = ",")
# View(games)
players <- read.csv("data/players.csv", header = T, sep = ",")
# View(players)
teams <- read.csv("data/teams.csv", header = T, sep = ",")
# View(teams)
games_details <- left_join(details, games, by = "GAME_ID")

# creation de la base pour le rang des C)quipes
ranking <- read.csv("data/ranking.csv",header=T,sep=",")

rank22 <- ranking[which(ranking$STANDINGSDATE=="2022-12-22"),]
rank <- ranking[which(
  as.numeric(substr(ranking$STANDINGSDATE,start=6,stop=7))==5 &
    as.numeric(substr(ranking$STANDINGSDATE,start=9,stop=10))==1
),]
rank <- rbind(rank22,rank)
rank$SEASON <- 2000 +  as.numeric(substr(rank$SEASON_ID,start=4,stop=5))

rank <- rank |> select(-c('LEAGUE_ID','SEASON_ID','RETURNTOPLAY'))
rank <- left_join(rank,teams,by="TEAM_ID")
rank <- select(rank,-c("LEAGUE_ID","TEAM_ID","MIN_YEAR","MAX_YEAR"))
rank <- rank |> relocate("SEASON","STANDINGSDATE","CONFERENCE","TEAM","ABBREVIATION","NICKNAME")

write.csv(rank,"data/rank.csv", row.names=T)

# creation de la base pour les stats des C)quipes
final_team <- games_details |> group_by(GAME_ID,SEASON,TEAM_ID) |> summarise(Team_points=sum(PTS),
                                                                             Team_FGM=sum(FGM),
                                                                             Team_FGA=sum(FGA),
                                                                             Team_FG3M=sum(FG3M),
                                                                             Team_FG3A=sum(FG3A),
                                                                             Team_FTM=sum(FTM),
                                                                             Team_FTA=sum(FTA),
                                                                             Team_Asts=sum(AST),
                                                                             Team_Orebs=sum(OREB),
                                                                             Team_Drebs=sum(DREB),
                                                                             Team_Rebs=sum(REB),
                                                                             Team_Steals=sum(STL),
                                                                             Team_Blks=sum(BLK),
                                                                             Team_TOs=sum(TO))

final_team <- final_team |> group_by(TEAM_ID,SEASON) |> summarise(Pts=mean(Team_points),
                                                                  Tirs_Reussis=mean(Team_FGM),
                                                                  Tirs_Tentes=mean(Team_FGA),
                                                                  Trois_Pts_Reussis=mean(Team_FG3M),
                                                                  Trois_Pts_Tentes=mean(Team_FG3A),
                                                                  Lancer_Franc_Reussi=mean(Team_FTM),
                                                                  Lancer_Franc_Tente=mean(Team_FTA),
                                                                  Passe_D=mean(Team_Asts),
                                                                  Rebond_Offensif=mean(Team_Orebs),
                                                                  Rebond_Defensif=mean(Team_Drebs),
                                                                  Rebond=mean(Team_Rebs),
                                                                  Interception=mean(Team_Steals),
                                                                  Contre=mean(Team_Blks),
                                                                  Ballons_Perdus=mean(Team_TOs))

final_team <- data.frame(TEAM_ID=final_team$TEAM_ID,SEASON=final_team$SEASON,
                         Pts=final_team$Pts,Tirs_Reussis=final_team$Tirs_Reussis,
                         Tirs_Tentes=final_team$Tirs_Tentes,PCT_Tirs=(final_team$Tirs_Reussis/final_team$Tirs_Tentes)*100,
                         Trois_Pts_Reussis=final_team$Trois_Pts_Reussis,Trois_Pts_Tentes=final_team$Trois_Pts_Tentes,
                         PCT_Trois_Pts=(final_team$Trois_Pts_Reussis/final_team$Trois_Pts_Tentes)*100,
                         Lancer_Franc_Reussi=final_team$Lancer_Franc_Reussi,Lancer_Franc_Tente=final_team$Lancer_Franc_Tente,
                         PCT_Lancer_Franc=(final_team$Lancer_Franc_Reussi/final_team$Lancer_Franc_Tente)*100,
                         final_team[,10:ncol(final_team)])

final_team <- left_join(final_team,teams,by="TEAM_ID")
final_team <- select(final_team,-c("LEAGUE_ID","TEAM_ID","MIN_YEAR","MAX_YEAR"))

final_team <- final_team[,c(19,20,1:18)]
colnames(final_team)[4:20] <- c("Points","Tirs Reussis","Tirs Tentees", "% Tirs",
                          "3 Points Reussis","3 Points Tentes","% 3 Poins","Lancer Franc Reussi",
                          "Lancer Franc Tente","% Lancer Franc", "Passes Decisives","Rebond Offensif",   
                          "Rebond Defensif","Rebond","Interception","Contre","Ballons Perdus")

write.csv(final_team,"data//final_team.csv", row.names=T)

# base de donnC)es des joueurs
play <- games_details |>  
  group_by(PLAYER_NAME,SEASON,TEAM_ID) |> 
  summarise("Points"=mean(PTS),
            "Passes_dC)cisives"=mean(AST),
            "Rebonds_Offensifs"=mean(OREB),
            "Rebonds_DC)fensifs"=mean(DREB),
            "Rebonds"=mean(REB),
            "Interceptions"=mean(STL),
            "Contres"=mean(BLK),
            "Balles_Perdues"=mean(TO))
# View(play)
final <- left_join(play, teams, by = "TEAM_ID")
write.csv(final,"data/final_players.csv", row.names=T)

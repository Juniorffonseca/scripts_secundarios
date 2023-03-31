# Carregando pacotes
library(shiny)
library(shinythemes)
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(neuralnet)
library(reshape2)
library(data.table)
library(readr)
library(ggplot2)
library(DT)

load(file = "model_nnet.rda")

link <- "https://www.vlr.gg/stats/?event_group_id=all&event_id=all&region=all&country=all&min_rounds=50&min_rating=1550&agent=all&map_id=all&timespan=all"

players <- read_html(link) %>% 
  html_node("table") %>% 
  html_table() %>% 
  separate(Player, into = c("Player", "Team"), sep = "\\s+", extra = "merge") %>% 
  select('Player', 'Team', 'R', 'Rnd', 'ACS', 'K:D', 'KAST', 'ADR') %>% 
  as.data.frame()


# Arrumando as colunas -------------------------------------------------------------------------------------
players <- dplyr::select(players, Player, R, ACS, 'K:D', KAST, ADR)
row.names(players) <- make.names(players[,1], unique = T)
players <- dplyr::select(players, -Player)
players$KAST <- parse_number(players$KAST)

# Time A
timeA = c('aspas', 'Sacy', 'saadhak', 'pANcada', 'Less')
timeA <- paste0('\\b', timeA, '\\b') 
players$timeA <- ifelse(grepl(paste(timeA, collapse = '|'), rownames(players), useBytes = T), 1, 0)

# Time B
timeB = c('FNS', 'yay', 'crashies', 'Marved', 'Victor')
timeB <- paste0('\\b', timeB, '\\b') 
players$timeB <- ifelse(grepl(paste(timeB, collapse = '|'), rownames(players), useBytes = T), 1, 0)

timeA_df <- filter(players, players$timeA == 1)
timeA_df <- dplyr::select(timeA_df, R, ACS, 'K:D', KAST, ADR)
timeB_df <- filter(players, players$timeB == 1) 
timeB_df <- dplyr::select(timeB_df, R, ACS, 'K:D', KAST, ADR)

#if(nrow(timeA_df) == 5 && nrow(timeB_df) == 5){

# Médias
timeA_R <- mean(timeA_df$R)
timeA_ACS <- mean(timeA_df$ACS)
timeA_KAST <- mean(timeA_df$KAST)
timeA_KD <- mean(timeA_df$'K:D')
timeA_ADR <- mean(timeA_df$ADR)
timeB_R <- mean(timeB_df$R)
timeB_ACS <- mean(timeB_df$ACS)
timeB_KAST <- mean(timeB_df$KAST)
timeB_KD <- mean(timeB_df$'K:D')
timeB_ADR <- mean(timeB_df$ADR)

partida <- c(timeA_R, timeB_R, timeA_ACS, timeB_ACS, timeA_KAST, timeB_KAST, timeA_KD, timeB_KD,
             timeA_ADR, timeB_ADR)

jogos_scale <- read.csv2('csv/partidas.csv') %>% select(-X, -ganhador)

jogos_scale <- rbind(jogos_scale, partida)

jogos_scale <- scale(jogos_scale)

partida <- jogos_scale[814,]

partida <- t(partida)

partida <- as.data.frame(partida)

colnames(partida) <- c('time1R', 'time2R', 'time1ACS', 'time2ACS', 'time1KAST', 'time2KAST', 'time1KD', 'time2KD',
                       'time1ADR', 'time2ADR')

previsao <- compute(n, partida)

previsao <- previsao$net.result[1]

partida_reversa <- partida

partida_reversa$time1R <- partida$time2R
partida_reversa$time2R <- partida$time1R
partida_reversa$time1ACS <- partida$time2ACS
partida_reversa$time2ACS <- partida$time1ACS
partida_reversa$time1KAST <- partida$time2KAST
partida_reversa$time2KAST <- partida$time1KAST
partida_reversa$time1KD <- partida$time2KD
partida_reversa$time2KD <- partida$time1KD
partida_reversa$time1ADR <- partida$time2ADR
partida_reversa$time2ADR <- partida$time1ADR

previsao2 <- compute(n, partida_reversa)

previsao2 <- previsao2$net.result[1]

a <- previsao
b <- previsao2

transforma_positivo <- function (x){
  y = atan(x) + pi/2
  return (y)
}

transforma_probabilidade <- function (y, x){
  z = y / (y + x)
  w = x / (x + y)
  c = as.matrix(c(z,w))
  return(c)
}

a <- transforma_positivo(a)
b <- transforma_positivo(b)
previsao <- transforma_probabilidade(a,b)

previsao <- previsao * 100

return(previsao)


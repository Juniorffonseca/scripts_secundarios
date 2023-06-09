# Carregando pacotes --------------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(reshape2)
library(readr)
library(purrr)

# Função medias_jogadores ---------------------------------------------------------------------------------
medias_Jogadores <- function(url_jogador){
  
  html_lido <- read_html(as.character(url_jogador))
  
  dados_jogador <- html_nodes(html_lido, 'table') %>%
    html_table()
  dados_jogador <- dados_jogador %>% map_df(as_tibble, .name_repair = 'minimal') %>%
    dplyr::select(Use, Rating, ACS, KAST, 'K:D', ADR)
  
  dados_jogador$Use <- as.numeric(gsub(".*\\((.*)\\).*", "\\1", dados_jogador$Use))
  
  dados_jogador$KAST <- parse_number(dados_jogador$KAST)
  
  dados_jogador[,2:ncol(dados_jogador)] <- lapply(dados_jogador[,2:ncol(dados_jogador)],
                                                  function(x, y) x * y, y = dados_jogador$Use)
  
  dados_jogador <- lapply(dados_jogador, sum, na.rm = T)
  
  dados_jogador <- lapply(dados_jogador, function(x, y) round(x / y, 2), dados_jogador$Use)
  
  medias_jogador <- dados_jogador
  
  medias_jogador[['KAST']] <- round(medias_jogador[['KAST']], 0)
  return(medias_jogador)
}

# Função medias_times -------------------------------------------------------------------------------------
medias_Times <- function (url_partida){
  # Pegando os dados no link da partida -------------------------------------------------------------------
  links_jogadores <- read_html('https://www.vlr.gg/162404/northwood-university-vs-o7-red-bull-campus-clutch-2022-world-final-stage-gf') %>% 
    html_nodes('td.mod-player a') %>% 
    html_attr('href')
  
  # Separando os nomes dos jogadores de cada time em 2 arrays
  timeA <- links_jogadores[1:5]
  timeB <- links_jogadores[6:10]
  
  # Criando os links usando os nomes dos jogadores para ficar entre '...vlr.gg' e '/?timespan...'
  n <- 1
  for (i in timeA){
    timeA[n] <- paste('https://www.vlr.gg', '/?timespan=all', sep = i)
    n = n + 1
  }
  
  n <- 1
  for(i in timeB){
    timeB[n] <- paste('https://www.vlr.gg', '/?timespan=all', sep = i)
    n = n + 1
  }
  
  timeA_medias <- list()
  timeB_medias <- list()
  
  for (i in timeA){
    timeA_medias[[length(timeA_medias)+1]] <- medias_Jogadores(i)
  }
  
  for (i in timeB){
    timeB_medias[[length(timeB_medias)+1]] <- medias_Jogadores(i)
  }
  
  timeA_medias <- timeA_medias %>% map_df(as_tibble)
  timeB_medias <- timeB_medias %>% map_df(as_tibble)
  
  timeA_medias <- dplyr::select(timeA_medias, -Use)
  timeB_medias <- dplyr::select(timeB_medias, -Use)
  
  partida <- cbind(timeA_medias, timeB_medias)
  
  colnames(partida) <- c('time1R', 'time1ACS', 'time1KAST', 'time1KD', 'time1ADR', 
                         'time2R', 'time2ACS', 'time2KAST', 'time2KD', 'time2ADR')
  
  partida <- select(partida, 'time1R', 'time2R', 'time1ACS', 'time2ACS', 'time1KAST', 'time2KAST', 'time1KD', 'time2KD',
                    'time1ADR', 'time2ADR')
  
  partida <- as.data.frame(t(colMeans(partida)))
  
  return(partida)
  
}



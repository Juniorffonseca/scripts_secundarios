# Carregando pacotes --------------------------------------------------------------------------------------
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(reshape2)
library(tidyverse)
library(neuralnet)
library(readr)
library(purrr)
library(plotly)
library(ggrepel)

# Criando variável páginas e criando variável 'p' que será a parte final do url (o número da página) -------
paginas <- 'https://www.vlr.gg/matches/results'
p <- 1

links <- read_html(paginas) %>% 
  html_nodes('a') %>% html_attr('href')

last_page <- str_extract(links[68], '\\d+')

paginas <- ''

p <- 1

for (i in 1:last_page){
  paginas[p] <- paste('https://www.vlr.gg/matches/results/?page=', p, sep = '')
  p = p + 1
}

c <- 1
matchs <- 'a'

funcaoPagina <- function(pagina){
  
  matchs <- read_html(pagina) %>% 
    html_nodes('a') %>% html_attr('href')
  
  matchs <- matchs[15:64]
  
  n <- 1
  
  for (i in matchs){
    matchs[n] <- paste('https://www.vlr.gg', matchs[n], sep = '')
    n = n + 1
    
  }
  
  return(matchs)
  
}

f <- 1
a <- list()

for (i in paginas){
  a[length(a)+1] = funcaoPagina(paginas[f])
  f = f + 1
  
}

a <- unlist(a)

write.csv2(a, 'csv/a.csv')

a <- read.csv2('csv/a.csv') %>% dplyr::select(-X)


catalogarporUrl <- function (string){
  tryCatch(
    
    {
      html_lido <- read_html(as.character(string))
      
      placar <- html_nodes(html_lido, "div.js-spoiler") %>% html_text(trim=T) %>% 
        str_replace_all(t_n)
      placar <- as.data.frame(placar[1]) 
      placar <- separate(placar, col = 1, into = c('Time1', 'Time2'), sep = ':', extra = 'merge')
      
      ifelse(placar$Time1 > placar$Time2, ganhador <- c(1,1,1,1,1,0,0,0,0,0), ganhador <- c(0,0,0,0,0,1,1,1,1,1))
      
      info <- html_nodes(html_lido, "table") %>%
        html_table()
      info <- rbind(info[[3]], info[[4]])
      
      colnames(info) <- c('jogador', 'time', 'R', 'ACS', 'K', 'D', 'A', '+/-', 'KAST', 'ADR', 'HS%', 'FK', 'FD', 'z')
      
      info <- select(info, 'jogador', 'R', 'ACS', 'K', 'D', 'KAST', 'ADR')
      
      info$R <- substr(info$R, 1, 4)
      info$ACS <- substr(info$ACS, 1, 3)
      info$K <- str_replace_all(info$K, t_n2)
      info$K <- substr(info$K, 1, 3)
      info$D <- str_replace_all(info$D, t_n2)
      info$D <- substr(info$D, 1, 3)
      info$KAST <- substr(info$KAST, 1, 3)
      info$ADR <- substr(info$ADR, 1, 3)
      
      info <- separate(info, 'jogador', into = c("Player", "Team"), sep = "\\s+", extra = "merge")
      
      info <- cbind(info, ganhador)
      
      return(info)
    }
    , error = function(e){cat('error:', conditionMessage(e), '\n')})
  
}



rm (c, f, i, p, matchs, paginas)

m <- 1

dff <- list()
valor <- list()

t_n <- c('\n' = '', '\t' = '')
t_n2 <- c('\t' = '', '\n' = ' ', '/  ' = '')

for (i in a[,]){
  start_time <- Sys.time()
  tryCatch({
    dff[[m]] <- catalogarporUrl(a[m,])
    valor[[m]] <- Sys.time() - start_time
    print(mean(as.numeric(valor)))
    m = m + 1
  }, error = function(e){cat('error:', conditionMessage(e), '\n')})
}

dff2 <- dff %>% map_df(as_tibble)

write.csv2(dff, 'csv/raw_historico.csv')
write.csv2(dff2, 'csv/historico.csv')

historico <- read.csv2('csv/historico.csv') %>% dplyr::select(-X)

historico <- na.omit(historico)

id <- 1:as.numeric(count(historico))

historico <- cbind(historico, id)

matriz_hist <- list()

z <- 1

while (z < count(historico)) {
  matriz_hist[[length(matriz_hist)+1]] <- historico[z:(z+9),]
  z = z + 10
}

partida <- 1

testes <- list()

testeF <- function(partida){
  time1Players <- matriz_hist[[partida]]$Player[1:5]
  time2Players <- matriz_hist[[partida]]$Player[6:10]
  time1Id <- matriz_hist[[partida]]$id[1:5]
  time2Id <- matriz_hist[[partida]]$id[6:10]
  time1 <- filter(historico, historico$Player==time1Players & historico$id > time1Id)
  time2 <- filter(historico, historico$Player==time2Players & historico$id > time2Id)
  time1R <- mean(as.numeric(time1$R))
  time2R <- mean(as.numeric(time2$R))
  time1ACS <- mean(time1$ACS)
  time2ACS <- mean(time2$ACS)
  time1KAST <- ifelse(is.character(time1$KAST), mean(parse_number(time1$KAST)), mean(time1$KAST))
  time2KAST <- ifelse(is.character(time2$KAST), mean(parse_number(time2$KAST)), mean(time2$KAST))
  time1$K <- str_replace_all(time1$K, ' ', '')
  time1$D <- str_replace_all(time1$D, ' ', '')
  time2$K <- str_replace_all(time2$K, ' ', '')
  time2$D <- str_replace_all(time2$D, ' ', '')
  time1KD <- mean(as.numeric(time1$K)/as.numeric(time1$D))
  time2KD <- mean(as.numeric(time2$K)/as.numeric(time2$D))
  time1ADR <- mean(time1$ADR)
  time2ADR <- mean(time2$ADR)
  ganhador <- ifelse(matriz_hist[[partida]]$ganhador[1] == 1, 1, 0)
  df <- cbind(time1R, time2R, time1ACS, time2ACS, time1KAST, time2KAST, time1KD, time2KD,
              time1ADR, time2ADR, ganhador)
  testes[[length(testes)+1]] <<- df
  return(testes)
  }

n <- 1

while(n < count(historico)){
  testeF(n)
  n = n + 1
}

totalidade_jogos <- testes

totalidade_jogos <- totalidade_jogos %>% map_df(as_tibble)

write.csv2(totalidade_jogos, 'csv/totalidade_jogos.csv')

totalidade_jogos <- read.csv2('csv/totalidade_jogos.csv') %>% dplyr::select(-X)

totalidade_jogos_sem_na <- totalidade_jogos[is.finite(rowSums(totalidade_jogos)),]

write.csv2(totalidade_jogos_sem_na, 'csv/totalidade_jogos_sem_na.csv')


# Testando acurácia 

load(file = "model_nnet.rda")

jogos <- read.csv2('csv/partidas.csv') %>% dplyr::select(-X, -ganhador)

outras_partidas <- read.csv2('csv/totalidade_jogos_sem_na.csv') %>% dplyr::select(-X, -ganhador)

jogos_scale <- rbind(jogos, outras_partidas)

jogos_scale <- scale(jogos_scale)

partidas <- jogos_scale[-1:-813,]

partidas <- as.data.frame(partidas)

previsao <- compute(n, partidas)

previsao <- previsao$net.result

partidas_reversas <- partidas

partidas_reversas$time1R <- partidas$time2R
partidas_reversas$time2R <- partidas$time1R
partidas_reversas$time1ACS <- partidas$time2ACS
partidas_reversas$time2ACS <- partidas$time1ACS
partidas_reversas$time1KAST <- partidas$time2KAST
partidas_reversas$time2KAST <- partidas$time1KAST
partidas_reversas$time1KD <- partidas$time2KD
partidas_reversas$time2KD <- partidas$time1KD
partidas_reversas$time1ADR <- partidas$time2ADR
partidas_reversas$time2ADR <- partidas$time1ADR

previsao2 <- compute(n, partidas_reversas)

previsao2 <- previsao2$net.result

previsoes <- cbind(previsao, previsao2)

transforma_positivo <- function (x){
  y = atan(x*10) + pi/2
  return (y)
}

transforma_probabilidade <- function (y, x){
  z = y / (y + x)
  w = x / (x + y)
  c = as.matrix(c(z,w))
  return(c)
}

a <- transforma_positivo(previsao)
b <- transforma_positivo(previsao2)
previsao <- transforma_probabilidade(a,b)
previsao <- previsao * 100
previsao2 <- previsao[(length(previsao)/2+1):length(previsao)]
previsao <- previsao[1:(length(previsao)/2)]
previsao <- cbind(previsao, previsao2)

ganhadores <- read.csv2('csv/totalidade_jogos_sem_na.csv') %>% dplyr::select(ganhador)

previsao <- cbind(previsao, ganhadores)
colnames(previsao) <- c('previsao1', 'previsao2', 'ganhador')

previsao <- previsao %>% 
  mutate(ganhador = as.factor(ganhador))

# Plot
ggplot(data = previsao, mapping = aes(x = previsao1, y = previsao2, colour = ganhador)) +
  geom_tile(aes(fill = ganhador)) +
  geom_point() +
  theme_bw()

resultado_previsto <- ifelse(previsao$previsao1>previsao$previsao2, 1, 0)

resultadovspredict <- cbind(partidas, resultado_previsto, ganhadores)

i <- sum(resultadovspredict$ganhador == resultadovspredict$resultado_previsto)/nrow(resultadovspredict)

# y <- round(i, 2)

# Acurácia total em 10284 partidas de 60%


# Preciso fazer um gráfico de estatisticas em função de vitória, ou seja, quais estatisticas tiveram mais impacto em vitorias

ggplot(data = resultadovspredict, mapping = aes(x = , y = previsao2, colour = ganhador)) +
  geom_tile(aes(fill = ganhador)) +
  geom_point() +
  theme_bw()



R <- ifelse(resultadovspredict$time1R > resultadovspredict$time2R, 1, 0)
ACS <- ifelse(resultadovspredict$time1ACS > resultadovspredict$time2ACS, 1, 0)
KAST <- ifelse(resultadovspredict$time1KAST > resultadovspredict$time2KAST, 1, 0)
KD <- ifelse(resultadovspredict$time1KD > resultadovspredict$time2KD, 1 , 0)
ADR <- ifelse(resultadovspredict$time1ADR > resultadovspredict$time2ADR, 1 , 0)
acertos_erros_R <- paste(R, resultadovspredict$resultado_previsto, resultadovspredict$ganhador)
acertos_erros_ACS <- paste(ACS, resultadovspredict$resultado_previsto, resultadovspredict$ganhador)
acertos_erros_KAST <- paste(KAST, resultadovspredict$resultado_previsto, resultadovspredict$ganhador)
acertos_erros_KD <- paste(KD, resultadovspredict$resultado_previsto, resultadovspredict$ganhador)
acertos_erros_ADR <- paste(ADR, resultadovspredict$resultado_previsto, resultadovspredict$ganhador)

grafico_data <- as.data.frame(cbind(acertos_erros_R, acertos_erros_ACS, acertos_erros_KAST, acertos_erros_KD,
                                    acertos_erros_ADR))

grafico_data$acertos_erros_R <- factor(grafico_data$acertos_erros_R,
                                       levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                  '0 1 0', '1 0 0'))
                                       # labels = c('Acertou', 'Acertou', 'Errou', 'Errou', 'Errou', 'Acertou',
                                       #            'Errou', 'Acertou'))


grafico_data$acertos_erros_ACS <- factor(grafico_data$acertos_erros_ACS,
                                         levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                    '0 1 0', '1 0 0'))

grafico_data$acertos_erros_KAST <- factor(grafico_data$acertos_erros_KAST,
                                         levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                    '0 1 0', '1 0 0'))

grafico_data$acertos_erros_KD <- factor(grafico_data$acertos_erros_KD,
                                         levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                    '0 1 0', '1 0 0'))

grafico_data$acertos_erros_ADR <- factor(grafico_data$acertos_erros_ADR,
                                         levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                    '0 1 0', '1 0 0'))

grafico_data$acertos_erros_R <- fct_rev(grafico_data$acertos_erros_R)
grafico_data$acertos_erros_ACS <- fct_rev(grafico_data$acertos_erros_ACS)
grafico_data$acertos_erros_KAST <- fct_rev(grafico_data$acertos_erros_KAST)
grafico_data$acertos_erros_KD <- fct_rev(grafico_data$acertos_erros_KD)
grafico_data$acertos_erros_ADR <- fct_rev(grafico_data$acertos_erros_ADR)

# Plot R
ggplot(grafico_data, aes(y = acertos_erros_R)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o Rating do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()


# Plot ACS
ggplot(grafico_data, aes(y = acertos_erros_ACS)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o ACS do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()

# Plot KAST
ggplot(grafico_data, aes(y = acertos_erros_KAST)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o KAST do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()

# Plot KD
ggplot(grafico_data, aes(y = acertos_erros_KD)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o KD do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()

# Plot ADR
ggplot(grafico_data, aes(y = acertos_erros_ADR)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o ADR do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()

# Tentando totalizar os erros e acertos de forma mais contundente

grafico_data$acertos_erros_R <- factor(grafico_data$acertos_erros_R,
                                       levels = c('1 1 1', '0 0 0', '0 0 1', '1 1 0', '1 0 1', '0 1 1',
                                                  '0 1 0', '1 0 0'),
                                       labels = c('Acertou e era maior', 'Acertou e era menor', 'Errou e era menor',
                                                  'Errou e era maior', 'Errou e era maior', 'Acertou e era menor',
                                                  'Errou e era menor', 'Acertou e era maior'))

# Plot R
ggplot(grafico_data, aes(y = acertos_erros_R)) +
  geom_bar(color = 'black', fill = "mediumseagreen") +
  geom_text(aes(label = paste0("(",round(..count..*100/nrow(grafico_data)), "%)")),
            stat = "count", vjust = 2.1, hjust = 1.3, colour = "black") +
  geom_label(aes(y = acertos_erros_R, label = ..count..),
             stat = 'count', hjust = 1.3) +
  labs(title = 'Relação de acertos com o Rating do time 1 ser maior',
       y = 'Tipos de cenário',
       x = 'Quantidade de ocorrências',
       caption = 'Partidas analisadas: 10284') +
  theme_light()

# Anotações: 61% de importancia Rating
# 
# 60% de importancia de ACS
# 
# 62% de importancia de KAST
# 
# 62% de importancia de KD
# 
# 58% de importancia de ADR


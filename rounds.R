# Carregando pacotes --------------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(lubridate)

# Urls ----------------------------------------------------------------------------------------------------
url <- "https://www.vlr.gg/team/stats/6961/loud/"

# Pegando os dados dos times no url e transformando em dataframe ------------------------------------------
ds_time <- read_html(url) %>% 
  html_node('table') %>% 
  html_table

# Renomeando as colunas 9 e 10 para tirar a ambiguidade que havia no dataframe que veio do site -----------
names(ds_time)[9] <- 'RW ATK'
names(ds_time)[10] <- 'RL ATK'

# Removendo duas colunas que não serão usadas -------------------------------------------------------------
ds_time <- select(ds_time, -Expand) %>% 
  select( -'Agent Compositions')

# Tirando todos os caracteres '\n e \t' do dataframe com a função lapply ----------------------------------
ds_time[-1] <- lapply(ds_time[-1], str_replace_all, "\n", ' ') %>% 
  lapply(str_replace_all, '\t', ' ') %>% 
  lapply(str_replace_all, '  ', '') 

# Retirando as linhas que contem 1 ou mais caracterer na coluna Map ---------------------------------------
ds_time <- subset(ds_time, nchar(gsub("[^a-z]", "", ds_time$`Map (#)`)) < 1)

# Separando os conteúdos das linhas em duas novas colunas de Data e Resultado -----------------------------
ds_time[c('Data', 'Resultado')] <- str_split_fixed(
  ds_time$`WIN%`, ' ', 2)

# Selecionando apenas Data e Resultado para o nosso dataframe ---------------------------------------------
ds_time <- select(ds_time, 'Data', 'Resultado')

# Passando os dados da coluna Data para o formato de data -------------------------------------------------
ds_time$Data <- as_date(ds_time$Data)

# Limpando os dados para deixar apenas os resultados------------------------------------------------------
ds_time$Resultado <- gsub("[^0-9/ .-]", "", ds_time$Resultado)# Deixando apenas números e "/"
#
ds_time$Resultado <- substr(ds_time$Resultado,
                            gregexpr("/", ds_time$Resultado)[[1]][1] - 3,
                            gregexpr("/", ds_time$Resultado)[[3]][1] + 3) # Tirando dados que estão longes das barras ("/")

ds_time <- separate(ds_time, Resultado, c("RW", "RL"), "/") # Transformando a coluna Resultado em RW e RL

ds_time$RL <- sub(" .*", "", ds_time$RL) # Tirando todos os caracteres que estavam à direita
ds_time$RW <- sub("*. ", "", ds_time$RW) # Tirando todos os caracteres que estavam à esquerda

ds_time$RW <- sub(" ", "", ds_time$RW) # Tirando todos os espaços
ds_time$RL <- sub(" ", "", ds_time$RL) # Tirando todos os espaços

ds_time$Resultados <- as.numeric(ds_time$RW) > as.numeric(ds_time$RL) # Criando uma coluna de resultados

ds_time$Resultados <- replace(ds_time$Resultados, ds_time$Resultados == TRUE, 'Win') %>% 
  replace(ds_time$Resultados == FALSE, 'Lose') # Renomeando TRUE para 'Win' e FALSE para 'Lose'

RW <- sum(as.numeric(ds_time$RW)) # rwins = rounds wins (rounds vitoriosos)
RL <- sum(as.numeric(ds_time$RL)) # rls = rounds loses (rounds perdidos)
Resultados <- RW - RL # saldo = rounds wins - rounds loses

rounds <- data.frame(RW, RL, Resultados) # passando para um dataframe

ds_time <- select(ds_time, -Data)

rounds$RW <- as.character(rounds$RW)
rounds$RL <- as.character(rounds$RL)
rounds$Resultados <- as.character(rounds$Resultados)

ds_time <- rbind(ds_time, rounds)



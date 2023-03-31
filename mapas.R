# Carregando pacotes --------------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)


## Urls dos dois times ------------------------------------------------------------------------------------
url_time1 <- "https://www.vlr.gg/team/stats/6961/loud/"
url_time2 <- "https://www.vlr.gg/team/stats/8127/optic-gaming/"


# Pegando os dados dos times no url e transformando em dataframe ------------------------------------------
# Time 1
ds_time1 <- read_html(url_time1) %>% 
  html_node("table") %>% 
  html_table

# Time 2
ds_time2 <- read_html(url_time2) %>% 
  html_node("table") %>% 
  html_table


# Renomeando as colunas 9 e 10 ----------------------------------------------------------------------------
# Time 1
names(ds_time1)[9] <- 'RW ATK'
names(ds_time1)[10] <- 'RL ATK'

# Time 2
names(ds_time2)[9] <- 'RW ATK'
names(ds_time2)[10] <- 'RL ATK'

# Removendo duas colunas que não serão usadas -------------------------------------------------------------
# Time 1
ds_time1 <- select(ds_time1, -Expand) %>% 
  select( -'Agent Compositions')

# Time 2
ds_time2 <- select(ds_time2, -Expand) %>% 
  select( -'Agent Compositions')

# Tirando todos os caracteres '\n e \t' do dataframe com a função lapply ----------------------------------
# Time 1
ds_time1[-1] <- lapply(ds_time1[-1], str_replace_all, "\n", ' ') %>% 
  lapply(str_replace_all, '\t', ' ') %>% 
  lapply(str_replace_all, '  ', '') 

# Time 2
ds_time2[-1] <- lapply(ds_time2[-1], str_replace_all, "\n", ' ') %>% 
  lapply(str_replace_all, ' ', '')

# Deixando apenas as linhas que tenha 1 ou mais caracteres na coluna Map ----------------------------------
ds_time1 <- subset(ds_time1, nchar(gsub("[^a-z]", "", ds_time1$`Map (#)`)) > 0)
ds_time2 <- subset(ds_time2, nchar(gsub("[^a-z]", "", ds_time2$`Map (#)`)) > 0)


# Comparando os dois times em todos os mapas e retornando um dataframe com esse feedback ------------------
ds_times <- ds_time1
ds_times$vantagem <- ifelse(ds_time1$`WIN%` > ds_time2$`WIN%`, 'Time1',
                            ifelse(ds_time1$`WIN%` < ds_time2$`WIN%`, 'Time2', 'Empate')) 
ds_times <- select(ds_times, `Map (#)`, `vantagem`)




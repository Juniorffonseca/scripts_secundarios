#Instalando pacotes (se necessário)
library(devtools)
install_github("Juniorffonseca/r-pacote-valorant")

# Carregando pacotes --------------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(neuralnet)
library(reshape2)
library(readr)
library(purrr)
library(valorant)

load(file = "rede_neural_teste.rda")

prever(link)

return <- prever(
  'https://www.vlr.gg/130685/loud-vs-optic-gaming-valorant-champions-2022-gf'
)


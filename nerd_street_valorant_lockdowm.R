# Carregando pacotes ---------------------------------------------------------------------------------------
library(tidyverse)
library(FactoMineR)
library(factoextra)
library(cluster)
library(xlsx)
library(ineq)
library(stringr)
library(dplyr)

# Carregando a base de dados de jogadores ---------------------------------------------------------------
dados_gerais <- read.csv2('jogadores_all.csv')

# Arrumando as colunas ----------------------------------------------------------------------------------
dados_gerais <- select(dados_gerais, -X, -Team)
row.names(dados_gerais) <- make.names(dados_gerais[,1], unique = T)
dados_gerais <- select(dados_gerais, -Player)
dados_gerais <- na.omit(dados_gerais)

# Definindo times especificos ---------------------------------------------------------------------------
#BASILISK
bsk = c('ohai', 'Jangler', 'Lin', 'kev', 'royal') # Definindo o time 1
bsk <- paste0('\\b', bsk, '\\b') # Colocando '\\b' antes e dps p pegar apenas as strings exatas
dados_gerais$bsk <- ifelse(grepl(paste(bsk, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#Shopify Rebellion GC
sr = c('KP', 'bENITA', 'flowerful', 'sonder', 'Lorri')
sr <- paste0('\\b', sr, '\\b') 
dados_gerais$sr <- ifelse(grepl(paste(sr, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#Guild X
gldx = c('aNNja', 'cinnamon', 'Smurfette', 'roxi', 'ness')
gldx <- paste0('\\b', gldx, '\\b')
dados_gerais$gldx <- ifelse(grepl(paste(gldx, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#G2 Gozen
g2 = c('Glance', 'Petra', 'mimi', 'juliano', 'Mary')
g2 <- paste0('\\b', g2, '\\b')
dados_gerais$g2 <- ifelse(grepl(paste(g2, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#Team Liquid Brazil
tl = c('drn', 'naxy', 'bstrdd', 'daiki', 'nat1')
tl <- paste0('\\b', tl, '\\b')
dados_gerais$tl <- ifelse(grepl(paste(tl, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#KRÜ Fem
kru = c('consu', 'baesht', 'conir', 'kalita', 'romi')
kru <- paste0('\\b', kru, '\\b')
dados_gerais$kru <- ifelse(grepl(paste(kru, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

#X10 Sapphire
x10 = c('JinNy', 'Muffyn', 'Babytz', 'Poly', 'alyssa')
x10 <- paste0('\\b', x10, '\\b')
dados_gerais$x10 <- ifelse(grepl(paste(x10, collapse = '|'), rownames(dados_gerais), useBytes = T), 1 ,0)

#FENNEL GC
flgc = c('suzu', 'KOHAL', 'Festival', 'Len', 'Curumi')
flgc <- paste0('\\b', flgc, '\\b')
dados_gerais$flgc <- ifelse(grepl(paste(flgc, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)

resultado <- filter(dados_gerais, dados_gerais$c9w == 1 | dados_gerais$sr == 1 | dados_gerais$gldx == 1
                    | dados_gerais$g2 == 1 | dados_gerais$tl == 1 | dados_gerais$kru == 1 | 
                      dados_gerais$x10 == 1 | dados_gerais$flgc == 1)

# Removendo uma jogadora que tem o mesmo de outra
while (nrow(resultado) > 40) {
  resultado <- resultado[-41,]
  }

# Calculando IDC (variancia de KAST entre os jogadores de cada time)
c9w_df <- filter(resultado, resultado$c9w == 1)
sr_df <- filter(resultado, resultado$sr == 1)
gldx_df <- filter(resultado, resultado$gldx == 1)
g2_df <- filter(resultado, resultado$g2 == 1)
tl_df <- filter(resultado, resultado$tl == 1)
kru_df <- filter(resultado, resultado$kru == 1)
x10_df <- filter(resultado, resultado$x10 == 1)
flgc_df <- filter(resultado, resultado$flgc == 1)
idc_t1 <- ineq(c9w_df$KAST, type = 'Gini')
idc_t2 <- ineq(sr_df$KAST, type = 'Gini')
idc_t3 <- ineq(gldx_df$KAST, type = 'Gini')
idc_t4 <- ineq(g2_df$KAST, type = 'Gini')
idc_t5 <- ineq(tl_df$KAST, type = 'Gini')
idc_t6 <- ineq(kru_df$KAST, type = 'Gini')
idc_t7 <- ineq(x10_df$KAST, type = 'Gini')
idc_t8 <- ineq(flgc_df$KAST, type = 'Gini')


# Colocando o indice de Gini em cada jogador para seu respectivo time
c9w_df$idc <- idc_t1
sr_df$idc <- idc_t2
gldx_df$idc <- idc_t3
g2_df$idc <- idc_t4
tl_df$idc <- idc_t5
kru_df$idc <- idc_t6
x10_df$idc <- idc_t7
flgc_df$idc <- idc_t8

# Removendo as variaveis idc_tn e times
rm(idc_t1, idc_t2, idc_t3, idc_t4, idc_t5, idc_t6, idc_t7, idc_t8)
rm(c9w, sr, gldx, g2, tl, kru, x10, flgc)

# Colocando os indices de gini no dataframe 'resultado'
resultado <- cbind(c9w_df, sr_df, gldx_df, g2_df, tl_df, kru_df, x10_df, flgc_df)
resultado <- merge(c9w_df, sr_df, all = T) %>%  
  merge(gldx_df, all = T) %>%  
  merge(g2_df, all = T) %>% 
  merge(tl_df, all = T) %>% 
  merge(kru_df, all = T) %>% 
  merge(x10_df, all = T) %>% 
  merge(flgc_df, all = T)

# Tirando colunas de times dos dataframes especificos de cada time
c9w_df <- c9w_df[,-7:-14]
flgc_df <- flgc_df[,-7:-14]
g2_df <- g2_df[,-7:-14]
gldx_df <- gldx_df[,-7:-14]
kru_df <- kru_df[,-7:-14]
sr_df <- sr_df[,-7:-14]
tl_df <- tl_df[,-7:-14]
x10_df <- x10_df[,-7:-14]

# Tentando mesclar dataframe ds_adversarios com outras estatisticas ------------------------------------------------
ds_adversarios_g2 <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_g2.csv",
                                sep = ',') %>% select(-X)
ds_adversarios_sr <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_sr.csv",
                               sep = ',') %>% select(-X)
ds_adversarios_c9w <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_c9w.csv",
                               sep = ',') %>% select(-X)
ds_adversarios_x10 <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_x10.csv",
                                sep = ',') %>% select(-X)
ds_adversarios_tl <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_tl.csv",
                              sep = ',') %>% select(-X)
ds_adversarios_kru <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_kru.csv",
                              sep = ',') %>% select(-X)
ds_adversarios_gldx <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_gldx.csv",
                                sep = ',') %>% select(-X)
ds_adversarios_flgc <- read.csv("C:/Users/anonb/Documents/TCC Pós/Scripts/scripts_times_gc/ds_adversarios_flgc.csv",
                               sep = ',') %>% select(-X)

# Ao fim de cada formula abaixo eu desconsiderei (subtraindo) o número de rounds ganhos ou perdidos nesse campeonato
#g2
g2_x10 <- sum(ds_adversarios_g2$Adversario == 'X10 Sapphire' & ds_adversarios_g2$Resultados == 'Win') - 
  sum(ds_adversarios_g2$Adversario == 'X10 Sapphire' & ds_adversarios_g2$Resultados == 'Lose') - 2 

g2_c9w <- sum(ds_adversarios_g2$Adversario == 'Cloud9 White' & ds_adversarios_g2$Resultados == 'Win') - 
  sum(ds_adversarios_g2$Adversario == 'Cloud9 White' & ds_adversarios_g2$Resultados == 'Lose') - 1

#sr
sr_gldx <- sum(ds_adversarios_sr$Adversario == 'Guild X' & ds_adversarios_sr$Resultados == 'Win') -
  sum(ds_adversarios_sr$Adversario == 'Guild X' & ds_adversarios_sr$Resultados == 'Lose') - 1

sr_tl <- sum(ds_adversarios_sr$Adversario == 'Team Liquid Brazil' & ds_adversarios_sr$Resultados == 'Win') -
  sum(ds_adversarios_sr$Adversario == 'Team Liquid Brazil' & ds_adversarios_sr$Resultados == 'Lose') - 1

sr_x10 <- sum(ds_adversarios_sr$Adversario == 'X10 Sapphire' & ds_adversarios_sr$Resultados == 'Win') -
  sum(ds_adversarios_sr$Adversario == 'X10 Sapphire' & ds_adversarios_sr$Resultados == 'Lose') - 2

sr_c9w <- sum(ds_adversarios_sr$Adversario == 'Cloud9 White' & ds_adversarios_sr$Resultados == 'Win') -
  sum(ds_adversarios_sr$Adversario == 'Cloud9 White' & ds_adversarios_sr$Resultados == 'Lose') - 1

sr_g2 <- sum(ds_adversarios_sr$Adversario == 'G2 Gozen' & ds_adversarios_sr$Resultados == 'Win') - 
  sum(ds_adversarios_sr$Adversario == 'G2 Gozen' & ds_adversarios_sr == 'Lose') + 1

#kru
kru_c9w <- sum(ds_adversarios_kru$Adversario == 'Cloud9 White' & ds_adversarios_kru$Resultados == 'Win') -
  sum(ds_adversarios_kru$Adversario == 'Cloud9 White' & ds_adversarios_kru$Resultados == 'Lose') + 2

kru_x10 <- sum(ds_adversarios_kru$Adversario == 'X10 Sapphire' & ds_adversarios_kru$Resultados == 'Win') - 
  sum(ds_adversarios_kru$Adversario == 'X10 Sapphire' & ds_adversarios_kru$Resultados == 'Lose') + 1

#gldx
gldx_flgc <- sum(ds_adversarios_gldx$Adversario == 'FENNEL GC' & ds_adversarios_gldx$Resultados == 'Win') -
  sum(ds_adversarios_gldx$Adversario == 'FENNEL GC' & ds_adversarios_gldx$Resultados == 'Lose') - 2

gldx_c9w <- sum(ds_adversarios_gldx$Adversario == 'Cloud9 White' & ds_adversarios_gldx$Resultados == 'Win') -
  sum(ds_adversarios_gldx$Adversario == 'Cloud9 White' & ds_adversarios_gldx$Resultados == 'Lose') + 2

#Team Liquid
tl_g2 <- sum(ds_adversarios_tl$Adversario == 'G2 Gozen' & ds_adversarios_tl$Resultados == 'Win') -
  sum(ds_adversarios_tl$Adversario == 'G2 Gozen' & ds_adversarios_tl$Resultados == 'Lose') + 2

tl_flgc <- sum(ds_adversarios_tl$Adversario == 'FENNEL GC' & ds_adversarios_tl$Resultados == 'Win') -
  sum(ds_adversarios_tl$Adversario == 'FENNEL GC' & ds_adversarios_tl$Resultados == 'Lose') - 1


# Criando uma formula para dizer a porcentagem de chance de vitória do time 1 sobre o time 2 ----------------------
jogo1 <- (mean(c9w_df$R) + kru_c9w * 0.01) / ((mean(c9w_df$R) + kru_c9w * 0.01) +
                                                (mean(kru_df$R) + (-kru_c9w * 0.01)))

jogo2 <- (mean(g2_df$R) + -g2_x10 * 0.01) / ((mean(g2_df$R) + -g2_x10 * 0.01) +
                                               mean(x10_df$R) + (g2_x10 * 0.01))

jogo3 <- (mean(gldx_df$R) + sr_gldx * 0.01) / ((mean(gldx_df$R) + sr_gldx * 0.01) + 
                                                 mean(sr_df$R) + -sr_gldx * 0.01)

jogo4 <- (mean(flgc_df$R) + -tl_flgc * 0.01) / ((mean(flgc_df$R) + -tl_flgc * 0.01) +
                                                  mean(tl_df$R) + tl_flgc * 0.01)

jogo5 <- (mean(kru_df$R) + kru_c9w * 0.01) / ((mean(kru_df$R) + kru_c9w * 0.01) + 
                                                mean(c9w_df$R) + -kru_c9w * 0.01)

jogo6 <- (mean(gldx_df$R) + gldx_flgc * 0.01) / ((mean(gldx_df$R) + gldx_flgc * 0.01) +
                                                   mean(flgc_df$R) + -gldx_flgc * 0.01)

jogo7 <- (mean(c9w_df$R) + -g2_c9w * 0.01) / ((mean(c9w_df$R) + -g2_c9w * 0.01) + 
                                                mean(g2_df$R) + g2_c9w * 0.01)

jogo8 <- (mean(sr_df$R) + sr_tl * 0.01) / ((mean(sr_df$R) + sr_tl * 0.01) + 
                                             mean(tl_df$R) + -sr_tl * 0.01)

jogo9 <- (mean(sr_df$R) + sr_x10 * 0.01) / ((mean(sr_df$R) + sr_x10 * 0.01) + 
                                              mean(x10_df$R) + -sr_x10 * 0.01)

jogo10 <- (mean(c9w_df$R) + -gldx_c9w * 0.01) / ((mean(c9w_df$R) + -gldx_c9w * 0.01) + 
                                                   mean(gldx_df$R) + gldx_c9w * 0.01)

jogo11 <- (mean(g2_df$R) + -tl_g2 * 0.01) / ((mean(g2_df$R) + -tl_g2 * 0.01) +
                                               mean(tl_df$R) + tl_g2 * 0.01)

jogo12 <- (mean(sr_df$R) + sr_c9w * 0.01) / ((mean(sr_df$R) + sr_c9w * 0.01) +
                                               mean(c9w_df$R) + -sr_c9w * 0.01)

jogo13 <- (mean(g2_df$R) + -sr_g2 * 0.01) / ((mean(g2_df$R) + -sr_g2 * 0.01) +
                                               mean(sr_df$R) + sr_g2 * 0.01)

jogo14 <- (mean(tl_df$R) + -sr_tl * 0.01) / ((mean(tl_df$R) + -sr_tl * 0.01) + 
                                               mean(sr_df$R) + sr_tl * 0.01)

acertos = 0

analisa_resultados = function(jogo1, jogo2, jogo3, jogo4, jogo5, jogo6, jogo7, jogo8, jogo9, jogo10, jogo11, jogo12,
                              jogo13, jogo14){
  if(jogo1 > 0.50){
    acertos = acertos + 1
  }
  if(jogo2 > 0.50){
    acertos = acertos + 1
  }
  if(jogo3 < 0.50){
    acertos = acertos + 1
  }
  if(jogo4 < 0.50){
    acertos = acertos + 1
  }
  if(jogo5 < 0.50){
    acertos = acertos + 1
  }
  if(jogo6 > 0.50){
    acertos = acertos + 1
  }
  if(jogo7 < 0.50){
    acertos = acertos + 1
  }
  if(jogo8 < 0.50){
    acertos = acertos + 1
  }
  if(jogo9 > 0.50){
    acertos = acertos + 1
  }
  if(jogo10 > 0.50){
    acertos = acertos + 1
  }
  if(jogo11 > 0.50){
    acertos = acertos + 1
  }
  if(jogo12 > 0.50){
    acertos = acertos + 1
  }
  if(jogo13 > 0.50){
    acertos = acertos + 1
  }
  if(jogo14 < 0.50){
    acertos = acertos + 1
  }
  return(acertos/14)
}


analisa_resultados(jogo1, jogo2, jogo3, jogo4, jogo5, jogo6, jogo7, jogo8, jogo9, jogo10, jogo11,
                   jogo12, jogo13, jogo14)

# Primeiro teste: 64.28571% de acuracia
  


hist <- c(jogo1, jogo2, jogo3, jogo4, jogo5, jogo6, jogo7, jogo8, jogo9, jogo10, jogo11, jogo12, jogo13, jogo14)

hist(hist, breaks = 10)

# Carregando pacotes --------------------------------------------------------------------------------------
if(!require(pacman)) install.packages('pacman') library(pacman)
pacman::p_load(dplyr, psych, car, MASS, DescTools, QuantPsyc, ggplot2)

# Carregando o banco de dados -----------------------------------------------------------------------------
dados <- read.csv2('players.csv', stringsAsFactors = T, sep = ',')
dados2 <- read.csv2('ds_adversarios.csv', stringsAsFactors = T, sep = ',')


# Construindo o modelo ------------------------------------------------------------------------------------
mod <- glm(ganhador ~ time1 + time2,
           family = binomial(link = 'logit'), data = jogos)

plot(mod, which = 5)

summary(stdres(mod))


pairs.panels(jogos)


# Carregando pacotes ---------------------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(rvest)
library(quantmod)
library(httr)
library(tibble)
library(stringr)
library(lubridate)

# Times participantes:
# Americas League:
sentinels <- "https://www.vlr.gg/team/stats/2/sentinels/"
thieves_100 <- "https://www.vlr.gg/team/stats/120/100-thieves/"
cloud_9 <- "https://www.vlr.gg/team/stats/188/cloud9/"
nrg_esports <- "https://www.vlr.gg/team/stats/1034/nrg-esports/"
evil_geniuses <- "https://www.vlr.gg/team/stats/5248/evil-geniuses/"
furia <- "https://www.vlr.gg/team/2406/furia"
loud <- "https://www.vlr.gg/team/stats/6961/loud/"
mibr <- "https://www.vlr.gg/team/stats/7386/mibr/"
kru <- "https://www.vlr.gg/team/stats/2355/kr-esports/"
leviatan <- "https://www.vlr.gg/team/stats/2359/leviat-n/"
# EMEA League:
fnatic <- "https://www.vlr.gg/team/stats/2593/fnatic/"
team_liquid <- "https://www.vlr.gg/team/stats/474/team-liquid/"
team_vitality <- "https://www.vlr.gg/team/stats/2059/team-vitality/"
karmine_corp <- "https://www.vlr.gg/team/stats/8877/karmine-corp/"
team_heretics <- "https://www.vlr.gg/team/stats/1001/team-heretics/"
giants_gaming <- "https://www.vlr.gg/team/stats/2304/giants-gaming/"
natus_vincere <- "https://www.vlr.gg/team/stats/4915/natus-vincere/"
fut_esports <- "https://www.vlr.gg/team/stats/1184/fut-esports/"
bbl_esports <- "https://www.vlr.gg/team/stats/397/bbl-esports/"
koi <- "https://www.vlr.gg/team/stats/7035/koi/"
# Pacific League:
zeta_division <- "https://www.vlr.gg/team/stats/5448/zeta-division/"
detonation_gaming <- "https://www.vlr.gg/team/stats/278/detonation-gaming/"
gen_g <- "https://www.vlr.gg/team/stats/17/gen-g/"
t1 <- "https://www.vlr.gg/team/stats/14/t1/"
drx <- "https://www.vlr.gg/team/stats/8185/drx/"
team_secret <- "https://www.vlr.gg/team/stats/6199/team-secret/"
paper_rex <- "https://www.vlr.gg/team/stats/624/paper-rex/"
rex_regum_qeon <- "https://www.vlr.gg/team/stats/878/rex-regum-qeon/"
talon_esports <- "https://www.vlr.gg/team/stats/8304/talon-esports/"
global_esports <- "https://www.vlr.gg/team/stats/918/global-esports/"








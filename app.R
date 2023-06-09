# Carregamento de pacotes, dataframes, rede neural e sources
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

load(file = "model_nnet.rda")

# Define UI
ui <- fluidPage(theme = shinytheme("cyborg"),
                navbarPage(
                  "Valorant Prediction",
                  tabPanel("Prediction",
                           sidebarPanel(
                             tags$h3("Analisar partidas"),
                             textInput("texturl", "url da partida:", ""),
                             actionButton('submitbutton', 'Prever', 
                                          class = 'btn btn-primary')
                             
                             
                           ),
                           mainPanel(
                             h1("Resultado"),
                             
                             h4("Probabilidade de vitória de cada Time"),
                             verbatimTextOutput("txtout"),
                             
                           )
                           
                  ),
                  tabPanel("Navbar 2", "Em breve mais funções"),
                  tabPanel("Navbar 3", "Em breve mais funções")
                  
                )
)



# Define server function  
server <- function(input, output) {
  
  previsaoInput <- reactive({
    
    dados_gerais <- read.csv2('csv/jogadores.csv')
    
    # Arrumando as colunas -------------------------------------------------------------------------------------
    dados_gerais <- dplyr::select(dados_gerais, Player, R, ACS, K.D, KAST, ADR)
    row.names(dados_gerais) <- make.names(dados_gerais[,1], unique = T)
    dados_gerais <- dplyr::select(dados_gerais, -Player)
    dados_gerais$KAST <- parse_number(dados_gerais$KAST)
    
    # Link da partida ------------------------------------------------------------------------------------------
    value = as.character(input$texturl) 
    
    # Pegando os dados no link da partida ----------------------------------------------------------------------
    info <- read_html(value) %>% 
      html_nodes("table") %>% 
      html_table()
    
    timeA <- info[[1]]
    timeB <- info[[2]]
    
    timeA <- lapply(timeA, str_replace_all, '\n', '') %>% 
      lapply(str_replace_all, '\t', '')
    timeB <- lapply(timeB, str_replace_all, '\n', '') %>% 
      lapply(str_replace_all, '\t', '')
    
    timeA <- as.data.frame(timeA[1])
    timeB <- as.data.frame(timeB[1])
    
    colnames(timeA) <- '1'
    colnames(timeB) <- '1'
    
    timeA <- separate(timeA, '1', into = c("Player", "Team"), sep = "\\s+", extra = "merge")
    timeB <- separate(timeB, '1', into = c("Player", "Team"), sep ="\\s+", extra = "merge")
    
    timeA <- timeA$Player
    timeB <- timeB$Player
    
    # Time A
    #timeA = c('nome1', 'nome2', 'nome3', 'nome4', 'nome5') # se preferir passar de forma manual
    timeA <- paste0('\\b', timeA, '\\b') 
    dados_gerais$timeA <- ifelse(grepl(paste(timeA, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)
    dados_gerais['nobody.1',]$timeA <- 0
    dados_gerais['Laz.1',]$timeA <- 0 
    
    # Time B
    #timeB = c('nome1', 'nome2', 'nome3', 'nome4', 'nome5') # se preferir passar de forma manual
    timeB <- paste0('\\b', timeB, '\\b') 
    dados_gerais$timeB <- ifelse(grepl(paste(timeB, collapse = '|'), rownames(dados_gerais), useBytes = T), 1, 0)
    dados_gerais['Shiro.1',]$timeB<- 0
    
    timeA_df <- filter(dados_gerais, dados_gerais$timeA == 1)
    timeA_df <- dplyr::select(timeA_df, R, ACS, K.D, KAST, ADR)
    timeB_df <- filter(dados_gerais, dados_gerais$timeB == 1) 
    timeB_df <- dplyr::select(timeB_df, R, ACS, K.D, KAST, ADR)
    
    if(nrow(timeA_df) == 5 && nrow(timeB_df) == 5){
      
      # Médias
      timeA_R <- mean(timeA_df$R)
      timeA_ACS <- mean(timeA_df$ACS)
      timeA_KAST <- mean(timeA_df$KAST)
      timeA_KD <- mean(timeA_df$K.D)
      timeA_ADR <- mean(timeA_df$ADR)
      timeB_R <- mean(timeB_df$R)
      timeB_ACS <- mean(timeB_df$ACS)
      timeB_KAST <- mean(timeB_df$KAST)
      timeB_KD <- mean(timeB_df$K.D)
      timeB_ADR <- mean(timeB_df$ADR)
      
      partida <- c(timeA_R, timeB_R, timeA_ACS, timeB_ACS, timeA_KAST, timeB_KAST, timeA_KD, timeB_KD,
                   timeA_ADR, timeB_ADR)
      
      jogos_scale <- read.csv2('csv/jogos.csv') %>% select(-X, -ganhador)
      
      jogos_scale <- rbind(jogos_scale, partida)
      
      jogos_scale <- scale(jogos_scale)
      
      partida <- jogos_scale[141,]
      
      partida <- t(partida)
      
      partida <- as.data.frame(partida)
      
      colnames(partida) <- c('time1R', 'time2R', 'time1ACS', 'time2ACS', 'time1KAST', 'time2KAST', 'time1KD', 'time2KD',
                             'time1ADR', 'time2ADR')
      
      previsao <- compute(n, partida)
      
      previsao$net.result
      
      previsao <- previsao$net.result
      
      a <- previsao[1]
      b <- previsao[2]
      
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
      
    }
    else{
      return('Não foi possível fazer a análise, provavelmente dados de um ou mais jogadores estavam faltantes no site vlr')
    }
  })
  
  #    output$txtout <- renderText(
  #     if (input$texturl!= NULL){round(previsaoInput(), digits = 2)})
  
  output$txtout <- renderText({
    if (input$submitbutton>0) { 
      paste(round(previsaoInput(), 2), '%', '')
      
    } else {
      return("A rede neural está pronta para calcular as probabilidades.")
    }
  })
  
} # server


# Create Shiny object
shinyApp(ui = ui, server = server)


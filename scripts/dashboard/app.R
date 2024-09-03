library(tidyverse)
library(dplyr)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(ggvenn)
library(bsplus)           # https://stackoverflow.com/questions/76799976/how-to-make-accordion-type-side-bar-layout-in-shiny
library(conflicted)
library(bslib)



conflicts_prefer(dplyr::filter)
conflicts_prefer(shinydashboard::box)


# ####------------------- Pool data from database -------------------#####

publications <- read_csv("dim_publication_summary.csv")

# Get categories for filter
categories <- publications %>% 
  pull(keyterm_category)

categories <- c(as.character(unique(categories)))


ui <-fluidPage(
  
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly"),
  
  #titlePanel("PMDD literature in Pubmed"),
  
  navbarPage("PMDD literature in Pubmed",
             nav_spacer(),
             nav_item(
               tags$li(tags$a(href="https://github.com/aramos8/pmdd_pubmed/tree/main/scripts/dashboard", icon("github"), target ="_blank"))
             )),
p(),  
p("by Ana Ramos",
tags$a(href="mailto:anaramos.data@gmail.com", icon("envelope"), target ="_blank"),
tags$a(href="https://www.linkedin.com/in/ramos-ana/", icon("linkedin"), target ="_blank"),
tags$a(href="https://github.com/aramos8", icon("github"), target ="_blank")),

p(em("Last updated on", Sys.Date())),

p("
    
    
    "),

card(tabsetPanel(
  tabPanel("Goal",
           p("The dashboard shows the most recent publications obtained from Pubmed, and it enables filtering of the search by three main 
    categories:", strong("Drug Therapy"), ",", strong("Non-Drug Therapy"),", and", strong("Symptoms"),". The goal of this dashboard is to help those affected by PMDD find scientific 
    literature discussing symptoms and potential treatment options so that they can discuss these resources with their health care providers."),
           
           p("Suggested uses for this dashboard include:", 
             tags$li("You or a loved one have just been diagnosed and want to learn more about PMDD"),
             tags$li("You found some resources online recommending remedies for PMDD and you want to fact-check their claims"),
             tags$li("You want to find new treatment options to discuss with your health care provider"),
             tags$li("You are noticing recurring symptoms during your luteal phase and want to explore if it has been linked to PMDD in scientific studies")
           )
  ),
  tabPanel("All time PMDD publications in Pubmed",
           fluidRow(
             
             box(width = 9,
                 plotOutput("pubs_year", height = 300)
             ),
             
             box(width = 3, 
                 plotOutput("keyterm_categories", height = 300)
             )
           )
  )
)),

tags$h4("Use the filters below to find recent publications"),


p("Keyterms are keywords, MeSH terms, and chemicals indicated by the publication authors. We have assigned these terms to the
      three categories indicated above."),

p('First, apply the', strong("Category"), 'filter, which will enable the keyterms in that category in the', strong("Keyterms"), 'filter'),
p('Once you have selected the', strong("Category"), 'you are interested in, the bar graph will show you the top 50 keyterms for the 
      selected category (based on the number of publications using the keyterm). With the keyterm selected, you can find the publications using 
      your selected keyterm in the table at the bottom of the dashboard. You will find the Pubmed ID (unique ID that Pubmed assigns to publications), 
      title of the publication, the year when it was published, and the abstract, which is the summary scientists provide for their article.'),


fluidRow(
  column(width = 2,
         selectInput("categories_filter","Category",
                     choices = categories,
                     multiple = FALSE,
                     selectize = TRUE,
                     selected = "Non-Drug Therapy"
                     
         ),
         
         selectInput("keyterms_filter","Keyterms",
                     choices = publications$keyterms$keyterm,
                     multiple = FALSE,
                     selected = publications %>% 
                       #unnest(keyterms) %>% 
                       filter(keyterm_category == "Non-Drug Therapy") %>% 
                       group_by(keyterm) %>% 
                       summarize(publications = n_distinct(pubmed_id, na.rm = TRUE)) %>%
                       arrange(desc(publications)) %>% 
                       head(1) %>% 
                       pull(keyterm)
                     
         )
  ),
  
  column(width = 10,
         box(
           width = "100%",
           plotOutput("pubs_keyword", height = 600)
         )
  )
),


p(em("NOTE: you can click on the PubmedID and it will take you to the article page in Pubmed")),


fluidRow(
  width = "100%",
  DT::dataTableOutput("table")
),

p(em("For questions and/or suggestions please contact the author."))

)



server <- function(input, output, session) {
  
  ## Adapted from https://stackoverflow.com/questions/68084974/multiple-filters-shiny
  observe({
    pubs_k <- publications[publications$keyterm_category %in% input$categories_filter,]
    if (is.null(input$categories_filter)) {selected_choices = publications$keyterm
    }else selected_choices = unique(pubs_k$keyterm)
    
    updateSelectInput(session, "keyterms_filter", choices = selected_choices)
  })
  
  ## Let's plot the publications per year
  output$pubs_year <- renderPlot({
    n_articles_year <- publications %>% 
      group_by(publication_year) %>% 
      summarize(articles = n_distinct(pubmed_id))
    
    ggplot(data = filter(n_articles_year, !is.na(publication_year))) +
      geom_col(mapping = aes(x = publication_year, y = articles), fill = "#7A6085") + 
      xlab("Publication Year") +
      ylab("Number of publications") +
      theme_classic() +
      theme(axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 12))
  })
  
  
  output$keyterm_categories <- renderPlot({  
    x <- list(
      A = publications %>% filter(keyterm_category == "Drug Therapy") %>% pull(pubmed_id) %>% unlist(), 
      B = publications %>% filter(keyterm_category == "Non-Drug Therapy") %>% pull(pubmed_id) %>% unlist(),
      C = publications %>% filter(keyterm_category == "Symptoms") %>% pull(pubmed_id) %>% unlist()
    )
    names(x) <-  c("Drug Therapy" , "Non-Drug Therapy" , "Symptoms")
    ggvenn(
      x,
      fill_color = c("#440154ff", '#21908dff', '#fde725ff'),
      stroke_size = 0,
      #stroke_color = "#F9F5F5",
      set_name_size = 5
      
    ) + 
      scale_x_continuous() +
      theme(plot.background = element_blank(),
            panel.background = element_blank()
      )
    
  })
  
  output$pubs_keyword <- renderPlot({
    n_articles_keyterm <- publications %>%
      filter(keyterm_category %in% coalesce(input$categories_filter, categories)) %>% 
      group_by(keyterm = keyterm) %>% 
      summarize(articles = n_distinct(pubmed_id)) %>% 
      arrange(desc(articles))
    
    ggplot(data = head(n_articles_keyterm, n=50), aes(x = fct_reorder(keyterm, articles), y = articles) ) +
      geom_col(fill = "#7A6085") +
      coord_flip() + scale_y_continuous(name="Number of publications") +
      scale_x_discrete(name="Keyterm") +
      theme_classic() +
      theme(axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 12)
      )
  })
  
  # Explore this to apply filters: https://stackoverflow.com/questions/42742788/r-shiny-filter-for-all-values
  
  output$table <- DT::renderDataTable({
    DT::datatable(
      publications %>% 
        filter(keyterm %in% coalesce(input$keyterms_filter, publications$keyterm) & keyterm_category %in% input$categories_filter) %>% 
        unique() %>% 
        transmute(
          PubmedID = sprintf(paste0("<a href= 'https://pubmed.ncbi.nlm.nih.gov/",pubmed_id,"/' target='_blank'>", pubmed_id, "</a>")),
          Title = title,
          Year = publication_year, 
          Abstract = abstract) %>% 
        arrange(desc(Year)),
      escape = FALSE)
  })
  
}

shinyApp(ui, server)
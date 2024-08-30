library(DBI)
library(duckdb)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(shiny)
library(shinydashboard)
library(fresh)      #https://github.com/dreamRs/fresh
library(VennDiagram)
library(conflicted)

conflicts_prefer(dplyr::filter)
conflicts_prefer(shinydashboard::box)


####------------------- Pool data from database -------------------#####
# Connect to DuckDB database

database_path <- file.path('/Users', 'anaelizondo-ramos', 'Documents', 'Projects', 'pmdd', 'pmdd_pubmed',"data", "pmdd.db")
#database_path <- file.path("pmdd_pubmed", "data", "pmdd.db")

con <- dbConnect(duckdb(), dbdir = database_path)


# Get table from database and store in dataframe
publications <- dbGetQuery(con, "SELECT * FROM dim_publication_summary;")


# Close connection to database
dbDisconnect(con)



# Get categories for filter
categories <- publications %>% 
  unnest(keyterms) %>% 
  pull(keyterm_category)

categories <- c(as.character(unique(categories)))

###------------------- Dashboard -------------------###

mytheme <- create_theme(
  adminlte_color(
    light_blue = "#434C5E"
  ),
  adminlte_sidebar(
    width = "400px",
    dark_bg = "#D8DEE9",
    dark_hover_bg = "#81A1C1",
    dark_color = "#2E3440"
  ),
  adminlte_global(
    content_bg = "#FFF",
    box_bg = "#D8DEE9", 
    info_box_bg = "#D8DEE9"
  )
)  



ui <- 
  # page_fillable(
  # 
  # theme = bs_theme(version = 5, bootswatch = "flatly"),
  # 
  dashboardPage(
    #skin = "purple",
    
    dashboardHeader(
      title = "PMDD literature in Pubmed",
      titleWidth = 450
    ),
    
    dashboardSidebar(disable = TRUE),
    
    dashboardBody(
      
      use_theme(mytheme),
      
      fluidRow(
        
        box(plotOutput("pubs_year", height = 300)),
        
        box(plotOutput("keyterm_categories", height = 300))
      
        
      ),
      
      fluidRow(
        column(width = 2,
               selectInput("categories_filter","Category",
                           choices = categories,
                           multiple = FALSE,
                           selectize = TRUE
                           
               ),
               
               # [OR] filter
               selectInput("keyterms_filter","Keyterms",
                           choices = publications$keyterms$keyterm,
                           multiple = FALSE,
                           selected = NULL
               )
        ),
        
        column(width = 10,
               box(plotOutput("pubs_keyword", height = 600))
        )
      ),
      
      fluidRow(
        DT::dataTableOutput("table",
                            width = "100%")
      )
    )
  )
#)


server <- function(input, output, session) {
  
  ## Adapted from https://stackoverflow.com/questions/68084974/multiple-filters-shiny
  observe({
    pubs_k <- publications[publications$keyterms$keyterm_category %in% input$categories_filter,]
    #if (is.null(input$categories_filter)) {selected_choices = ""
    #}else if("All" %in% input$categories_filter) {selected_choices = publications$keyterms$keyterm
    if (is.null(input$categories_filter)) {selected_choices = publications$keyterms$keyterm
    }else selected_choices = unique(pubs_k$keyterms$keyterm)
    
    updateSelectInput(session, "keyterms_filter", choices = selected_choices)
  })
  
  ## Let's plot the publications per year
  output$pubs_year <- renderPlot({
    n_articles_year <- publications |>
      group_by(publication_year) |>
      summarize(articles = n_distinct(pubmed_id))
    
    ggplot(data = filter(n_articles_year, !is.na(publication_year))) +
      geom_col(mapping = aes(x = publication_year, y = articles), fill = "#907C99") + 
      xlab("Publication Year") +
      ylab("Number of publications") 
  })
  
  
  output$keyterm_categories <- renderPlot({
    # categories <- publications %>% 
    #   group_by(category = keyterms$keyterm_category) %>% 
    #   summarize(keyterms = n_distinct(keyterms$keyterm, na.rm = TRUE))
    # 
    # ggplot(data = categories, aes(x="", y=keyterms, fill=category)) +
    #   geom_bar(stat="identity", width=1)+
    #   coord_polar("y")+
    #   theme_void()
    
    grid.draw(
      venn.diagram(
        x = list(
          publications %>% filter(keyterms$keyterm_category == "Drug Therapy") %>% select(pubmed_id) %>% unlist(), 
          publications %>% filter(keyterms$keyterm_category == "Non-Drug Therapy") %>% select(pubmed_id) %>% unlist(),
          publications %>% filter(keyterms$keyterm_category == "Symptoms") %>% select(pubmed_id) %>% unlist()
        ),
        category.names = c("Drug Therapy" , "Non-Drug Therapy" , "Symptoms"),
        filename = NULL,
        output = FALSE,
        height = "100%",
        width = "100%",
        # resolution = 300,
        # compression = "lzw",
        lwd = 1,
        col=c("#440154ff", '#21908dff', '#fde725ff'),
        fill = c(alpha("#440154ff",0.3), alpha('#21908dff',0.3), alpha('#fde725ff',0.3)),
        cex = 0.8,
        fontfamily = "sans",
        cat.cex = 1,
        cat.default.pos = "outer",
        cat.fontfamily = "sans",
        cat.col = c("#440154ff", '#21908dff', '#fde725ff'),
        # rotation = 1
      )
    )
    
    
  })
  
  output$pubs_keyword <- renderPlot({
    n_articles_keyterm <- publications %>%
      filter(keyterms$keyterm_category %in% coalesce(input$categories_filter, categories)) %>% 
      group_by(keyterm = keyterms$keyterm) %>% 
      summarize(articles = n_distinct(pubmed_id)) %>% 
      arrange(desc(articles))
    
    ggplot(data = head(n_articles_keyterm, n=50), aes(x = fct_reorder(keyterm, articles), y = articles) ) +
      geom_col(fill = "#907C99") +
      coord_flip() + scale_y_continuous(name="Number of publications") +
      scale_x_discrete(name="Keyterm") +
      theme_classic() +
      theme(axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 12)
      )
  })
  
  
  output$table <- DT::renderDataTable({
    DT::datatable(
      publications %>% 
        unnest(keyterms) %>% 
        # filter(keyterm_category %in% input$categories_filter) %>% 
        # filter(keyterm %in% coalesce(input$keyterms_filter, publications$keyterms$keyterm)) %>% 
        # {if (is.null(input$category_filter)) filter(keyterm %in% coalesce(input$keyterms_filter, publications$keyterms$keyterm))
        #  else (keyterm %in% coalesce(input$keyterms_filter, publications$keyterms$keyterm) & keyterm_category %in% input$categories_filter)} %>% 
        filter(keyterm %in% coalesce(input$keyterms_filter, publications$keyterms$keyterm) & keyterm_category %in% input$categories_filter) %>% 
        unique() %>% 
        transmute(
          PubmedID = sprintf(paste0("<a href= 'https://pubmed.ncbi.nlm.nih.gov/",pubmed_id,"/'>", pubmed_id, "</a>")),
          Title = title,
          Year = publication_year, 
          Abstract = abstract),
      escape = FALSE)
  })
  
}

shinyApp(ui, server)
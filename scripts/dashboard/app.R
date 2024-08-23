library(DBI)
library(duckdb)
library(tidyverse)
library(dplyr)
library(plotly)
library(shiny)
library(shinydashboard)
library(conflicted)

conflicts_prefer(dplyr::filter)
conflicts_prefer(shinydashboard::box)


####------------------- Pool data from database -------------------#####
# Connect to DuckDB database

database_path <- file.path('/Users', 'anaelizondo-ramos', 'Documents', 'Projects', 'pmdd', 'pmdd_pubmed',"data", "pmdd.db")

con <- dbConnect(duckdb(), dbdir = database_path)

# Ensure databse connection is closed when closing this notebook
#on.exit(dbDisconnect(con), add = TRUE)

# or
#con <- dbConnect(duckdb(), dbdir = ":memory:")

# Get table from database and store in dataframe
entrez_clean <- dbGetQuery(con, "SELECT * FROM entrez_clean;")
#pmc_filelist <- dbGetQuery(con, "SELECT * FROM pmc_filelist;")

# Close connection to database
dbDisconnect(con)



#####------------------- Build data frames -------------------#####

# Number of PMDD publications produced each year 
n_articles_year <- entrez_clean |>
  group_by(publication_year) |>
  summarize(articles = n_distinct(pubmed_id))

# Number of publications reporting keywords 
pubs_w_kwds <- entrez_clean %>% 
  unnest(keywords) %>% 
  filter(!(keywords %in% c('N/A', 'NULL'))) %>% 
  summarize(with_kws_pubs_perc = round(n_distinct(pubmed_id, na.rm = FALSE)/n_distinct(entrez_clean$pubmed_id, na.rm = FALSE)*100, digits = 2),
            no_kws_pubs_perc = 100 - with_kws_pubs_perc
  ) %>% 
  pivot_longer(cols = everything()
               ) %>% 
  select(name,
         value) %>% 
  mutate(name = case_when(name ==  "with_kws_pubs_perc" ~ "Publications with keywords",
                            name == "no_kws_pubs_perc" ~ "Publications without keywords"))


# Number of publications per keyword 
## First we clean the keyword terms to consolidate singular/plural versions and capitalization versions.
stg_kws <- entrez_clean %>% 
  unnest(keywords) %>% 
  transmute(keywords,
            lower_kw = case_when(
              grepl("premenstrual syndrome", keywords, ignore.case = TRUE) ~ "pms",  
              grepl("PMDD/PMS|PMS/P", keywords, ignore.case = TRUE) ~ "pms/pmdd",  
              grepl("pre-menstrual dysphoric disorder|premenstrual dysphoric disorder|premenstrual dysphoria disorder", keywords, ignore.case = TRUE) ~ "pmdd",
              grepl("-", keywords) ~ keywords,
              .default = tolower(keywords)),
            singulars = stringr::str_replace_all(lower_kw, c("[^[:alnum:]]$" = "",  "s$" = "", "(\\(\\d*)" = "\\1\\)" ))
  )

## Now, we can use stg_kws to decide which term to use for the keyword.
## If the singular form of the keyword is present in the lower-case version of the original keyword, then we use the singular form. If the singular version is not present in the original keyword then we keep the original. 
keywords <- entrez_clean %>%
  unnest(keywords) %>%
  left_join(stg_kws, relationship = "many-to-many") %>%
  group_by(keyword = case_when(
    singulars %in% stg_kws$lower_kw ~ singulars, 
    .default = lower_kw)) %>% 
  summarize(publications = n_distinct(pubmed_id),
            first_date = min(publication_year),
            pubs_before_2019 = n_distinct(case_when(publication_year < 2019 ~ as.character(pubmed_id), .default = NA), na.rm = TRUE),
            pubs_after_2019 = n_distinct(case_when(publication_year >= 2019 ~ as.character(pubmed_id), .default = NA), na.rm = TRUE)
  ) %>% 
  arrange(desc(publications)) %>% 
  filter(!(keyword %in% c('n/a', 'null')))



# Number of times a publication is referenced 
# Table with ID, title and abstract of a publication of interest 




###------------------- Dashboard -------------------###

ui <- dashboardPage(
  dashboardHeader(
    title = "PMDD literature in Pubmed",
    titleWidth = 450
    ),
  
  dashboardSidebar(disable = TRUE),
  
  dashboardBody(
    # Boxes need to be put in a row (or column)
    fluidRow(
      
      box(plotOutput("pubs_year", height = 300)),
      
      box(plotOutput("pubs_w_kwds", height = 300)),
      
      box(plotOutput("pubs_keyword", height = 300)),
      
      selectInput("keywords_filter","Keywords",
                  choices = keywords$keyword,
                  multiple = TRUE
      ),
      
      DT::dataTableOutput("table", width = "100%")

    )
  )
)



server <- function(input, output) {
  ## Let's plot the publications per year
  output$pubs_year <- renderPlot({
    ggplot(data = filter(n_articles_year, !is.na(publication_year))) +
      geom_col(mapping = aes(x = publication_year, y = articles), fill = "#0072b2") + 
      xlab("Publication Year") +
      ylab("Number of publications") 
  })
  
  output$pubs_w_kwds <- renderPlot({
    # pie(pubs_w_kwds$value,
    #     labels = c("Publications with keywords", "Publications without keywords"))
    ggplot(data = pubs_w_kwds, aes(x="", y=value, fill=name)) +
      geom_bar(stat="identity", width=1)+
      coord_polar("y")+
      theme_void()
  })
  
  output$pubs_keyword <- renderPlot({
    ggplot(data = head(keywords, n=30), aes(x = fct_reorder(keyword, publications), y = publications) ) +
      geom_col(fill = "#0072b2") +
      coord_flip() + scale_y_continuous(name="Number of publications") +
      scale_x_discrete(name="Keyword")
  })
  
  output$table <- DT::renderDataTable({
    entrez_clean %>% 
      #filter(lower(keywords) %in% input$keywords_filter) %>% 
      select(pubmed_id,
             pmc_id,
             doi,
             title,
             abstract) %>% 
      unique()
  })
  
}

shinyApp(ui, server)

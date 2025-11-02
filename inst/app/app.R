library(shiny)
library(dplyr)
library(ggplot2)
library(bslib)

ui <- page_fluid(
  theme = bs_theme(bootswatch = "flatly"),
  title = "NBA Shot Explorer",
  layout_sidebar(
    sidebar = sidebar(
      sliderInput("year", "Year",
                  min = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  max = max(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  value = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  sep = ""),
      selectInput("season", "Season type",
                  choices = c("All", levels(nba_shots$season_type)),
                  selected = "All"),
      selectInput("outcome", "Outcome",
                  choices = c("All", "Made", "Missed"),
                  selected = "All"),
      helpText("Fields: shot_distance (ft), x/y_location (coords), shot_made_flag (1/0).")
    ),
    card(
      card_header("Court scatter (filtered)"),
      plotOutput("scatter", height = 420),
      div(class = "px-3 pb-3",
          tags$small("Interpretation: made vs missed attempts for the chosen filters."))
    ),
    card(
      card_header("Accuracy & Expected Points by Distance"),
      plotOutput("distplot", height = 340),
      div(class = "px-3 pb-3",
          tags$small("Accuracy = mean(shot_made_flag). Expected points = mean(shot_type * shot_made_flag)."))
    )
  )
)

server <- function(input, output, session) {
  df_filtered <- reactive({
    yr <- input$year
    dat <- nba_shots |>
      mutate(year = lubridate::year(game_date)) |>
      filter(year == yr)

    if (input$season != "All") dat <- dat |> filter(season_type == input$season)
    if (input$outcome == "Made")   dat <- dat |> filter(shot_made_flag == 1)
    if (input$outcome == "Missed") dat <- dat |> filter(shot_made_flag == 0)
    dat
  })

  output$scatter <- renderPlot({
    dat <- df_filtered()
    ggplot(dat, aes(x_location, y_location, color = factor(shot_made_flag))) +
      geom_point(alpha = 0.3, size = 0.5) +
      coord_fixed() +
      scale_color_manual(values = c("0" = "#999999", "1" = "#2c7fb8"), labels = c("Missed", "Made")) +
      labs(x = "X", y = "Y", color = "Outcome") +
      theme_minimal()
  })

  output$distplot <- renderPlot({
    dat <- df_filtered()
    by_dist <- dat |>
      group_by(shot_distance) |>
      summarise(
        accuracy = mean(shot_made_flag),
        expected_points = mean(shot_type * shot_made_flag),
        .groups = "drop"
      )
    ggplot(by_dist, aes(shot_distance)) +
      geom_point(aes(y = accuracy)) +
      geom_point(aes(y = expected_points), color = "red") +
      labs(x = "Distance (ft)", y = "Average accuracy / expected points") +
      theme_minimal()
  })
}

shinyApp(ui, server)

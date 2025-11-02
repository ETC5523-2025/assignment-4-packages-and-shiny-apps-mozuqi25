library(shiny)
library(dplyr)
library(ggplot2)
library(bslib)
library(shinyjs)

data("nba_shots", package = "asg4nbashots")

ui <- page_navbar(
  theme = bs_theme(bootswatch = "flatly"),
  title = "NBA Shot Data Explorer (1997 - 2020)",
  tags$head(tags$link(rel="stylesheet", type="text/css", href="style.css")),
  layout_sidebar(
    sidebar = sidebar(
      width = 500,
      h4("Using the Shiny-App Dashboard"),
      p("Adjust these options and slider field to explore the data through the Shot Location Plot and Average Accuracy & Expected Points Plot."),
      useShinyjs(),
      p("1. Select the All Year Data, Average for Overall Data (for accuracy & expected points), or Select a Particular Year."),
      checkboxInput("all_years",  "Show All Year Data (Overlay)", FALSE),  # per-year dots (accumulated/overlay)
      checkboxInput("avg_overall", "Average of Overall Years", TRUE),   # single pooled series

      sliderInput("year", "Year",
                  min = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  max = max(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  value = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  sep = "", width = "100%"),

      p("2. Select the Playoffs season, Regular season, or Both to see whether any interesting differences."),
      checkboxGroupInput(
        "season", "Season type:",
        choices  = levels(nba_shots$season_type),
        selected = levels(nba_shots$season_type)
      ),
      p("3. Select the Scored Shot, Missed Shot, or Both to see the shoot success tendency by the shoot location/position."),
      checkboxGroupInput(
        "outcome", "Shot Outcome:",
        choices  = c("Scored" = "Scored", "Missed" = "Missed"),
        selected = c("Scored", "Missed")
      ),
      h4("About the Data"),
      p(
        HTML('Further information about this shiny-app, the <b>nba_shots</b> Dataset, and the <b>asg4nbashots</b> Package can be found <a href="https://etc5523-2025.github.io/assignment-4-packages-and-shiny-apps-mozuqi25/" target="_blank">here</a>.')
      )
    ),
    navset_card_tab(
      id = "main_tabs",
      nav_panel("Shot Location Plot",
                card(
                  card_header("Shot Location Plot. All shots were transformed into one ring shot (Left-Hand Side)."),
                  plotOutput("scatter", height = 550),
                  div(class = "px-3 pb-3"),
                  p("Output description: The blue dots represent missed shots, while the red dots represent successful shots. Darker areas indicate higher shot frequency. From the plot above, clear spatial patterns emerge over the 24-year period, most attempts cluster near the basket-ring and around the three-point line, reflecting consistent player preferences and strategic evolution in shot selection.")
                )
      ),
      nav_panel("Accuracy Average & Expected Points Plot",
                card(
                  card_header("Accuracy Average & Expected Points by Distance. Calculated by number of scored shots and type of shot."),
                  plotOutput("distplot", height = 550),
                  div(class = "px-3 pb-3"),
                  p("Output description: The lower dark-blue points represent the average shot accuracy by distance, while the upper red points represent the expected points scored. Although shots taken closer to the basket (< 2.5 ft) have the highest accuracy, medium-range shots (2.5–22 ft) maintain a relatively consistent success rate. Beyond 22 ft, accuracy declines as distance increases, yet a “sweet spot” emerges around 22–29 ft, where expected points remain higher or equal to mid-range attempts due to the added value of three-point shots.")
                )
      )
    )
  )
)

server <- function(input, output, session) {
  all_years_active <- reactive({
    isTRUE(input$avg_overall) || isTRUE(input$all_years)
  })

  observe({
    if (all_years_active()) shinyjs::disable("year") else shinyjs::enable("year")
  })

  observe({
    if (identical(input$main_tabs, "Accuracy Average & Expected Points Plot")) {
      updateCheckboxGroupInput(session, "outcome", selected = c("Scored","Missed"))
      shinyjs::disable("outcome")
      shinyjs::enable("avg_overall")
    } else {
      shinyjs::enable("outcome")
      updateCheckboxInput(session, "avg_overall", value = FALSE)  # untick overlay
      shinyjs::disable("avg_overall")                             # disable on scatter tab
    }
  })

  df_filtered <- reactive({
    dat <- nba_shots |>
      mutate(year = lubridate::year(game_date))

    if (!isTRUE(input$all_years)) {
      dat <- dat |> filter(year == input$year)
    }

    req(length(input$season) > 0)
    dat <- dat |> filter(season_type %in% input$season)

    req(length(input$outcome) > 0)
    wanted <- c("Missed" = 0L, "Scored" = 1L)[input$outcome]
    dat <- dat |> filter(shot_made_flag %in% wanted)

    dat
  })

  output$scatter <- renderPlot({
    dat <- df_filtered()
    req(nrow(dat) > 0)

    ggplot(dat, aes(y_location, -x_location, color = factor(shot_made_flag))) +
      geom_point(alpha = 0.2, size = 1.2) +
      geom_vline(xintercept = c(-50, 420, 890), color = "darkgrey", linewidth = 1.1) +
      geom_hline(yintercept = c(-250, 250), color = "darkgrey", linewidth = 1.1) +
      coord_fixed(xlim = c(-50, 890), ylim = c(-250, 250)) +
      scale_color_manual(
        values = c("0" = "#03c6fc", "1" = "red"),
        labels = c("Missed", "Scored")
      ) +
      labs(
        x = "Court Length (ft, baseline → half-court)",
        y = "Court Width (ft, left → right)",
        color = "Outcome"
      ) +
      theme_minimal()
  })

  output$distplot <- renderPlot({
    req(length(input$season) > 0)

    # ignore specific year if either pooled-average or overlay is requested
    base <- nba_shots |>
      dplyr::mutate(year = lubridate::year(game_date)) |>
      dplyr::filter(
        if (all_years_active()) TRUE else year == input$year,
        season_type %in% input$season,
        shot_distance <= 33
      )

    validate(need(nrow(base) > 0, "No data for the current selection."))

    # pooled series (this is what we always draw first)
    by_dist <- base |>
      dplyr::group_by(shot_distance) |>
      dplyr::summarise(
        accuracy        = mean(shot_made_flag),
        expected_points = mean(shot_type * shot_made_flag),
        .groups = "drop"
      )

    # subtitle text
    period_lab <- if (isTRUE(input$avg_overall)) {
      "Average of overall years"
    } else if (isTRUE(input$all_years)) {
      "All years (per-year overlay)"
    } else {
      paste("Year", input$year)
    }

    p <- ggplot(by_dist, aes(shot_distance)) +
      geom_point(aes(y = accuracy)) +
      geom_point(aes(y = expected_points), color = "red") +
      geom_vline(xintercept = c(2.5, 21.5, 29.5), color = "darkgrey", linewidth = 0.8) +
      scale_x_continuous(limits = c(0, 33), breaks = seq(0, 33, by = 2.5)) +
      scale_y_continuous(limits = c(0, 1.6), breaks = seq(0, 1.6, by = 0.2)) +
      labs(
        title    = "Accuracy & Expected Points by Distance",
        subtitle = period_lab,
        x = "Distance (ft, ~33 ft ≈ 400 in, half-court)",
        y = "Average accuracy / expected points",
        caption  = "Accuracy = mean(shot_made_flag). Expected points = mean(shot_type * shot_made_flag)."
      ) +
      theme_minimal()

    # overlay per-year points only when all_years = TRUE
    if (isTRUE(input$all_years)) {
      by_year_dist <- base |>
        dplyr::group_by(year, shot_distance) |>
        dplyr::summarise(
          accuracy        = mean(shot_made_flag),
          expected_points = mean(shot_type * shot_made_flag),
          .groups = "drop"
        )

      p <- p +
        geom_point(data = by_year_dist, aes(y = accuracy), alpha = 0.18, size = 1) +
        geom_point(data = by_year_dist, aes(y = expected_points), color = "red", alpha = 0.18, size = 1)
    }

    p
  })

}

shinyApp(ui, server)

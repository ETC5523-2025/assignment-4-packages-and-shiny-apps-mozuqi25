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
      p(HTML('Adjust these <i><u>options</u></i> and <i><u>slider field</u></i> to explore the data through the <b>Shot Location Plot</b> and <b>Average Accuracy & Expected Points Plot</b>.')),
      useShinyjs(),
      p(HTML('1. Select the <i><u>All Year Data</i></u>, <i><u>Average for Overall Data</i></u> (for accuracy & expected points), or select a <i><u>Particular Year (from 1997 to 2020)</i></u>.')),
      checkboxInput("all_years",  "Show All Year Data (Overlay)", FALSE),  # per-year dots (accumulated/overlay)
      checkboxInput("avg_overall", "Average of Overall Years", TRUE),   # single pooled series

      sliderInput("year", "Year",
                  min = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  max = max(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  value = min(lubridate::year(nba_shots$game_date), na.rm = TRUE),
                  sep = "", width = "100%"),

      p(HTML('2. Select the <i><u>Playoffs</i></u> season, <i><u>Regular</i></u> season, or <i><u>Both</i></u> to see whether any interesting differences.')),
      checkboxGroupInput(
        "season", "Season type:",
        choices  = levels(nba_shots$season_type),
        selected = levels(nba_shots$season_type)
      ),
      p(HTML('3. Select the <i><u>Scored Shot</i></u>, <i><u>Missed Shot</i></u>, or <i><u>Both</i></u> to see the shoot success tendency by the shoot location/position.')),
      checkboxGroupInput(
        "outcome", "Shot Outcome:",
        choices  = c("Scored" = "Scored", "Missed" = "Missed"),
        selected = c("Scored", "Missed")
      ),
      h4("About the Data"),
      p(
        HTML('This NBA Shot Data Explorer was inspired by the <a href="https://www.youtube.com/watch?v=yh5c3duQQ1w" target="_blank">Stand-up Maths</a> video <b>“We analysed 4,678,387 NBA shots”</b>. The raw dataset sourced from <b>“NBA Shot Data 1997–2020”</b> on <a href="https://data.world/sportsvizsunday/june-2020-nba-shots-1997-2019" target="_blank">data.world/sportsvizsunday.</a>')
      ),
      p(
        HTML('Further information about this shiny-app, the <b>nba_shots</b> Dataset, and the <b>asg4nbashots</b> Package can be found <a href="https://etc5523-2025.github.io/assignment-4-packages-and-shiny-apps-mozuqi25/" target="_blank">here</a>.')
      )
    ),
    navset_card_tab(
      id = "main_tabs",
      nav_panel("Shot Location Plot",
                card(
                  card_header("NBA Shot Location Plot. All shots were transformed into one ring shot (Left-Hand Side)."),
                  p(HTML('<i>⚠️ Note: The shiny-app may take a few moments to load the first time you open it!</i>')),
                  plotOutput("scatter", height = 550),
                  div(class = "px-3 pb-3"),
                  p(HTML('<b><u>Output description:</u></b> The <font color="blue">blue dots</font> represent <b>missed shots</b>, while the <font color="red">red dots</font> represent <b>successful shots</b>. Darker areas indicate higher shot frequency. From the plot above, clear spatial patterns emerge over the 24-year period, most attempts cluster near the basket-ring and around the three-point line, reflecting consistent player preferences and strategic evolution in shot selection.'))
                )
      ),
      nav_panel("Accuracy Average & Expected Points Plot",
                card(
                  card_header("NBA Shot Accuracy Average & Expected Points by Distance. Calculated by number of scored shots and type of shot."),
                  plotOutput("distplot", height = 550),
                  div(class = "px-3 pb-3"),
                  p(HTML('<b><u>Output description:</u></b> The lower <font color="blue">blue points</font> represent <b>the average shot accuracy</b> by distance, while the upper <font color="red">red points</font> represent <b>the expected points scored</b>, calculated by multiplying the shot accuracy by either 2 or 3, depending on the shot type/position. Shots taken closer to the basket (< 2.5 ft) have the highest accuracy and medium-range shots (2.5–22 ft) maintain a relatively consistent success rate. Although beyond 22 ft accuracy declines as distance increases, yet a <i>“sweet spot”</i> emerges around 22–29 ft, where expected points remain higher or equal to mid-range attempts due to the added value of three-point shots.'))
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
        x = "Court Length (inch, 0 = the basket-ring board target)",
        y = "Court Width (inch, 0 = the center point of basket-ring)",
        color = "Outcome"
      ) +
      theme_minimal() +
      theme(
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 14),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 14)
      )
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
      geom_point(aes(y = accuracy), color = "blue") +
      geom_point(aes(y = expected_points), color = "red") +
      geom_vline(xintercept = c(2.5, 21.5, 29.5), color = "darkgrey", linewidth = 0.8) +
      scale_x_continuous(limits = c(0, 33), breaks = seq(0, 33, by = 2.5)) +
      scale_y_continuous(limits = c(0, 1.6), breaks = seq(0, 1.6, by = 0.2)) +
      labs(
        title    = "Accuracy & Expected Points by Distance",
        subtitle = period_lab,
        x = "Distance (ft, 0 = basket-ring board position, total distance ~33 ft ≈ 400 in, half-court)",
        y = "Average accuracy / expected points"
      ) +
      theme_minimal()  +
      theme(
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 14),
        legend.title = element_text(size = 14, face = "bold"),
        legend.text = element_text(size = 14)
      )

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

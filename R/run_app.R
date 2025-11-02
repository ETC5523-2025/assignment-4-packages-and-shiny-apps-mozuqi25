#' Launch the NBA Shiny app
#'
#' Opens the interactive explorer bundled in this package.
#' @return A running Shiny app.
#' @export
run_nbashots_app <- function() {
  shiny::shinyAppDir(system.file("app", package = "asg4nbashots"))
}

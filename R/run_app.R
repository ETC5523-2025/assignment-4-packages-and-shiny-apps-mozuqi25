#' Launch the NBA Shot Shiny app
#'
#' Opens the interactive explorer bundled in this package.
#' @return A running Shiny app.
#' @export
#' @importFrom shiny runApp
run_nbashots_app <- function() {
  appDir <- system.file("shiny", package = "asg4nbashots")

  shiny::runApp(appDir)
}

#' NBA Shot Data, 1997–2020
#'
#' Detailed shot-level data for over 4.7 million NBA attempts from 1997 to 2020,
#' including shot type, distance, court zones, outcome, and season context for
#' analysis of shot selection and efficiency, or interactive exploration via Shiny.
#'
#' @format A tibble with 4,729,512 rows and 11 variables:
#' \describe{
#'   \item{action_type}{factor — specific shot action (e.g., Jump Shot, Layup, Dunk).}
#'   \item{shot_distance}{integer — distance in feet.}
#'   \item{shot_zone_basic}{factor — broad shot zone (e.g., Restricted Area, Mid-Range, Left Corner 3).}
#'   \item{shot_zone_area}{factor — court area (Left Side, Center, Right Side).}
#'   \item{shot_zone_range}{factor — distance category (e.g., <8 ft, 8–16 ft, 16–24 ft, 24+ ft).}
#'   \item{x_location}{integer — x-coordinate on court.}
#'   \item{y_location}{integer — y-coordinate on court.}
#'   \item{shot_type}{integer — shot value (2 or 3).}
#'   \item{shot_made_flag}{integer — 1 if made, 0 if missed.}
#'   \item{game_date}{Date — YYYY-MM-DD.}
#'   \item{season_type}{factor — season category (Regular Season, Playoffs).}
#' }
#' @source Public “NBA Shot Data 1997–2020” on
#' \url{https://data.world/sportsvizsunday/june-2020-nba-shots-1997-2019};
#' inspired by Stand-up Maths' video “We analysed 4,678,387 NBA shots”
#' (\url{https://www.youtube.com/watch?v=yh5c3duQQ1w}). Differences in total
#' rows (~4.7M vs 4.68M cited) likely reflect source compilation or filtering.
#' cleaned and processed in `data-raw/nba_shots.R`.
#'
#' @examples
#' # Load dataset
#' data("nba_shots")
#'
#' # Summarise field goal accuracy by shot zone
#' dplyr::count(nba_shots, shot_zone_basic, shot_made_flag) |>
#'   dplyr::group_by(shot_zone_basic) |>
#'   dplyr::summarise(accuracy = sum(shot_made_flag) / dplyr::n())
#'
#' # Summarise average shot distance by season type
#' dplyr::group_by(nba_shots, season_type) |>
#'   dplyr::summarise(mean_distance = mean(shot_distance, na.rm = TRUE))
"nba_shots"


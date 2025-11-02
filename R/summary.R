# R/summary.R

#' Summarise shot success by year and zone
#'
#' Provides aggregated shot accuracy by year and basic zone classification.
#'
#' @param data A tibble like \code{nba_shots}.
#' @return A tibble with columns: \code{year}, \code{shot_zone_basic}, and \code{accuracy}.
#' @examples
#' shot_zone_summary()
#' @export
shot_zone_summary <- function(data = nba_shots) {
  data |>
    dplyr::mutate(year = lubridate::year(game_date)) |>
    dplyr::group_by(year, shot_zone_basic) |>
    dplyr::summarise(
      attempts = dplyr::n(),
      made = sum(shot_made_flag),
      accuracy = made / attempts,
      .groups = "drop"
    )
}

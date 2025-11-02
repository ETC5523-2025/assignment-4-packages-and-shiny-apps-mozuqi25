## code to prepare `nba_shots` dataset goes here

library(dplyr)
library(readr)
library(janitor)

nba_shots_raw <- read_csv("data-raw/nba_shots_97_20.csv")

# Clean column names and keep relevant variables
nba_shots <- nba_shots_raw %>%
  # Clean names: lower case, underscores
  janitor::clean_names() %>%
  # Keep only essential columns (rename them manually if necessary)
  select(
    action_type,
    shot_distance,
    shot_zone_basic,
    shot_zone_area,
    shot_zone_range,
    x_location,
    y_location,
    shot_type,
    shot_made_flag,
    game_date,
    season_type
  ) %>%
  # Convert game_date numeric like 20070123 → 2007
  mutate(
    action_type = as.factor(action_type),
    shot_zone_basic = as.factor(shot_zone_basic),
    shot_zone_area  = as.factor(shot_zone_area),
    shot_zone_range = as.factor(shot_zone_range),
    shot_distance = as.integer(shot_distance),
    x_location    = as.integer(x_location),
    y_location    = as.integer(y_location),
    shot_type = as.integer(substr(as.character(shot_type), 1, 1)),
    shot_made_flag = as.integer(shot_made_flag),
    game_date = as.Date(as.character(as.integer(game_date)), format = "%Y%m%d"),
    season_type = as.factor(season_type)
  )

# Save cleaned dataset to package data
usethis::use_data(nba_shots, overwrite = TRUE, compress = "xz")


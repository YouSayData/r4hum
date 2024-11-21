# Introduction to Geospatial Analysis in R
# This comprehensive script demonstrates geospatial data manipulation and visualization
# using R's powerful tools such as `sf`, `rnaturalearth`, `tidyverse`, and `geodata`.

# Required installations:
# Some parts of this script may require external dependencies, such as GDAL or PROJ.4.
# For Mac users, these can be installed via Homebrew, and Windows users can use osgeo4w.

# 1: Load Required Libraries --------------------------------------------
library(tidyverse)        # For data manipulation and visualization
library(rnaturalearth)    # Provides Natural Earth map data
library(rnaturalearthdata) # Companion package with additional datasets
library(sf)               # For handling spatial data
library(geodata)          # Access to geospatial datasets
library(tidytuesdayR)     # For loading Tidytuesday datasets
library(cartogram)       # For creating cartograms

# 2: Load and Plot World Map --------------------------------------------

# Load world map data as an sf object
world <- ne_countries(scale = "medium", returnclass = "sf")

# Create a basic world map with default projection
ggplot(world) +
  geom_sf(fill = "lightgray", color = "white") +
  coord_sf(crs = st_crs(4326)) +  # Use default geographic CRS
  labs(
    title = "World Map with Coordinate Reference System (CRS)",
    subtitle = "Using coord_sf() to visualize spatial data",
    caption = "Source: Natural Earth"
  ) +
  theme_minimal()

# 3: Function to Plot Projections ---------------------------------------

# Define a reusable function to visualize maps with different projections
plot_projection <- function(crs, title, subtitle) {
  ggplot(world) +
    geom_sf(fill = "lightgray", color = "white") +
    coord_sf(crs = st_crs(crs)) +
    labs(
      title = title,
      subtitle = subtitle,
      caption = "Source: Natural Earth"
    ) +
    theme_minimal()
}

# Example projections using the function
plot_projection(4326, "Equirectangular Projection", "EPSG:4326 - Default Projection")
plot_projection(3857, "Mercator Projection", "EPSG:3857 - Common for Web Mapping")
plot_projection("+proj=moll", "Mollweide Projection", "Equal-Area Projection")
plot_projection("+proj=robin", "Robinson Projection", "Aesthetic Projection")
plot_projection("+proj=ortho +lat_0=51 +lon_0=10", "Orthographic Projection", "Centered on Germany")
plot_projection("+proj=ortho +lat_0=-41 +lon_0=174", "Orthographic Projection", "Centered on New Zealand")

# 4: Highlight Specific Regions -----------------------------------------

# Highlight European countries on the world map
europe <- world |> filter(region_un == "Europe")

ggplot(data = world) +
  geom_sf(fill = "lightgray") +
  geom_sf(data = europe, fill = "blue", color = "white") +
  labs(
    title = "Highlighting Europe",
    subtitle = "Filtering Geospatial Data Example",
    caption = "Source: Natural Earth"
  ) +
  theme_minimal()

# 5: Coffee Ratings Analysis --------------------------------------------

# Load coffee ratings data
coffee_ratings <- tidytuesdayR::tt_load(2020, week = 28)$coffee_ratings

# Summarize average coffee ratings by country
coffee_summary <- coffee_ratings |>
  group_by(country_of_origin) |>
  summarize(avg_points = mean(total_cup_points, na.rm = TRUE))

# Join coffee data with world map
coffee_map <- world |>
  left_join(coffee_summary, by = c("name" = "country_of_origin"))

# Visualize coffee ratings using a thematic map
coffee_palette <- c("#4E342E", "#6D4C41", "#8D6E63", "#A1887F", "#D7CCC8")

ggplot(coffee_map) +
  geom_sf(aes(fill = avg_points), color = "black", size = 0.1) +
  coord_sf(crs = "+proj=robin") +
  scale_fill_gradientn(
    colors = coffee_palette,
    na.value = "#D3D3D3",
    name = "Avg. Points"
  ) +
  labs(
    title = "Average Coffee Ratings by Country",
    subtitle = "Coffee-Inspired Visualization",
    caption = "Source: Coffee Ratings Dataset"
  ) +
  theme_minimal()

# Create a cartogram of coffee ratings
# Filter world data to include only countries present in coffee_summary
coffee_cartogram_data <- world |>
  semi_join(coffee_summary, by = c("name" = "country_of_origin")) |>
  left_join(coffee_summary, by = c("name" = "country_of_origin"))

# Transform the world map to a projected CRS (e.g., EPSG:3857 for Web Mercator)
coffee_cartogram_data_projected <- st_transform(coffee_cartogram_data, crs = 3857)

# Create a cartogram based on the average coffee ratings
# Adjust countries' sizes proportionally to the average coffee points
coffee_cartogram <- cartogram_cont(coffee_cartogram_data_projected, "avg_points")

# Plot the distorted map
ggplot(coffee_cartogram) +
  geom_sf(aes(fill = avg_points), color = "black", size = 0.1) +
  scale_fill_gradientn(
    colors = coffee_palette,
    na.value = "#D3D3D3",
    name = "Avg. Points"
  ) +
  labs(
    title = "Cartogram of Average Coffee Ratings by Country",
    subtitle = "Countries Resized Proportionally to Average Coffee Ratings",
    caption = "Source: Coffee Ratings Dataset"
  ) +
  theme_minimal()

# 6: Focus on Germany ---------------------------------------------------

# Load weather station data from DWD
dwd <- read_csv2("https://userpage.fu-berlin.de/soga/300/30100_data_sets/DWD.csv") |>
  select(id, `STATION NAME`, LAT, LON, `RECORD LENGTH`) |>
  drop_na() |>
  mutate(RECORD.LENGTH.CATEGORY = cut(
    `RECORD LENGTH`,
    breaks = c(-Inf, 10, 30, 60, 90, Inf),
    labels = c("very short (<10)", "short (10-30)", "middle (30-60)", "long (60-90)", "very long (>90)")
  ))

# Load German administrative boundaries
germany <- geodata::gadm(country = "DEU", path = tempdir(), resolution = 2, level = 1)
germany_sf <- st_as_sf(germany)

# Spatial join to link weather stations to states
dwd_sf <- dwd |> st_as_sf(coords = c("LON", "LAT"), crs = 4326)
dwd_sf <- st_transform(dwd_sf, crs = st_crs(germany_sf))
dwd_with_states <- st_join(dwd_sf, germany_sf, join = st_within)

# Calculate average record length by state
state_avg_record_length <- dwd_with_states |>
  group_by(NAME_1) |>
  summarize(avg_record_length = mean(`RECORD LENGTH`, na.rm = TRUE)) |>
  st_set_geometry(NULL)

# Join average record length back to Germany sf object
germany_sf_with_avg <- germany_sf |>
  left_join(state_avg_record_length, by = c("NAME_1" = "NAME_1"))

# Plot average record length by state
ggplot(germany_sf_with_avg) +
  geom_sf(aes(fill = avg_record_length), color = "black") +
  scale_fill_gradient(low = "lightblue", high = "darkblue", na.value = "grey90", name = "Avg Record Length") +
  labs(
    title = "Average Record Length by State in Germany",
    subtitle = "DWD Weather Stations Data",
    caption = "Source: DWD Weather Stations"
  ) +
  theme_minimal()

# 7: Analyze Water Points in Kenya --------------------------------------

# Load water dataset
water <- tidytuesdayR::tt_load(2021, week = 19)$water

# Filter for functional water points
water_functional <- water |>
  filter(!str_detect(str_to_lower(status), "non.+functional")) |>
  filter(!str_detect(str_to_lower(status), "not.+functional")) |>
  filter(str_detect(str_to_lower(status), "functional"))

# Filter for Kenya
kenya_water <- water_functional |> filter(country_name == "Kenya")

# Get Kenya's map data
kenya_map <- ne_countries(scale = "medium", country = "Kenya", returnclass = "sf")

# Plot water points in Kenya
ggplot() +
  geom_sf(data = kenya_map, fill = "gray95", color = "black", alpha = 0.5) +
  geom_point(
    data = kenya_water,
    aes(x = lon_deg, y = lat_deg),
    color = "blue", size = 1, alpha = 0.6
  ) +
  labs(
    title = "Water Points in Kenya",
    subtitle = "Water Points Overlaid on Kenya's Map",
    caption = "Source: WPdx"
  ) +
  theme_minimal() +
  coord_sf()

# Extra: mapview ----------------------------------------------------------

# Load the mapview library for interactive maps
library(mapview)

# convert kenya_water to an sf object
kenya_water_sf <- st_as_sf(kenya_water, coords = c("lon_deg", "lat_deg"), crs = 4326)

# Create an interactive map water points in Kenya
mapview(kenya_water_sf, zcol = "water_source")



# Exercise: Mapping Coffee Ratings by Species and Harvest Year
# Use the coffee ratings dataset to summarize ratings by country_of_origin, species, and harvest_year.
# Find the geographical coordinates for each country.
# Create thematic maps to visualize the results, highlighting differences between species or harvest years.


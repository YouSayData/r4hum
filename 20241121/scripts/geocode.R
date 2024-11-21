library(tidyverse)
library(tidygeocoder)
library(mapview)

kebab_shops <- tibble(
  Name = c(
    "Sultan’s Grill",
    "Oriental Oasis",
    "Kebab Komets",
    "Leipzig Döner Dream",
    "Mediterranean Delight",
    "The Golden Skewer",
    "Anatolian Feast",
    "Nomad's Kebab Corner",
    "Leipziger Grillhaus",
    "Urban Wraps"
  ),
  Address = c(
    "Karl-Liebknecht-Straße 45",
    "Petersstraße 18",
    "Eisenbahnstraße 110",
    "Georg-Schwarz-Straße 25",
    "Jahnallee 70",
    "Augustusplatz 12",
    "Harkortstraße 32",
    "Prager Straße 88",
    "Zschochersche Straße 48",
    "Richard-Wagner-Straße 10"
  )
) |> 
  mutate(Address = str_c(Address, "Leipzig", sep = ", "))

reviews <- kebab_shops |> 
  slice_sample(n = 1000, replace = T) |> 
  mutate(stars = sample(1:5, 1000, replace = T))

kebab_shops_geocodes <- geocode(kebab_shops, Address)

# join the reviews and geocode data

kebab_shops_with_reviews <- reviews |> 
  left_join(kebab_shops_geocodes, by = c("Name", "Address"))

# summarise by mean star score, then turn into an sf object and visualise with mapview

kebab_shops_with_reviews_sf <- kebab_shops_with_reviews |> 
  group_by(Name, Address, long, lat) |>
  summarise(mean_stars = mean(stars), no_reviews = n(), .groups = "drop" ) |>
  mutate(mean_stars = round(mean_stars, 2)) |> 
  st_as_sf(coords = c("long", "lat"), crs = 4326)

# color should be mean_stars
mapview(
  kebab_shops_with_reviews_sf,
  zcol = "mean_stars"
)


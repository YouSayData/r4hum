## ----setup, include=FALSE------------------------------------------------------------------
library(learnr)
library(tidyverse)
library(tidytuesdayR)
library(skimr)

rolling_stone <- tt_load(2024, week = 19)[["rolling_stone"]]

rolling_stone

skim(rolling_stone)

ggplot(data = rolling_stone) +
  geom_point(mapping = aes(x = release_year, y = spotify_popularity))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity, color = artist_gender))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity, size = weeks_on_billboard))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity, alpha = weeks_on_billboard))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity, shape = artist_gender))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity), size = 2)

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity))  + 
  facet_wrap(~ artist_gender, ncol = 2)

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity)) + 
  facet_grid(artist_gender ~ type)

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity))

ggplot(data = rolling_stone) + 
  geom_smooth(mapping = aes(x = release_year, y = spotify_popularity, linetype = artist_gender))

ggplot(data = rolling_stone) + 
  geom_point(mapping = aes(x = release_year, y = spotify_popularity)) +
  geom_smooth(mapping = aes(x = release_year, y = spotify_popularity, col = artist_gender))

ggplot(data = rolling_stone, mapping = aes(x = release_year, y = spotify_popularity)) + 
  geom_point() +
  geom_smooth(mapping = aes(col = artist_gender))

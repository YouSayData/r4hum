library(tidyverse)
library(tidytext)
library(textdata)
library(here)

# Import Data From ECB
ecb_speeches <- read_delim(
  "https://www.ecb.europa.eu/press/key/shared/data/all_ECB_speeches.csv?1eb0264cf0cacb208581a3a529014a28",
  delim = "|"
  )

# Check for Problems
problems(ecb_speeches)

ecb_speeches |> 
  slice(2014)

ecb_speeches <- ecb_speeches |> 
  mutate(
    across(everything(), str_squish)
  ) |> 
  filter(!is.na(contents))

# Build an id column 
ecb_speeches <- ecb_speeches |> 
  mutate(id = str_c(
    str_replace_all(speakers, "(\\w)\\w*\\W*", "\\1"),
    str_replace_all(date, "-", ""),
    sep = "_")
    ) |> 
  select(
    id, everything()
  )

# extract date components
ecb_speeches <- ecb_speeches |> 
  mutate(
    date = ymd(date),
    year = year(date),
    month = month(date),
    month_lbl = month(date, label = T, abbr = T),
    day = day(date),
    weekday = wday(date, label = T, abbr = T),
    iso_week = isoweek(date)
  )

# Focusing on Christine Lagarde

clagarde_speeches <- ecb_speeches |> 
  filter(str_detect(speakers, "Lagarde")) |> 
  select(id, contents)

clagarde_speeches

# unnest token
clagarde_speeches_unnested <- clagarde_speeches |> 
  unnest_tokens(word, contents)

clagarde_speeches_unnested

# stop words
data(stop_words)
stop_words

clagarde_speeches_sw_removed <- clagarde_speeches_unnested |> 
  anti_join(stop_words)

clagarde_speeches_sw_removed

# is this useful? compare!

clagarde_speeches_unnested |> 
  count(word, sort = T)

clagarde_speeches_sw_removed |> 
  count(word, sort = T)


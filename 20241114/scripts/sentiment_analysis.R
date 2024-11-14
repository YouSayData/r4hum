library(tidyverse)
library(tidytext)
library(textdata)
library(here)

ecb_speeches <- read_delim(
  here("data", "ecb_speeches.csv"),
  delim = "|"
) |> 
  mutate(
    across(everything(), str_squish)
  ) |> 
  filter(!is.na(contents)) |> 
  mutate(id = str_c(
    str_replace_all(speakers, "(\\w)\\w*\\W*", "\\1"),
    str_replace_all(date, "-", ""),
    sep = "_")
  ) |> 
  select(
    id, everything()
  ) |> 
  mutate(
    date = ymd(date),
    year = year(date),
    month = month(date),
    month_lbl = month(date, label = T, abbr = T),
    day = day(date),
    weekday = wday(date, label = T, abbr = T),
    iso_week = isoweek(date)
  ) 

clagarde_speeches_tidy <- ecb_speeches |> 
  filter(str_detect(speakers, "Lagarde")) |> 
  select(id, contents) |> 
  unnest_tokens(word, contents)

clagarde_speeches_sw_removed <- clagarde_speeches_tidy |> 
  anti_join(stop_words)


# sentiment analysis ------------------------------------------------------

# SA: AFINN ---------------------------------------------------------------

afinn <- get_sentiments("afinn")
afinn

clagarde_speeches_sw_removed |> 
  left_join(afinn) |> 
  drop_na() |> 
  arrange(value)

clagarde_speeches_sw_removed |> 
  left_join(afinn) |> 
  drop_na() |> 
  arrange(-value)

# visualisation of sentiments by word

clagarde_speeches_sw_removed |> 
  left_join(afinn) |> 
  drop_na() |> 
  mutate(sentiment = if_else(value > 0, "positive", "negative")) |> 
  group_by(word, value, sentiment) |> 
  count() |> 
  ungroup() |> 
  slice_max(n, n = 10) |> 
  ggplot(aes(n, value, col = sentiment)) +
  geom_col(aes(fill = sentiment), position = "dodge", width = 0.2) +
  geom_label(aes(label = word)) +
  theme_minimal() +
  coord_cartesian(ylim = c(-5, 5))

# sentiment analysis by speech

clagarde_speeches_afinn_rated <- clagarde_speeches_sw_removed |> 
  left_join(afinn) |> 
  drop_na() |> 
  summarise(
    sentiment = mean(value),
    n = n(),
    .by = id
  )

clagarde_speeches_afinn_rated$n |> range()

clagarde_speeches_afinn_rated |> 
  ggplot() +
  geom_histogram(aes(n))

clagarde_speeches_afinn_rated |>
  ggplot() +
  geom_point(aes(n, sentiment))

clagarde_speeches_afinn_rated_meta <- clagarde_speeches_afinn_rated |>
  left_join(ecb_speeches |> 
              transmute(date = ymd(date), month_lbl, weekday, iso_week, year, id), by = "id")
clagarde_speeches_afinn_rated_meta

clagarde_speeches_afinn_rated_meta |> 
  ggplot(aes(date, sentiment, size = n)) +
  geom_point()

clagarde_speeches_afinn_rated_meta |> 
  ggplot(aes(date, sentiment)) +
  geom_smooth()

clagarde_speeches_afinn_rated_meta |> 
  ggplot(aes(month_lbl, sentiment)) +
  geom_violin() +
  facet_wrap(~ year)

# SA: Loughran ------------------------------------------------------------

loughran <- get_sentiments("loughran")
loughran

clagarde_speeches_sw_removed |> 
  inner_join(loughran) |> 
  drop_na()

clagarde_speeches_loughran_rated <- clagarde_speeches_sw_removed |> 
  inner_join(loughran) |> 
  drop_na() |> 
  count(id, sentiment) |> 
  group_by(id) |> 
  mutate(perc = n / sum(n)) |> 
  ungroup() |> 
  select(-n)

clagarde_speeches_loughran_rated |> 
  group_by(id) |> 
  slice_max(perc, n = 2) |> 
  ungroup() |> 
  left_join(ecb_speeches |> 
              transmute(date = ymd(date), month_lbl, weekday, iso_week, year, id), by = "id") |> 
  filter(
    between(date, ymd("2023-10-01"), ymd("2023-12-31"))
  ) |> 
  ggplot(aes(date, perc, fill = sentiment)) +
  geom_col(position = "dodge", col = "white") +
  theme_minimal()


# Exercise

# 1. Find out whether Christine Lagarde is looking forward to the weekend or not
# 2. There are two other sentiment lexicons available: bing, ncr. Try to use them and compare the results.

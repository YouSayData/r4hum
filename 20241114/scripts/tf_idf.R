library(tidyverse)
library(tidytext)
library(textcat)
library(here)

ecb_speeches <- read_delim(
  here("data", "ecb_speeches.csv"),
  delim = "|"
) |> 
  mutate(
    across(everything(), str_squish)
  ) |> 
  filter(!is.na(contents), contents != "") |>
  mutate(id = str_c(
    str_replace_all(speakers, "(\\w)\\w*\\W*", "\\1"),
    str_replace_all(date, "-", ""),
    sep = "_")
  ) |> 
  select(
    id, everything()
  )

ecb_speeches_tidy <- ecb_speeches |> 
  select(id, speakers, contents) |>
  unnest_tokens(word, contents) |> 
  anti_join(stop_words) |> 
  filter(!str_detect(word, "\\d+"))

# Corpus is multilingual 
ecb_speeches_tidy |> 
  count(speakers, word, sort = T)


# textcat ---------------------------------------------------------------

ecb_language <- ecb_speeches |>
  transmute(
    excerpt = str_sub(contents, 1, 1000),
    id,
    lang = textcat(excerpt)
  )


# speaker names also feature ----------------------------------------------

speaker_name_parts <- tibble(
  word = ecb_speeches$speakers |> 
    str_to_lower() |> 
    str_squish() |> 
    str_split(" ") |> 
    unlist() |> 
    str_remove_all("[^[:alpha:]]") |>
    str_squish()
)

  
ecb_speeches_tidy <- ecb_speeches |>
  semi_join(ecb_language |> filter(lang == "english"), by = "id") |>
  select(id, speakers, contents) |>
  unnest_tokens(word, contents) |> 
  anti_join(stop_words) |> 
  filter(!str_detect(word, "\\d+")) |>
  mutate(
    word = str_replace_all(word, "[^[:alpha:]]", "") |> str_to_lower(),
  ) |> 
  anti_join(speaker_name_parts)

# the problem with word frequencies ---------------------------------------

speaker_words <- ecb_speeches_tidy |> 
  count(speakers, word, sort = T)

total_words <- speaker_words |> 
  summarise(total = sum(n), .by = speakers)

speaker_words <- speaker_words |> 
  left_join(total_words, by = "speakers") |> 
  mutate(tf = n / total)

speaker_words |> 
  ggplot(aes(tf, fill = speakers)) +
  geom_histogram(show.legend = F) +
  facet_wrap(~ speakers, ncol = 4, scales = "free_y")

# TF-IDF -------------------------------------------------------------------

speaker_words |> 
  select(word, speakers, n) |> 
  bind_tf_idf(word, speakers, n) |> 
  arrange(desc(tf_idf)) |> 
  head(100) |> 
  View()

speaker_words |> 
  bind_tf_idf(word, speakers, n) |> 
  group_by(speakers) |>
  slice_max(tf_idf, n = 10) |>
  ungroup() |>
  filter(str_detect(speakers, "Lagarde") | str_detect(speakers, "Draghi")) |> 
  ggplot(aes(tf_idf, fct_reorder(word, tf_idf), fill = speakers)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~speakers, ncol = 2, scales = "free") +
  labs(x = "tf-idf", y = NULL)

# Exercise
# Try to find a way to see whether you can use tf-idf to identify whether Christine Lagarde's focus changed over the years


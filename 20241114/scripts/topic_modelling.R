library(tidyverse)
library(tidytext)
library(textcat)
library(here)
library(topicmodels)
library(stopwords)
library(reshape2)
library(ggthemes)
library(LDAvis)
library(philentropy)

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

# lang detection ---------------------------------------------------------------

ecb_language <- ecb_speeches |>
  transmute(
    excerpt = str_sub(contents, 1, 1000),
    id,
    lang = textcat(excerpt)
  )


# additional stopwords ----------------------------------------------------

german_stopwords <- tibble(
  word = stopwords("german")
)

french_stopwords <- tibble(
  word = stopwords("french")
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
  select(id, contents) |>
  unnest_tokens(word, contents) |>
  filter(!str_detect(word, "\\d+")) |>
  mutate(
    word = str_replace_all(word, "[^[:alpha:]]", "") |> str_to_lower(),
  ) |>
  anti_join(stop_words) |> 
  anti_join(german_stopwords) |>
  anti_join(french_stopwords) |>
  anti_join(speaker_name_parts)

# for topic modelling also remove words that are not very frequent

rare_words <- ecb_speeches_tidy |> 
  count(word, sort = TRUE) |> 
  filter(n < 4) |> 
  select(word)

# very frequent words are also not good

very_frequent_words <- ecb_speeches_tidy |> 
  count(word, sort = TRUE) |> 
  head(100) |> 
  select(word)

ecb_speeches_tidy <- ecb_speeches_tidy |> 
  anti_join(rare_words) |> 
  anti_join(very_frequent_words)

# Just so we can run it in class we throw out very short and very long speeches
#ecb_speeches_tidy <- ecb_speeches_tidy |> 
#  group_by(id) |> 
#  filter(n() > 100, n() < 2000) |> 
#  ungroup()

# Topic modelling ---------------------------------------------------------

ecb_sums <- ecb_speeches_tidy |> 
  count(id, word, sort = TRUE)

ecb_dtm <- ecb_sums |> 
  cast_dtm(id, word, n)

ecb_lda <- LDA(ecb_dtm, 
               k = 21,
               method = "Gibbs", 
               control = list(
                 iter = 500, 
                 seed = 73)
               )

ecb_lda

ecb_lda_beta <- tidy(ecb_lda)

ecb_lda_beta |>
  group_by(topic) |>
  top_n(10, beta) |>
  ungroup() |>
  arrange(topic, -beta) |>
  mutate(term = reorder_within(term, -beta, topic)) |>
  ggplot(aes(term, beta)) +
  geom_col() +
  scale_x_reordered() +
  facet_wrap(~ topic, scales = "free_x", ncol = 10) +
  theme_clean() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1))

# documents

ecb_lda_gamma <- tidy(ecb_lda, matrix = "gamma")

# posterior
ecb_posterior <- posterior(ecb_lda)

ecb_topics_documents <- ecb_posterior$topics |>
  as_tibble()

colnames(ecb_topics_documents) <- formatC(colnames(ecb_topics_documents) |> as.integer(), width = 2, flag = "0")
ecb_topics_documents |> 
  mutate(
    id = rownames(ecb_posterior$topics)
  ) |> 
  select(
    id,
    everything()
  )

# interactive visualisation -----------------------------------------------

jsPCA_2 <- function(phi) {
  jensenShannon <- function(x, y) {
    philentropy::distance(rbind(x, y),
                          method = "jensen-shannon",
                          unit = "log2",
                          mute.message = T
    )
  }
  dist.mat <- proxy::dist(x = phi, method = jensenShannon)
  # then, we reduce the K by K proximity matrix down to K by 2 using PCA
  pca.fit <- stats::cmdscale(dist.mat, k = 2)
  data.frame(x = pca.fit[,1], y = pca.fit[,2])
}

topicmodels2LDAvis <- function(x, ...){
  post <- topicmodels::posterior(x)
  if (ncol(post[["topics"]]) < 3) stop("The model must contain > 2 topics")
  mat <- x@wordassignments
  LDAvis::createJSON(
    phi = post[["terms"]], 
    theta = post[["topics"]],
    vocab = colnames(post[["terms"]]),
    doc.length = slam::row_sums(mat, na.rm = TRUE),
    term.frequency = slam::col_sums(mat, na.rm = TRUE),
    mds.method = jsPCA_2
  )
}

createJSONResult <- topicmodels2LDAvis(ecb_lda)
LDAvis::serVis(createJSONResult)

# install.packages("tidyverse")
# install.packages("esquisse")
# install.packages("skimr")
# install.packages("tidytuesdayR")

library(tidyverse)
library(tidytuesdayR)
library(skimr)
library(esquisse)

tidytuesdayR::tt_datasets(2024)

my_data_lst <- tt_load(2024, week = 33)
world_fairs <- my_data_lst$worlds_fairs

skim(world_fairs)

esquisser(viewer = "browser")

# 1.1. Getting Started with `dplyr`
# 
# Once again we are going to work with one of the most central libraries 
# in modern R: `tidyverse`. This time we work with the `dplyr` library. 
# It's a library for working and cleaning up rectangular data.
# 
# If you start a fresh R session, you will have to load the tidyverse again.
# 
library(tidyverse)
# 
# Let's also install a package that contains some example data:
# 
install.packages("nycflights13")
# 
# And tell R that we want to use it:
# 
library(nycflights13)
# 
# `nycflights13` just has a bunch of tables on which 
# we can practice some data cleaning techniques. 
# The tables are related to flights that were scheduled to depart from any of the three NYC airports in 2013. We are going to work with the `flights` library throughout this class:
# 
flights
# 
# `dplyr` Functions
# 
# Since we are assuming we are working with tidy data, 
# we will refer to the rows in the flight data set as **observations** and 
# to the columns in the data set as **variables** in today's class. 
# The main `dplyr` functions we are going to look at today are:
# 
# -   `filter()`: pick observations based on their values.
# -   `arrange()`: reorder observations.
# -   `select()`: pick variables based on their type or name.
# -   `mutate()` / `transmute()`: create new variables with functions of existing variables.
# -   `summarise()`: collapse many values down to a single summary.
# -   `group_by()`: grouping your observations before doing any of it (especially with `mutate()` and `summarise()`)
# -   `across()`: selecting several variables before doing any of it (especially with `mutate()` and `summarise()`)
# 
# 1.2. `filter()`
# 
# Let's have a look at the flights table. 
# If we want to know which flights left on Nov 8 2013, we could simply do:
# 
filter(flights, month == 11, day == 8)
# 
# And if we want it saved into our environment, we can **assign** it:
# 
(flights_nov_8 <- filter(flights, month == 11, day == 8))

# 
# *Does anyone know why I put brackets around the expression?*
# 
# Please note the `==`. A common mistake is to only use one `=`.
# 
# As you can see, `filter()` tests each value of selected variables 
# with a condition. If this evaluates to `TRUE`, it keeps the observations, 
# otherwise it drops it.
# 
# Caveat: Sometimes a computer evaluates things differently than us!
# 
# Think about the following expressions. Do they evaluate to true or false?
# 
sqrt(2) ^ 2 == 2
# 
1 / 49 * 49 == 1
# 
# Every computer has a build in precision, so they stop calculating and do not go on forever solving a simple equation. You can access the precision of your system like this:
# 
.Machine$double.eps
# 
# If you work with very long floats it might be beneficial to use the `dplyr` function `near()` instead. 
# `near()` takes the precision into account:
# 
near(sqrt(2) ^ 2,  2)
# 
# Combining Conditions
# 
# `filter()` can deal with all of R's boolean operators: !, &, \|, and `xor()`, 
# but you have to be precise:
# 
# this works
filter(flights, month == 11 | month == 12)

# this does not
filter(flights, month == 11 | 12)

# this works again
nov_dec <- filter(flights, month %in% c(11, 12))
# 
# Sometimes you can give conditions in a positive or a negative way:
# 
# this produces the same results
x <- filter(flights, !(arr_delay > 120 | dep_delay > 120))
y <- filter(flights, arr_delay <= 120, dep_delay <= 120)

identical(x, y)
# 
# Really think about your conditions when you design 
# more complicated queries. Especially when part of a condition evaluates to `NA` you might have a problem, because `NA`s are contagious:
# 
# missing values are contagious
NA > 5
10 == NA
NA + 10
NA / 2
NA == NA
# 
# The last one might be surprising, but let's think about it for a moment:
# 
# Let x be Mary's age. We don't know how old she is.
x <- NA

# Let y be John's age. We don't know how old he is.
y <- NA

# Are John and Mary the same age?
x == y
# 
# While this is sound, it can lead to bugs if we try things like `x == NA` (which would be wrong). If we need to find out whether a value is `NA` we can instead ask `is.na()`:
# 

df <- tibble(x = c(1, NA, 3))
filter(df, is.na(x) | x > 1)
# 
# 1.3 Exercises
# 
# 1.  Find all flights that:
# 
# 1.  Had an arrival delay of two or more hours
# 

# 
# 2.  Flew to Houston (IAH or HOU)
# 

# 
# 3.  Were operated by United, American, or Delta
# 

# 
# 4.  Departed in summer (July, August, and September)
# 

# 
# 5.  Arrived more than two hours late, but didn't leave late
# 

# 
# 6.  Were delayed by at least an hour, but made up over 30 minutes in flight
# 

# 
# 7.  Departed between midnight and 6am (inclusive)
# 

# 
# 2.1 `arrange()`
# 
# With arrange we can sort our observations in ascending order:
# 
arrange(flights, carrier, year, month, day)
# 
# Or in descending order:
# 
arrange(flights, desc(dep_delay))
arrange(flights, -dep_delay)
# 
# 2.2 `arrange()` exercises
# 
# 1.  Sort flights to find the most delayed flights. Find the flights that left earliest.
# 

# 
# 2.  Which flights travelled the longest? Which travelled the shortest?
# 

# 
# 3.  Sort flights to find the fastest flights.
# 

# 
# 4.  How could you use `arrange()` to sort all missing values to the start? (Hint: use `is.na()`)
# 

# 
# 3.1 `select()`
# 
# You can select a variable by index:
# 
select(flights, 4, 5, 1)
# 
# You can select a variable by name:
# 
select(flights, dep_time, sched_dep_time, year)
# 
# You cam also use either:
# 
select(flights, all_of("year", "month", "day"))
# 
# Or:
# 
select(flights, any_of("year", "month", "day"))
# 
# You can also select a range:
# 
select(flights, year:day)
# 
# Or the inverse:
# 
select(flights, !year:day)
# 
# There are also `starts_with()`, `ends_with()`, `contains()`, `matches()`, and `num_range()`.
# 
# In addition there is `everything()`, which might not sound useful, but is great for reordering:
# 
select(flights, carrier, everything())
# 
# An alternative for reordering with `select()` is to use `relocate()`:
# 
relocate(flights, carrier, .before = year)
# 
# You can also rename columns when you are selecting them:
# 
select(flights, tail_num = tailnum, everything())
# 
# An alternative is the `rename()` function:
# 
rename(flights, tail_num = tailnum)
# 
# 3.2 `select()` exercises
# 
# 1.  Brainstorm as many ways as possible to select dep_time, dep_delay, arr_time, and arr_delay from flights.
# 

# 
# 4.1 `mutate()` / `transmute()`
# 
# Let's create a smaller tibble, so everything we do fits on our screen:
# 
flights_sml <- select(flights, 
                      year:day, 
                      ends_with("delay"), 
                      distance, 
                      air_time
)
# 
# Now let's create new variables based on variables in the data set:
# 
mutate(flights_sml,
       gain = dep_delay - arr_delay,
       speed = distance / air_time * 60
)
# 
# You can even use a variable you have just created to create another one in the same call!
# 
mutate(flights_sml,
       gain = dep_delay - arr_delay,
       hours = air_time / 60,
       gain_per_hour = gain / hours
)
# 
# If you only want to keep the columns you created use `transmute()`
# 
transmute(flights,
          gain = dep_delay - arr_delay,
          hours = air_time / 60,
          gain_per_hour = gain / hours
)
# 
# You can use all typical math functions, including integer division and modulo (remainder):
# 
transmute(flights,
          dep_time,
          hour = dep_time %/% 100,
          minute = dep_time %% 100
)
# 
# 4.2 `mutate()` / `transmute()` exercises
# 
# 1.  Currently dep_time and sched_dep_time are convenient to look at, but hard to compute with because they're not really continuous numbers. Convert them to a more convenient representation of number of minutes since midnight.
# 

# 
# 2.  Find the 10 most delayed flights using a ranking function. How do you want to handle ties? Carefully read the documentation for min_rank().
# 

# 
# 5.1 `summarise()`
# 
summarise(flights, delay = mean(dep_delay, na.rm = TRUE))
# 
# 6.1 `group_by()`
# 
by_day <- group_by(flights, year, month, day)
summarise(by_day, delay = mean(dep_delay, na.rm = TRUE))
# 
flights  |>
  group_by(year, month, day) |>
  summarise(delay = mean(dep_delay, na.rm = TRUE))
# 
flights  |>
  group_by(year, month, day) |>
  summarise(delay = mean(dep_delay, na.rm = TRUE, .groups = "drop"))
# 
flights |> 
  group_by(origin, carrier) |> 
  summarise(count = n()) |> 
  mutate(prop_per_airport = count / sum(count)) |>
  arrange(-prop_per_airport)
# 
# 7.1 `across()`
# 
flights  |>
  group_by(origin) |>
  summarise(
    across(
      c(dep_delay, arr_delay),
      .fns = list(
        mean = \(x) mean(x, na.rm = T), 
        min = \(x) min(x, na.rm = T),
        max = \(x) max(x, na.rm = T)
        )
      ),
    scheduled_flights = n(),
    cancelled = sum(is.na(dep_time))
    ) |>
  mutate(
    prop_cancelled = cancelled / scheduled_flights)


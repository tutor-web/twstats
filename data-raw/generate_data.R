library(twstats)
# Rebuild all pregenerated package data

library(eurostat)
eurostat_registrations <- twstats:::generate_eurostat_registrations(
    as.character(read.table('data-raw/eurostat_registrations.csv')[[1]]))
str(eurostat_registrations)

usethis::use_data(eurostat_registrations, internal = TRUE, overwrite = TRUE)

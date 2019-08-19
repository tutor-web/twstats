library(twstats)
# Rebuild all pregenerated package data

library(eurostat)
eurostat_registrations <- twstats:::generate_eurostat_registrations(
    as.character(read.table('data-raw/eurostat_registrations.csv')[[1]]))
str(eurostat_registrations)

library(pxweb)
pxweb_registrations <- twstats:::generate_pxweb_registrations(
    as.character(read.table('data-raw/pxweb_uris.csv')[[1]]))
str(pxweb_registrations)

usethis::use_data(
    eurostat_registrations,
    pxweb_registrations,
    internal = TRUE, overwrite = TRUE)

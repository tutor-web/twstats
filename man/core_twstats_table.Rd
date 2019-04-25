\name{datastore}
\alias{twstats_get_table}
\alias{twstats_find_tables}

\title{TWStats table-finding functions}
\description{
    Main functions for searching and retrieving tables
}

\usage{
    twstats_get_table(required_name)
    twstats_find_tables(
        required_columns = NULL,
        required_rowcount = NULL,
        previous_tables = c())
}

\arguments{
    \item{required_name}{
        Name of the table you want to read, e.g. \code{'eurostat/tin00073/BE'}
    }
    \item{required_columns}{
        Column types your table should have, e.g. \code{'year/country/value'}
    }
    \item{required_rowcount}{
        Approximate power-of-ten rows the returned tables should have, e.g. \code{10}, \code{100}, \code{1000}.
    }
    \item{previous_tables}{
        Character vector of already-known tables, filtered from results, e.g. \code{c('eurostat/tin00073/BE', 'eurostat/tin00073/UK')}.
    }
}

\details{
Find and retrieve data from twstats.
}

\value{
\code{twstats_get_table} returns a \code{\link{twstats_table}} object, or an error if nothing can be found.

\code{twstats_find_tables} returns a character vector of all matching table names.
}

\examples{\dontrun{
# Find all tables with per-country data
table_names <- twstats_find_tables('country/value')

# Get a twstats table, extract the title and data
tbl <- twstats_get_table('eurostat/tin00073/BE')
title <- tbl$title
df <- tbl$data()
}}

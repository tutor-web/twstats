\name{table}
\alias{twstats_table}

\title{TWStats table definition}
\description{
    Class definining all tables in twstats
}

\usage{
    twstats_table(name, title, columns, rowcount, data)
}

\arguments{
    \item{name}{
        A string uniquely naming the table, e.g. \code{'eurostat/tin00073/BE'}.
    }
    \item{title}{
        A string title for the table
    }
    \item{columns}{
        A slash-separated string describing the columns in the table, e.g. \code{'year/country/value'}.

        Possible values are:
        \enumerate{
            \item \bold{year} A column of years, e.g. \code{2008}.
            \item \bold{country} A column of country codes, e.g. \code{IS}, \code{UK}.
            \item \bold{value} An arbitary numeric value. The data will have a more descriptive name, e.g. "Households".
            \item \bold{perc} A percentage.
        }
    }
    \item{rowcount}{
        Approximate power-of-ten rows the returned tables should have, e.g. \code{10}, \code{100}, \code{1000}.
    }
    \item{data}{
        A function that returns a \code{data.frame}-like object matching the restrictions.
    }
}

\value{
A \code{twstats} object.
}

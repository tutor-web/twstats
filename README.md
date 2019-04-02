# twstats: Fetch random table data for use in questions / examples

## Prerequisites

To install eurostat:

```
apt install \
    libudunits2-dev libcurl4-openssl-dev libssl-dev libgdal-dev \
    r-cran-nlme # Newer NLME requires R 3.4, not in Debian stretch
```

## Quickstart: Building a question

1. Use ``twstats_find_tables`` to search for tables you can use:

```
twstats_tables <- twstats_find_tables(
    required_columns = 'year/country/value',
    required_rowcount = 10)
```

...will search for any tables with year / country / value columns, and have
approximately 10s of rows in it.

2. Hard-code that list to the question code. Set ``TW:PERMUTATIONS`` to the length of
this list:

```
# TW:PERMUTATIONS=3

twstats_tables <- c(
    'eurostat/tin00073/2015',
    'eurostat/tin00073/2016',
    . . .)
```

3. Fetch table according to the permutation

```
question <- function(permutation, data_frames) {
    t <- twstats_get_table(twstats_tables[[permutation]])
    . . .
}
```

## Quickstart: Updating a question with new data

To update a question, you need to preserve the order of existing tables in ``twstats_tables`` to ensure questions don't change.
Provide the existing list with ``previous_tables``, which will filter then from the result:

```
twstats_find_tables('year/country/value', required_rowcount = 10,
    previous_tables = twstats_tables)
```

## Methods: twstats_find_tables

Find tables that match a pattern.

```
twstats_find_tables(required_columns, required_rowcount = NULL, previous_tables = c())
```

* required_columns: A glob of '/' separated column types the table should have, possible types are:
  * year: Year of data, e.g. ``2007``
  * country: Country-code, e.g. ``AT``, ``CZ``.
  * value: A numeric value
  * perc: A percentage value
* required_rowcount: An approximate power-of-10 count of rows the table should have. For example, for the same dataset:
  * ``10`` could return data for one or two countries at random.
  * ``100`` could return data for all countries in the dataset.
* previous_tables: If supplied, filter these tables from the output

Returns a vector of table IDs, e.g. ``c('eurostat/tin00073/2015', 'eurostat/tin00073/2016')``.

### TODO:

* Do we need to select tables by a theme (say employment/roads/broadband), or country (e.g. all datasets for the UK)?

## Methods: twstats_get_table

Fetch a table ID returned from ``twstats_find_tables``.

```
twstats_get_table(table_id)
```

For example, ``twstats_get_table('eurostat/tin00073/2007')`` would return:

```
list(
    title = "Households with broadband access",
    unit = "Households",
    source = '<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=tin00073&lang=en">Eurostat</a>',
    data = data.frame(
        year = c('2007', ...),
        country = c('AT', ...),
        value = c(22, ...)))
```

### TODO:

* Do we need to have another function to, e.g. select the tables from the list that are from a particular year or country, so a student could choose a country (or countries) of interest?
* ``source`` should be HTML to embed the link into the page.

## Adding sources to twstats

Sources can be regstered with the following:

```
twstats_register_source('eurostat/tin00073/2015',
    columns = 'year/country/value',
    rowcount = 100,
    data = {
        d <- get_eurostat('tin00073')
        list(
            title = ...
            data = d)
    })
```

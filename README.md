# twstats: Fetch random table data for use in questions / examples

## Prerequisites

Any dependencies of twstats will be installed as you install the package,
however the data packages it understands will not be installed automatically.

### Eurostat

Eurostat requires nlme, which isn't available on CRAN for the version of R in Debian stable.
Make sure you use the debian package instead:

```
apt install \
    libudunits2-dev libcurl4-openssl-dev libssl-dev libgdal-dev \
    r-cran-nlme # Newer NLME requires R 3.4, not in Debian stretch
```

Finally, install the package:

```
install.packages('eurostat')
```

### cbsodataR

Install the package:

```
install.packages('cbsodataR')
```

See https://cran.r-project.org/web/packages/cbsodataR/vignettes/cbsodataR.html for more information.

## Installation

You can install using devtools:

```
devtools::install_github('tutor-web/twstats')
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
    source = '<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=tin00073&lang=en">Eurostat</a>',
    data = function() { data.frame(
        year = c('2007', ...),
        country = c('AT', ...),
        value = c(22, ...))) }
```

### TODO:

* Do we need to have another function to, e.g. select the tables from the list that are from a particular year or country, so a student could choose a country (or countries) of interest?

## Adding sources to twstats

Sources can be regstered with the following:

```
twstats_register_table(twstats_table('eurostat/tin00073/2015',
    columns = 'year/country/value',
    rowcount = 100,
    data = {
        d <- get_eurostat('tin00073')
        list(
            title = ...
            data = d)
    }))
```

# [https://tutor-web.github.io/](twstats): Fetch random table data for use in questions / examples

This package provides a wrapper around various sources of national statistics
to provide tables of data that match an approximate template. Whilst an
independent entity, it is primarily designed for use within the
[tutor-web](https://tutor-web.info/) LCMS, so we can generate questions based
on actual live data rather than made up examples.

This package does not attempt to try and provide a complete interface to every
data source, and is not useful if you wish to search for specific data sets on
a particular topic. The aim is to provide as many different data tables as
possible, constrained just enough that an R script can generate a question from
them.

## Prerequisites

Any dependencies of twstats will be installed as you install the package,
however the data packages it understands will not be installed automatically.
You will need to make sure at least one of the following is installed:

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

## Usage

See the [examples vignette](https://tutor-web.github.io/twstats/articles/examples.html)
for an overview of how to use the module. For reference read [the R manuals](https://tutor-web.github.io/twstats/reference/index.html).

## Acknowledgements

This project has received funding from the European Union’s Seventh Framework
Programme for research, technological development and demonstration under grant
agreement no. 825696.

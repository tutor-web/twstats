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

## Usage

See the [examples vignette](https://tutor-web.github.io/twstats/articles/examples.html)
for an overview of how to use the module. For reference read the R manuals.

### TODO:

* Do we need to select tables by a theme (say employment/roads/broadband), or country (e.g. all datasets for the UK)?

## Acknowledgements

This project has received funding from the European Union’s Seventh Framework
Programme for research, technological development and demonstration under grant
agreement no. 825696.

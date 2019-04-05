# Given a table with a country column, register a variant for each country
register_all_countries <- function (tbl, sub_rowcount) {
    # Country codes we are interested in
    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))

    filter_data_fn <- function(sel_country) {
        force(sel_country)  # NB: http://www.win-vector.com/blog/2017/02/iteration-and-closures-in-r/
        function () {
            d <- tbl$data()[country == sel_country,]
            d[,country := NULL]
            return(data.table(d))  # TODO: Why does this stop being a data.table?
        }
    }

    for (sel_country in twstat_countries$code) {
        s <- twstats_table(paste0(tbl$name, '/', sel_country),
            columns = gsub('(^|/)country', '', tbl$columns),
            rowcount = sub_rowcount,
            title = paste0(tbl$title, ' in ', twstat_countries[code == sel_country]$name),
            unit = tbl$unit,
            data = filter_data_fn(sel_country))
        twstats_register_table(s)
    }
}

twstats_register_eurostat <- function () {
    if (!require(eurostat)) {
        warning("eurostat package not available, not registering eurostat tables")
        return()
    }

    # Country codes we are interested in
    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))

    tin00073 <- twstats_table('eurostat/tin00073',
        columns = 'year/country/value',
        rowcount = 100,
        title = "Households with broadband access",
        unit = "Households",
        data = function () {
            d <- data.table::as.data.table(eurostat::get_eurostat('tin00073'))[geo %in% twstat_countries$code, c('time', 'geo', 'values')]
            d[, time := as.numeric(gsub('\\-.*', '', time))]
            data.table::setnames(d, c('year', 'country', 'value'))
            return(data.table(d))  # TODO: Why does this stop being a data.table?
        })
    twstats_register_table(tin00073)
    register_all_countries(tin00073, 10)
}
twstats_register_eurostat()

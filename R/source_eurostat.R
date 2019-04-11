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
            source = tbl$source,
            data = filter_data_fn(sel_country))
        twstats_register_table(s)
    }
}

register_country_comparisons <- function (tbl, sub_rowcount) {
    # Country codes we are interested in
    twstat_countries <- structure(eurostat::eu_countries$name, names = eurostat::eu_countries$code)

    filter_data_fn <- function(sel_countries) {
        force(sel_countries)  # NB: http://www.win-vector.com/blog/2017/02/iteration-and-closures-in-r/
        function () {
            # Get values for each country, rename value columns
            tbl_1 <- tbl$data()[country == names(sel_countries)[[1]],]
            data.table::setnames(tbl_1, gsub('^value$', names(sel_countries)[[1]], strsplit(tbl$columns, '/')[[1]]))
            tbl_1[,country := NULL]

            tbl_2 <- tbl$data()[country == names(sel_countries)[[2]],]
            data.table::setnames(tbl_2, gsub('^value$', names(sel_countries)[[2]], strsplit(tbl$columns, '/')[[1]]))
            tbl_2[,country := NULL]

            return(merge(tbl_1, tbl_2))
        }
    }

    # For all pairs of countries...
    for (sel_countries in utils::combn(twstat_countries, 2, simplify = FALSE)) {
        s <- twstats_table(paste0(tbl$name, '/', paste0(names(sel_countries), collapse = "-")),
            columns = gsub('(^|/)country(/|$)', '\\1value\\2', tbl$columns),
            rowcount = sub_rowcount,
            title = paste0(tbl$title, ' in ', paste0(sel_countries, collapse = " vs ")),
            source = tbl$source,
            data = filter_data_fn(sel_countries))
        twstats_register_table(s)
    }
}

twstats_register_eurostat <- function () {
    if (!requireNamespace('eurostat', quietly = TRUE)) {
        warning("eurostat package not available, not registering eurostat tables")
        return()
    }

    source_html <- function (id) {
        paste0('<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=', id, '&lang=en">Eurostat</a>')
    }

    # Country codes we are interested in
    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))

    tin00073 <- twstats_table('eurostat/tin00073',
        columns = 'year/country/value',
        rowcount = 100,
        title = "Households with broadband access",
        source = source_html('tin00073'),
        data = function () {
            d <- data.table::as.data.table(eurostat::get_eurostat('tin00073'))[geo %in% twstat_countries$code, c('time', 'geo', 'values')]
            d[, time := as.numeric(gsub('\\-.*', '', time))]
            data.table::setnames(d, c('year', 'country', "Households"))
            return(data.table(d))  # TODO: Why does this stop being a data.table?
        })
    twstats_register_table(tin00073)
    register_all_countries(tin00073, 10)
    register_country_comparisons(tin00073, 10)
}

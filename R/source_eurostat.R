# Given a table with a country column, register a variant for each country
register_all_countries <- function (tbl, sub_rowcount) {
    # Country codes we are interested in
    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))

    filter_data_fn <- function(sel_country) {
        force(sel_country)  # NB: http://www.win-vector.com/blog/2017/02/iteration-and-closures-in-r/
        function () {
            d <- data.table::as.data.table(tbl$data())
            d <- d[country == sel_country,]
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
            val_columns <- strsplit(tbl$columns, '/')[[1]] == 'value'

            # Get values for each country, rename value columns
            tbl_1 <- data.table::as.data.table(tbl$data())
            tbl_1 <- tbl_1[country == names(sel_countries)[[1]],]
            colnames(tbl_1)[val_columns] <- paste0(colnames(tbl_1)[val_columns], ' - ', sel_countries[[1]])
            tbl_1[,country := NULL]

            tbl_2 <- data.table::as.data.table(tbl$data())
            tbl_2 <- tbl_2[country == names(sel_countries)[[2]],]
            colnames(tbl_2)[val_columns] <- paste0(colnames(tbl_2)[val_columns], ' - ', sel_countries[[2]])
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

    for (twstats_id in names(eurostat_registrations)) {
        if (!('columns' %in% names(eurostat_registrations[[twstats_id]]))) {
            # An error, ignore it
            next()
        }

        t <- do.call(twstats_table, c(list(twstats_id), eurostat_registrations[[twstats_id]], list(
            data = function () {
                convert_eurostat_table(twstats_id)
            })))

        twstats_register_table(t)
        if (grepl('(^|/)country(/|$)', eurostat_registrations[[twstats_id]]$columns)) {
            # Register country variants too
            register_all_countries(t, 10)
            register_country_comparisons(t, 10)
        }
    }

    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))
    source_html <- function (id) {
        paste0('<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=', id, '&lang=en">Eurostat</a>')
    }
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


get_eurostat_dic_aslist <- function (x) {
    out <- eurostat::get_eurostat_dic(x)
    out <- structure(out$full_name, names=out$code_name)
    return(out)
}

convert_eurostat_table <- function (twstats_id) {
    twstat_countries <- structure(eurostat::eu_countries$name, names = eurostat::eu_countries$code)
    eurostat_unit <- get_eurostat_dic_aslist('unit')
    title_list <- eurostat::get_eurostat_toc()
    title_list <- structure(title_list$title, names=title_list$code)

    # Get all data associated
    id_parts <- strsplit(twstats_id, '/')[[1]]
    d <- eurostat::get_eurostat(id_parts[2], select_time = 'Y')
    d_title <- title_list[[id_parts[2]]]

    sub_ids <- list(sep = '/', 'eurostat', id_parts[2])
    columns <- colnames(d)

    # Convert all columns into something we know
    for (col_name in colnames(d)) {
        if (col_name == 'time') {
            # Convert a time column to a year column
            d$time <- as.numeric(gsub('\\-.*', '', d$time))
            names(d)[names(d) == 'time'] <- 'year'
            columns[columns == 'time'] <- 'year'

        } else if (col_name == 'geo') {
            # Filter out totals from any geo column
            d <- d[d$geo %in% names(twstat_countries), ]
            names(d)[names(d) == 'geo'] <- 'country'
            columns[columns == 'geo'] <- 'country'

        } else if (col_name == 'sex') {
            # Discard any sex column totals
            d <- d[!(d$sex %in% c('T', 'DIFF', 'NAP')),]

        } else if (col_name == 'unit') {
            # Filter table by any selected unit
            if (length(levels(d$unit)) == 1) {
                # Only one unit, select it
                sel_unit <- levels(d$unit)[[1]]
            } else {
                sel_unit <- gsub('^unit:', '', id_parts[startsWith(id_parts, 'unit:')])
            }
            if (length(sel_unit) > 0) {
                d <- d[d$unit == sel_unit[1], !(colnames(d) == 'unit')]
                names(d)[names(d) == 'values'] <- eurostat_unit[[sel_unit[1]]]
                d_title <- c(d_title, eurostat_unit[[sel_unit[1]]])
            } else {
                # Add units to list of potential IDs
                sub_ids <- c(sub_ids, list(paste0("unit:", levels(d$unit))))
            }
            columns <- columns[columns != col_name]

        } else if (col_name == 'values') {
            # Values should have been renamed by the unit column
            columns[columns == 'values'] <- ifelse(startsWith(sel_unit, 'PC_'), 'perc', 'value')

        } else if (length(levels(d[[col_name]])) == 1) {
            # Column only has one level (indic_*, e.g.), ignore it.
            d <- d[,!(colnames(d) == col_name)]
            columns <- columns[columns != col_name]

        } else if ("TOTAL" %in% levels(d[[col_name]])) {
            stop("Unknown column (with total) ", col_name)
            # Use total from whatever value this is
            d <- d[,!(colnames(d) == col_name)]
            columns <- columns[columns != col_name]

        } else {
            stop("Unknown column ", col_name)
        }
    }

    sub_ids <- do.call(paste, sub_ids)
    attr(d, 'sub_ids') <- sub_ids[sub_ids != twstats_id]
    attr(d, 'title') <- paste(d_title, collapse = ', ')
    attr(d, 'columns') <- paste0(columns, collapse = '/')
    attr(d, 'source') <- paste0('<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=', id_parts[2], '&lang=en">Eurostat</a>')
    return(d)
}


generate_eurostat_registrations <- function (eurostat_codes) {
    eurostat_registrations <- list()

    for (ec in eurostat_codes) {
        twstats_id <- paste0('eurostat/', ec)
        tbl <- tryCatch({
            d <- convert_eurostat_table(twstats_id)
            if (length(attr(d, 'sub_ids')) > 0) {
                # TODO: Register all sub_ids
                d <- convert_eurostat_table(attr(d, 'sub_ids')[[1]])
            } else {
                eurostat_registrations[[twstats_id]] <- list(
                    columns = attr(d, 'columns'),
                    rowcount = 10 ^ round(log10(nrow(d))),
                    title = attr(d, 'title'),
                    source = attr(d, 'source'))
            }
        }, error = function (e) {
            eurostat_registrations[[twstats_id]] <- list(
                message = e$message)
        })
    }

    return(eurostat_registrations)
}

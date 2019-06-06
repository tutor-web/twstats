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
            columns = paste0(gsub('(^|/)country(/|$)', '\\1', tbl$columns), '/value', collapse = '/'),
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
            data = substitute(function () {
                convert_eurostat_table(twstats_id)
            }, list(twstats_id = twstats_id)))))

        twstats_register_table(t)
        if (grepl('(^|/)country(/|$)', eurostat_registrations[[twstats_id]]$columns)) {
            # Register country variants too
            register_country_comparisons(t, 10)
        }
    }

    twstat_countries <- data.table(rbind(eurostat::eu_countries, eurostat::efta_countries))
    source_html <- function (id) {
        paste0('<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=', id, '&lang=en">Eurostat</a>')
    }
}


get_eurostat_dic_aslist <- memoise::memoise(function (x) {
    out <- eurostat::get_eurostat_dic(x)
    out <- structure(out$full_name, names=out$code_name)
    return(out)
})


paste0_if_nonempty <- function (...) {
    for (x in list(...)) {
        if (length(x) == 0) return(character(0))
    }
    return(paste0(...))
}


convert_eurostat_table <- function (twstats_id) {
    all_countries <- c(eurostat::eu_countries$code, eurostat::efta_countries$code)
    # NB: There is no clean definition of EU codes. eurostat/country_list.R
    # doesn't parse the table for us since it's incomplete and wrong.
    # Just get the most useful definitions
    all_areas <- c('EA', 'EU')
    eurostat_geo <- get_eurostat_dic_aslist('geo')
    eurostat_unit <- get_eurostat_dic_aslist('unit')
    title_list <- eurostat::get_eurostat_toc()
    title_list <- structure(title_list$title, names=title_list$code)

    # Get all data associated
    id_parts <- strsplit(twstats_id, '/')[[1]]
    if (length(id_parts) < 2) {
        stop("Not enough id_parts: ", twstats_id)
    }
    d <- eurostat::get_eurostat(id_parts[2], select_time = 'Y')
    d_title <- title_list[[id_parts[2]]]

    sub_ids <- character(0)
    columns <- colnames(d)
    sel_unit <- ''

    # Convert all columns into something we know
    for (col_name in colnames(d)) {
        if (col_name == 'time') {
            # Convert a time column to a year column
            d$time <- as.numeric(gsub('\\-.*', '', d$time))
            names(d)[names(d) == 'time'] <- 'year'
            columns[columns == 'time'] <- 'year'

        } else if (col_name == 'geo') {
            # Filter out totals from any geo column
            sel_geo <- gsub('^(country|area):', '', id_parts[startsWith(id_parts, 'country:') | startsWith(id_parts, 'area:')])
            if (length(sel_geo) > 0) {
                d <- d[d$geo == sel_geo, !(colnames(d) == 'geo')]
                d_title <- c(d_title, eurostat_geo[[sel_geo]])
                columns <- columns[columns != col_name]
            } else {
                sub_ids <- c(sub_ids, paste0_if_nonempty("area:", intersect(levels(d$geo), all_areas)))
                avail_countries <- intersect(levels(d$geo), all_countries)
                sub_ids <- c(sub_ids, paste0_if_nonempty("country:", avail_countries))
                d <- d[d$geo %in% all_countries, ]
                names(d)[names(d) == 'geo'] <- 'country'
                columns[columns == 'geo'] <- 'country'
            }

        } else if (col_name == 'sex') {
            if (length(levels(d$sex)) > 1) {
                # Discard any sex column totals
                d <- d[!(d$sex %in% c('T', 'DIFF', 'NAP')),]
            }

        } else if (col_name == 'unit') {
            # Filter table by any selected unit
            if (length(levels(d$unit)) == 1) {
                # Only one unit, select it
                sel_unit <- levels(d$unit)[[1]]
            } else {
                sel_unit <- gsub('^unit:', '', id_parts[startsWith(id_parts, 'unit:')])
            }

            if (length(sel_unit) > 0) {
                # Select given unit
                d <- d[d$unit == sel_unit, !(colnames(d) == 'unit')]
                names(d)[names(d) == 'values'] <- eurostat_unit[[sel_unit[1]]]
                d_title <- c(d_title, eurostat_unit[[sel_unit[1]]])
            } else {
                # Multiple-unit tables are meaningless, but their sub_ids aren't
                sub_ids <- c(sub_ids, paste0_if_nonempty("unit:", levels(d$unit)))
                return(structure(NA, sub_ids = paste(twstats_id, sub_ids, sep = '/')))
            }
            columns <- columns[columns != col_name]

            if (isTRUE(startsWith(sel_unit, 'PC_') || sel_unit == 'PC')) {
                columns[columns == 'values'] <- 'perc'
            }

        } else if (col_name == 'values') {
            # Values should have been renamed by the unit column

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

    # Rename any remaining "values" columns
    columns[columns == 'values'] <- 'value'

    # Order columns alphabetically, value/perc on end
    ordering <- order(gsub('^(value|perc)$', 'zzzz\1', columns), method = "shell")
    columns <- columns[ordering]
    data.table::setcolorder(d, ordering)

    if (length(sub_ids) > 0) {
        sub_ids <- paste(twstats_id, sub_ids, sep = '/')
    }
    attr(d, 'id') <- twstats_id
    attr(d, 'sub_ids') <- sub_ids[sub_ids != twstats_id]
    attr(d, 'title') <- paste(d_title, collapse = ', ')
    attr(d, 'columns') <- paste0(columns, collapse = '/')
    attr(d, 'source') <- paste0('<a href="http://appsso.eurostat.ec.europa.eu/nui/show.do?dataset=', id_parts[2], '&lang=en">Eurostat</a>')
    return(d)
}


generate_eurostat_registrations <- function (eurostat_codes) {
    out <- list()

    add_table <- function (d) {
        if (length(d) > 0 && !is.na(d) && nrow(d) > 0) {
            out[[attr(d, 'id')]] <<- list(
                columns = attr(d, 'columns'),
                rowcount = 10 ^ round(log10(nrow(d))),
                title = attr(d, 'title'),
                source = attr(d, 'source'))
        }

        for (sub_id in attr(d, 'sub_ids')) {
            add_table(convert_eurostat_table(sub_id))
        }
    }

    for (ec in eurostat_codes) {
        twstats_id <- paste0('eurostat/', ec)
        tbl <- tryCatch({
            add_table(convert_eurostat_table(twstats_id))

        }, error = function (e) {
            out[[twstats_id]] <- list(
                message = e$message)
        })
    }

    return(out)
}

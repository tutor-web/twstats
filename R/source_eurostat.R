twstats_register_eurostat <- function () {
    if (!requireNamespace('eurostat', quietly = TRUE)) {
        warning("eurostat package not available, not registering eurostat tables")
        return()
    }

    for (r in eurostat_registrations) {
        if (!('columns' %in% names(r))) {
            # An error, ignore it
            next()
        }

        data_fn <- substitute(function () {
            convert_eurostat_table(x)
        }, list(x = r$name))

        t <- do.call(twstats_table, c(
            r,
            list(data = data_fn)))

        twstats_register_table(t)
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
    sel_geo <- c()

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
            if (length(sel_geo) == 2) {
                d <- d[d$geo %in% sel_geo, ]  # NB: Don't remove geo column yet, need to combine once values are sorted out
                d_title <- c(d_title, paste0(eurostat_geo[sel_geo], collapse = "-"))
            } else if (length(sel_geo) == 1) {
                d <- d[d$geo == sel_geo, !(colnames(d) == 'geo')]
                d_title <- c(d_title, eurostat_geo[[sel_geo]])
                columns <- columns[columns != col_name]
            } else {
                sub_ids <- c(sub_ids, paste0_if_nonempty("area:", intersect(levels(d$geo), all_areas)))
                avail_countries <- intersect(levels(d$geo), all_countries)
                sub_ids <- c(sub_ids, paste0_if_nonempty("country:", avail_countries))

                if (length(avail_countries) > 2) {
                    # Include country-combinations
                    sub_ids <- c(sub_ids, utils::combn(avail_countries, 2, function (x) { paste0('country:', x, collapse = "/") }))
                }

                d <- d[d$geo %in% all_countries, ]
                names(d)[names(d) == 'geo'] <- 'country'
                columns[columns == 'geo'] <- 'country'
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

        } else if (col_name == 'values') {
            # Values get renamed last, once any unit column is processed.

        } else if (length(levels(d[[col_name]])) == 1) {
            # Column only has one level (indic_*, e.g.), ignore it.
            d <- d[,!(colnames(d) == col_name)]
            columns <- columns[columns != col_name]

        } else if (col_name == 'sex') {
            if (length(levels(d$sex)) > 1) {
                # Discard any sex column totals
                d <- d[!(d$sex %in% c('T', 'DIFF', 'NAP')),]
            }

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
    columns[columns == 'values'] <- ifelse(isTRUE(startsWith(sel_unit, 'PC_') || sel_unit == 'PC'), 'perc', 'value')
    names(d)[names(d) == 'values'] <- ifelse(sel_unit == '', 'value', eurostat_unit[[sel_unit[1]]])

    # Combine any country comparisons into multiple columns
    if (length(sel_geo) == 2) {
        val_columns <- (columns == 'value' | columns == 'perc')

        table_part <- function (tbl, sel_cty) {
            colnames(tbl)[val_columns] <- paste0(colnames(tbl)[val_columns], ' - ', sel_cty)
            return(tbl[tbl$geo == sel_cty, !(colnames(tbl) == 'geo')])
        }

        d <- merge(table_part(d, sel_geo[[1]]), table_part(d, sel_geo[[2]]))
        columns <- c(columns, columns[val_columns])
        columns <- columns[columns != 'geo']
    }

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
    out <- new.env()

    add_table <- function (d) {
        if (length(d) > 0 && !is.na(d) && nrow(d) > 0) {
            assign(attr(d, 'id'), list(
                name = attr(d, 'id'),
                columns = attr(d, 'columns'),
                rowcount = 10 ^ round(log10(nrow(d))),
                title = attr(d, 'title'),
                source = attr(d, 'source')), envir = out)
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
            cat("****** ", ec, ":", e$message, " ******\n")
            assign(twstats_id, list(
                name = twstats_id,
                message = e$message), envir = out)
        })
    }

    return(mget(ls(out), envir = out))
}

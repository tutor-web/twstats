twstats_register_pxweb <- function () {
    if (!requireNamespace('pxweb', quietly = TRUE)) {
        warning("pxweb package not available, not registering pxweb tables")
        return()
    }

    # Make a memoised version, to lessen data loads
    tmp_path <- tempfile(fileext = ".twstats_pxweb")
    dir.create(tmp_path)

    for (r in pxweb_registrations) {
        if (!('columns' %in% names(r))) {
            # An error, ignore it
            next()
        }

        data_fn <- substitute(memoise::memoise(function () {
            fetch_pxweb_table(x)
        }, cache = memoise::cache_filesystem(tmp_path)), list(x = r))

        t <- do.call(twstats_table, list(
             name = r$name,
             title = r$title,
             source = r$source,
             columns = r$columns,
             data = data_fn))

        twstats_register_table(t)
    }
}


fetch_pxweb_table <- function (r) {
    tbl <- pxweb::pxweb_get(r$px_uri, pxweb::pxweb_query(r$px_query))
    r$output_cols[r$output_cols == '**value**'] <- tbl$columns[[length(tbl$columns)]]$text
    return(as.data.frame(tbl)[, r$output_cols])
}


generate_pxweb_registrations <- function (uris) {
    out <- new.env()

    # Shrink URI whilst keeping it unique
    short_name <- function (uri) {
        uri <- gsub(
            '^https?://(.*?):?\\d*/.*/api/v1/en/', '\\1/',
            uri,
            perl = TRUE)
        uri <- gsub('/', '_', uri, fixed = TRUE)
        return(uri)
    }

    # Turn a API URI to a pxweb UI link
    api_to_ui <- function (uri) {
        parts <- strsplit(uri, '/api/v1/en/')[[1]]
        m <- regmatches(uri, regexec('(.*?)/api/v1/([^/]+)/([^/]+)/(.*)/([^/]+\\.px)', uri))[[1]]
        if (length(m) > 0) {
            return(paste(
                m[[2]],  # URL root
                'pxweb',
                m[[3]],  # Language
                m[[4]],  # Database (i.e. first part of path)
                gsub('/', '__', paste(m[[4]], m[[5]], sep = '/'), fixed = TRUE),  # Path to file
                m[[6]],
                sep = '/'))
        }
        return(uri)
    }

    add_registration <- function (px_uri, meta = pxweb::pxweb_get(px_uri), px_query = list(), descend = TRUE) {
        columns <- c()
        output_cols <- c()
        name <- c('pxweb', short_name(px_uri))
        title <- meta$title
        re_total <- 'total|both|^whole country$|^men and women$'

        # Iterate over columns, assume english names are reasonably consistent
        for (v in meta$variables) switch(gsub('^gender$', 'sex', tolower(v$text)),
            year = {
                columns <- c(columns, 'year')
                output_cols <- c(output_cols, v$text)
                px_query[[v$code]] <- '*'  # Fetch all years
            },
            period = {
                columns <- c(columns, 'year')
                output_cols <- c(output_cols, v$text)
                px_query[[v$code]] <- '*'  # Fetch all periods, call them years
            },
            sex = {
                if (is.null(px_query[[v$code]])) {
                    columns <- c(columns, 'sex')
                    output_cols <- c(output_cols, v$text)
                    # Remove any total from output
                    px_query[[v$code]] <- v$values[!grepl(re_total, v$valueTexts, ignore.case = TRUE, perl = TRUE)]

                    if (descend) {
                        # Add the total sub-table too
                        sub_query <- px_query
                        sub_query[[v$code]] <- 'total'
                        add_registration(px_uri, meta, sub_query, descend = FALSE)
                    }
                } else if (identical(px_query[[v$code]], 'total')) {
                    # Select total column in output
                    # NB: We're doing the inverse of below and adding to name for backward-compatibility
                    px_query[[v$code]] <- v$values[grepl(re_total, v$valueTexts, ignore.case = TRUE, perl = TRUE)]
                    name <- c(name, paste(v$code, 'total', sep = ":"))
                    title <- paste(title, v$valueText[v$values == px_query[[v$code]]], sep = ", ")
                }
            },
            {  # default
                tot_column <- grep(re_total, v$valueTexts, ignore.case = TRUE, value = FALSE)[1]
                tot_value <- v$values[tot_column]

                if (is.na(tot_column)) {
                    # No total, choose first value arbitrarily (we could choose all, but the combinatorial explosion takes too long)
                    px_query[[v$code]] <- v$values[1]
                    name <- c(name, paste(v$code, px_query[[v$code]], sep = ":"))
                    title <- paste(title, v$valueText[v$values == px_query[[v$code]]], sep = ", ")
                } else if (is.null(px_query[[v$code]])) {
                    # No explicit selection, select total if there is one
                    for (sub_v in v$values) {
                        if (sub_v == tot_value) {
                            # This is the total column, and the "default", not a sub-table
                            px_query[[v$code]] <- sub_v
                        } else if (descend) {
                            # Non-total column, and we're not already a sub-table, add it as a sub-table
                            sub_query <- px_query
                            sub_query[[v$code]] <- sub_v
                            add_registration(px_uri, meta, sub_query, descend = FALSE)
                        }
                    }
                } else {
                    # Add note of selection to title, if it's not the total
                    if (px_query[[v$code]] != tot_value) {
                        name <- c(name, paste(v$code, px_query[[v$code]], sep = ":"))
                        title <- paste(title, v$valueText[v$values == px_query[[v$code]]], sep = ", ")
                    }
                }
            }
        )

        # Check the resulting query is valid
        inv_err <- tryCatch({
            pxweb::pxweb_validate_query_with_metadata(pxweb::pxweb_query(px_query), meta)
            NULL
        }, error = function (e) e)

        if (is.null(inv_err)) {
            # We don't know anything about the value until the data is fetched.
            # assume there's one column and sort it out afterwards.
            columns <- c(columns, 'value')
            output_cols <- c(output_cols, '**value**')
            ordering <- order(gsub('^(value|perc)$', 'zzzz\1', columns), method = "shell")
            name <- paste(name, collapse = "/")

            assign(name, list(
                name = name,
                px_uri = px_uri,
                px_query = px_query,
                columns = paste0(columns[ordering], collapse = '/'),
                output_cols = output_cols[ordering],
                source = paste0('<a href="', api_to_ui(px_uri), '">PX-Web</a>'),
                title = title), envir = out)
        } else {
            # Not a valid query (e.g. we didn't find a total column), so don't add it.
            name <- paste(name, collapse = "/")

            assign(name, list(
                name = name,
                message = inv_err), envir = out)
        }
    }

    for (px_uri in uris) {
        if(nchar(px_uri) > 0) add_registration(px_uri)
    }

    return(mget(ls(out), envir = out))
}

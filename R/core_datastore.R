# Internal data.table holding all registrations
twregistry <- new.env(parent = emptyenv())

# Add a new table(s) to the data.table
twstats_register_table <- function (new_table) {
    if (exists(new_table$name, envir = twregistry)) {
        stop("A table named ", new_table$name, " already exists")
    }
    assign(new_table$name, new_table, envir = twregistry)

    return(invisible(NULL))
}


# Fetch table object for a table
twstats_get_table <- function (required_name) {
    rv <- get(required_name, envir = twregistry)
    return(rv)
}


# Search data.table for one that matches columns
twstats_find_tables <- function (required_columns = NULL, required_rowcount = NULL, previous_tables = c()) {
    cond <- TRUE

    twtables <- data.table::rbindlist(lapply(twregistry, function (x) {
        x[c('name', 'columns', 'rowcount')]
    }))

    # Add an extra condition to the input
    add_condition <- function (extra, negate = FALSE) {
        if (isTRUE(cond) & !isTRUE(negate)) {
            cond <<- extra
        } else if (isTRUE(negate)) {
            cond <<- call("&", call("(", cond), call("!", call("(", extra))) # ))
        } else {
            cond <<- call("&", call("(", cond), call("(", extra)) # ))
        }
    }

    colglob_regexp <- function (p) {
        p <- paste0("^", p, "$")
        p <- gsub("\\.", "\\\\.", p)
        p <- gsub("\\*", "[^/]*", p)
        return(p)
    }

    if (!is.null(required_rowcount)) {
        add_condition(call("==", as.symbol('rowcount'), required_rowcount))
    }

    if (!is.null(required_columns)) {
        add_condition(quote(data.table::like(columns, colglob_regexp(required_columns))))
    }

    if (length(previous_tables) > 0) {
        add_condition(call("%in%", as.symbol('name'), previous_tables), negate = TRUE)
    }
    return(twtables[eval(cond)]$name)
}

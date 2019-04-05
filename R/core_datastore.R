# Internal data.table holding all registrations
twtables <- data.table(  # NB: Has to have same columns/order as a twstats_table
    name = character(),
    title = character(),
    unit = character(),
    rowcount = numeric(),
    columns = character(),
    data = list())


# Add a new table(s) to the data.table
twstats_register_table <- function (new_table) {
    # NB: Since vector of functions aren't a thing, needs to be a list
    new_table$data <- list(new_table$data)

    # Combine new table with existing table table
    twtables <<- rbind(
        twtables,
        new_table)

    return(invisible(NULL))
}


# Fetch table object for a table
twstats_get_table <- function (required_name) {
    rv <- as.list(twtables[name == required_name])

    if (length(rv$data) != 1) {
        stop("Searching for ", required_name, " found ", length(rv$data), " tables")
    }
    rv$data <- rv$data[[1]]

    return(rv)
}


# Search data.table for one that matches columns
twstats_find_tables <- function (required_columns = NULL, required_rowcount = NULL, previous_tables = c()) {
    cond <- TRUE

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

    if (!is.null(required_rowcount)) {
        add_condition(call("==", as.symbol('rowcount'), required_rowcount))
    }

    # TODO: glob2rx doesn't respect path slashes
    if (!is.null(required_columns)) {
        add_condition(quote(data.table::like(columns, glob2rx(required_columns))))
    }

    if (length(previous_tables) > 0) {
        add_condition(call("%in%", as.symbol('name'), previous_tables), negate = TRUE)
    }
    return(twtables[eval(cond)])
}

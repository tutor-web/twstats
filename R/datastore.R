library(data.table)


# Internal data.table holding all registrations
twstats_table <- data.table(
    name = character(),
    title = character(),
    unit = character(),
    rowcount = numeric(),
    columns = character(),
    data = list())


# Add a new source to the data.table
twstats_register_source <- function (name, title, columns, unit, rowcount, data) {
    # Turn expression into a function that returns that expression
    to_function <- function (x) { as.function(alist(x)) }

    check_scalar <- function (x) {
        if (length(x) != 1) {
            stop("Input ", deparse(match.call()[[2]]), " does not have length 1");
        }
        return(x)
    }
    # TODO: Check format of columns?

    # Combine new source with existing source table
    extra_rows <- data.table(
        # NB: These have to match the order of the existing table
        name = check_scalar(name),
        title = check_scalar(title),
        unit = check_scalar(unit),
        rowcount = check_scalar(rowcount),
        columns = check_scalar(columns),
        data = to_function(data))
    twstats_table <<- rbindlist(list(twstats_table, extra_rows))

    return(invisible(NULL))
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
        add_condition(call("%like%", as.symbol('columns'), glob2rx(required_columns)))
    }

    if (length(previous_tables) > 0) {
        add_condition(call("%in%", as.symbol('name'), previous_tables), negate = TRUE)
    }
    
    return(twstats_table[eval(cond)])
}

# Fetch data for a table
twstats_get_table <- function (required_name) {
    # TODO: What if <> 1 results?
    rv <- as.list(twstats_table[name == required_name])

    # Call data function, replace with results
    rv$data <- rv[['data']][[1]]()

    return(rv)
}

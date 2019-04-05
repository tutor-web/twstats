# Create a twstats table
twstats_table <- function (name, title, columns, unit, rowcount, data) {
    # Turn expression into a function that returns that expression
    to_function <- function (x) {
        return(x)  # TODO: Do we really need it?
        # Check whether x is a function, without parsing x
        str(deparse(alist(x)[[1]])[[1]])
        if (grepl("^function", deparse(alist(x)[[1]])[[1]])) {
            return(x)
        } else {
            as.function(alist(x))
        }
    }

    check_function <- function (x) {
        if (!is.function(x)) {
            stop(deparse(match.call()[[2]]), " is not a function")
        }
        return(x)
    }

    check_scalar <- function (x) {
        if (length(x) != 1) {
            stop("Input ", deparse(match.call()[[2]]), " does not have length 1");
        }
        return(x)
    }
    # TODO: Check format of columns?

    # TODO: Give it a class?
    return(list(
        # NB: These have to match the order of the existing table
        name = check_scalar(name),
        title = check_scalar(title),
        unit = check_scalar(unit),
        rowcount = as.numeric(check_scalar(rowcount)),
        columns = check_scalar(columns),
        data = check_function(data)))
}

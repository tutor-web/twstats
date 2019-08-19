# Create a twstats table
twstats_table <- function (name, title, source, columns, rowcount = 0, data) {
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

    # TODO: Give it a class?
    return(list(
        # NB: These have to match the order of the existing table
        name = check_scalar(name),
        title = check_scalar(title),
        source = check_scalar(source),
        rowcount = as.numeric(check_scalar(rowcount)),
        columns = check_scalar(columns),
        data = check_function(data)))
}

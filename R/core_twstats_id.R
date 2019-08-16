parse_twstats_id <- function (twstats_id) {
    id_parts <- strsplit(strsplit(twstats_id, '/', fixed = TRUE)[[1]], ':', fixed = TRUE)

    # First 2 parts don't have a name
    if (length(id_parts) < 2) {
        stop("Not enough id_parts: ", twstats_id)
    }
    id_parts[[1]] <- c('class', id_parts[[1]])
    id_parts[[2]] <- c('source', id_parts[[2]])

    # Group id_parts by first element (i.e. name)
    id_names <- lapply(id_parts, function (x) x[1])
    id_levels <- unique(id_names)

    # For each level, extract matching items, strip their name and join them together
    lapply(structure(id_levels, names = id_levels), function (lvl) vapply(
        id_parts[id_names == lvl],
        function (x) x[seq(2, length(x))],
        character(1)))
}

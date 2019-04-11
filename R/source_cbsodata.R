twstats_register_cbsodatar <- function () {
    if (!requireNamespace('cbsodataR', quietly = TRUE)) {
        warning("cbsodataR package not available, not registering cbsodataR tables")
        return()
    }

    source_html <- function (id) {
        paste0('<a href="https://opendata.cbs.nl/statline/#/CBS/en/dataset/', id, '/table">opendata.cbs.nl</a>')
    }

    # Make a memoised version, to lessen data loads
    tmp_path <- tempfile(fileext = ".twstats_cbso")
    dir.create(tmp_path)
    cached_cbs_get_data <- memoise::memoise(cbsodataR::cbs_get_data, cache = memoise::cache_filesystem(tmp_path))

    twstats_register_table(twstats_table('cbso/82610ENG/total',
        columns = 'year/value',
        rowcount = 10,
        title = "Total renewable energy production in the Netherlands",
        source = source_html('82610ENG'),
        data = function () {
            d <- cached_cbs_get_data('82610ENG', EnergySourcesTechniques = c("T001028 "))
            d <- cbsodataR::cbs_add_label_columns(d, 'Periods')

            data.table(
                year = as.numeric(as.character(d$Periods_label)),
                "million kWh" = d$GrossProductionOfElectricity_2)
        }))

    twstats_register_table(twstats_table('cbso/82610ENG/perc',
        columns = 'year/perc',
        rowcount = 10,
        title = "Percentage renewable energy production in the Netherlands",
        source = source_html('82610ENG'),
        data = function () {
            d <- cached_cbs_get_data('82610ENG', EnergySourcesTechniques = c("T001028 "))
            d <- cbsodataR::cbs_add_label_columns(d, 'Periods')

            data.table(
                year = as.numeric(as.character(d$Periods_label)),
                percentage = d$GrossProductionOfElectricity_5)
        }))
}

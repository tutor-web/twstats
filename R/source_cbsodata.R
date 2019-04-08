twstats_register_cbsodatar <- function () {
    if (!require(cbsodataR)) {
        warning("cbsodataR package not available, not registering cbsodataR tables")
        return()
    }

    # Make a memoised version, to lessen data loads
    tmp_path <- tempfile(fileext = ".twstats_cbso")
    dir.create(tmp_path)
    cached_cbs_get_data <- memoise::memoise(cbsodataR::cbs_get_data, cache = memoise::cache_filesystem(tmp_path))

    twstats_register_table(twstats_table('cbso/82610ENG/total',
        columns = 'year/value',
        rowcount = 10,
        title = "Total renewable energy production in the Netherlands",
        unit = "million kWh",
        data = function () {
            d <- cached_cbs_get_data('82610ENG', EnergySourcesTechniques = c("T001028 "))
            d <- cbsodataR::cbs_add_label_columns(d, 'Periods')

            data.table(
                year = as.numeric(as.character(d$Periods_label)),
                value = d$GrossProductionOfElectricity_2)
        }))

    twstats_register_table(twstats_table('cbso/82610ENG/perc',
        columns = 'year/perc',
        rowcount = 10,
        title = "Percentage renewable energy production in the Netherlands",
        unit = "percentage",
        data = function () {
            d <- cached_cbs_get_data('82610ENG', EnergySourcesTechniques = c("T001028 "))
            d <- cbsodataR::cbs_add_label_columns(d, 'Periods')

            data.table(
                year = as.numeric(as.character(d$Periods_label)),
                perc = d$GrossProductionOfElectricity_5)
        }))
}

library(unittest)

library(twstats)

cmp <- function (a, b) {
    if (identical(a, b)) return(TRUE)
    capture.output({ str(a) ; writeLines('... vs ...'); str(b) })
}

ok_group('parse_twstats_id', {
    ok(cmp(twstats:::parse_twstats_id('pxweb/fi_statfin_kuol_pxt_002/country:99IS/country:99DK'), list(
        class = "pxweb",
        source = "fi_statfin_kuol_pxt_002",
        country = c("99IS", "99DK"))), "Grouped multiple entries together")
})

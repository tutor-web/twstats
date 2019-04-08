.onLoad <- function(libname, pkgname) {
    twstats_register_eurostat()
    twstats_register_cbsodatar()
}

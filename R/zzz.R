.onLoad <- function(libname, pkgname) {
    twstats_register_eurostat()
    twstats_register_cbsodatar()
    twstats_register_pxweb()
}

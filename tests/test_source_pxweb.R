library(unittest)

cmp <- function (a, b) {
    if (identical(a, b)) return(TRUE)
    capture.output({ str(a) ; writeLines('... vs ...'); str(b) })
}

ok_group('generate_pxweb_registrations', {
    regs <- twstats:::generate_pxweb_registrations("https://px.hagstofa.is:443/pxen/api/v1/en/Ibuar/mannfjoldi/3_bakgrunnur/Faedingarland/MAN12103.px")

    # Check returned tables
    ok(cmp(
        grep('MAN12103\\.px$', names(regs), value = TRUE),
        "pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px"), "Default")
    ok(cmp(
        grep('Fæðingarland:99TR', names(regs), value = TRUE),
        "pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px/Fæðingarland:99TR"), "Country subtables")
    ok(cmp(
        grep('Aldur:9', names(regs), value = TRUE),
        "pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px/Aldur:9"), "Age subtables (NB: No age *and* country)")

    # Titles
    ok(cmp(
        regs[['pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px']]$title,
        "Population by country of birth, sex and age 1 January 1998-2018"), "Total title based on table title")
    ok(cmp(
        regs[['pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px/Fæðingarland:99TR']]$title,
        "Population by country of birth, sex and age 1 January 1998-2018, Turkey"), "Include selected country for country table")
    ok(cmp(
        regs[['pxweb/px.hagstofa.is_Ibuar_mannfjoldi_3_bakgrunnur_Faedingarland_MAN12103.px/Aldur:9']]$title,
        "Population by country of birth, sex and age 1 January 1998-2018, 35\u009639 years"), "Include selected age for age table")
    
})
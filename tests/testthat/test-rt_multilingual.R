# Non-English (multilingual) conflict-of-interest and funding detection. The
# helpers run on transliterated, accent-stripped text; the tokens are
# language-distinctive and must not fire on English.

test_that(".which_spanish_coi_1 detects non-English COI phrases", {
  expect_length(rtransparent:::.which_spanish_coi_1("conflicto de interes"), 1)     # ES
  expect_length(rtransparent:::.which_spanish_coi_1("conflictos de intereses"), 1)  # ES
  expect_length(rtransparent:::.which_spanish_coi_1("conflito de interesse"), 1)    # PT
  expect_length(rtransparent:::.which_spanish_coi_1("conflitto di interessi"), 1)   # IT
  expect_length(rtransparent:::.which_spanish_coi_1("conflit d'interets"), 1)       # FR
  expect_length(rtransparent:::.which_spanish_coi_1("declaration de liens d'interets"), 1)  # FR
  expect_length(rtransparent:::.which_spanish_coi_1("kein Interessenkonflikt besteht"), 1)  # DE
})

test_that(".which_spanish_coi_1 does not fire on English COI text", {
  expect_length(rtransparent:::.which_spanish_coi_1(
    "the authors declare a conflict of interest"), 0)
  expect_length(rtransparent:::.which_spanish_coi_1(
    "no competing interests were declared"), 0)
})

test_that(".which_multilingual_fund_1 detects non-English funding", {
  expect_length(rtransparent:::.which_multilingual_fund_1("financiado por la beca de salud"), 1)  # ES
  expect_length(rtransparent:::.which_multilingual_fund_1("foi financiado pelo CNPq"), 1)         # PT
  expect_length(rtransparent:::.which_multilingual_fund_1("finance par l'agence nationale"), 1)   # FR
  expect_length(rtransparent:::.which_multilingual_fund_1("gefordert von der DFG"), 1)            # DE
  expect_length(rtransparent:::.which_multilingual_fund_1("finanziato dal ministero"), 1)         # IT
})

test_that(".which_multilingual_fund_1 does not fire on English funding text", {
  expect_length(rtransparent:::.which_multilingual_fund_1(
    "this study was funded by the NIH"), 0)
  expect_length(rtransparent:::.which_multilingual_fund_1(
    "supported by a grant from the Wellcome Trust"), 0)
})

test_that("negate_absence_1 treats non-English no-funding as absence", {
  expect_true(rtransparent:::negate_absence_1("no hubo fuentes de financiacion externas"))  # ES
  expect_true(rtransparent:::negate_absence_1("cette etude a ete effectuee sans subvention externe"))  # FR
  expect_true(rtransparent:::negate_absence_1("es bestand keine finanzielle unterstutzung"))  # DE
  expect_true(rtransparent:::negate_absence_1("non ha ricevuto alcun finanziamento"))  # IT
})

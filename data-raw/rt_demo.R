# Builds data/rt_demo.rda: a small, simulated corpus of detector output used to
# illustrate rt_summary(), rt_score() and rt_plot() in examples and the
# vignettes. The data are SIMULATED, not real detector output; prevalences and
# their time trends are chosen to resemble published findings (high conflicts of
# interest and funding disclosure, lower protocol registration, low but rising
# data sharing, rare code sharing, and a recent, fast-rising disclosure of
# generative-AI use) so the illustrations look realistic.

set.seed(2024)

n <- 1200L
year <- sample(2010:2026, n, replace = TRUE)
type <- sample(
  c("research-article", "review-article", "systematic-review"),
  n, replace = TRUE, prob = c(0.70, 0.20, 0.10)
)

# Centered, scaled year so the logistic trends are gentle.
yr <- (year - 2017) / 4
draw <- function(intercept, slope) {
  stats::rbinom(n, 1, stats::plogis(intercept + slope * yr)) == 1L
}

# Disclosure of generative-AI use in manuscript preparation did not exist as a
# practice before 2023, so it is only evaluated for 2023 onward (NA earlier),
# mirroring rt_ai_pmc()'s year gate. Among evaluated articles it is rare in 2023
# and rises quickly (about 9%, 17%, 30%, 47% across 2023-2026).
ai_yr <- (year - 2024) / 1.5
ai_raw <- stats::rbinom(n, 1, stats::plogis(-1.6 + 1.1 * ai_yr)) == 1L
is_ai_pred <- ifelse(year >= 2023, ai_raw, NA)

rt_demo <- tibble::tibble(
  pmid = sprintf("%08d", sample(20000000:39999999, n)),
  year = year,
  type = type,
  is_coi_pred         = draw( 0.9, 0.45),  # ~70-75%, rising
  is_fund_pred        = draw( 1.3, 0.30),  # ~80%
  is_register_pred    = draw(-1.1, 0.50),  # ~25%
  is_open_data        = draw(-1.8, 0.70),  # ~15-20%, rising
  is_open_code        = draw(-3.1, 0.80),  # ~5%, rising
  is_novelty_pred     = draw( 0.1, 0.10),
  is_replication_pred = draw(-2.4, 0.20),
  is_ai_pred          = is_ai_pred         # NA before 2023, then rising
)

save(rt_demo, file = "data/rt_demo.rda", version = 2)

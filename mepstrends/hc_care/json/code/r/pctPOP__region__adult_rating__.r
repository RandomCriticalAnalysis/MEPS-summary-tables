# Install and load packages
  package_names <- c("survey","dplyr","foreign","devtools")
  lapply(package_names, function(x) if(!x %in% installed.packages()) install.packages(x))
  lapply(package_names, require, character.only=T)

  install_github("e-mitchell/meps_r_pkg/MEPS")
  library(MEPS)

  options(survey.lonely.psu="adjust")

# Load FYC file
  FYC <- read.xport('C:/MEPS/.FYC..ssp');
  year <- .year.
  
  FYC <- FYC %>%
    mutate_at(vars(starts_with("AGE")),funs(replace(., .< 0, NA))) %>%
    mutate(AGELAST = coalesce(AGE.yy.X, AGE42X, AGE31X))

  FYC$ind = 1

# Rating for care (adults)
  FYC <- FYC %>%
    mutate(
      adult_rating = as.factor(case_when(
        .$ADHECR42 >= 9 ~ "9-10 rating",
        .$ADHECR42 >= 7 ~ "7-8 rating",
        .$ADHECR42 >= 0 ~ "0-6 rating",
        .$ADHECR42 == -1 ~ "Inapplicable",
        .$ADHECR42 <= -7 ~ "Don\'t know/Non-response",
        TRUE ~ "Missing")))

# Census region
  if(year == 1996)
    FYC <- FYC %>% mutate(REGION42 = REGION2, REGION31 = REGION1)

  FYC <- FYC %>%
    mutate_at(vars(starts_with("REGION")), funs(replace(., .< 0, NA))) %>%
    mutate(region = coalesce(REGION.yy., REGION42, REGION31)) %>%
    mutate(region = recode_factor(region, .default = "Missing", .missing = "Missing", 
      "1" = "Northeast",
      "2" = "Midwest",
      "3" = "South",
      "4" = "West"))

SAQdsgn <- svydesign(
  id = ~VARPSU,
  strata = ~VARSTR,
  weights = ~SAQWT.yy.F,
  data = FYC,
  nest = TRUE)

results <- svyby(~adult_rating, FUN=svymean, by = ~region, design = subset(SAQdsgn, ADAPPT42 >= 1 & AGELAST >= 18))
print(results)

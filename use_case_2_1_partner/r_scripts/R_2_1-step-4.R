############################ Description #############################
# Partner code for running propensity score matching to match 
# study cohort individuals with local comparison cohort individuals
#

options(scipen=999)

#library(DBI) # remove once import available
#library(RPostgres) # remove once import available
#library(odbc) # remove once import available
library(dplyr)
library(readr)
#library(mice)
library(MatchIt)


## choose partner
partner <- "kp" # edit here
# 

# edit this once import file is set
# psm_inputs <- read_csv("combined/data/psm_inputs.csv")
psm_inputs_link <- read_csv("partner_out/cohort_CC_kp.csv") # edit here for file path

# # join psm_inputs with link id
# psm_inputs_link <- left_join(psm_inputs, codi.link, by = "patid")
# length(psm_inputs_link$linkid)
# length(unique(psm_inputs_link$linkid))
# 
# # pull demo_index_flag, used CH here
# demo_index_flag <- read_csv("DCC_out/demo_CH_index_flag.csv")
# length(unique(demo_index_flag$linkid))


# TEST ONLY take out rows without match, use inner join for now 
# demo_psm_prep <- inner_join(demo_index_flag, psm_inputs_link, by = "linkid")

demo_psm_prep <- psm_inputs_link
demo_psm_prep %>% filter(index_site_flag == TRUE)


# prep seed
set.seed(1492)

# TEMP, remove when complete data available
# generate random inputs for those with complete missing
# demo_psm_prep$pat_pref_language_spoken <- sample(c(1,2,3,4,5), length(demo_psm_prep$patid), replace=T, prob=c(.2,.2,.2,.2,.2))
# demo_psm_prep$hispanic <- sample(c(FALSE,TRUE), length(demo_psm_prep$patid), replace=T, prob=c(.8,.2))
# demo_psm_prep$insurance <- sample(c("Tricare", "Public non-tricare", "Other"),
#                                      length(demo_psm_prep$patid), 
#                                      replace=T, 
#                                      prob=c(.33,.33, .33))



# filter for patid where index site matches site
demo_psm_prep_local <- demo_psm_prep %>% filter(index_site_flag == TRUE #&
                                                        #exclusion == 0
                                                )



# # impute rest of missing TEST ONLY, subject to change
# demo_psm_prep_local_i <- mice(demo_psm_prep_local, method = "cart", seed = 1492)
# demo_psm_prep_local_i_comp <- complete.mids(demo_psm_prep_local_i, 1)
# demo_psm_prep_local_i_comp$age[demo_psm_prep_local_i_comp$age < 0] <- 2

demo_psm_prep_local$race[is.na(demo_psm_prep_local$race)] <- "NULL" 
        
apply(is.na(demo_psm_prep_local), 2, which) 

#demo_psm_prep_local$bmi_percent_of_p95 <- as.numeric(demo_psm_prep_local$bmi_percent_of_p95)

# change to factor when appropriate
demo_psm_prep_local$sex <- as.factor(demo_psm_prep_local$sex)
demo_psm_prep_local$bmi <- as.numeric(demo_psm_prep_local$bmi)
demo_psm_prep_local$bmi_percent_of_p95 <- as.numeric(demo_psm_prep_local$bmi_percent_of_p95)
demo_psm_prep_local$race <- as.factor(demo_psm_prep_local$race)
demo_psm_prep_local$pat_pref_language_spoken <- as.factor(demo_psm_prep_local$pat_pref_language_spoken)
demo_psm_prep_local$hispanic <- as.factor(demo_psm_prep_local$hispanic)
demo_psm_prep_local$insurance <- as.factor(demo_psm_prep_local$insurance)


# drop factors that only have 1 factor
demo_psm_prep_local_test <- demo_psm_prep_local

# variables to check
demo_psm_prep_local_factors <- demo_psm_prep_local %>% select(ageyrs, 
                                                              sex,
                                                              acanthosis_nigricans,
                                                              Obstructive_sleep_apnea,
                                                              adhd,
                                                              anxiety,
                                                              asthma,
                                                              autism,
                                                              depression,
                                                              diabetes,
                                                              eating_disorders,
                                                              hyperlipidemia,
                                                              hypertension,
                                                              NAFLD,
                                                              Obstructive_sleep_apnea,
                                                              PCOS,
                                                              pmca,
                                                              bmi_percent_of_p95,
                                                              pat_pref_language_spoken,
                                                              race,
                                                              hispanic,
                                                              insurance
                                                              )

# identify drops
ifelse(demo_psm_prep_local_dropped <- sapply(demo_psm_prep_local_factors, 
                                             function(x) length(levels(x))) == 1, "DROP", "NODROP") 

# preserve names of variables that need to be dropped
names(demo_psm_prep_local_dropped)[demo_psm_prep_local_dropped == TRUE]

# select all variables except dropped variables
demo_psm_prep_local_test <- demo_psm_prep_local_test %>% select(-names(demo_psm_prep_local_dropped)[demo_psm_prep_local_dropped == TRUE])

# subset variables for psm only to be in formula
demo_psm_prep_local_kept <- demo_psm_prep_local_test %>% select(names(demo_psm_prep_local_dropped)[demo_psm_prep_local_dropped == FALSE])

# populate psm_input local with complete covariates, dropping BMI_percent for now, need to impute missing
# need to do for rest of sites

match.form <- as.formula(paste("in_study_cohort~", paste(names(demo_psm_prep_local_kept), collapse="+")))

#test complete case
demo_psm_prep_local_comp <- demo_psm_prep_local[complete.cases(demo_psm_prep_local),]

match.test <- matchit(match.form
                      ,
                      #data = demo_psm_prep_local_i_comp,
                      #data = demo_psm_prep_local,
                      data = demo_psm_prep_local_comp,
                      replace = FALSE,
                      method="nearest",
                      distance = "logit",
                      model = "logit",
                      caliper = 0.2,
                      ratio=4)

# match.test <- matchit(in_study_cohort ~ 
#                               ageyrs + 
#                               sex + 
#                               acanthosis_nigricans + 
#                               Obstructive_sleep_apnea + 
#                               adhd + 
#                               anxiety + 
#                               asthma + 
#                               autism + 
#                               depression + 
#                               diabetes + 
#                               eating_disorders + 
#                               hyperlipidemia + 
#                               hypertension + 
#                               NAFLD + 
#                               PCOS + 
#                               pmca + 
#                               bmi_percent_of_p95 + 
#                               race
#                       ,
#                       #data = demo_psm_prep_local_i_comp,
#                       data = demo_psm_prep_local,
#                       replace = FALSE,
#                       method="nearest",
#                       distance = "logit",
#                       model = "logit",
#                       caliper = 0.2,
#                       ratio=4)

# match.test <- matchit(in_study_cohort ~ 
#                               ageyrs + 
#                               sex + 
#                               adhd +
#                               anxiety +
#                               asthma +
#                               autism +
#                               depression +
#                               diabetes +
#                               eating_disorders +
#                               hyperlipidemia +
#                               hypertension +
#                               NAFLD +
#                               Obstructive_sleep_apnea +
#                               PCOS +
#                               pmca +
#                               #bmi_percent_of_p95 + 
#                               #pat_pref_language_spoken +
#                               race #+
#                               #hispanic + 
#                               #insurance
#                       , 
#                     #data = demo_psm_prep_local_i_comp, 
#                     data = demo_psm_prep_local,
#                     replace = FALSE,
#                     method="nearest", 
#                     distance = "logit",
#                     model = "logit",
#                     caliper = 0.2,
#                     ratio=4)

summary(match.test, verbose = T)


match.test.data <- match.data(match.test)
matched_data <- get_matches(match.test, demo_psm_prep_local_comp)
View(matched_data)

table(matched_data$in_study_cohort)

matched_data_id <- matched_data %>% select(linkid, in_study_cohort)

write_csv(matched_data_id, path = paste("partner_out/PSM_matched_data_", partner, ".csv", sep = ''))


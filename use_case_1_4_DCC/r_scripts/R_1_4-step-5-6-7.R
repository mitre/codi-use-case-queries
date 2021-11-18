
#install packages for growthcleanr
# install.packages(c("devtools", "dplyr", "data.table", "foreach", "doParallel", "Hmisc"))
# install.packages("bit64")

library(tidyr)
library(readr)
library(eeptools)

#for growthcleanr
library(devtools)
library(data.table)
library(foreach)
library(doParallel)
library(Hmisc)
library(bit64)

# install growthcleanr
devtools::install_github("carriedaymont/growthcleanr")

library(growthcleanr)

library(dplyr)

options(scipen=999)

#read csv, cohort_demographic
cohort_tract_comorb_ch <- read_csv("partner_out/cohort_tract_comorb_ch.csv", na = "NULL")

cohort_tract_comorb_dh <- read_csv("partner_out/cohort_tract_comorb_dh.csv", na = "NULL")

cohort_tract_comorb_gotr <- read_csv("partner_out/cohort_tract_comorb_gotr.csv", na = "NULL")

cohort_tract_comorb_hfc <- read_csv("partner_out/cohort_tract_comorb_hfc.csv", na = "NULL")

cohort_tract_comorb_kp <- read_csv("partner_out/cohort_tract_comorb_kp.csv", na = "NULL")

cohort_tract_comorb <- rbind(cohort_tract_comorb_ch,
                             cohort_tract_comorb_dh,
                             cohort_tract_comorb_gotr,
                             cohort_tract_comorb_hfc,
                             cohort_tract_comorb_kp)

cohort_tract_comorb %>% unique() %>% group_by(linkid) %>% arrange(linkid) %>% View()

cohort_tract_comorb_ch %>% unique() %>% arrange(linkid)

#read csv, pmca_output
pmca_output_ch <- read_csv("partner_out/pmca_output_ch.csv", na = "NULL")

pmca_output_dh <- read_csv("partner_out/pmca_output_dh.csv", na = "NULL")

pmca_output_gotr <- read_csv("partner_out/pmca_output_gotr.csv", na = "NULL")

pmca_output_hfc <- read_csv("partner_out/pmca_output_hfc.csv", na = "NULL")

pmca_output_kp <- read_csv("partner_out/pmca_output_kp.csv", na = "NULL")


# race_condition_inputs_cv
race_condition_inputs_ch <- read_csv("partner_out/race_condition_inputs_ch.csv", na = "NULL")

race_condition_inputs_dh <- read_csv("partner_out/race_condition_inputs_dh.csv", na = "NULL")

race_condition_inputs_gotr <- read_csv("partner_out/race_condition_inputs_gotr.csv", na = "NULL")

race_condition_inputs_hfc <- read_csv("partner_out/race_condition_inputs_hfc.csv", na = "NULL")

race_condition_inputs_kp <- read_csv("partner_out/race_condition_inputs_kp.csv", na = "NULL")

race_condition_inputs <- rbind(race_condition_inputs_ch,
                               race_condition_inputs_dh,
                               race_condition_inputs_gotr,
                               race_condition_inputs_hfc,
                               race_condition_inputs_kp)

race_condition_inputs$linkid <- as.numeric(race_condition_inputs$linkid)

race_condition_inputs <- race_condition_inputs %>% dplyr::rename(CNT = count, DATE = early_admit_date)


race_condition_inputs <- race_condition_inputs %>% dplyr::mutate(category_form = dplyr::case_when(
        category == "Asthma" ~ "ASTHMA",
        category == "Celiac disease" ~ "CELIAC",
        category == "Cystic fibrosis" ~ "CF",
        category == "Hypercholesterolemia" ~ "HCL",
        category == "Schizophrenia" ~ "SCZ",
        category == "Sickle-cell disease" ~ "SCD",
        category == "Spina bifida" ~ "SB"
)
)

#read csv, measures_output
measures_output_ch <- read_csv("partner_out/measures_output_ch.csv", na = "NULL")

measures_output_dh <- read_csv("partner_out/measures_output_dh.csv", na = "NULL")

measures_output_gotr <- read_csv("partner_out/measures_output_gotr.csv", na = "NULL")

measures_output_hfc <- read_csv("partner_out/measures_output_hfc.csv", na = "NULL")

measures_output_kp <- read_csv("partner_out/measures_output_kp.csv", na = "NULL")


## pull DCC saved demographics
demo_recon <- read_csv("DCC_out/demo_recon.csv", na = "NULL")

demo_recon %>% arrange(linkid) %>% View()

## pull bmiagerev
bmiagerev <- read_csv("reference/bmiagerev.csv") %>% dplyr::rename(agemos = Agemos, sex = Sex)

# save birth date and  sex only

# demo_ch <- cohort_demographic_ch %>% select(linkid, birth_date, sex) %>% unique()
# 
# demo_dh <- cohort_demographic_dh %>% select(linkid, birth_date, sex) %>% unique()
# 
# demo_gotr <- cohort_demographic_gotr %>% select(linkid, birth_date, sex) %>% unique()
# 
# demo_hfc <- cohort_demographic_hfc %>% select(linkid, birth_date, sex) %>% unique()
# 
# demo_kp <- cohort_demographic_kp %>% select(linkid, birth_date, sex) %>% unique()

# recode age and sex to growthcleanr format
# sex, 1 = female, 0 = male

demo_recon$sex[demo_recon$sex == "F"] <- 1
demo_recon$sex[demo_recon$sex == "M"] <- 0

# demo_ch$sex[demo_ch$sex == "F"] <- 1
# demo_ch$sex[demo_ch$sex == "M"] <- 0
# 
# demo_dh$sex[demo_dh$sex == "F"] <- 1
# demo_dh$sex[demo_dh$sex == "M"] <- 0
# 
# demo_gotr$sex[demo_gotr$sex == "F"] <- 1
# demo_gotr$sex[demo_gotr$sex == "M"] <- 0
# 
# demo_hfc$sex[demo_hfc$sex == "F"] <- 1
# demo_hfc$sex[demo_hfc$sex == "M"] <- 0
# 
# demo_kp$sex[demo_kp$sex == "F"] <- 1
# demo_kp$sex[demo_kp$sex == "M"] <- 0

# left join ht weights with age, sex 
measures_demo_ch <- left_join(measures_output_ch, demo_recon, by = "linkid")
measures_demo_dh <- left_join(measures_output_dh, demo_recon, by = "linkid")
measures_demo_gotr <- left_join(measures_output_gotr, demo_recon, by = "linkid")
measures_demo_hfc <- left_join(measures_output_hfc, demo_recon, by = "linkid")
measures_demo_kp <- left_join(measures_output_kp, demo_recon, by = "linkid")

# calculate age in days from birth date to measurement date
measures_demo_ch$agedays <- as.numeric(difftime(measures_demo_ch$measure_date, 
                                                measures_demo_ch$birth_date, 
                                                units = "days")) 

measures_demo_dh$agedays <- as.numeric(difftime(measures_demo_dh$measure_date, 
                                                measures_demo_dh$birth_date, 
                                                units = "days")) 

measures_demo_gotr$agedays <- as.numeric(difftime(measures_demo_gotr$measure_date, 
                                                  measures_demo_gotr$birth_date, 
                                                  units = "days")) 

measures_demo_hfc$agedays <- as.numeric(difftime(measures_demo_hfc$measure_date, 
                                                 measures_demo_hfc$birth_date, 
                                                 units = "days")) 

measures_demo_kp$agedays <- as.numeric(difftime(measures_demo_kp$measure_date, 
                                                measures_demo_kp$birth_date, 
                                                units = "days")) 




# convert height from inches to CM
measures_demo_ch$HEIGHTCM <- measures_demo_ch$ht * 2.54
measures_demo_dh$HEIGHTCM <- measures_demo_dh$ht * 2.54
measures_demo_gotr$HEIGHTCM <- measures_demo_gotr$ht * 2.54
measures_demo_hfc$HEIGHTCM <- measures_demo_hfc$ht * 2.54
measures_demo_kp$HEIGHTCM <- measures_demo_kp$ht * 2.54

# convert weight from pounds to Kg
measures_demo_ch$WEIGHTKG <- measures_demo_ch$wt * 0.45359237
measures_demo_dh$WEIGHTKG <- measures_demo_dh$wt * 0.45359237
measures_demo_gotr$WEIGHTKG <- measures_demo_gotr$wt * 0.45359237
measures_demo_hfc$WEIGHTKG <- measures_demo_hfc$wt * 0.45359237
measures_demo_kp$WEIGHTKG <- measures_demo_kp$wt * 0.45359237


# wide to long for measurement type

measures_demo_ch_long <- gather(measures_demo_ch, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key=TRUE)
measures_demo_dh_long <- gather(measures_demo_dh, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key=TRUE)
measures_demo_gotr_long <- gather(measures_demo_gotr, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key=TRUE)
measures_demo_hfc_long <- gather(measures_demo_hfc, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key=TRUE)
measures_demo_kp_long <- gather(measures_demo_kp, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key=TRUE)

# length(unique(measures_demo_ch_long$linkid))
# length(unique(measures_demo_dh_long$linkid))
# length(unique(measures_demo_gotr_long$linkid))
# length(unique(measures_demo_hfc_long$linkid))
# length(unique(measures_demo_kp_long$linkid))

# prep data tables

measures_demo_long <- rbind(measures_demo_ch_long,
                            measures_demo_dh_long,
                            measures_demo_gotr_long,
                            measures_demo_hfc_long,
                            measures_demo_kp_long)

# test unique only
measures_demo_long <- measures_demo_long %>% unique()

measures_demo_long <- as.data.table(measures_demo_long)
setkey(measures_demo_long, linkid, param, agedays)

# length(unique(measures_demo_long$linkid))

# measures_demo_ch_long <- as.data.table(measures_demo_ch_long)
# measures_demo_dh_long <- as.data.table(measures_demo_dh_long)
# measures_demo_gotr_long <- as.data.table(measures_demo_gotr_long)
# measures_demo_hfc_long <- as.data.table(measures_demo_hfc_long)
# measures_demo_kp_long <- as.data.table(measures_demo_kp_long)
# 
# setkey(measures_demo_ch_long, linkid, param, agedays)
# setkey(measures_demo_dh_long, linkid, param, agedays)
# setkey(measures_demo_gotr_long, linkid, param, agedays)
# setkey(measures_demo_hfc_long, linkid, param, agedays)
# setkey(measures_demo_kp_long, linkid, param, agedays)



# clean measurements
cleaned_measures_demo_long <- measures_demo_long[, clean_value:=
                                                         cleangrowth(linkid, param, agedays, sex, measurement,
                                                                     parallel = T)]

# cleaned_measures_demo_ch_long <- measures_demo_ch_long[, clean_value:=
#                                                                cleangrowth(linkid, param, agedays, sex, measurement,
#                                                                            parallel = T)]
# cleaned_measures_demo_dh_long <- measures_demo_dh_long[, clean_value:=
#                                                                cleangrowth(linkid, param, agedays, sex, measurement,
#                                                                            parallel = T)]
# cleaned_measures_demo_gotr_long <- measures_demo_gotr_long[, clean_value:=
#                                                                cleangrowth(linkid, param, agedays, sex, measurement,
#                                                                            parallel = T)]
# cleaned_measures_demo_hfc_long <- measures_demo_hfc_long[, clean_value:=
#                                                                cleangrowth(linkid, param, agedays, sex, measurement,
#                                                                            parallel = T)]
# cleaned_measures_demo_kp_long <- measures_demo_kp_long[, clean_value:=
#                                                                cleangrowth(linkid, param, agedays, sex, measurement,
#                                                                            parallel = T)]

# keep those marked include only

measures_demo_long_kept <- cleaned_measures_demo_long[clean_value=='Include']

# measures_demo_ch_long_kept <- cleaned_measures_demo_ch_long[clean_value=='Include']
# measures_demo_dh_long_kept <- cleaned_measures_demo_dh_long[clean_value=='Include']
# measures_demo_gotr_long_kept <- cleaned_measures_demo_gotr_long[clean_value=='Include']
# measures_demo_hfc_long_kept <- cleaned_measures_demo_hfc_long[clean_value=='Include']
# measures_demo_kp_long_kept <- cleaned_measures_demo_kp_long[clean_value=='Include']

write_csv(measures_demo_long_kept, path = "DCC_out/measures_demo_long_kept.csv")


# 1.4.6 here
# reconcile PMCA

pmca_output <- rbind(pmca_output_ch,
                     pmca_output_dh,
                     pmca_output_gotr,
                     pmca_output_hfc,
                     pmca_output_kp)

# pmca_output$linkid %>% length()
# (pmca_output %>% unique())$linkid %>% length()
pmca_output 
pmca_output$linkid %>% duplicated()

pmca_output$linkid %>% length()
pmca_output$linkid %>% unique() %>% length()

length((pmca_output %>% unique())$linkid)

#pmca_output %>% unique() %>% group_by(linkid) %>% filter(pmca >= 1) %>% duplicated() %>% count()
#pmca_output$pmca <- ifelse()

# count unique body systems and filter by uniques
pmca_recon <- pmca_output %>% 
        group_by(linkid) %>% 
        dplyr::mutate(count_bs = dplyr::n_distinct(body_system_name, na.rm = TRUE)) %>%
        unique()

pmca_recon %>% View()

# pmca_recon %>% arrange(linkid) %>% ifelse(pmca == 1,)
     
# add max pmca 
pmca_recon_count <- pmca_recon %>% 
        group_by(linkid) %>% 
        dplyr::arrange(linkid) %>% 
        dplyr::mutate(pmca_max = max(pmca))

# pmca_recon_count$pmca_all <- ifelse(pmca == 2,
#                                     2,
#                                     ifelse(pmca == 1 & )
#                                     )

pmca_recon_count %>% View()

pmca_recon_count$pmca_max <- ifelse(pmca_recon_count$count_bs >= 2,
                                    2,
                                    pmca_recon_count$pmca_max)

pmca_recon_count_max <- pmca_recon_count %>% select(linkid, pmca_max) %>% unique()

write_csv(pmca_recon_count_max, path = "DCC_out/pmca_recon_count_max.csv")


#### weight category for random BMI ####

# spread to wide format again by date
measures_demo_wide_kept <- measures_demo_long_kept %>% spread(param, measurement)

# filter by measure dates that occur in 2017, 2018, 2019
measures_demo_wide_kept_CY <- measures_demo_wide_kept %>% filter(measure_date >= "2017-01-01" & measure_date < "2020-01-01")

# pull yr var based on measure_date
measures_demo_wide_kept_CY <- measures_demo_wide_kept_CY %>% 
        dplyr::mutate(yr = year(measure_date))

measures_demo_wide_kept_CY <- measures_demo_wide_kept_CY %>% 
        filter(!is.na(HEIGHTCM) & !is.na(WEIGHTKG)) %>% 
        dplyr::mutate(bmi = WEIGHTKG/(HEIGHTCM * 0.01))

# select 1 random row per linkid, per yr
set.seed(1492)
measures_demo_wide_rand <- measures_demo_wide_kept_CY %>% 
        group_by(linkid, yr) %>% 
        sample_n(1)

# add age in months
measures_demo_wide_rand$agemos <- floor(age_calc(measures_demo_wide_rand$birth_date, enddate = measures_demo_wide_rand$measure_date,
                                           units = "months", precise = TRUE))
measures_demo_wide_rand$sex <- measures_demo_wide_rand$sex %>% as.numeric()

# join with bmiagerev
measures_demo_wide_rand_z <- left_join(measures_demo_wide_rand, bmiagerev, by = c("agemos", "sex"))

# calculate z
measures_demo_wide_rand_z <- measures_demo_wide_rand_z %>% 
        dplyr::mutate(z = ((bmi/M)^L - 1)/(L*S))

# convert to percentiles
measures_demo_wide_rand_z_perc <- measures_demo_wide_rand_z %>% 
        dplyr::mutate(bmi_percentile = case_when(
                z < -1.881 ~ 3, # Underweight
                z < -1.645 ~ 5, #Underweight
                z < -1.282 ~ 10,
                z < -0.675 ~ 25,
                z > 1.881 ~ 97, # Obese
                z > 1.645 ~ 95, # Obese
                z > 1.282 ~ 90, # Overweight
                z > 1.036 ~ 85, # Overweight
                z > 0.675 ~ 75,
                TRUE ~ 50
        )
)

# convert to bmi categories
measures_demo_wide_rand_z_perc_cat <- measures_demo_wide_rand_z_perc %>% 
        dplyr::mutate(wt_category = case_when(
                is.na(bmi_percentile) ~ 'Missing',
                bmi_percentile >= 95 & bmi >= (1.4 * P95) ~ 'Class III Obese',
                bmi_percentile >= 95 & bmi >= (1.2 * P95) ~ 'Class II Obese',
                bmi_percentile >= 95 ~ 'Class I Obese',
                bmi_percentile >= 85 ~ 'Overweight',
                bmi_percentile <= 5 ~ 'Underweight',
                TRUE ~ 'Normal'
))


cleaned_measures_demo_long %>% filter(linkid == 100000)
measures_demo_wide_kept %>% filter(linkid == 100000)
measures_demo_wide_kept_CY %>% filter(linkid == 100000) %>% arrange(measure_date)

write_csv(measures_demo_wide_rand_z_perc_cat, path = "DCC_out/measures_demo_cat.csv")


measures_demo_wide_rand_z_perc_cat




# outputs in terms of counts by yr/wt/(var) groupings

demo_recon %>% group_by(linkid)
pmca_recon_count_max %>% group_by(linkid)

# age
measures_demo_wide_rand_z_perc_cat$age <- floor(age_calc(measures_demo_wide_rand_z_perc_cat$birth_date, 
                                                         enddate = measures_demo_wide_rand_z_perc_cat$measure_date,
                                                         units = "years", precise = TRUE))

age_group_counts <- measures_demo_wide_rand_z_perc_cat %>% 
        select(linkid, yr, age, wt_category) %>%
        group_by(yr, age, wt_category) %>%
        dplyr::summarise(count = n())
age_group_counts

# sex
sex_group_counts <- measures_demo_wide_rand_z_perc_cat %>% 
        select(linkid, yr, sex, wt_category) %>%
        group_by(yr, sex, wt_category) %>%
        dplyr::summarise(count = n())
sex_group_counts

# race
race_group_counts <- measures_demo_wide_rand_z_perc_cat %>% 
        select(linkid, yr, race, wt_category) %>%
        group_by(yr, race, wt_category) %>%
        dplyr::summarise(count = n())
race_group_counts

# ethnicity
ethn_group_counts <- measures_demo_wide_rand_z_perc_cat %>% 
        select(linkid, yr, hispanic, wt_category) %>%
        group_by(yr, hispanic, wt_category) %>%
        dplyr::summarise(count = n())
ethn_group_counts


# insurance
insurance_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        select(linkid, yr, insurance_type, wt_category) %>%
        group_by(yr, insurance_type, wt_category) %>%
        dplyr::summarise(count = n())
insurance_group_counts

# tract
tract_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, TRACT, wt_category) %>%
        group_by(yr, TRACT, wt_category) %>%
        dplyr::summarise(count = n())
tract_group_counts

# PMCA
pmca_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(pmca_recon_count_max, by = "linkid") %>%
        select(linkid, yr, pmca_max, wt_category) %>%
        group_by(yr, pmca_max, wt_category) %>%
        dplyr::summarise(count = n())
pmca_group_counts

## co occurring conditions ##

# Acanthosis_Nigricans
acanthosis_nigricans_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, acanthosis_nigricans, wt_category) %>%
        group_by(yr, acanthosis_nigricans, wt_category) %>%
        dplyr::summarise(count = n())
acanthosis_nigricans_group_counts

# measures_demo_wide_rand_z_perc_cat %>% group_by(linkid) %>% select(linkid, wt_category, yr) %>% unique()
# cohort_tract_comorb %>% group_by(linkid) %>% select(linkid, yr) %>% unique()
# 
# left_join(measures_demo_wide_rand_z_perc_cat %>% group_by(linkid) %>% select(linkid, wt_category, yr) %>% unique(), cohort_tract_comorb %>% group_by(linkid) %>% select(linkid, yr, acanthosis_nigricans) %>% unique(),
#           by =  c("linkid", "yr")) %>% View()

# adhd
adhd_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, adhd, wt_category) %>%
        group_by(yr, adhd, wt_category) %>%
        dplyr::summarise(count = n())
adhd_group_counts %>% View()


# anxiety
anxiety_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, anxiety, wt_category) %>%
        group_by(yr, anxiety, wt_category) %>%
        dplyr::summarise(count = n())
anxiety_group_counts


# asthma
asthma_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, asthma, wt_category) %>%
        group_by(yr, asthma, wt_category) %>%
        dplyr::summarise(count = n())
asthma_group_counts

# autism
autism_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, autism, wt_category) %>%
        group_by(yr, autism, wt_category) %>%
        dplyr::summarise(count = n())
autism_group_counts


# depression
depression_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, depression, wt_category) %>%
        group_by(yr, depression, wt_category) %>%
        dplyr::summarise(count = n())
depression_group_counts

# diabetes
diabetes_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, diabetes, wt_category) %>%
        group_by(yr, diabetes, wt_category) %>%
        dplyr::summarise(count = n())
diabetes_group_counts


# eating_disorders
eating_disorders_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, eating_disorders, wt_category) %>%
        group_by(yr, eating_disorders, wt_category) %>%
        dplyr::summarise(count = n())
eating_disorders_group_counts


# hyperlipidemia
hyperlipidemia_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, hyperlipidemia, wt_category) %>%
        group_by(yr, hyperlipidemia, wt_category) %>%
        dplyr::summarise(count = n())
hyperlipidemia_group_counts

# hypertension
hypertension_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, hypertension, wt_category) %>%
        group_by(yr, hypertension, wt_category) %>%
        dplyr::summarise(count = n())
hypertension_group_counts

# NAFLD
NAFLD_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, NAFLD, wt_category) %>%
        group_by(yr, NAFLD, wt_category) %>%
        dplyr::summarise(count = n())
NAFLD_group_counts

# Obstructive_sleep_apnea
Obstructive_sleep_apnea_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, Obstructive_sleep_apnea, wt_category) %>%
        group_by(yr, Obstructive_sleep_apnea, wt_category) %>%
        dplyr::summarise(count = n())
Obstructive_sleep_apnea_group_counts


# PCOS
PCOS_group_counts <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        select(linkid, yr, PCOS, wt_category) %>%
        group_by(yr, PCOS, wt_category) %>%
        dplyr::summarise(count = n())
PCOS_group_counts


# write outputs
write_csv(age_group_counts, path = "DCC_out/age_group_counts.csv")
write_csv(sex_group_counts, path = "DCC_out/sex_group_counts.csv")
write_csv(race_group_counts, path = "DCC_out/race_group_counts.csv")
write_csv(ethn_group_counts, path = "DCC_out/ethn_group_counts.csv")
write_csv(insurance_group_counts, path = "DCC_out/insurance_group_counts.csv")
write_csv(tract_group_counts, path = "DCC_out/tract_group_counts.csv")
write_csv(pmca_group_counts, path = "DCC_out/pmca_group_counts.csv")


write_csv(acanthosis_nigricans_group_counts, path = "DCC_out/acanthosis_nigricans_group_counts.csv")
write_csv(adhd_group_counts, path = "DCC_out/adhd_group_counts.csv")
write_csv(anxiety_group_counts, path = "DCC_out/anxiety_group_counts.csv")
write_csv(asthma_group_counts, path = "DCC_out/asthma_group_counts.csv")
write_csv(autism_group_counts, path = "DCC_out/autism_group_counts.csv")
write_csv(depression_group_counts, path = "DCC_out/depression_group_counts.csv")
write_csv(diabetes_group_counts, path = "DCC_out/diabetes_group_counts.csv")
write_csv(eating_disorders_group_counts, path = "DCC_out/eating_disorders_group_counts.csv")
write_csv(hyperlipidemia_group_counts, path = "DCC_out/hyperlipidemia_group_counts.csv")
write_csv(hypertension_group_counts, path = "DCC_out/hypertension_group_counts.csv")
write_csv(NAFLD_group_counts, path = "DCC_out/NAFLD_group_counts.csv")
write_csv(Obstructive_sleep_apnea_group_counts, path = "DCC_out/Obstructive_sleep_apnea_group_counts.csv")
write_csv(PCOS_group_counts, path = "DCC_out/PCOS_group_counts.csv")



#### NORC input style ####


measures_demo_wide_rand_z_perc_cat %>% View()

cohort_tract_comorb %>% View()

# grab all required inputs to start
NORC_input_prep <- measures_demo_wide_rand_z_perc_cat %>%
        left_join(cohort_tract_comorb, by = c("linkid", "yr")) %>%
        left_join(race_condition_inputs, by = "linkid") %>%
        select(linkid, 
               birth_date, 
               sex,
               race,
               hispanic,
               latitude,
               longitude,
               STATE,
               ZIP,
               TRACT,
               COUNTY,
               yr,
               WEIGHTKG,
               HEIGHTCM,
               bmi,
               wt_category,
               age,
               category,
               CNT,
               DATE
               )
NORC_input_prep <- NORC_input_prep %>% group_by(linkid) %>% distinct()

# concatenate STATE to COUNTY to generate COUNTY_FIPS
NORC_input_prep$COUNTY_FIPS <- paste0(NORC_input_prep$STATE, NORC_input_prep$COUNTY)

# pull demo set of columns for prep, and rename
NORC_input_prep_demo <- NORC_input_prep %>% select(linkid,
                                                   DOB = birth_date,
                                                   SEX = sex,
                                                   RACE = race,
                                                   ETHNICITY = hispanic,
                                                   LAT = latitude,
                                                   LNG = longitude,
                                                   STATE_FIPS = STATE,
                                                   ZIP,
                                                   CENSUS_TRACT = TRACT,
                                                   COUNTY_FIPS
)

# filter by distinct
NORC_input_prep_demo <- NORC_input_prep_demo %>% group_by(linkid) %>% distinct()

# pull BMI  set of columns for prep, and rename
NORC_input_prep_bmi_prep <- NORC_input_prep %>% select(linkid,
                                                       yr,
                                                       WEIGHT = WEIGHTKG,
                                                       HEIGHT = HEIGHTCM,
                                                       BMI = bmi,
                                                       WTCAT = wt_category,
                                                       AGEYR = age,
        
)

# convert from long to wide to tag on CY for each column
NORC_input_prep_bmi <- pivot_wider(NORC_input_prep_bmi_prep, 
                                   id_cols = linkid,
                                   names_from = yr,
                                   names_glue = "{.value}{yr}",
                                   values_from = c(WEIGHT,
                                                   HEIGHT,
                                                   BMI,
                                                   WTCAT,
                                                   AGEYR))

NORC_input_prep_bmi %>% View()


# merge the results
NORC_input_prep_merged <- left_join(NORC_input_prep_demo, NORC_input_prep_bmi, by = "linkid")

# handle race_conditions inputs

# check if race_condition_inputs has rows
if(length(race_condition_inputs$linkid) != 0){
        
        # convert long to wide to add category as part of column name
        NORC_input_prep_race_condition_test <- pivot_wider(race_condition_inputs,
                                                           id_cols = linkid,
                                                           names_from = category,
                                                           names_glue = "{category}{.value}",
                                                           values_from = c(CNT, DATE))
        
        # populate columns names if missing
        if(!("HCLCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$HCLCNT <- NA
        }
        if(!("HCLDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$HCLDATE <- NA
        }
        
        
        if(!("CFCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$CFCNT <- NA
        }
        if(!("CFDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$CFDATE <- NA
        }
        
        
        if(!("SCDCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SCDCNT <- NA
        }
        if(!("SCDDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SCDDATE <- NA
        }
        
        
        if(!("SBCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SBCNT <- NA
        }
        if(!("SBDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SBDATE <- NA
        }
        
        
        if(!("ASTHMACNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$ASTHMACNT <- NA
        }
        if(!("ASTHMADATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$ASTHMADATE <- NA
        }
        
        
        if(!("CELIACCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$CELIACCNT <- NA
        }
        if(!("CELIACDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$CELIACDATE <- NA
        }
        
        
        if(!("SCZCNT" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SCZCNT <- NA
        }
        if(!("SCZDATE" %in% colnames(race_condition_inputs))) {
                NORC_input_prep_race_condition_test$SCZDATE <- NA
        }
        
        
        # join with NORC_input_prep_merged
        NORC_input_final <- left_join(NORC_input_prep_merged, NORC_input_prep_race_condition_test, by = "linkid")
        
} else { # just attached columns and fill with null to merged
        
        NORC_input_final <- NORC_input_prep_merged %>% mutate(
                HCLCNT = NA,
                HCLDATE = NA,
                CFCNT = NA,
                CFDATE = NA,
                SCDCNT = NA,
                SCDDATE = NA,
                SBCNT = NA,
                SBDATE = NA,
                ASTHMACNT = NA,
                ASTHMADATE = NA,
                CELIACCNT = NA,
                CELIACDATE = NA,
                SCZCNT = NA,
                SCZDATE = NA
        )
}




# leaving a "merged" version for now, there will be duplicate rows due to the way yrs and location vars work right now
NORC_input_final %>% View()

NORC_input_final <- NORC_input_final %>% select(linkid,
                                                   DOB,
                                                   SEX,
                                                   RACE,
                                                   ETHNICITY,
                                                   LAT,
                                                   LNG,
                                                   STATE_FIPS,
                                                   ZIP	,		  
                                                   CENSUS_TRACT,
                                                   COUNTY_FIPS,
                                                   WEIGHT2017,
                                                   HEIGHT2017,
                                                   BMI2017,
                                                   WTCAT2017,
                                                   AGEYR2017,
                                                   WEIGHT2018,
                                                   HEIGHT2018,
                                                   BMI2018,
                                                   WTCAT2018,
                                                   AGEYR2018,
                                                   WEIGHT2019,
                                                   HEIGHT2019,
                                                   BMI2019,
                                                   WTCAT2019,
                                                   AGEYR2019,
                                                   HCLCNT,
                                                   HCLDATE,
                                                   CFCNT,
                                                   CFDATE,
                                                   SCDCNT,
                                                   SCDDATE,
                                                   SBCNT,
                                                   SBDATE,
                                                   ASTHMACNT,
                                                   ASTHMADATE,
                                                   CELIACCNT,
                                                   CELIACDATE,
                                                   SCZCNT,
                                                   SCZDATE)

write_csv(NORC_input_final, path = "DCC_out/NORC_input_final.csv")








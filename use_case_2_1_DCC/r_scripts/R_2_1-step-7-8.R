############################ Description #############################
# DCC code for reconciling data from 2.1.6


# install packages for growthcleanr
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


# read csv, matched_data
matched_data <- read_csv("DCC_out/matched_data.csv", na = "NULL")

# read csv, cohort_demographic
cohort_demographic <- read_csv("DCC_out/demo_index_site_final.csv", na = "NULL")

# read csv, demo_bd_sex_recon for growthcleanr
demo_bd_sex_recon <- read_csv("DCC_out/demo_bd_sex_recon.csv", na = "NULL")

# read csv, measures_output
measures_output_ch <- read_csv("partner_out/OUTCOME_VITALS_ch.csv", na = "NULL")

measures_output_dh <- read_csv("partner_out/OUTCOME_VITALS_dh.csv", na = "NULL")

measures_output_kp <- read_csv("partner_out/OUTCOME_VITALS_kp.csv", na = "NULL")

# read csv, OUTCOME_LAB_RESULTS
OUTCOME_LAB_RESULTS_ch <- read_csv("partner_out/OUTCOME_LAB_RESULTS_ch.csv", na = "NULL")

OUTCOME_LAB_RESULTS_dh <- read_csv("partner_out/OUTCOME_LAB_RESULTS_dh.csv", na = "NULL")

OUTCOME_LAB_RESULTS_kp <- read_csv("partner_out/OUTCOME_LAB_RESULTS_kp.csv", na = "NULL")

# read csv, EXPOSURE_DOSE
EXPOSURE_DOSE_ch <- read_csv("partner_out/EXPOSURE_DOSE_ch.csv", na = "NULL")

EXPOSURE_DOSE_dh <- read_csv("partner_out/EXPOSURE_DOSE_dh.csv", na = "NULL")

EXPOSURE_DOSE_gotr <- read_csv("partner_out/EXPOSURE_DOSE_gotr.csv", na = "NULL")

EXPOSURE_DOSE_hfc <- read_csv("partner_out/EXPOSURE_DOSE_hfc.csv", na = "NULL")

EXPOSURE_DOSE_kp <- read_csv("partner_out/EXPOSURE_DOSE_kp.csv", na = "NULL")

# read csv, HF_PARTICIPANTS
HF_PARTICIPANTS_ch <- read_csv("partner_out/HF_PARTICIPANTS_ch.csv", na = "NULL")

HF_PARTICIPANTS_dh <- read_csv("partner_out/HF_PARTICIPANTS_dh.csv", na = "NULL")

HF_PARTICIPANTS_gotr <- read_csv("partner_out/HF_PARTICIPANTS_gotr.csv", na = "NULL")

HF_PARTICIPANTS_hfc <- read_csv("partner_out/HF_PARTICIPANTS_hfc.csv", na = "NULL")

HF_PARTICIPANTS_kp <- read_csv("partner_out/HF_PARTICIPANTS_kp.csv", na = "NULL")

# read csv, ADI_OUT
ADI_OUT_ch <- read_csv("partner_out/ADI_OUT_ch.csv", na = "NULL")

ADI_OUT_dh <- read_csv("partner_out/ADI_OUT_dh.csv", na = "NULL")

ADI_OUT_gotr <- read_csv("partner_out/ADI_OUT_gotr.csv", na = "NULL")

ADI_OUT_hfc <- read_csv("partner_out/ADI_OUT_hfc.csv", na = "NULL")

ADI_OUT_kp <- read_csv("partner_out/ADI_OUT_kp.csv", na = "NULL")

# read csv, DIET_NUTR_ENC
DIET_NUTR_ENC_ch <- read_csv("partner_out/DIET_NUTR_ENC_ch.csv", na = "NULL")

DIET_NUTR_ENC_dh <- read_csv("partner_out/DIET_NUTR_ENC_dh.csv", na = "NULL")

DIET_NUTR_ENC_kp <- read_csv("partner_out/DIET_NUTR_ENC_kp.csv", na = "NULL")


# combine tables
# cohort_demo <- rbind(cohort_demographic_ch,
#                      cohort_demographic_dh,
#                      cohort_demographic_kp)

measures_output <- rbind(measures_output_ch,
                         measures_output_dh,
                         measures_output_kp)

OUTCOME_LAB_RESULTS <- rbind(OUTCOME_LAB_RESULTS_ch,
                             OUTCOME_LAB_RESULTS_dh,
                             OUTCOME_LAB_RESULTS_kp)

EXPOSURE_DOSE <- rbind(EXPOSURE_DOSE_ch,
                       EXPOSURE_DOSE_dh,
                       EXPOSURE_DOSE_gotr,
                       EXPOSURE_DOSE_hfc,
                       EXPOSURE_DOSE_kp)

HF_PARTICIPANTS <- rbind(HF_PARTICIPANTS_ch,
                         HF_PARTICIPANTS_dh,
                         HF_PARTICIPANTS_gotr,
                         HF_PARTICIPANTS_hfc,
                         HF_PARTICIPANTS_kp)

ADI_OUT <- rbind(ADI_OUT_ch,
                 ADI_OUT_dh,
                 ADI_OUT_gotr,
                 ADI_OUT_hfc,
                 ADI_OUT_kp)

DIET_NUTR_ENC <- rbind(DIET_NUTR_ENC_ch,
                       DIET_NUTR_ENC_dh,
                       DIET_NUTR_ENC_kp)

# for merging and printing out
cohort_demographic_u <- cohort_demographic %>% unique()

cohort_demographic_u <- left_join(matched_data, cohort_demographic_u, by = 'linkid')


# convert to match growthcleanr format
demo_bd_sex_recon$sex[demo_bd_sex_recon$sex == "F"] <- 1
demo_bd_sex_recon$sex[demo_bd_sex_recon$sex == "M"] <- 0

# left join ht weights with age, sex, (USE RECON demo HERE)
measures_demo <- left_join(measures_output, demo_bd_sex_recon, by = "linkid")


# calculate age in days from birth date to measurement date
measures_demo$agedays <- as.numeric(difftime(measures_demo$measure_date, 
                                                measures_demo$birth_date, 
                                                units = "days")) 

# convert height from inches to CM
measures_demo$HEIGHTCM <- measures_demo$ht * 2.54

# convert weight from pounds to Kg
measures_demo$WEIGHTKG <- measures_demo$wt * 0.45359237

# convert wide to long
measures_demo_long <- gather(measures_demo, param, measurement, c(HEIGHTCM, WEIGHTKG), factor_key = TRUE)

# prep for growthcleanr
measures_demo_long <- as.data.table(measures_demo_long)
setkey(measures_demo_long, linkid, param, agedays)

# clean measurements, creates new column for whether to include measurement
cleaned_measures_demo_long <- measures_demo_long[, clean_value:=
                                                         cleangrowth(linkid, param, agedays, sex, measurement,
                                                                     parallel = T)]


# write to file all outputs
# cohort_demo 
cohort_demo <- cohort_demographic_u %>% select(linkid, birth_date, sex, race, hispanic, in_study_cohort) %>% 
        mutate(age = floor(age_calc(birth_date, enddate = as.Date("2017-01-01"), units = "years")),
               study = in_study_cohort) %>% 
        select(linkid, birth_date, age, sex, race, hispanic, study)

# convert to output format
cohort_demo$study[cohort_demo$study == 0] <- 2

write_csv(cohort_demo, path = "DCC_out/cohort_demo.csv")

# cleaned_measures_demo_long
write_csv(cleaned_measures_demo_long, path = "DCC_out/measures_output_cleaned.csv")

# OUTCOME_LAB_RESULTS
write_csv(OUTCOME_LAB_RESULTS, path = "DCC_out/OUTCOME_LAB_RESULTS.csv")

# EXPOSURE_DOSE
write_csv(EXPOSURE_DOSE, path = "DCC_out/EXPOSURE_DOSE.csv")

# HF_PARTICIPANTS
write_csv(HF_PARTICIPANTS, path = "DCC_out/HF_PARTICIPANTS.csv")

# ADI_OUT
write_csv(ADI_OUT, path = "DCC_out/ADI_OUT.csv")

# DIET_NUTR_ENC
write_csv(DIET_NUTR_ENC, path = "DCC_out/DIET_NUTR_ENC.csv")

cohort_demo %>% group_by(linkid)
cleaned_measures_demo_long %>% group_by(linkid)
OUTCOME_LAB_RESULTS %>% group_by(linkid)
EXPOSURE_DOSE %>% group_by(linkid) # this has more IDs than demo
HF_PARTICIPANTS %>% group_by(linkid)
ADI_OUT %>% group_by(linkid)
DIET_NUTR_ENC %>% group_by(linkid)




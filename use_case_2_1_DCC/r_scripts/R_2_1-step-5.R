############################ Description #############################
# DCC code for combining matched IDs from 2.1.4
#
library(dplyr)
library(readr)

options(scipen=999)


PSM_matched_data_ch <- read_csv("Partner_out/PSM_matched_data_ch.csv")
PSM_matched_data_dh <- read_csv("Partner_out/PSM_matched_data_dh.csv")
PSM_matched_data_kp <- read_csv("Partner_out/PSM_matched_data_kp.csv")

PSM_matched_data_ch <- mutate(PSM_matched_data_ch, index_site = "CH")
PSM_matched_data_dh <- mutate(PSM_matched_data_dh, index_site = "DH")
PSM_matched_data_kp <- mutate(PSM_matched_data_kp, index_site = "KP")

PSM_matched_data <- rbind(PSM_matched_data_ch,
                          PSM_matched_data_dh,
                          PSM_matched_data_kp)

matched_data <- PSM_matched_data %>% group_by(linkid) %>% select(linkid, in_study_cohort, index_site)


# write out to DCC_out
write_csv(matched_data, path = "DCC_out/matched_data.csv")
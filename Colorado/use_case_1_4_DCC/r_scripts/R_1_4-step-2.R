###################### Description #######################
# DCC code for reconciling demographic variables
# Reads in CSVs from data partners,
# reconciles DOB, sex, race, ethnicity based on (in order):
# 1. majority
# 2. most encounter counts
# 3. random site
#
# send csv of reconciled variables per linkid

options(scipen=999) # prevent scientific notation


library(dplyr)
library(tidyr)
library(readr)


#actual read csv, modify file paths as needed
study_cohort_demographic_ch <- read_csv("partner_out/study_cohort_demographic_ch_VDW.csv", na = "NULL")

study_cohort_demographic_dh <- read_csv("partner_out/study_cohort_demographic_dh_VDW.csv", na = "NULL")

study_cohort_demographic_gotr <- read_csv("partner_out/study_cohort_demographic_gotr_VDW.csv", na = "NULL")

study_cohort_demographic_hfc <- read_csv("partner_out/study_cohort_demographic_hfc_VDW.csv", na = "NULL")

study_cohort_demographic_kp <- read_csv("partner_out/study_cohort_demographic_kp_VDW.csv", na = "NULL")

#label by site, keep relevant columns
demo_enc_vital_CH <- dplyr::mutate(study_cohort_demographic_ch, site = "ch") %>% 
        select(linkid, birth_date, sex, race, hispanic, yr, encN, site, loc_start)

demo_enc_vital_DH <- dplyr::mutate(study_cohort_demographic_dh, site = "dh") %>% 
        select(linkid, birth_date, sex, race, hispanic, yr, encN, site, loc_start)

demo_enc_vital_GOTR <- dplyr::mutate(study_cohort_demographic_gotr, site = "gotr") %>% 
        select(linkid, birth_date, sex, race, hispanic, yr, encN, site, loc_start)

demo_enc_vital_HFC <- dplyr::mutate(study_cohort_demographic_hfc, site = "hfc") %>% 
        select(linkid, birth_date, sex, race, hispanic, yr, encN, site, loc_start)

demo_enc_vital_KP <- dplyr::mutate(study_cohort_demographic_kp, site = "kp") %>% 
        select(linkid, birth_date, sex, race, hispanic, yr, encN, site, loc_start)


# merge into one tibble
demo_enc_vital_prep <- rbind(demo_enc_vital_CH, 
                             demo_enc_vital_DH, 
                             demo_enc_vital_GOTR, 
                             demo_enc_vital_HFC, 
                             demo_enc_vital_KP)
demo_enc_vital_prep_test <- demo_enc_vital_prep

# convert to proper classes
demo_enc_vital_prep$linkid <- as.numeric(demo_enc_vital_prep$linkid)
demo_enc_vital_prep$birth_date <- as.Date(demo_enc_vital_prep$birth_date)

demo_enc_vital_prep$race[demo_enc_vital_prep$race == "NULL"] <- NA
#demo_enc_vital_prep$race <- as.numeric(demo_enc_vital_prep$race)

demo_enc_vital_prep$yr <- as.numeric(demo_enc_vital_prep$yr)
demo_enc_vital_prep$loc_start <- as.Date(demo_enc_vital_prep$loc_start)
demo_enc_vital_prep$encN <- as.numeric(demo_enc_vital_prep$encN)


demo_enc_vital_prep_link <- demo_enc_vital_prep %>% 
        group_by(linkid, site) %>%
        dplyr::mutate(sum_encn = sum(encN))

#preserve demo variables plus linkids, patikds
demo_link <- demo_enc_vital_prep_link %>% select(linkid, site, birth_date, sex, race, hispanic, sum_encn) %>% arrange(linkid)

# keep unique rows
demo_link_u <- unique(demo_link)

demo_enc_vital <- demo_link_u

length(unique(demo_link$linkid))
length(unique(demo_link_u$linkid))

# BD majority, then enc
demo_enc_vital_bd <- demo_enc_vital %>% 
        group_by(linkid) %>% 
        dplyr::count(birth_date) %>% 
        slice_max(n, n = 1) # has ties?

dev_bd_join <- left_join(demo_enc_vital, demo_enc_vital_bd, by = c("linkid", "birth_date")) # join back

demo_enc_vital_bd_recon <- dev_bd_join %>% 
        group_by(linkid) %>% 
        arrange(linkid, n, desc(sum_encn)) %>% 
        select(linkid, birth_date, sum_encn, n) %>% 
        slice_max(n, n = 1) %>% 
        slice_max(sum_encn, n = 1) # break ties with sum_encn

demo_enc_vital_bd_recon_final_prep <- demo_enc_vital_bd_recon[!duplicated(demo_enc_vital_bd_recon),]

# roll random site for each linkid
set.seed(1492)
demo_enc_vital_bd_recon_final <- sample_n(demo_enc_vital_bd_recon_final_prep, 1, replace = TRUE)

# Sex majority, then enc
demo_enc_vital_sex <- demo_enc_vital %>% 
        group_by(linkid) %>% 
        dplyr::count(sex) %>% 
        slice_max(n, n = 1) # has ties?

dev_sex_join <- left_join(demo_enc_vital, demo_enc_vital_sex, by = c("linkid", "sex")) # join back

demo_enc_vital_sex_recon <- dev_sex_join %>% 
        group_by(linkid) %>% 
        arrange(linkid, n, desc(sum_encn)) %>% 
        select(linkid, sex, sum_encn, n) %>% 
        slice_max(n, n = 1) %>% 
        slice_max(sum_encn, n = 1) # break ties with sum_encn

demo_enc_vital_sex_recon_final_prep <- demo_enc_vital_sex_recon[!duplicated(demo_enc_vital_sex_recon),]

# roll random site for each linkid
set.seed(1492)
demo_enc_vital_sex_recon_final <- sample_n(demo_enc_vital_sex_recon_final_prep, 1, replace = TRUE)

# Race majority, then enc
demo_enc_vital_race <- demo_enc_vital %>% 
        group_by(linkid) %>% 
        dplyr::count(race) %>%
        slice_max(n, n = 1) # has ties?

dev_race_join <- left_join(demo_enc_vital, demo_enc_vital_race, by = c("linkid", "race")) # join back

demo_enc_vital_race_recon <- dev_race_join %>% 
        group_by(linkid) %>% 
        arrange(linkid, n, desc(sum_encn)) %>% 
        select(linkid, race, sum_encn, n) %>% 
        slice_max(n, n = 1) %>% 
        slice_max(sum_encn, n = 1) # break ties with sum_encn

demo_enc_vital_race_recon_final_prep <- demo_enc_vital_race_recon[!duplicated(demo_enc_vital_race_recon),]

# roll random site for each linkid
set.seed(1492)
demo_enc_vital_race_recon_final <- sample_n(demo_enc_vital_race_recon_final_prep, 1, replace = TRUE)


# test
identical(demo_enc_vital %>% group_by(linkid) %>% dplyr::count(race) %>% slice_max(n, n = 1), 
          demo_enc_vital_race_recon_final %>% select(linkid, race, n))


# hispanic majority, then enc
demo_enc_vital_hispanic <- demo_enc_vital %>% 
        group_by(linkid) %>% 
        dplyr::count(hispanic) %>%
        slice_max(n, n = 1) # has ties?

dev_hispanic_join <- left_join(demo_enc_vital, demo_enc_vital_hispanic, by = c("linkid", "hispanic")) # join back

demo_enc_vital_hispanic_recon <- dev_hispanic_join %>% 
        group_by(linkid) %>% 
        arrange(linkid, n, desc(sum_encn)) %>% 
        select(linkid, hispanic, sum_encn, n, site) %>% 
        slice_max(n, n = 1) %>% 
        slice_max(sum_encn, n = 1) # break ties with sum_encn

demo_enc_vital_hispanic_recon_final_prep <- demo_enc_vital_hispanic_recon[!duplicated(demo_enc_vital_hispanic_recon),]

# roll random site for each linkid
set.seed(1492)
demo_enc_vital_hispanic_recon_final <- sample_n(demo_enc_vital_hispanic_recon_final_prep, 1, replace = TRUE)

### check

identical(demo_enc_vital %>% group_by(linkid) %>% dplyr::count(hispanic) %>% slice_max(n, n = 1), 
          demo_enc_vital_hispanic_recon_final %>% select(linkid, hispanic, n))


# final merge of recon vars 
demo_enc_vital_recon <- demo_enc_vital_bd_recon_final %>% 
        left_join(demo_enc_vital_sex_recon_final, by = "linkid") %>% arrange(linkid) %>% 
        left_join(demo_enc_vital_race_recon_final, by = "linkid") %>% arrange(linkid) %>%
        left_join(demo_enc_vital_hispanic_recon_final, by = "linkid") %>% arrange(linkid) %>%
        select(linkid, birth_date, sex, race, hispanic)
demo_enc_vital_recon %>% View()

length(unique(demo_enc_vital_prep$linkid))
length(unique(demo_enc_vital_recon$linkid))

# write output to csv for site to read in
write.csv(demo_enc_vital_recon, 
          file = "DCC_out/demo_recon.csv", 
          na = "NULL",
          row.names = FALSE)


demo_loc_prep <- demo_enc_vital_prep %>% select(linkid, site, yr, loc_start)

demo_loc_prep %>% group_by(linkid, yr) %>% 
        arrange(linkid, yr, desc(loc_start)) %>% View()
# for each LINKID, keeps last address date per CY
demo_loc_prep_tie <- demo_loc_prep %>% group_by(linkid, yr) %>% 
        arrange(linkid, yr, desc(loc_start)) %>% 
        slice_max(loc_start, n = 1) 
        
# roll random site for each linkid
set.seed(1492)
demo_loc <- sample_n(demo_loc_prep_tie, 1, replace = TRUE)

demo_loc %>% View()

# preserve demo_loc up to this point
demo_loc_norm <- demo_loc

# keep ties for now, also keeps LINKIDs that have at least 1 address
# demo_loc <- demo_loc_prep_tie

length(unique(demo_loc$linkid)) *3 


# ##### EXPERIMENTAL CY LOCATION  ASSUMPTION #####
# ### Assumptions for partial missing location for certain CY, include if desired and document
# # number of LINKID with partial missing location for certain CY
# (demo_loc %>% group_by(linkid) %>% tally())$n %>% table()
# 
# # append column to track number of CY with sites per LINKID
# demo_loc_fix_prep <- demo_loc %>% group_by(linkid) %>% add_tally(name = "n_yr")
# 
# ### for 1 CY available
# demo_loc_fix_prep_1 <- demo_loc_fix_prep %>% 
#         filter(n_yr == "1") %>%  # choose those with 1 CY available
#         mutate(need = 3) %>% # append freq column for each row (need 3 per linkid in this case)
#         uncount(need) %>% # expand by need count per linkid
#         group_by(linkid) %>% # group for next step
#         mutate(yr_new = 2017:2019) %>% # edit years so it's one per CY
#         select(linkid, site, yr = yr_new, loc_start, census_location_id)# save/edit original columns
#         
# demo_loc_fix_prep_1 %>% View()
# 
# 
# ### for 2 CY available
# 
# # filter out those with only 2 CY for location
# demo_loc_fix_prep_2 <- demo_loc_fix_prep %>% 
#         filter(n_yr == "2")
# 
# # create base df with 3 CY to join with
# demo_loc_fix_prep_base <- demo_loc_fix_prep_2 %>% 
#         select(linkid) %>%
#         unique() %>% 
#         mutate(need = 3) %>% # append freq column for each row (need 3 per linkid in this case)
#         uncount(need) %>% # expand by need count per linkid
#         group_by(linkid) %>%
#         mutate(yr = 2017:2019)
# demo_loc_fix_prep_base %>% View()
# 
# # join to have empty rows for remaining CY
# demo_loc_fix_prep_2_step <- left_join(demo_loc_fix_prep_base, demo_loc_fix_prep_2, by = c("linkid", "yr"))
# demo_loc_fix_prep_2_step <- demo_loc_fix_prep_2_step %>% 
#         group_by(linkid) %>%
#         arrange(linkid, yr)
# 
# demo_loc_fix_prep_2 <- demo_loc_fix_prep_2_step
# 
# # for loop to fix each instance
# # if CY 2017 is missing location, use next year's info
# # if CY 2018 or 2019 is missing location, use previous year's info
# for (i in 1:length(demo_loc_fix_prep_2$linkid)) {
#         
#         if(is.na(demo_loc_fix_prep_2$loc_start[i])){
#                 
#                 if(demo_loc_fix_prep_2$yr[i] == 2017) {
#                         
#                         demo_loc_fix_prep_2$site[i] = demo_loc_fix_prep_2$site[i + 1] 
#                         demo_loc_fix_prep_2$loc_start[i] = demo_loc_fix_prep_2$loc_start[i + 1] 
#                         demo_loc_fix_prep_2$census_location_id[i] = demo_loc_fix_prep_2$census_location_id[i + 1]
#                         
#                 } else if(demo_loc_fix_prep_2$yr[i] == 2018 | demo_loc_fix_prep_2$yr[i] == 2019) {
#                         
#                         demo_loc_fix_prep_2$site[i] = demo_loc_fix_prep_2$site[i - 1] 
#                         demo_loc_fix_prep_2$loc_start[i] = demo_loc_fix_prep_2$loc_start[i - 1] 
#                         demo_loc_fix_prep_2$census_location_id[i] = demo_loc_fix_prep_2$census_location_id[i - 1]
#                         
#                 }
#         }
# }
# 
# demo_loc_fix_prep_2 %>% View()
#         
# # filter for n_yr == 3 
# demo_loc_fix_prep_3 <- demo_loc_fix_prep %>% 
#         filter(n_yr == "3")
#         
# # append each fix to rebuild data
# demo_loc <- rbind(demo_loc_fix_prep_1,
#       demo_loc_fix_prep_2,
#       demo_loc_fix_prep_3)
# 


#demo_recon_loc <- left_join(demo_enc_vital_recon, demo_loc, by = "linkid")
demo_recon_loc <- left_join(demo_enc_vital_recon, demo_loc_norm, by = "linkid")

demo_recon_loc %>% View()
demo_recon_loc %>% filter(is.na(yr)) %>% arrange(linkid) %>% View() 

# (demo_recon_loc %>% group_by(linkid) %>% tally())$n %>% table()

# store separate dataframes for each site
demo_recon_loc_ch <- demo_recon_loc %>% filter(site == "ch") %>% select(linkid, site, yr)

demo_recon_loc_dh <- demo_recon_loc %>% filter(site == "dh") %>% select(linkid, site, yr)

demo_recon_loc_gotr <- demo_recon_loc %>% filter(site == "gotr") %>% select(linkid, site, yr)

demo_recon_loc_hfc <- demo_recon_loc %>% filter(site == "hfc") %>% select(linkid, site, yr)

demo_recon_loc_kp <- demo_recon_loc %>% filter(site == "kp") %>% select(linkid, site, yr)




# write output to csv for each site to read in
write_csv(demo_recon_loc_ch, path = "DCC_out/demo_recon_loc_ch.csv", na = "")

write_csv(demo_recon_loc_dh, path = "DCC_out/demo_recon_loc_dh.csv", na = "")

write_csv(demo_recon_loc_gotr, path = "DCC_out/demo_recon_loc_gotr.csv", na = "")

write_csv(demo_recon_loc_hfc, path = "DCC_out/demo_recon_loc_hfc.csv", na = "")

write_csv(demo_recon_loc_kp, path = "DCC_out/demo_recon_loc_kp.csv", na = "")

## NEED TO TEST BELOW, maybe duplicate and modify a few rows with new sites to force tie breaks
##



#### for tests ####
#
# cdm_demo %>% group_by(patid)
# 
# demo_enc_vital %>% group_by(patid)
# 
# identical(demo_enc_vital$patid, cdm_demo$patid)
# anti_join(demo_enc_vital, cdm_demo, by = "patid") %>% group_by(patid)
# 
# codi_link %>% group_by(linkid)



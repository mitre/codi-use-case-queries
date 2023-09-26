Prerequisites:

	* All SQL code developed and tested on SQL Server 15.0.2000.5 databases
	* All R scripts tested as of R version 4.0.2

The following R packages need to be installed:

	- dplyr
	- readr
	- MatchIt
	- tidyr
	- eeptools
	- devtools
	- data.table
	- foreach
	- doParallel
	- Hmisc
	- bit64
	- growthcleanr (will install with script)

Setup:

	- Save contents into directory, all following references will be to subdirectories within main directory (example: C:\use_case\)

	- Check that empty \DCC_out, \partner_out subdirectories exists within directory (example: C:\use_case\DCC_out, C:\use_case\partner_out)

	- Check that \reference is populated

	- Working directory for R scripts should be base directory, or the same directory where \DCC_out and \partner_out are located.

Prior to running, check the following directory/subdirectories setup to match the following (\use_case\ will be replaced with relevent bundle such as "\use_case_2_1_DCC\"):

	\use_case_2_1_DCC\
	\use_case_2_1_DCC\DCC_out\
	\use_case_2_1_DCC\parter_out\
	\use_case_2_1_DCC\r_scripts\

	\use_case_2_1_DCC\reference\

Process:

	* Set working directory to \use_case_2_1_DCC\
	* Clear environment between each step

2.1.2 - DCC
Prior to the next step, make sure you receive the following outputs from partner and place them in \use_case_2_1_DCC\DCC_out\:

	- study_cohort_demographic_ch.csv
	- study_cohort_demographic_dh.csv
	- study_cohort_demographic_gotr.csv
	- study_cohort_demographic_hfc.csv
	- study_cohort_demographic_kp.csv
	
1. Run \r_scripts\R_2_1-step-2.R

Outputs (found in \use_case_2_1_DCC\DCC_out\):

	- index_site_ch.csv
	- index_site_dh.csv
	- index_site_kp.csv
	
Take the results for each site and add INSERT statements to 2_1-step-3.sql, line 42
Send the customized SQL code to the respective sites

Outputs (found in \use_case_2_1_DCC\DCC_out\)

	- demo_bd_sex_recon.csv
	- demo_index_site_final.csv
	



2.1.5 - DCC
Prior to the next step, make sure you receive the following outputs from partner and place them in \use_case_2_1_DCC\DCC_out\:
	
	- PSM_matched_data_ch.csv
	- PSM_matched_data_dh.csv
	- PSM_matched_data_kp.csv

2. Run \r_scripts\R_2_1-step-5.R (comment out lines referring to other databases if they are not imported <ch/dh/kp>

Outputs (found in \use_case_2_1_DCC\DCC_out\):

	- matched_data.csv
	
Take the results and add INSERT statements to 2_1-step-6.sql, line 15
Send the customized SQL code to the respective sites
	

2.1.7-8
Prior to the next step, make sure you receive the following outputs from partner and place them in \use_case_2_1_DCC\DCC_out\:

	- OUTCOME_VITALS_ch.csv
	- OUTCOME_VITALS_dh.csv
	- OUTCOME_VITALS_kp.csv
	
	- OUTCOME_LAB_RESULTS_ch.csv
	- OUTCOME_LAB_RESULTS_dh.csv
	- OUTCOME_LAB_RESULTS_kp.csv
	
	- EXPOSURE_DOSE_ch.csv
	- EXPOSURE_DOSE_dh.csv
	- EXPOSURE_DOSE_gotr.csv
	- EXPOSURE_DOSE_hfc.csv
	- EXPOSURE_DOSE_kp.csv
	
	- HF_PARTICIPANTS_ch.csv
	- HF_PARTICIPANTS_dh.csv
	- HF_PARTICIPANTS_gotr.csv
	- HF_PARTICIPANTS_hfc.csv
	- HF_PARTICIPANTS_kp.csv
	
	- ADI_OUT_ch.csv
	- ADI_OUT_dh.csv
	- ADI_OUT_gotr.csv
	- ADI_OUT_hfc.csv
	- ADI_OUT_kp.csv
	
	- DIET_NUTR_ENC_ch.csv
	- DIET_NUTR_ENC_dh.csv
	- DIET_NUTR_ENC_kp.csv
	

3. Run \r_scripts\R_2_1-step-7-8.R 

Final Outputs:

	- cohort_demo.csv
	- measures_output_cleaned.csv
	- OUTCOME_LAB_RESULTS.csv
	- EXPOSURE_DOSE.csv
	- HF_PARTICIPANTS.csv
	- ADI_OUT.csv
	- DIET_NUTR_ENC.csv
	
	
	
	
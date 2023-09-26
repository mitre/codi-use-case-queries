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

Prior to running, check the following directory/subdirectories setup to match the following (\use_case\ will be replaced with relevent bundle such as "\use_case_1_4_DCC\"):

	\use_case_1_4_DCC\
	\use_case_1_4_DCC\DCC_out\
	\use_case_1_4_DCC\parter_out\
	\use_case_1_4_DCC\r_scripts\

	\use_case_1_4_DCC\reference\


Process:

	* Set working directory to \use_case_1_4_DCC\
	* Clear environment between each step

1.4.2 - DCC
Prior to the next step, make sure you receive the following outputs from partners and place them in \use_case_1_4_DCC\partner_out\:

	- study_cohort_demographic_ch.csv
	- study_cohort_demographic_dh.csv
	- study_cohort_demographic_gotr.csv
	- study_cohort_demographic_hfc.csv
	- study_cohort_demographic_kp.csv

1. Run R_1_4-step-2.R


Outputs (found in \use_case_1_4_DCC\DCC_out\):

	- demo_recon_loc_ch.csv
	- demo_recon_loc_dh.csv
	- demo_recon_loc_gotr.csv
	- demo_recon_loc_hfc.csv
	- demo_recon_loc_kp.csv

Take the results for each site and add INSERT statements to 1-4-step-3-4.sql, line 33
Send the customized SQL code to the respective sites

Output (found in \use_case_1_4_DCC\DCC_out\, to be used later):
	- demo_recon.csv



1.4.5-6-7 - DCC
Prior to the next step, make sure you receive the following outputs from partners and place them in \use_case_1_4_DCC\partner_out\:

	- cohort_tract_comorb_ch.csv
	- cohort_tract_comorb_dh.csv
	- cohort_tract_comorb_gotr.csv
	- cohort_tract_comorb_hfc.csv
	- cohort_tract_comorb_kp.csv
	
	- pmca_output_ch.csv
	- pmca_output_dh.csv
	- pmca_output_gotr.csv
	- pmca_output_hfc.csv
	- pmca_output_kp.csv
	
	- measures_output_ch.csv
	- measures_output_dh.csv
	- measures_output_gotr.csv
	- measures_output_hfc.csv
	- measures_output_kp.csv
	
	- race_condition_inputs_ch.csv
	- race_condition_inputs_dh.csv
	- race_condition_inputs_gotr.csv
	- race_condition_inputs_hfc.csv
	- race_condition_inputs_kp.csv
	
Need the following in \use_case_1_4_DCC\DCC_out\:

	- demo_recon.csv
	
Need the following in \use_case_1_4_DCC\reference\:

	- bmiagerev.csv
	
2. Run R_1_4-step-5-6-7.R


Final Outputs:
	- age_group_counts.csv
	- sex_group_counts.csv
	- race_group_counts.csv
	- ethn_group_counts.csv
	- insurance_group_counts.csv
	- tract_group_counts.csv
	- pmca_group_counts.csv
	- acanthosis_nigricans_group_counts.csv
	- adhd_group_counts.csv
	- anxiety_group_counts.csv
	- asthma_group_counts.csv
	- autism_group_counts.csv
	- depression_group_counts.csv
	- diabetes_group_counts.csv
	- eating_disorders_group_counts.csv
	- hyperlipidemia_group_counts.csv
	- hypertension_group_counts.csv
	- NAFLD_group_counts.csv
	- Obstructive_sleep_apnea_group_counts.csv
	- PCOS_group_counts.csv
	- NORC_input_final.csv
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

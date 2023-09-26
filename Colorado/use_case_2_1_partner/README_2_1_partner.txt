Prerequisites:

	* All SQL code developed and tested on SQL Server 15.0.2000.5 databases
	* All R scripts tested as of R version 4.0.2

The following R packages need to be installed:

	- dplyr
	- readr
	- MatchIt

Setup:

	- Save contents into directory, all following references will be to subdirectories within main directory (example: C:\use_case\)

	- Check that an empty \partner_out subdirectory exists within directory (example: C:\use_case\partner_out)

	- Working directory for R scripts should be base directory, or the same directory where \DCC_out and \partner_out are located.

Prior to running, check the following directory/subdirectories setup to match the following (\use_case\ will be replaced with relevent bundle such as "\use_case_2_1_partner\"):

	\use_case_2_1_partner\
	\use_case_2_1_partner\parter_out\
	\use_case_2_1_partner\r_scripts\
	\use_case_2_1_partner\sql\



Process:

2.1.1 - Partner

1. Run \sql\step-1-both.sql
2. Use bash/cmd to export outputs to csvs (name the output file so it ends with one of the following tags <ch/dh/gotr/hfc/kp> like "C:\use_case_2_1_partner\partner_out\study_cohort_demographic_ch.csv")

	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM study_cohort_demographic;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\study_cohort_demographic_<ch/dh/gotr/hfc/kp>.csv

Outputs (found in \use_case_2_1_partner\parter_out\, send to DCC):

	- study_cohort_demographic_<ch/dh/gotr/hfc/kp>.csv
	
	

2.1.3 - Partner

	* Set working directory to \use_case_2_1_partner

	
3. Run \sql\2_1-step-3.sql
4. Use bash/cmd to export outputs to csvs (name the output file so it ends with one of the following tags <ch/dh/kp> like "C:\use_case_2_1_partner\partner_out\cohort_CC_ch.csv")

sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM cohort_CC;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\cohort_CC_<ch/dh/kp>.csv

Outputs (found in \use_case_2_1_partner\parter_out\):

	- cohort_CC_<ch/dh/kp>.csv
	

2.1.4 - Partner

5. In \r_scripts\R_2_1-step-4.R, edit partner <- "<ch/dh/kp>" to your partner name
6. In \r_scripts\R_2_1-step-4.R, edit psm_inputs_link <- read_csv("Partner_out/cohort_CC_<ch/dh/kp>.csv") to your partner name
7. Run \r_scripts\R_2_1-step-4.R

Outputs (found in \use_case_2_1_partner\parter_out\, send to DCC):

	- PSM_matched_data_<ch/dh/kp>.csv



2.1.6 - Partner

8. In \sql\2_1-step-6.sql, modify or comment out depending on your partner name: 

	/* Uncomment and edit UPPER(' ') for CH, DH, and KP. 
		Comment out entire line for GOTR and HFC. */
		
	DELETE #patientlist WHERE index_site <> UPPER('<ch/dh/kp>'); 
	
9. Run \sql\2_1-step-6.sql
10. Use bash/cmd to export outputs to csvs (name the output file so it ends with one of the following tags <ch/dh/kp> like "C:\use_case_2_1_partner\partner_out\cohort_CC_ch.csv")

Edit and run version below for CH, DH, and KP:

	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM OUTCOME_VITALS;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\partner_out\OUTCOME_VITALS_<ch/dh/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM OUTCOME_LAB_RESULTS;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\partner_out\OUTCOME_LAB_RESULTS_<ch/dh/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM EXPOSURE_DOSE;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\EXPOSURE_DOSE_<ch/dh/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM HF_PARTICIPANTS;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\HF_PARTICIPANTS_<ch/dh/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM ADI_OUT;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\ADI_OUT_<ch/dh/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM DIET_NUTR_ENC;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\DIET_NUTR_ENC_<ch/dh/kp>.csv

Edit and run version below for GOTR and HFC:

	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM EXPOSURE_DOSE;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\EXPOSURE_DOSE_<gotr/hfc>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM HF_PARTICIPANTS;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\HF_PARTICIPANTS_<gotr/hfc>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM ADI_OUT;" | findstr /v /c:"---"  > C:\use_case_2_1_partner\partner_out\ADI_OUT_<gotr/hfc>.csv


Outputs (found in \use_case_2_1_partner\parter_out\, send to DCC):

	- OUTCOME_VITALS_<ch/dh/kp>.csv
	- OUTCOME_LAB_RESULTS_<ch/dh/kp>.csv
	- EXPOSURE_DOSE_<ch/dh/gotr/hfc/kp>.csv
	- HF_PARTICIPANTS_<ch/dh/gotr/hfc/kp>.csv
	- ADI_OUT_<ch/dh/gotr/hfc/kp>.csv
	- DIET_NUTR_ENC_<ch/dh/kp>.csv















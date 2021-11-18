Prerequisites:

	* All SQL code developed and tested on SQL Server 15.0.2000.5 databases
	* All R scripts tested as of R version 4.0.2

Setup:

	- Save contents into directory, all following references will be to subdirectories within main directory (example: C:\use_case\)

	- Check that an empty \partner_out subdirectory exists within directory (example: C:\use_case\partner_out)


Prior to running, check the following directory/subdirectories setup to match the following (\use_case\ will be replaced with relevent bundle such as "\use_case_1_4_partner\"):

	\use_case_1_4_partner\
	\use_case_1_4_partner\parter_out\
	\use_case_1_4_partner\sql\


Process:

1.4.1 - Partner

1. Run \sql\step-1-both.sql
2. Use bash/cmd to export outputs to csvs (name the output file so it ends with one of the following tags <ch/dh/gotr/hfc/kp> like "C:\use_case_1_4_partner\partner_out\study_cohort_demographic_ch.csv")

	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM study_cohort_demographic;" | findstr /v /c:"---"  > C:\use_case_1_4_partner\partner_out\study_cohort_demographic_<ch/dh/gotr/hfc/kp>.csv

Outputs (found in \use_case_1_4_partner\parter_out\, send to DCC):

	- study_cohort_demographic_<ch/dh/gotr/hfc/kp>.csv


1.4.3-4 - Partner

3. Run 1-4-step-3-4.sql 
4. Use bash/cmd to export outputs to csvs (name the output file so it ends with one of the following tags <ch/dh/gotr/hfc/kp> like "C:\use_case\partner_out\study_cohort_demographic_ch.csv")

	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM cohort_tract_comorb;" | findstr /v /c:"---"  > C:\use_case\partner_out\cohort_tract_comorb_<ch/dh/gotr/hfc/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM pmca_output;" | findstr /v /c:"---"  > C:\use_case\partner_out\pmca_output_<ch/dh/gotr/hfc/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM measures_output;" | findstr /v /c:"---"  > C:\use_case\partner_out\partner_out\measures_output_<ch/dh/gotr/hfc/kp>.csv
	sqlcmd -S . -d <database name> -E -s"," -W -Q "set nocount on; SELECT * FROM race_condition_inputs;" | findstr /v /c:"---"  > C:\use_case\partner_out\race_condition_inputs_<ch/dh/gotr/hfc/kp>.csv

Outputs (found in \use_case_1_4_partner\partner_out\, send to DCC):

	- cohort_demographic_<ch/dh/gotr/hfc/kp>.csv
	- pmca_output_<ch/dh/gotr/hfc/kp>.csv
	- measures_output_<ch/dh/gotr/hfc/kp>.csv
	- race_condition_inputs_<ch/dh/gotr/hfc/kp>.csv





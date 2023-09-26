/*******************************************************************************************/
/***PROGRAM: CODI_Query2.SAS									 				     	 ***/
/***VERSION: 4.0																	 	 ***/
/***AUTHOR: The MITRE Corporation														 ***/
/***DATE: July 3, 2023														 			 ***/
/*******************************************************************************************/

/*CODI Use Case #1 - describing the population enrolled in NC CODI programs;
	/*Research Question: What are the characteristics* of the population served by each CODI-participating organization/program?
	/*		Characteristics = demographic, geographic, SDOH, or health-related;
	/*SAS program outline:

						based on linkids in use case 1 query 1:
		/*STEP #4: Pulling in and merging the SDOH data with the cohort population (patid) of individuals enrolled in a program;***/ 
		/*STEP #5: Pulling in the pregnancy data ;***/
		/*STEP #5: Pulling in theinsurance data for cohort participants;***/
		/*STEP #6: Pulling in the vitals (height, weight, bmi, blood pressure) for the cohort. Calculating BMI and creating a variable for BMI Category according to the CDC classifications;***/
		/*STEP #7: Reading in the csv files with the ICD-10 code systems for each of the 5 conditions selected from VSAC and creating SQL tables;***/
		/*NOTE: The data is converted to a SAS file after each step;***/
/**********************************************************************************************/

/*User instructions-
		1 replace with local directory- CODISAS: replace with the CODI tables
									  	PCORSAS: replace with the local file path for the PCOR tables
									  	OUT: replace with the local file path for the output folder
									  	dir: replace with the local file path for excel file containing the ICD-10 condition codes
/***********************************************************************************************/
		libname CODISAS "C:\Users\LBOYER\Documents\Codi";
		libname PCORSAS "C:\Users\LBOYER\Documents\Codi";
		libname out "C:\Users\LBOYER\Documents\UseCase";
		%let dir=C:\Users\LBOYER\Desktop\ConditionCodes.xlsx;

		/*OPTION: uncomment this code to improve run time and reduce size of data on disk*/
		*options compress=yes reuse=yes;

/**********************************DO NOT EDIT BEYOND THIS POINT********************************/


	/*@Action: Selecting the patid for the cohort population to pull the remaining data for evaluation- this is based on the query 1 results;***/
		proc sql;
		Create Table Population
		as 
		select LINKID
		from out.UseCase1FinderFile;
		quit;
		
	/*@Action: Using the Linkid to find the site patid & limiting the link_iteration to 1 for the inital PPRL run*/ 
		proc sql;
		Create Table PopulationLink
		as 
		select l.LINKID, l.patid, l.link_iteration
		from Population p 
		join CODISAS.Link l
		on p.LINKID = l.LINKID
		where LINK_ITERATION = 1;
		quit;
		


		/*@Action: STEP #4: Pulling in and merging the SDOH data with the cohort population (patid) of individuals enrolled in a program;***/ 
		/*@Action: Pulling in the SDOH evidence data, and limiting the data from 2017 to 2022;***/
		/*@Note: Pulling in the asset delivery table to see any instances where data owner, partner, or researcher has made an assertion indicating the presence of SDOH evidence, and the asset delivery tabe to identify any instances an asset such as food or health insurance was provided;***/
		/*@Action: Creating variables for the month and year of the SDOH evidence and assets data for analysis purposes;***/
			proc sql;
			Create Table SDOHLinkid
			as 
			select n.linkid, e.EVIDENCE_DATE, e.sdoh_evidence_indicator_id, e.EVIDENCE_TABLE_NAME, e.SDOH_CATEGORY, e.EVIDENCE_ROWID, e.EVIDENCE_DATE FORMAT = monyy7. as FormatedEvidence, 
			YEAR(FormatedEvidence) as YEAR_SDOH, MONTH(FormatedEvidence) as MONTH_SDOH
			from PopulationLink n
			join CODISAS.SDOH_Evidence_indicator e
			on n.patid = e.patid 
			where CALCULATED year_SDOH in (2017, 2018, 2019, 2020, 2021, 2022); 
			quit;
		
			data out.UseCase1SDOH;
				set SDOHLinkid;
			run;
	
	
	
	/*@Action: Pulling in and merging the Asset data with the SDOH data for controls;***/ 
	/*@Action: Pulling in the asset delivery data, and limiting the data from 2017 to 2022;***/
			proc sql;
			Create Table AssetLinkid
			as 
			select n.linkid, a.ASSET_DELIVERY_ID, a.ASSET_PURPOSE, a.DELIVERY_END_DATE, a.DELIVERY_FREQ, a.DELIVERY_FREQ_UNIT, a.delivery_start_date, 
			a.delivery_start_date FORMAT = monyy7. as FormatedDelivery, YEAR(a.delivery_start_date) as YEAR_ASSET, MONTH(a.delivery_start_date) as MONTH_ASSET,a.PATID, a.PROGRAMID
			from PopulationLink n
			join CODISAS.asset_delivery a
			on n.patid = a.patid
			where CALCULATED year_asset in (2017, 2018, 2019, 2020, 2021, 2022); 
			quit;
	
		/*@Action: STEP #3: Convert the SDOH and Asset data to a SAS dataset;***/
				data out.UseCase1Asset;
					set AssetLinkid;
				run;
	
	
	/*@Action: STEP #5: Pulling in the pregnancy data and insurance data for the cohort and merging it with the SDOH data from the last step;***/ 
			/*@Note: Pulling in the pregancy table, the insurance information (payer type varaibles) and ambulatory(AV), inpatient(IP), ED, ED to inpatient (EI), telehealth,(TH) observation(OS and OA) from the encounters table;***/ 
			/*@Note: The encounter table variables are limited to 2017 through 2022 with the year_admit variable;***/
	
			proc sql;
			Create Table PregLinkid
			as 
			select n.linkid, p.LAST_MENSES_DATE, p.ESTIMATED_DELIVERY_DATE, p.DELIVERY_DATE, trunc(year(p.DELIVERY_DATE),4) as year_delivery, p.FETUS_COUNT, p.PRE_PREGNANCY_WT, p.PRE_PREGNANCY_BMI, p.DELIVERY_WT
			from PopulationLink n
			join CODISAS.pregnancy p 
			on n.patid = p.patid
			where CALCULATED year_delivery in (2017, 2018, 2019, 2020, 2021, 2022); 
			quit;
	
		/*@Action: STEP #3: Print the pregnancy data to a SAS dataset;***/
			data out.UseCase1Preg;
				set PregLinkid;
			run;
	
			
	/*@Action: STEP #6: Pulling in the insurance data for the cohort;***/ 		
			proc sql;
			Create Table EncounterLinkid
			as
			select n.linkid, e.payer_type_primary, e.payer_type_secondary, e.admit_date, trunc(year(e.admit_date),4) as year_admit, e.enc_type, e.encounterid
			from PopulationLink n
			join PCORSAS.encounter e
			on n.patid = e.patid
			where (payer_type_primary <> '' AND enc_type in('ED', 'AV', 'IP', 'EI', 'TH', 'OS', 'OA')) 
			AND Calculated year_admit in (2017, 2018, 2019, 2020, 2021, 2022);
			quit;
	
		/*@Action: STEP #3: Convert the Encounter and insurance data to a SAS dataset;***/
			data out.UseCase1EncounterLink;
				set EncounterLinkid;
			run;
	
	
	/*@/*@Action: STEP #6: Pulling in the vital (height, weight, bmi, blood pressure) for the cohort. Calculating BMI and creating a variable for BMI Category according to the CDC classifications;***/
			/*@Note: There can multiple rows for encounters in the same year for an individual;***/
			/*@Note: BMI & Obesity categories taken from the CDC: https://www.cdc.gov/obesity/basics/adult-defining.html ***/
				proc sql;
				create table vitalLinkid
				as 
				select p.linkid, v.HT, v.WT, v.DIASTOLIC, v.SYSTOLIC, v.MEASURE_DATE, trunc(year(measure_date),4) as YEAR_MEASURE,v.ENCOUNTERID, v.VITALID, v.ORIGINAL_BMI, 
				((WT*703)/(HT**2)) as CALCULATED_BMI,
				case 
				when CALCULATED CALCULATED_BMI BETWEEN 0 AND 18.5 then 'Underweight'
				when CALCULATED CALCULATED_BMI BETWEEN 18.5 AND 25 then 'Healthy weight'
				when CALCULATED CALCULATED_BMI BETWEEN 25 AND 30 then 'Overweight weight'
				when CALCULATED CALCULATED_BMI BETWEEN 30 and 35 then 'Obesity class 1'
				when CALCULATED CALCULATED_BMI BETWEEN 25 AND 30 then 'Obesity class 2'
				when CALCULATED CALCULATED_BMI GT 30 then 'Obesity class 3'
				else 'BMI missing'
				END as BMI_CATEGORY
				from PopulationLink p
				join PCORSAS.vital v
				on p.patid=v.patid
				where calculated year_measure in (2017, 2018, 2019, 2020, 2021, 2022);
				quit;
	
		/*@Action: STEP #3: Convert the vital data to a SAS dataset;***/
				data out.UseCase1vital;
					set vitalLinkid;
				run;
	
	
	
	
	/*@Action: STEP #7: Reading in the csv files with the ICD-10 code systems selected from VSAC and creating SQL tables;***/
			/*@ACTION: read in the ICD-10 codes for Diabetes***/
			PROC IMPORT OUT= WORK.DIABETES 
				DATAFILE= "&dir" 
				DBMS=xlsx REPLACE;
				sheet="Diabetes";
				format code $18.;
				run;
			PROC SQL;
				Create table DIABETES 
				as select
				code,
				Description,
				Code_System,
				Code_System_Version,
				Code_System_OID,
				TTY
				from WORK.DIABETES;
				run;
	
				
		/*@ACTION: read in the ICD-10 codes for Prediabetes***/
			PROC IMPORT OUT= WORK.PREDIABETES 
				DATAFILE= "&dir" 
				DBMS=xlsx REPLACE;
				sheet="Prediabetes";
				format code $18.;
				run;
			PROC SQL;
				Create table PREDIABETES
				as select
				code,
				Description,
				Code_System,
				Code_System_Version,
				Code_System_OID,
				TTY
				from WORK.PREDIABETES;
				quit;
	
		
		/*@ACTION: read in the ICD-10 codes for Pregnancy***/
			PROC IMPORT OUT= WORK.PREGNANCY  
				DATAFILE= "&dir" 
				DBMS=xlsx REPLACE;
				sheet="Pregnancy";
				format code $18.;
				run;
			PROC SQL;
				Create table PREGNANCY 
				as select
				code,
				Description,
				Code_System,
				Code_System_Version,
				Code_System_OID,
				TTY
				from WORK.PREGNANCY;
				quit;
			proc print data=PREGNANCY;run;
	
		/*@ACTION: read in the ICD-10 codes for Hypersion***/
			PROC IMPORT OUT= WORK.HYPERTENSION  
				DATAFILE= "&dir" 
				DBMS=xlsx REPLACE;
				sheet="Hypertension";
				format code $18.;
				run;
			PROC SQL;
				Create table HYPERTENSION 
				as select
				code,
				Description,
				Code_System,
				Code_System_Version,
				Code_System_OID,
				TTY
				from WORK.HYPERTENSION;
				quit;
			proc print data = Hypertension; run;
	
	
		/*@ACTION: read in the ICD-10 codes for Hemoglobin***/
			PROC IMPORT OUT= WORK.HEMOGLOBINA1C   
				DATAFILE= "&dir" 
				DBMS=xlsx REPLACE;
				sheet="HemoglobinA1C";
				format code $18.;
				run;
			PROC SQL;
				Create table HemoglobinA1C
				as select
				code,
				Description,
				Code_System,
				Code_System_Version,
				Code_System_OID,
				TTY
				from WORK.HEMOGLOBINA1C;
				quit;
			proc print data = HEMOGLOBINA1C; run;
	
				proc sql;
					create table AllRelevantCodes as
					select * from Diabetes d
					union
					select * from Prediabetes
					union
					select * from Hypertension
					union
					select * from Pregnancy;
				quit;
				/* hemoglobin a1c not included here since that's not a diagnosis/condition */
	
		/*@Action: Pulling in the condition table data limited to the cohort;***/
				proc sql;
				Create Table Condition
				as 
				select p.LINKID, c.encounterid, c.condition, c.condition_source, c.condition_type, c.resolve_date, c.onset_date, c.report_date, trunc(year(onset_date),4) as year_onset, trunc(year(report_date),4) as year_report
				from PopulationLink p
				join PCORSAS.condition c
				on p.patid=c.patid
				join AllRelevantCodes ac
				on c.condition = ac.code
				where Calculated year_onset in (2017, 2018, 2019, 2020, 2021, 2022);
				quit;
		
				data out.UseCase1Condition;
					set Condition;
				run;
	
				/*@Action: Pulling in the diagnosis table data limited to the cohort;***/
				proc sql;
				Create Table Diagnosis
				as 
				select p.LINKID, d.dx, d.encounterid, d.dx_type,d.dx_source,d.dx_origin, d.admit_date, trunc(year(admit_date),4) as year_admit, ac.code, ac.code_system, ac.Code_System_OID, ac.Code_System_Version, ac.Description
				from PopulationLink p
				join PCORSAS.diagnosis d 
				on p.patid=d.patid
				join AllRelevantCodes ac
				on d.dx = ac.code
				where Calculated year_admit in (2017, 2018, 2019, 2020, 2021, 2022);
				quit;
	
				data out.UseCase1Diagnosis;
					set Diagnosis;
				run;
	
	
		/*@Action: Merging the cohort condition and diagnosis data to select only encounters with HemoglobinA1C lab codes;***/
				proc sql;
				Create Table HemoglobinA1CCodesLink
				as 
				select p.linkid, l.lab_result_cm_id, l.RESULT_TIME, l.SPECIMEN_SOURCE, l.encounterid, l.lab_loinc, l.lab_order_date, l.lab_loinc, l.lab_px_type, 
				l.specimen_date, l.result_date, trunc(year(result_date),4) as year_result, l.result_loc, l.result_num, l.result_qual, l.result_snomed, l.result_unit,  h.code, h.code_system, h.Code_System_OID, h.Code_System_Version, 
				h.Description
				from PopulationLink p
				join CODISAS.lab_result_cm l
				on p.patid=l.patid
				join HemoglobinA1C h
				on l.LAB_LOINC = h.code
				where Calculated year_result in (2017, 2018, 2019, 2020, 2021, 2022);
				quit;
	
		/*@Action: STEP #3: Convert the HemoglobinA1C to a SAS dataset;***/
				data out.UseCase1HemoglobinA1C;
					set HemoglobinA1CCodesLink;
				run;

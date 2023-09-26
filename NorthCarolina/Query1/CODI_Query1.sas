/*******************************************************************************************/
/***PROGRAM: CODI_Query1.SAS									 				     	 ***/
/***VERSION: 3.0																	 	 ***/
/***AUTHOR: LILLY BOYER																	 ***/
/***DATE: July 13, 2023														 			 ***/
/*******************************************************************************************/

/*CODI Use Case #1 - describing the population enrolled in NC CODI programs;
	/*Research Question: What are the characteristics* of the population served by each CODI-participating organization/program?
	/*		Characteristics = demographic, geographic, SDOH, or health-related;
	/*SAS program outline:

		/*STEP #1: Pulling in and merging the program enrollment, program description & session attendence data;***/
		/*STEP #2: Pulling in and merging demographic data for individuals enrolled in one of the NC CODI programs (e.g., YMCA, Parks & Rec, etc.);***/
		/*STEP #3: Print cohort finder file as a SAS dataset;***/
					
/**************************************************************************************************/


/*User instructions:
		Replace with local directory- CODISAS: replace with the CODI tables
									  OUT: replace with the file path for the output
		Run the code and find the output SAS file in the out file path you supplied below;***/
		
		libname CODISAS "C:\Users\LBOYER\Documents\Codi";
		libname out "C:\Users\LBOYER\Documents\UseCase";

/**********************************DO NOT EDIT BEYOND THIS POINT********************************/



/*@Action: STEP #1: Pulling in and merging the program enrollment, program description & session attendence data;***/
	/*@Action: Select the enrollment data to define the cohort;***/
	/*@Action: Creating a YEAR_ENROLL variable for year of enrollment & MONTH_ENROLL variable pulled from the month listed in the enrollment date to aid in analysis;***/
		proc sql;
		Create table Enrollment
		as
		select PATID, PROGRAMID, COMPLETION_DATE, ENROLLMENT_DATE, ENROLLMENT_DATE FORMAT = monyy7. as FormatedEnrolled, YEAR(FormatedEnrolled) as YEAR_ENROLL, MONTH(FormatedEnrolled) as MONTH_ENROLL, PROGRAM_ENROLLMENT_ID
		from CODISAS.PROGRAM_ENROLLMENT
		where CALCULATED YEAR_ENROLL in (2017, 2018, 2019, 2020, 2021, 2022,.);
		quit;
		proc print data=Enrollment;
		run;

	
/*@Action: Pulling in the program data and merging with the cohort***/
		proc sql;
		Create Table Program
		as 
		select e.PATID, COALESCE (e.PROGRAMID,p.PROGRAMID) as PROGRAMID, e.ENROLLMENT_DATE, e.COMPLETION_DATE, e.FormatedEnrolled, e.YEAR_ENROLL, e.MONTH_ENROLL, e.PROGRAM_ENROLLMENT_ID, p.PROGRAMID, 
		p.PROGRAM_NAME, p.PROGRAM_DESCRIPTION, p.AIM_NUTRITION, p.AIM_ACTIVITY, p.AIM_WEIGHT, p.PRESCRIBED_TOTAL_DOSE
		from Enrollment e
		left join CODISAS.program p 
		on e.programid = p.programid;
		quit;
		proc print data= Program; 
		run;


	/*@Action: Merging the enrollment, session and program data for cohort participants;***/
		/*@Action: Creating a year_session variable to aid in analysis;***/ 
		proc sql;
		Create Table Session
		as
		select COALESCE (p.PATID, s.PATID) as PATID, p.ENROLLMENT_DATE, p.COMPLETION_DATE, p.PROGRAMID, p.FormatedEnrolled, p.YEAR_ENROLL, p.MONTH_ENROLL, p.PROGRAM_ENROLLMENT_ID,  p.PROGRAMID, p.PROGRAM_NAME, 
		p.PROGRAM_DESCRIPTION, p.AIM_NUTRITION, p.AIM_ACTIVITY, p.AIM_WEIGHT, p.PRESCRIBED_TOTAL_DOSE, s.SESSION_DATE, s.SCREENING, s.COUNSELING, s.INTERVENTION_ACTIVITY, s.INTERVENTION_NUTRITION, 
		s.INTERVENTION_NAVIGATION, trunc(year(s.SESSION_DATE),4) as year_session, trunc(month(SESSION_DATE),4) as month_session
		from Program p
		left outer join CODISAS.Session s
		on p.PATID = s.PATID;
		*where Calculated year_session in (2017, 2018, 2019, 2020, 2021, 2022, .);
		quit;
		proc print data= Session; 
		run;
	
/*@Action: Creating a total session variable which counts the number of sessions for each person in the program session data***/
		proc sql;
		create table SessionCount
		as
		    select patid, count(unique sessionid) as session_total
		    from Session
		    group by patid;
		quit;
		proc print data= SessionCount (obs=5); 
		run;

	/*@NOTE: Confirming the maximum session count of an individual from cohort participants***/ 	
		proc sql;
		select unique(max(session_total))
		from SessionCount;
		quit;


	/*@Action: Merge the session data with the session count data;***/
		proc sql;
		Create Table sessionmerged
		as 
		select *
		from Session s, SessionCount c
		where s.patid=c.patid;
		run; 
	
		proc print data= sessionmerged (obs=50); run;
		proc sort data=sessionmerged;
		by patid session_date;
		run;


	/*@Action: Merging the census location data to the enrollment, session and program data for cohort participants;***/
		proc sql;
		Create table EnrolledLoc
		as
		select s.ENROLLMENT_DATE, s.COMPLETION_DATE, s.PROGRAMID, s.FORMATEDENROLLED, s.YEAR_ENROLL, s.MONTH_ENROLL, s.PROGRAM_ENROLLMENT_ID, s.PROGRAM_NAME, 
		s.PROGRAM_DESCRIPTION, s.AIM_NUTRITION, s.AIM_ACTIVITY, s.AIM_WEIGHT, s.PRESCRIBED_TOTAL_DOSE, s.SESSION_DATE, s.SCREENING, s.COUNSELING, s.INTERVENTION_ACTIVITY, 
		s.INTERVENTION_NUTRITION, s.INTERVENTION_NAVIGATION, s.YEAR_SESSION, s.MONTH_SESSION, s.SESSION_TOTAL, COALESCE (s.PATID, c.person_id) as PATID, c.LOC_START, 
		c.LOC_END, c.GEOCODE, c.GEOCODE_BOUNDARY_YEAR, c.GEOLEVEL
		from sessionmerged s 
		left outer join CODISAS.CENSUS_LOCATION c
		on s.patid= c.person_id;
		quit;
		proc print data= EnrolledLoc (obs=50); run;

	/*@Action: Merging the household link data to the enrollment, session and program and census location data for cohort participants;***/
		proc sql;
		Create table EnrolledH
		as
		select e.*, h.HOUSEHOLDID
		from EnrolledLoc e 
		left outer join CODISAS.HOUSEHOLD_LINK h
		on h.patid = e.patid;
		quit;
		proc print data= EnrolledH (obs=50); run;

/*@Action: STEP #2: Pulling in and merging demographic data for individuals enrolled in one of the NC CODI programs with the enrollment, session, program, census and household link data to create the finder file;***/

		proc sql;
		Create Table EnrolledDemo
		as 
		select COALESCE (e.PATID, D.PATID) as PATID,d.BIRTH_DATE,d.SEX,d.RACE, d.HISPANIC,FLOOR(intck('day',BIRTH_DATE, e.ENROLLMENT_DATE) / 365.25)as age, e.ENROLLMENT_DATE, 
		e.COMPLETION_DATE, e.PROGRAMID, e.FORMATEDENROLLED, e.YEAR_ENROLL, e.MONTH_ENROLL, e.PROGRAM_ENROLLMENT_ID, e.PROGRAM_NAME, e.PROGRAM_DESCRIPTION, e.AIM_NUTRITION, 
		e.AIM_ACTIVITY, e.AIM_WEIGHT, e.PRESCRIBED_TOTAL_DOSE, e.SESSION_DATE, e.SCREENING, e.COUNSELING, e.INTERVENTION_ACTIVITY, e.INTERVENTION_NUTRITION, e.INTERVENTION_NUTRITION, 
		e.INTERVENTION_NAVIGATION, e.YEAR_SESSION, e.MONTH_SESSION, e.SESSION_TOTAL, e.LOC_START, e.LOC_END, e.GEOCODE, e.GEOCODE_BOUNDARY_YEAR, e.GEOLEVEL, e.HOUSEHOLDID,
			CASE
			 WHEN  CALCULATED age  BETWEEN 0 AND 19 THEN 1
			 WHEN  CALCULATED age BETWEEN 20 AND 39 THEN 2
			 WHEN  CALCULATED age BETWEEN 40 AND 59 THEN 3
			 WHEN  CALCULATED age BETWEEN 60 AND 79 THEN 4
			 ELSE 99
		 	END AS AgeCategory
		from EnrolledH e
		left outer join CODISAS.DEMOGRAPHIC d
		on e.patid = d.patid;
		quit;
		proc print data= EnrolledDemo (obs=25); 
		run;
/*@Action: Pulling in the Linkid & limiting the link_iteration to 1 for the inital PPRL run*/ 
		proc sql;
		Create Table EnrolledLink
		as 
		select e.PATID,e.BIRTH_DATE,e.SEX,e.RACE, e.HISPANIC,e.age, e.ENROLLMENT_DATE, e.COMPLETION_DATE, e.PROGRAMID, e.FORMATEDENROLLED, e.YEAR_ENROLL, e.MONTH_ENROLL, 
		e.PROGRAM_ENROLLMENT_ID, e.PROGRAM_NAME, e.PROGRAM_DESCRIPTION, e.AIM_NUTRITION, e.AIM_ACTIVITY, e.AIM_WEIGHT, e.PRESCRIBED_TOTAL_DOSE, e.SESSION_DATE, e.SCREENING, 
		e.COUNSELING, e.INTERVENTION_ACTIVITY, e.INTERVENTION_NUTRITION, e.INTERVENTION_NUTRITION, e.INTERVENTION_NAVIGATION, e.YEAR_SESSION, e.MONTH_SESSION, e.SESSION_TOTAL, 
		e.LOC_START, e.LOC_END, e.GEOCODE, e.GEOCODE_BOUNDARY_YEAR, e.GEOLEVEL, e.HOUSEHOLDID, e.AgeCategory, l.LINKID
		from EnrolledDemo e 
		left outer join CODISAS.Link l
		on e.patid = l.patid
		where LINK_ITERATION = 1;
		quit;
		proc print data=EnrolledLink (obs=20);
		run;
/*@Action: drop the site level patid*/
		proc sql;
		alter table EnrolledLink
			drop patid;
		quit;
		proc print data=EnrolledLink (obs=20);
		run;
/*@Action: STEP #3: Print cohort finder file as a SAS dataset;***/
			data out.UseCase1FinderFile;
			set EnrolledLink;
			run;

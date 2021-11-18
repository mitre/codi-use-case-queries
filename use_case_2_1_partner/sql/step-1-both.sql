-- STEP 1 for both use case

-- Usecase 1.4

-- STEP 1 - COMPUTE SUMMARY OF EACH CHILD (demographics, last addres date, #of Encounter

--SET NOCOUNT ON
------- Update According to Data Partner Environment ----------

---------------------------------------------------------------

-- substitude for the age function in postgres 
CREATE OR ALTER FUNCTION dbo.get_age (@bdate varchar(10), @cap_date varchar(10))
RETURNS @age TABLE
( year int,
  month int,
  day int
)
AS
BEGIN
	DECLARE @yr int;
	DECLARE @month smallint;
	DECLARE @day int;
	DECLARE @temp_date date;
	SELECT @yr = CASE
			WHEN DATEDIFF(day, DATEADD(year, DATEDIFF(YEAR, @bdate , @cap_date), @bdate), @cap_date) <0 
			THEN DATEDIFF(YEAR, @bdate , @cap_date)-1
			ELSE DATEDIFF(YEAR, @bdate , @cap_date)
		   END;

	SELECT @temp_date = DATEADD(year, @yr, @bdate);
	SELECT @month = DATEDIFF(MONTH, @temp_date, @cap_date);

	SELECT @month = CASE
		   WHEN DATEDIFF(day, DATEADD(MONTH, @month , @temp_date), @cap_date) < 0
			 THEN @month -1
			 ELSE @month
		   END;

	SELECT @temp_date = DATEADD(MONTH, @month, @temp_date);
	SELECT @day = DATEDIFF(DAY, @temp_date, @cap_date);
	INSERT @age
	VALUES (@yr, @month, @day);
	RETURN
END;
GO

CREATE OR ALTER PROCEDURE dbo.CreateTempTable
    @tblname nvarchar(50),
    @filePath nvarchar(255)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @SQL_BULK nvarchar(255);
	SET @SQL_BULK = 'BULK INSERT ' + @tblname +' FROM ''' + @filePath + ''' WITH
      (
      	FIRSTROW = 2,
		FIELDTERMINATOR = '','',
		ROWTERMINATOR = ''0x0a'',
		KEEPNULLS
	  )';

	EXEC (@SQL_BULK);
END;
GO

-- add encounter counts by CY
DROP VIEW IF EXISTS enc_counts;
GO
CREATE VIEW enc_counts AS
SELECT linkid, patid, yr, COUNT(ENC_ID) AS encN
FROM (
	SELECT link.linkid AS linkid, dbo.ENCOUNTERS.PERSON_ID as patid, ENC_ID,
		CASE WHEN ADATE >= '2017-1-1' AND ADATE < '2018-1-1' THEN 2017
			 WHEN  ADATE >= '2018-1-1' AND ADATE < '2019-1-1' THEN 2018
			 WHEN  ADATE >= '2019-1-1' AND ADATE < '2020-1-1' THEN 2019
		END AS yr
	FROM dbo.ENCOUNTERS
	JOIN dbo.link as link on link.patid =  dbo.ENCOUNTERS.PERSON_ID
	WHERE ADATE >= '2017-1-1' AND ADATE < '2020-1-1'
) AS encounter_plus_year
GROUP BY linkid, patid, yr;
GO

SELECT DISTINCT patid FROM enc_counts;
SELECT * FROM enc_counts;

-- testing 2.1 study sample
DROP VIEW IF EXISTS cohort_2017_test;
GO
CREATE VIEW cohort_2017_test AS
SELECT
	PERSON_ID AS patid,
	*,
	(SELECT year from dbo.get_age(BIRTH_DATE, '1/1/2017')) AS study_age_yrs_2017
FROM
	dbo.DEMOGRAPHICS
;
GO

SELECT * FROM cohort_2017_test;

SELECT DISTINCT patid FROM cohort_2017_test WHERE (study_age_yrs_2017 BETWEEN 2 AND 19);

SELECT * FROM cohort_2017_test
LEFT JOIN dbo.CENSUS_LOCATION ON cohort_2017_test.patid = dbo.CENSUS_LOCATION.PERSON_ID
;

SELECT DISTINCT PERSON_ID FROM dbo.DEMOGRAPHICS;
SELECT DISTINCT PERSON_ID FROM dbo.census_location;


DROP VIEW IF EXISTS ec_test;
GO
CREATE VIEW ec_test AS
SELECT * FROM dbo.CENSUS_LOCATION 
	INNER JOIN enc_counts ON enc_counts.patid = CENSUS_LOCATION.PERSON_ID
	WHERE loc_start <= CONVERT(datetime, '12-31-'+CAST(yr AS VARCHAR(4)))
;
GO

SELECT * FROM ec_test WHERE loc_start <= CONVERT(datetime, '12-31-'+CAST(yr AS VARCHAR(4)))

DROP VIEW IF EXISTS ec_test_latest_loc_date;
GO
CREATE VIEW ec_test_latest_loc_date AS
SELECT 
	PERSON_ID, 
	yr,
	MAX(CONVERT(date, loc_start)) AS latest_loc_date 
FROM ec_test 
WHERE loc_start <= CONVERT(datetime, '12-31-'+CAST(yr AS VARCHAR(4)))
GROUP BY PERSON_ID, yr; 
GO

SELECT * FROM ec_test_latest_loc_date;
SELECT * FROM ec_test_latest_loc_date WHERE PERSON_ID = 19437886 OR PERSON_ID = 19438686 OR PERSON_ID = 19438874;

DROP VIEW IF EXISTS ec_NEW;
GO
CREATE VIEW ec_NEW AS
SELECT 
		linkid, 
		enc_counts.patid, 
		enc_counts.yr, 
		encN, 
		ec_test_latest_loc_date.latest_loc_date
	FROM enc_counts 
		LEFT JOIN ec_test_latest_loc_date ON enc_counts.patid = ec_test_latest_loc_date.PERSON_ID
		AND enc_counts.yr = ec_test_latest_loc_date.yr;
GO

DROP VIEW IF EXISTS ec_OG;
GO
CREATE VIEW ec_OG AS
SELECT 
		linkid, 
		enc_counts.patid, 
		enc_counts.yr, 
		encN, 
		(SELECT MAX(CONVERT(date, loc_start)) -- rewrite 
			FROM dbo.CENSUS_LOCATION 
			WHERE enc_counts.patid = PERSON_ID
			AND loc_start <= CONVERT(datetime, '12-31-'+CAST( enc_counts.yr AS VARCHAR(4)))
		) AS latest_loc_date
	FROM enc_counts;
GO

SELECT * FROM ec_NEW
EXCEPT
SELECT * FROM ec_OG
ORDER BY linkid

SELECT * FROM ec_OG
EXCEPT
SELECT * FROM ec_NEW
ORDER BY linkid

--DROP TABLE IF EXISTS cohort_demographic;
DROP VIEW IF EXISTS cohort_demographic;
GO
CREATE VIEW cohort_demographic AS
SELECT 
	linkid, 
	dbo.DEMOGRAPHICS.PERSON_ID AS patid, 
	--dbo.DEMOGRAPHICS.PERSON_ID, 
	birth_date, 
	GENDER AS sex, -- substitute
	RACE1 AS race, -- using RACE1 only
	hispanic, 
	yr,
	encN, 
	CONVERT(date, loc_start) AS loc_start, 
	loc_end, 
	geocode_boundary_year,
	geolevel, 
	latitude, 
	longitude --, 
	--census_location_id --removed for now
FROM (
	SELECT 
		linkid, 
		enc_counts.patid, 
		enc_counts.yr, 
		encN, 
		ec_test_latest_loc_date.latest_loc_date
	FROM enc_counts 
		LEFT JOIN ec_test_latest_loc_date ON enc_counts.patid = ec_test_latest_loc_date.PERSON_ID
		AND enc_counts.yr = ec_test_latest_loc_date.yr
) AS enc_counts_loc
LEFT JOIN dbo.CENSUS_LOCATION ON CENSUS_LOCATION.PERSON_ID = enc_counts_loc.patid 
				AND loc_start = enc_counts_loc.latest_loc_date 
JOIN dbo.DEMOGRAPHICS ON DEMOGRAPHICS.PERSON_ID = enc_counts_loc.patid;
GO

SELECT * FROM cohort_demographic;

SELECT DISTINCT patid FROM cohort_demographic WHERE yr = 2017;

SELECT DISTINCT patid FROM cohort_demographic;

-- get study age per CY 
DROP VIEW IF EXISTS cohort_demographic_age;
GO
CREATE VIEW cohort_demographic_age AS
SELECT 
	*,
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) AS study_age_yrs_2017,
	(SELECT year from dbo.get_age(birth_date, '1/1/2018')) AS study_age_yrs_2018,
	(SELECT year from dbo.get_age(birth_date, '1/1/2019')) AS study_age_yrs_2019
FROM 
	cohort_demographic
;
GO


SELECT DISTINCT patid FROM cohort_demographic WHERE yr = 2017;
SELECT DISTINCT patid FROM cohort_demographic_age WHERE (yr = 2017 AND study_age_yrs_2017 BETWEEN 2 AND 19);

SELECT * FROM cohort_demographic_age ORDER BY study_age_yrs_2017;
SELECT DISTINCT linkid FROM cohort_demographic_age;
SELECT DISTINCT patid FROM cohort_demographic_age;
SELECT * FROM cohort_demographic_age ORDER BY study_age_yrs_2018;
SELECT * FROM cohort_demographic_age ORDER BY study_age_yrs_2019;

DROP VIEW IF EXISTS cohort_demographic_age_filter;
GO
CREATE VIEW cohort_demographic_age_filter AS
SELECT 
	linkid,
	patid,
	encN,
	birth_date,
	sex,
	race,
	hispanic,
	yr,
	loc_start --,
	--study_age_yrs_2017,
	--study_age_yrs_2018,
	--study_age_yrs_2019
FROM 
	cohort_demographic_age 
WHERE 
	(yr = 2017 AND study_age_yrs_2017 BETWEEN 2 AND 19) OR
	(yr = 2018 AND study_age_yrs_2018 BETWEEN 2 AND 19) OR
	(yr = 2019 AND study_age_yrs_2019 BETWEEN 2 AND 19)
;
GO

SELECT DISTINCT patid FROM cohort_demographic_age_filter;

SELECT * FROM cohort_demographic_age_filter WHERE yr = 2017;
SELECT * FROM cohort_demographic_age_filter ORDER BY birth_date;

SELECT DISTINCT linkid FROM cohort_demographic_age_filter WHERE yr = 2017;

-- execute this script and write output of the SELECT statement below to file --
-- sqlcmd -S <server name> -d <database name> -E -Q "SELECT * FROM cohort_demographic_age_filter" -o "MyData.csv" -s "," -w 700



-- Usecase 2.1

-- STEP 1 - COMPUTE SUMMARY OF EACH CHILD (demographics, last addres date, #of Encounter
------- Update According to Data Partner Environment ----------
---------------------------------------------------------------

DROP TABLE IF EXISTS #study_programs;
CREATE TABLE #study_programs (programid varchar(15))
-- TODO: Enumerate Denver-specific programids.
INSERT INTO #study_programs (programid)
VALUES 
('cwmp')
--, ('hf'),
-- ;
GO
-- Enumerates all patids of children of the correct age
--	with a 2017 intervention and
--	no late 2016 intervention.
DROP TABLE IF EXISTS #study_cohort;
GO
SELECT 
	PERSON_ID AS patid, 
	birth_date, 
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) AS study_age_yrs
INTO #study_cohort
 FROM dbo.DEMOGRAPHICS
 WHERE PERSON_ID IN (
	SELECT 
		patid 
	FROM 
		dbo.session
		 WHERE DATEPART(YEAR, session_date) = 2017
		 AND programid IN (SELECT programid from #study_programs)
	EXCEPT 
	SELECT patid  
	FROM dbo.session
		WHERE session_date >= '1-Jun-2016' AND session_date < '1-Jan-2017'
		AND programid IN (SELECT programid from #study_programs)
 )
AND (SELECT year from dbo.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
GO

-- study sample
DROP TABLE IF EXISTS #study_sample;
GO
SELECT 
	PERSON_ID AS patid, 
	birth_date, 
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) AS study_age_yrs
INTO #study_sample
 FROM dbo.DEMOGRAPHICS
 WHERE
 (SELECT year from dbo.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
GO
SELECT * FROM #study_sample;
SELECT * FROM dbo.DEMOGRAPHICS;

SELECT * FROM dbo.session;

---- create inclusion subset test
--DROP TABLE IF EXISTS #study_cohort_inclusion;
--GO
--SELECT patid, birth_date, 
--	(SELECT year from codi.get_age(birth_date, '1/1/2017')) AS study_age_yrs
--INTO #study_cohort_inclusion
-- FROM cdm.demographic
-- WHERE patid IN (
--	SELECT patid 
--	FROM codi.session
--		 WHERE DATEPART(YEAR, session_date) = 2017
--		 AND programid IN (SELECT programid from #study_programs)
-- )
--AND (SELECT year from codi.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
--GO

-- create inclusion flag 
DROP TABLE IF EXISTS #study_cohort_inclusion;
GO
SELECT 
	PERSON_ID AS patid, 
	birth_date, 
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) AS study_age_yrs,
	CASE WHEN PERSON_ID IN (
		(SELECT 
			patid 
		FROM 
			dbo.session
		WHERE 
			DATEPART(YEAR, session_date) = 2017
			AND programid IN (SELECT programid from #study_programs))) THEN 1 ELSE 0 END AS inclusion
INTO 
	#study_cohort_inclusion
FROM 
	dbo.DEMOGRAPHICS
WHERE
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
GO

SELECT * FROM #study_cohort_inclusion WHERE inclusion = 1;

---- create exclusion subset
--DROP TABLE IF EXISTS #study_cohort_exclusion;
--GO
--SELECT patid, birth_date, 
--	(SELECT year from codi.get_age(birth_date, '1/1/2017')) AS study_age_yrs
--INTO #study_cohort_exclusion
-- FROM cdm.demographic
-- WHERE patid IN (
--	SELECT patid  
--	FROM codi.session
--		WHERE session_date >= '1-Jun-2016' AND session_date < '1-Jan-2017'
--		AND programid IN (SELECT programid from #study_programs)
-- )
--AND (SELECT year from codi.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
--GO

--SELECT * FROM #study_cohort_exclusion;

-- create exclusion flag
DROP TABLE IF EXISTS #study_cohort_exclusion;
GO
SELECT 
	PERSON_ID AS patid, 
	birth_date, 
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) AS study_age_yrs,
	CASE WHEN PERSON_ID IN (
		(SELECT 
			patid  
		FROM 
			dbo.session
		WHERE 
			session_date >= '1-Jun-2016' AND session_date < '1-Jan-2017'
				AND programid IN (SELECT programid from #study_programs))) THEN 1 ELSE 0 END AS exclusion
INTO 
	#study_cohort_exclusion
FROM 
	dbo.DEMOGRAPHICS
WHERE 
	(SELECT year from dbo.get_age(birth_date, '1/1/2017')) BETWEEN 2 AND 19;
GO





SELECT * FROM #study_cohort ORDER BY study_age_yrs;
-- Determines, for each child, the most recent well-child-visit in then right date range.
-- TODO: Use only the well-child-visit codes; the sample data is lacking those right now.

-- LATEST CHILD VISIT FOR EACH CALENDER YEAR OR LASTEST ADDRESS NO LATER THAN THE LAST DAY OF
-- CALENER YEAR  
DROP TABLE IF EXISTS #recent_well_child;
GO
SELECT 
	PERSON_ID AS patid, 
	MAX(PROCDATE) most_recent_well_child_visit
INTO #recent_well_child
FROM dbo.PROCEDURES
WHERE PROCDATE >= '6/1/2016' AND PROCDATE < '1/1/2020'
GROUP BY PERSON_ID;

-- Determines, for each child, the number of encounters in calendar year 2017.
DROP TABLE IF EXISTS #encounter_count;
GO
SELECT 
	PERSON_ID AS patid, 
	COUNT(ENC_ID) enc_count
INTO #encounter_count
FROM dbo.ENCOUNTERS
WHERE DATEPART(YEAR, ADATE) = 2017
GROUP BY PERSON_ID;

-- Builds the record that needs to be shared with the DCC.

DROP TABLE IF EXISTS #study_cohort_export;
GO
SELECT S.patid, most_recent_well_child_visit, enc_count
INTO #study_cohort_export
FROM #study_cohort S
	LEFT OUTER JOIN #recent_well_child R ON S.patid = R.patid
	LEFT OUTER JOIN #encounter_count E ON S.patid = E.patid;

SELECT * FROM #study_cohort_export;

DROP TABLE IF EXISTS #cohort;
GO
CREATE TABLE #cohort (
	patid varchar(255) PRIMARY KEY,
	ageyrs integer, -- Is this the right unit?
	sex varchar(2),
	-- enumerate conditions,
	pmca integer,
	bmi_percent_of_p95 double precision,
	distance_from_program double precision, -- In what units?
	pat_pref_language_spoken varchar(3),
	race varchar(2),
	hispanic varchar(2),
	insurance varchar(1),
	in_study_cohort varchar(1)
);
INSERT INTO #cohort
(patid, ageyrs, sex, pat_pref_language_spoken, race, hispanic, in_study_cohort)
SELECT 
	d.PERSON_ID, 
	(SELECT year from dbo.get_age(d.birth_date, '1/1/2017')) ,
	GENDER, 
	PRIMARY_LANGUAGE, 
	RACE1, 
	hispanic,
	CASE WHEN s.patid IS NOT NULL THEN 'T' ELSE 'F' END
FROM dbo.DEMOGRAPHICS d LEFT OUTER JOIN #study_cohort s ON d.PERSON_ID = s.patid;

SELECT * FROM #cohort;

DROP TABLE IF EXISTS #study_cohort_demographic;
GO
SELECT 
	cohort_demographic_age_filter.linkid, 
	cohort_demographic_age_filter.patid, 
	cohort_demographic_age_filter.birth_date, 
	cohort_demographic_age_filter.sex, 
	cohort_demographic_age_filter.race, 
	cohort_demographic_age_filter.hispanic, 
	cohort_demographic_age_filter.yr, 
	cohort_demographic_age_filter.encN, 
	cohort_demographic_age_filter.loc_start, 
	--cohort_demographic_age_filter.loc_end,
	--cohort_demographic_age_filter.geocode_boundary_year,
	--cohort_demographic_age_filter.geolevel,
	--cohort_demographic_age_filter.latitude,
	--cohort_demographic_age_filter.longitude,
	--cohort_demographic_age_filter.census_location_id,
	#study_cohort_export.most_recent_well_child_visit,
	#study_cohort_export.enc_count,
	#study_cohort_inclusion.inclusion,
	#study_cohort_exclusion.exclusion
INTO #study_cohort_demographic
FROM 
	cohort_demographic_age_filter 
		LEFT OUTER JOIN #study_cohort_export ON cohort_demographic_age_filter.patid = #study_cohort_export.patid
		LEFT OUTER JOIN #study_cohort_inclusion ON cohort_demographic_age_filter.patid = #study_cohort_inclusion.patid
		LEFT OUTER JOIN #study_cohort_exclusion ON cohort_demographic_age_filter.patid = #study_cohort_exclusion.patid
;

--SELECT * FROM #study_cohort_demographic;
--SELECT * FROM #study_cohort_demographic WHERE enc_count IS NOT NULL;

DROP TABLE IF EXISTS study_cohort_demographic;
GO
SELECT 
	linkid,
	encN,
	birth_date,
	sex,
	race,
	hispanic,
	yr,
	loc_start,
	most_recent_well_child_visit,
	enc_count,
	inclusion,
	exclusion
INTO 
	study_cohort_demographic
FROM 
	#study_cohort_demographic
;

-- EXPORT csv after STEP 1 for both use case
-- execute this script and write output of the SELECT statement below to file --
-- sqlcmd -S <server name> -d <database name> -E -Q "SELECT * FROM study_cohort_demographic" -o "MyData.csv" -s "," -w 1000

SELECT * FROM study_cohort_demographic WHERE yr = 2017;

SELECT * FROM study_cohort_demographic WHERE yr = 2017 AND inclusion = 1;

SELECT * FROM study_cohort_demographic ORDER BY birth_date;


SELECT * FROM study_cohort_demographic ORDER BY linkid;

SELECT * FROM dbo.DEMOGRAPHICS ORDER BY birth_date;


USE Alumni_Salesforce_Testing
GO

/**********Declare Globals*************************/

DECLARE @Universal_Cohort AS INT
SET @Universal_Cohort = 2016

--Switch to pull academic data completeness
DECLARE @Summarize_Academic_Data AS BIT
SET @Summarize_Academic_Data = 1

--Create region lookup to crosswalk datasets.
CREATE TABLE #tt_Region_Lookup (
 Region_ID INT
,Salesforce_ID VARCHAR(255)
,Region_Name VARCHAR(255)
)
/********Create Regional Lookup Table************/
--Need to see if there's an easier way to do this...-MH
INSERT INTO #tt_Region_Lookup (Region_ID, Salesforce_ID, Region_Name)
 VALUES (4 ,'0018000000etIHIAA2','TEAM Schools')
,(1800 ,'0018000000etIHJAA2','KIPP Reach')
,(16 ,'0018000000etIDUAA2','KIPP Baltimore')
,(26 ,'0018000000eKkINAA0','KIPP DFW')
,(19 ,'0018000000esCKBAA2','KIPP Colorado')
,(21 ,'0018000000etIHFAA2','KIPP Memphis')
,(15 ,'0018000000eKk9ZAAS','Philadelphia')
,(10 ,'0018000000eKkjZAAS','KIPP New Orleans')
,(33 ,'0018000000etIHBAA2','KIPP Indianapolis')
,(2 ,'0018000000Zuh1bAAB','KIPP NYC')
,(3 ,'0018000000ZuUh5AAF','KIPP Houston')
,(27 ,'0018000000etIHEAA2','KIPP Mass')
,(13 ,'0018000000etIHDAA2','KIPP LA')
,(3600 ,'0018000000etIHMAA2','KIPP Adelante')
,(22 ,'0018000000eKkibAAC','KIPP Chicago')
,(18 ,'0018000000etIHLAA2','KIPP San Antonio')
,(12 ,'0018000000etIDTAA2','KIPP Austin')
,(1 ,'0018000000etIHKAA2','KIPP Bay Area')
,(6 ,'0018000000eKkIcAAK','KIPP DC')
,(11 ,'0018000000esCKGAA2','KIPP Delta')
,(32 ,'0018000000etIHAAA2','KIPP Gaston')
,(9 ,'0018000000etIDSAA2','KIPP Metro Atlanta')
,(4700,'0018000000etIHOAA2','KIPP Tulsa')
,(31,'0018000000etIHHAA2','KIPP Nashville')
,(6200,'0018000000etIH8AAM','KIPP Charlotte')
,(6100,'0018000000etIHCAA2','KIPP Kansas City')
,(4600,'0018000000etIDRAA2','KIPP Albany')
,(7500,'0018000000etIHGAA2','KIPP Minneapolis')
,(17,'0018000000etIH9AAM','KIPP Central Ohio')


/*******Pulls in Middle School Completers********/
SELECT C.Id
	,L.Region_ID
	,L.Region_Name
	,C.Name AS Contact_Name
	,E.Name AS Enrollment_Name
	,A.Name AS Account_Name
	,E.Student_HS_Cohort__c
	,C.Highest_ACT_Score__c
	,C.Highest_SAT_Score__c
	,(CASE WHEN (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_HS_Assessment
	,E.Status__c
	,'8th Grade Completer' AS Alumni_Type
	
  INTO #tt_8th_Grade_Cohort	
  FROM Contact C
  JOIN Enrollment__c E
  ON C.Id = E.Student__c
  JOIN Account A
  ON E.School__c = A.Id
  LEFT JOIN #tt_Region_Lookup L
  ON A.ParentId = L.Salesforce_ID
  WHERE E.Student_HS_Cohort__c  <= (@Universal_Cohort)
  AND A.Name LIKE '%KIPP%'
  AND A.RecordTypeId = '01280000000BRFEAA4'
  AND E.Status__c = 'Graduated'
  
  --SELECT * FROM #tt_8th_Grade_Cohort
  --DROP TABLE #tt_8th_Grade_Cohort
  --DROP TABLE #tt_Region_Lookup
  
  
  /***************Pulls in 9th Grade Starters*******************/
  
  SELECT C.Id
	,L.Region_ID
	,L.Region_Name
	,C.Name AS Contact_Name
	,E.Name AS Enrollment_Name
	,A.Name AS Account_Name
	,1 AS KIPP_HS
	,E.Student_HS_Cohort__c
	,C.Highest_ACT_Score__c
	,C.Highest_SAT_Score__c
	,E.Final_GPA__c
	,(CASE WHEN E.Final_GPA__c IS NOT NULL
		THEN 1
		ELSE 0
		END) AS N_GPA
	,(CASE WHEN (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_HS_Assessment
	,E.Status__c
	,'9th Grade Starter' AS Alumni_Type
	
  INTO #tt_9th_Grade_Starters	
  FROM Contact C
  JOIN Enrollment__c E
  ON C.Id = E.Student__c
  JOIN Account A
  ON E.School__c = A.Id
  JOIN #tt_Region_Lookup L
  ON A.ParentId = L.Salesforce_ID
  WHERE E.Student_HS_Cohort__c <= (@Universal_Cohort)
  AND A.Name LIKE '%KIPP%'
  AND A.RecordTypeId = '01280000000BQEjAAO'
  AND E.Status__c NOT IN ('Withdrawn', 'Transferred out')
  AND C.Id NOT IN (SELECT Id --Removes all students previously identified as 8th grade completers.
  FROM #tt_8th_Grade_Cohort
  )
  
  --SELECT * FROM #tt_9th_Grade_Starters
  --DROP TABLE #tt_8th_Grade_Cohort
  --DROP TABLE #tt_9th_Grade_Starters
  --DROP TABLE #tt_Region_Lookup
  
  
  /***************Scrub Data as Needed************************/
  --Transfers NOW students over to KIPP Houston
  UPDATE #tt_8th_Grade_Cohort
  SET Region_ID = 3
  , Region_Name = 'KIPP Houston'
  WHERE Id IN ('0038000000y6FnvAAE', '0038000000n07mrAAA')
  
  /****************Pull in 8th Grade Alum High School Data*********/
  SELECT G.Id
  ,G.Region_ID	
  ,G.Region_Name
  ,G.Contact_Name
  ,E.Name AS HS_Enroll_Name
  ,A.Name AS HS_Name
  ,(CASE WHEN E.Name LIKE '%KIPP%' 
		THEN 1 
		ELSE 0 END) AS KIPP_HS
  ,G.Student_HS_Cohort__c
  ,G.Highest_ACT_Score__c
  ,G.Highest_SAT_Score__c
  ,E.Final_GPA__c
  ,(CASE WHEN E.Final_GPA__c IS NOT NULL
		THEN 1
		ELSE 0
		END) AS N_GPA
  ,G.N_HS_Assessment
  ,G.Status__c
  ,G.Alumni_Type
  INTO #tt_8th_Grade_Mod
  FROM #tt_8th_Grade_Cohort G
  JOIN Enrollment__c E
  ON G.Id = E.Student__c
  JOIN Account A
  ON E.School__c = A.Id
  /****Filters for most current HS enrollment***/
  JOIN (
  SELECT
	Student__c
  ,MAX(Start_Date__c) AS time_stamp
  FROM Enrollment__c
  JOIN Account
  ON Enrollment__c.School__c = Account.Id
  WHERE Account.RecordTypeId = '01280000000BQEjAAO'
  GROUP BY Student__c) AS T
  ON E.Start_Date__c = T.time_stamp
  AND E.Student__c = T.Student__c
  WHERE A.RecordTypeId = '01280000000BQEjAAO'
  AND E.Status__c NOT IN ('Withdrawn', 'Transferred out')
 
  
  --SELECT * FROM #tt_8th_Grade_Mod
  --DROP TABLE #tt_8th_Grade_Mod
  --DROP TABLE #tt_9th_Grade_Starters
  --DROP TABLE #tt_8th_Grade_Cohort
  --DROP TABLE #tt_Region_Lookup
  
  /***************Create Union Table of Alumni Types************************/
  
  SELECT * 
  INTO #tt_All_Alums 
  FROM( 
  SELECT
   Id
  ,Region_ID
  ,Region_Name
  ,Contact_Name
  ,HS_Enroll_Name
  ,HS_Name
  ,KIPP_HS
  ,Student_HS_Cohort__c
  ,Highest_ACT_Score__c
  ,Highest_SAT_Score__c
  ,N_HS_Assessment
  ,Final_GPA__c
  ,Alumni_Type
  ,N_GPA
  FROM #tt_8th_Grade_Mod
  
  UNION
  
  SELECT
   Id
  ,Region_ID
  ,Region_Name
  ,Contact_Name
  ,Enrollment_Name AS HS_Enroll_Name
  ,Account_Name AS HS_Name
  ,KIPP_HS
  ,Student_HS_Cohort__c
  ,Highest_ACT_Score__c
  ,Highest_SAT_Score__c
  ,N_HS_Assessment
  ,Final_GPA__c
  ,Alumni_Type
  ,N_GPA
  FROM #tt_9th_Grade_Starters
  ) AS A
  
  --SELECT * FROM #tt_All_Alums
  --DROP TABLE #tt_All_Alums
  --DROP TABLE #tt_8th_Grade_Cohort
  --DROP TABLE #tt_8th_Grade_Mod
  --DROP TABLE #tt_9th_Grade_Starters
  --DROP TABLE #tt_Region_Lookup
  
  /***************Pulls in Application Data**********************/
  SELECT
   P.Id
  ,P.Name
  ,P.RecordTypeId
  ,P.Applicant__c
  ,School__c
  ,P.Application_Status__c
  --I HATE STRING MATCHING. -MH
  ,CASE WHEN Application_Status__c IN (
   'Withdrawn'
  ,'Conditionally Accepted'
  ,'Rescinded'
  ,'Withdrew Application'
  ,'Accepted'
  ,'Matriculated'
  ,'Waitlist'
  ,'Accepted (Chicago region - Replied)'
  ,'Denied'
  ,'Deferred'
  )
  THEN 1
  ELSE 0
  END AS Application_Closed 
  ,Type__c
INTO #tt_Applications  
FROM Application__c P
WHERE
Type__c = 'College' 
--AND Application_Status__c
--IN ('Withdrawn'
--,'Conditionally Accepted'
--,'Rescinded'
--,'Unknown'
--,'Withdrew Application'
--,'Not Matched'
--,'Accepted'
--,'Submitted'
--,'Incomplete'
--,'Matriculated'
--,'Wishlist'
--,'Waitlist'
--,'Accepted (Chicago region - Replied)'
--,'Denied'
--,'Cancelled Application'
--,'In Progress'
--,'Not Started'
--,'Deferred'
)
AND P.Applicant__c IN (
SELECT Id
FROM #tt_All_Alums
)

--SELECT * FROM #tt_Applications
--DROP TABLE #tt_Applications
--DROP TABLE #tt_All_Alums
--DROP TABLE #tt_8th_Grade_Cohort
--DROP TABLE #tt_8th_Grade_Mod
--DROP TABLE #tt_9th_Grade_Starters
--DROP TABLE #tt_Region_Lookup
  
  
  /***************Summarizes student academic data by region*****************/
 WHILE @Summarize_Academic_Data = 1
 BEGIN
 SET @Summarize_Academic_Data = 0
 
 SELECT
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
  ,COUNT(Id) AS N_Students
  ,SUM(N_GPA) AS N_GPA
  ,CAST((SUM(N_GPA) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_GPA  
  ,SUM(N_HS_Assessment) AS N_HS_Assessment
  ,CAST((SUM(N_HS_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_Assessment
  FROM #tt_All_Alums
  
  GROUP BY
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
  
  ORDER BY 
   Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
  
 /*****Originally had the UNION during the aggregate statement. This seems to be catching some duplicates so I've disabled. -MH*****/
 -- SELECT * 
 -- FROM (
 -- SELECT 
 --  Region_ID
 -- ,Region_Name
 -- ,Student_HS_Cohort__c
 -- ,Alumni_Type
 -- ,COUNT(Id) AS N_Students
 -- ,SUM(N_GPA) AS N_GPA
 -- ,CAST((SUM(N_GPA) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_GPA  
 -- ,SUM(N_HS_Assessment) AS N_HS_Assessment
 -- ,CAST((SUM(N_HS_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_Assessment
 -- FROM #tt_8th_Grade_Mod
  
 -- GROUP BY
 --  Region_ID
 -- ,Region_Name
 -- ,Student_HS_Cohort__c
 -- ,Alumni_Type
  
 -- UNION
  
 -- SELECT 
 --  Region_ID
 -- ,Region_Name
 -- ,Student_HS_Cohort__c
 -- ,Alumni_Type
 -- ,COUNT(Id) AS N_Students
 -- ,SUM(N_GPA) AS N_GPA
 -- ,CAST((SUM(N_GPA) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_GPA
 -- ,SUM(N_HS_Assessment) AS N_HS_Assessment
 -- ,CAST((SUM(N_HS_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_Assessment
 -- FROM #tt_9th_Grade_Starters
    
 -- GROUP BY
 --  Region_ID
 -- ,Region_Name
 -- ,Student_HS_Cohort__c
 -- ,Alumni_Type
 --) AS A
 
 -- ORDER BY 
 --  Region_Name
 -- ,Student_HS_Cohort__c
 -- ,Alumni_Type
  
  END
  
  DROP TABLE #tt_Region_Lookup
  DROP TABLE #tt_8th_Grade_Cohort
  DROP TABLE #tt_8th_Grade_Mod
  DROP TABLE #tt_9th_Grade_Starters
  DROP TABLE #tt_All_Alums
  DROP TABLE #tt_Applications
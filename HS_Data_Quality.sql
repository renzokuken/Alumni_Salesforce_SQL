USE Alumni_Salesforce_Testing
GO

/**********Declare Globals*************************/

DECLARE @Universal_Cohort AS INT
SET @Universal_Cohort = 2016

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
  
  
  /***************Pulls in 9th Grade Starters*******************/
  SELECT C.Id
	,L.Region_ID
	,L.Region_Name
	,C.Name AS Contact_Name
	,E.Name AS Enrollment_Name
	,A.Name AS Account_Name
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
  ,G.Student_HS_Cohort__c
  ,G.Highest_ACT_Score__c
  ,G.Highest_SAT_Score__c
  ,G.N_HS_Assessment
  ,E.Final_GPA__c
  ,G.Alumni_Type
  ,(CASE WHEN E.Final_GPA__c IS NOT NULL
		THEN 1
		ELSE 0
		END) AS N_GPA
  INTO #tt_8th_Grade_Mod
  FROM #tt_8th_Grade_Cohort G
  JOIN Enrollment__c E
  ON G.Id = E.Student__c
  JOIN Account A
  ON E.School__c = A.Id
  WHERE A.RecordTypeId = '01280000000BQEjAAO'
  AND E.Status__c NOT IN ('Withdrawn', 'Transferred out')
  
  --SELECT * FROM #tt_8th_Grade_Mod
  --DROP TABLE #tt_8th_Grade_Mod
  
  
  
  /***************Summarizes students by region*****************/
 
  SELECT * 
  FROM (
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
  FROM #tt_8th_Grade_Mod
  
  GROUP BY
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
  
  UNION
  
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
  FROM #tt_9th_Grade_Starters
    
  GROUP BY
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
 ) AS A
 --WHERE Student_HS_Cohort__c IN (2010, 2011, 2012)
  ORDER BY 
   Region_Name
  ,Student_HS_Cohort__c
  ,Alumni_Type
  
  DROP TABLE #tt_Region_Lookup
  DROP TABLE #tt_8th_Grade_Cohort
  DROP TABLE #tt_8th_Grade_Mod
  DROP TABLE #tt_9th_Grade_Starters
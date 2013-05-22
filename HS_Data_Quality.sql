USE Attainment
GO

/**********Declare Globals*************************/

DECLARE @Universal_Cohort AS INT
SET @Universal_Cohort = 2016

--Switch to pull academic data completeness
DECLARE @Summarize_Academic_Data AS BIT
SET @Summarize_Academic_Data = 1

--Switch to pull application data completeness
DECLARE @Summarize_Application_Data AS BIT
SET @Summarize_Application_Data = 1

--Switch to pull financial data completeness
DECLARE @Summarize_Financial_Data AS BIT
SET @Summarize_Financial_Data = 0

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
	,C.Cumulative_GPA__c
	,C.YTD_GPA__c
	,C.Highest_ACT_Score__c
	,C.Highest_SAT_Score__c
	,(CASE WHEN (C.Cumulative_GPA__c IS NOT NULL OR YTD_GPA__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_GPA
	,(CASE WHEN (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_HS_Assessment
    ,(CASE WHEN ((C.Cumulative_GPA__c IS NOT NULL OR YTD_GPA__c IS NOT NULL) AND (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL))
		THEN 1
		ELSE 0
		END) AS N_GPA_and_Assessment
	,E.Status__c
	,C.EFC_from_FAFSA__c
	,(CASE WHEN C.EFC_from_FAFSA__c IS NOT NULL
		THEN 1
		ELSE 0
		END) AS N_FAFSA
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
	,C.Cumulative_GPA__c
	,C.YTD_GPA__c
	,C.Highest_ACT_Score__c
	,C.Highest_SAT_Score__c
    ,(CASE WHEN (C.Cumulative_GPA__c IS NOT NULL OR YTD_GPA__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_GPA
	,(CASE WHEN (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL)
		THEN 1
		ELSE 0
		END) AS N_HS_Assessment
    ,(CASE WHEN ((C.Cumulative_GPA__c IS NOT NULL OR YTD_GPA__c IS NOT NULL) AND (C.Highest_SAT_Score__c IS NOT NULL OR C.Highest_ACT_Score__c IS NOT NULL))
		THEN 1
		ELSE 0
		END) AS N_GPA_and_Assessment
	,E.Status__c
	,C.EFC_from_FAFSA__c
	,(CASE WHEN C.EFC_from_FAFSA__c IS NOT NULL
		THEN 1
		ELSE 0
		END) AS N_FAFSA
	,'High School Starter' AS Alumni_Type
	
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
  --AND E.Status__c NOT IN ('Withdrawn', 'Transferred out')
  AND C.Id NOT IN (
  SELECT Id --Removes all students previously identified as 8th grade completers.
  FROM #tt_8th_Grade_Cohort
  )
  
  --SELECT * FROM #tt_9th_Grade_Starters
  
  
  /***************Scrub Data as Needed************************/
  --Transfers NOW students over to KIPP Houston
  UPDATE #tt_8th_Grade_Cohort
  SET Region_ID = 3
  , Region_Name = 'KIPP Houston'
  WHERE Id IN ('0038000000y6FnvAAE', '0038000000n07mrAAA')
  
  /*****************Pull in most recent HS enrollment**********/
    SELECT
     E.Student__c
    ,E.Name
    ,E.Final_GPA__c 
    ,School__c
    INTO #tt_Max_HS_Enrollment
    FROM Enrollment__c E
    JOIN Account A
    ON E.School__c = A.Id
    JOIN (
    SELECT
	Student__c
  ,MAX(Start_Date__c) AS time_stamp
  FROM Enrollment__c
  LEFT JOIN Account
  ON Enrollment__c.School__c = Account.Id
  WHERE Account.RecordTypeId = '01280000000BQEjAAO'
  AND Student__c IN (
  SELECT Student__c
  FROM #tt_8th_Grade_Cohort
  )
  GROUP BY Student__c) AS T
  ON E.Start_Date__c = T.time_stamp
  AND E.Student__c = T.Student__c
  
  /****************Join in 8th Grade Alum High School Data*********/
  SELECT G.Id
  ,G.Region_ID	
  ,G.Region_Name
  ,G.Contact_Name
  ,E.Name AS HS_Enroll_Name
  ,A.Name AS HS_Name
  ,(CASE WHEN E.Name LIKE '%KIPP%' 
		THEN 1
		WHEN E.Name IS NULL 
		THEN 0 
		ELSE 0 END) AS KIPP_HS
  ,G.Student_HS_Cohort__c
  ,G.Cumulative_GPA__c
  ,G.YTD_GPA__c
  ,G.Highest_ACT_Score__c
  ,G.Highest_SAT_Score__c
  ,G.N_GPA
  ,G.N_HS_Assessment
  ,G.N_GPA_and_Assessment
  ,G.Status__c
  ,G.Alumni_Type
  ,G.EFC_from_FAFSA__c
  INTO #tt_8th_Grade_Mod
  FROM #tt_8th_Grade_Cohort G
  LEFT JOIN #tt_Max_HS_Enrollment E
  ON G.Id = E.Student__c
  LEFT JOIN Account A
  ON E.School__c = A.Id
    
  --SELECT * FROM #tt_8th_Grade_Mod
  
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
  ,N_GPA_and_Assessment
  ,Cumulative_GPA__c
  ,YTD_GPA__c
  ,Alumni_Type
  ,EFC_from_FAFSA__c
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
  ,N_GPA_and_Assessment
  ,Cumulative_GPA__c
  ,YTD_GPA__c
  ,Alumni_Type
  ,EFC_from_FAFSA__c
  ,N_GPA
  FROM #tt_9th_Grade_Starters
  ) AS A
  
  SELECT * FROM #tt_All_Alums

  /***************Summarizes student academic data by region*****************/
 WHILE @Summarize_Academic_Data = 1
 BEGIN
 SET @Summarize_Academic_Data = 0
 
 SELECT
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,KIPP_HS
  --,Alumni_Type
  ,COUNT(Id) AS N_Students
  ,SUM(N_GPA) AS N_GPA
  ,SUM(N_HS_Assessment) AS N_HS_Assessment
  ,SUM(N_GPA_and_Assessment) AS N_GPA_and_Assessment
  ,CASE WHEN (CAST((SUM(N_GPA) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) = 0) 
   THEN NULL
   ELSE CAST((SUM(N_GPA) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) END AS PCT_GPA  
  ,CASE WHEN (CAST((SUM(N_HS_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) = 0)
   THEN NULL
   ELSE CAST((SUM(N_HS_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) END AS PCT_Assessment
  ,CASE WHEN (CAST((SUM(N_GPA_and_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) = 0)
   THEN NULL
   ELSE CAST((SUM(N_GPA_and_Assessment) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) END AS PCT_GPA_and_Assessment
  FROM #tt_All_Alums
  
  GROUP BY
   Region_ID
  ,Region_Name
  ,Student_HS_Cohort__c
  ,KIPP_HS
  --,Alumni_Type
  
  ORDER BY 
   Region_Name
  ,Student_HS_Cohort__c
  ,KIPP_HS
  --,Alumni_Type
  
  END
  
  /***************Pulls in Application Data**********************/
  

  
  SELECT
   P.Id
  ,P.Name
  ,P.RecordTypeId
  ,P.Applicant__c
  ,School__c
  ,P.Application_Status__c
  ,CASE WHEN Application_Status__c IN (  --I HATE STRING MATCHING. -MH
   'Accepted'
  ,'Conditionally Accepted'
  ,'Matriculated'
  ,'Denied'
  ,'Deferred'
  )
  THEN 1
  ELSE 0
  END AS Application_Closed 
  ,CASE WHEN Application_Status__c IN ('Accepted', 'Matriculated', 'Deferred') 
   THEN 1 
   ELSE 0 
   END AS Accepted_Flag --I assume that Matriculated should be captured under here for now - MH
  ,Type__c
INTO #tt_Applications  
FROM Application__c P
WHERE
Type__c = 'College' 
AND Application_Status__c
IN (
 'Accepted'
,'Conditionally Accepted'
,'Submitted'
,'Matriculated'
,'Waitlist'
,'Denied'
,'Deferred'
)
AND P.Applicant__c IN (
SELECT Id
FROM #tt_All_Alums
)

--SELECT * FROM #tt_Applications

  /***************Summarizes application data by student***************/
  
 SELECT
   A.Id
  ,A.Contact_Name
  ,A.Region_ID
  ,A.Region_Name
  ,A.KIPP_HS
  ,A.Student_HS_Cohort__c
  ,A.Alumni_Type
  ,EFC_from_FAFSA__c
  ,COUNT(P.Id) AS N_Applications
  ,SUM(P.Application_Closed) AS N_Closed
  ,CASE WHEN (COUNT(P.Id) >= 9) THEN '9+ Apps' --I should REALLY set these to integer values...-MH
		WHEN (COUNT(P.Id) >= 4 AND (COUNT(P.Id) < 9)) THEN '4-8 Apps'
		WHEN (COUNT(P.Id) = 0) THEN 'Zero Apps'
		WHEN (COUNT(P.Id) IS NULL) THEN 'Zero Apps'
		ELSE '<4 Apps'
		END AS N_Apps
  ,CASE WHEN SUM(Accepted_Flag) IS NULL THEN 0
		ELSE SUM(Accepted_Flag)
		END AS N_Accepted
  ,CASE WHEN SUM(Accepted_Flag) >= 1 
   THEN '1+ Accepted'
   ELSE 'No Acceptances' END AS Accepted
  INTO #tt_Alum_Acceptance
  FROM #tt_All_Alums A
  LEFT JOIN #tt_Applications P
  ON A.Id = P.Applicant__c
  
  GROUP BY
   A.Id
  ,A.Contact_Name
  ,A.Region_ID
  ,A.Region_Name
  ,A.KIPP_HS
  ,A.Student_HS_Cohort__c
  ,A.Alumni_Type
  ,A.EFC_from_FAFSA__c
  
  SELECT * FROM #tt_Alum_Acceptance  
  
  /***************Summarizes application data by region*******************/
  
  WHILE @Summarize_Application_Data = 1
  BEGIN
  SET @Summarize_Application_Data = 0 
  
  SELECT
   Region_ID
  ,Region_Name
  ,KIPP_HS
  ,Student_HS_Cohort__c
  ,Alumni_Type
  ,COUNT(Id) AS N_Students
  ,SUM(N_Applications) AS N_Applications
  ,SUM(N_Closed) AS N_Closed_Apps
  ,SUM(N_Accepted) AS N_Accepted_Apps
  ,SUM(CASE WHEN N_Apps <> 'Zero Apps'
   THEN 1
   ELSE 0 END) AS N_Students_Submitted
  ,SUM(CASE WHEN N_Apps = '4-8 Apps'
   THEN 1 
   ELSE 0 END) AS N_4_to_8
  ,SUM(CASE WHEN N_Apps = '9+ Apps'
   THEN 1 
   ELSE 0 END) AS N_Over_9
  ,SUM(CASE WHEN Accepted = '1+ Accepted'
   THEN 1 
   ELSE 0 END) AS N_Accepted_Students
  ,CAST((SUM(N_Applications)) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS AVG_Apps_Per_Student
  ,CAST((SUM(CASE WHEN N_Apps = '4-8 Apps' 
   THEN 1 
   ELSE 0 END) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_4_to_8
  ,CAST((SUM(CASE WHEN N_Apps = '9+ Apps' 
   THEN 1 
   ELSE 0 END) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_Over_9
  ,CAST(SUM(N_Closed) * 100 / (SUM(N_Applications) + 0.0) AS DEC(5,2)) AS PCT_Closed
  ,CAST((SUM(CASE WHEN Accepted = '1+ Accepted' 
   THEN 1 
   ELSE 0 END) * 100) / (COUNT(Id) + 0.0) AS DEC(5,2)) AS PCT_Accepted

  FROM #tt_Alum_Acceptance
  
  GROUP BY
   Region_ID
  ,Region_Name
  ,KIPP_HS
  ,Student_HS_Cohort__c
  ,Alumni_Type
    
  END


/**********Pull in Financial Aid Data************/



  SELECT
   A.Id AS Application_ID
  ,A.Name
  ,A.RecordTypeId
  ,A.Applicant__c
  ,School__c
  ,A.Type__c
  ,F.Id AS Aid_ID
  ,CASE WHEN F.Id IS NOT NULL 
		THEN 1 
		ELSE 0 
		END AS Application_Aid_Flag
INTO #tt_Financial_Aid_Stage
FROM #tt_Applications A
LEFT JOIN Aid_Line_Item__c F
ON A.Id = F.Application__c
WHERE Accepted_Flag = 1

--SELECT * FROM #tt_Financial_Aid_Stage

   SELECT
    Application_ID
   ,Name
   ,RecordTypeId
   ,Applicant__c
   ,School__c
   ,Type__c
   ,COUNT(Aid_ID) AS N_Aid_Packages
   ,AVG(Application_Aid_Flag) AS Application_Aid_Flag
INTO #tt_Financial_Aid_Stage_Two
FROM #tt_Financial_Aid_Stage

GROUP BY
    Application_ID
   ,Name
   ,RecordTypeId
   ,Applicant__c
   ,School__c
   ,Type__c

SELECT
	 Applicant__c
	,Type__c
	,COUNT(School__c) AS N_Accepted
	,SUM(N_Aid_Packages) AS N_Aid_Packages
	,SUM(Application_Aid_Flag) AS Application_Aid_Flag
INTO #tt_Financial_Aid
FROM #tt_Financial_Aid_Stage_Two

GROUP BY
	Applicant__c
   ,RecordTypeId
   ,Type__c

--SELECT * FROM #tt_Financial_Aid


/********Pull in Scholarship Data**********/
  SELECT
   Id
  ,Name
  ,Applicant__c
  ,Amount__c
  ,Status__c
  ,Amount_Type__c
INTO #tt_Scholarships
FROM Scholarship_Application__c
WHERE Applicant__c IN (
SELECT Id
FROM #tt_All_Alums
)

/************Links Financial Aid data to students***************/

 SELECT
   A.Id
  ,A.Contact_Name
  ,A.Region_ID
  ,A.Region_Name
  ,A.KIPP_HS
  ,A.Student_HS_Cohort__c
  ,A.Alumni_Type
  ,A.EFC_from_FAFSA__c
  ,A.N_Applications
  ,A.N_Accepted
  ,SUM(Application_Aid_Flag) AS Application_Aid_Flag
  ,CASE WHEN A.EFC_from_FAFSA__c IS NULL 
	THEN 0
	ELSE 1
	END AS EFC_FAFSA_Flag
  ,N_Aid_Packages
  ,CASE WHEN (N_Aid_Packages >= 1)
		THEN 1
		END AS Student_Aid_Flag
  ,CASE WHEN COUNT(S.Id) IS NULL
		THEN 0
		ELSE COUNT(S.Id)
		END AS N_with_Scholarship
  ,CASE WHEN (COUNT(S.Id) >=1)
		THEN 1
		WHEN COUNT(S.Id) IS NULL
		THEN 0
		ELSE 0
		END AS Scholarship_Flag
  INTO #tt_Student_Aid
  FROM #tt_Alum_Acceptance A
  LEFT JOIN #tt_Financial_Aid F
  ON A.Id = F.Applicant__c
  LEFT JOIN #tt_Scholarships S
  ON A.Id = S.Applicant__c
  
  GROUP BY
   A.Id
  ,A.Contact_Name
  ,A.Region_ID
  ,A.Region_Name
  ,A.KIPP_HS
  ,A.Student_HS_Cohort__c
  ,A.Alumni_Type
  ,A.N_Applications
  ,A.N_Accepted
  ,A.EFC_from_FAFSA__c
  ,N_Aid_Packages
  
  --SELECT * FROM #tt_Student_Aid
  
/********Summarizes Financial Aid Data by Region**********/

 WHILE @Summarize_Financial_Data = 1
 BEGIN
 SET @Summarize_Financial_Data = 0 

SELECT Region_ID
,Region_Name
,KIPP_HS
,Student_HS_Cohort__c
,Alumni_Type
,COUNT(Id) AS N_Students
,SUM(CASE WHEN (N_Accepted >= 1)
		  THEN 1
		  ELSE 0
		  END) AS N_Accepted_Students
,SUM(N_Applications) AS N_Applications
,SUM(N_Accepted) AS N_Accepted_Apps
,SUM(Application_Aid_Flag) AS N_Accepted_Apps_w_Aid
,SUM(Student_Aid_Flag) AS N_Accepted_Students_w_Aid
,SUM(EFC_FAFSA_Flag) AS N_FAFSA_EFC
,SUM(Scholarship_Flag) AS N_Students_w_Scholarship
,(CASE WHEN SUM(N_Accepted) = 0 THEN NULL ELSE CAST(ROUND((SUM(Application_Aid_Flag) * 100) / (SUM(N_Accepted) + 0.0),0) AS DEC(5,2)) END) AS PCT_Accepted_Apps_w_Aid
,CAST(ROUND((SUM(Student_Aid_Flag) * 100) / (SUM(CASE WHEN (N_Accepted >= 1) THEN 1 ELSE 0 END) + 0.0),0) AS DEC(5,2)) AS PCT_Accepted_Students_w_Aid
,CAST(ROUND((SUM(EFC_FAFSA_Flag) * 100) / (COUNT(Id) + 0.0),0) AS DEC(5,2)) AS PCT_All_Students_FAFSA_EFC
,CAST(ROUND((SUM(Scholarship_Flag) * 100) / (COUNT(Id) + 0.0),0) AS DEC(5,2)) AS PCT_All_Students_w_Scholarship
FROM #tt_Student_Aid

GROUP BY
Region_ID
,Region_Name
,KIPP_HS
,Student_HS_Cohort__c
,Alumni_Type

END

/************Final Clear of Tables************/
  DROP TABLE #tt_Region_Lookup
  DROP TABLE #tt_8th_Grade_Cohort
  DROP TABLE #tt_8th_Grade_Mod
  DROP TABLE #tt_Max_HS_Enrollment
  DROP TABLE #tt_9th_Grade_Starters
  DROP TABLE #tt_All_Alums
  DROP TABLE #tt_Applications
  DROP TABLE #tt_Alum_Acceptance
  DROP TABLE #tt_Financial_Aid_Stage
  DROP TABLE #tt_Financial_Aid_Stage_Two
  DROP TABLE #tt_Financial_Aid
  DROP TABLE #tt_Scholarships
  DROP TABLE #tt_Student_Aid

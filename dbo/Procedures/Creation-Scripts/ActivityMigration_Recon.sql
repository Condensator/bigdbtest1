SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ActivityMigration_Recon]

AS
BEGIN
	DROP TABLE IF EXISTS #Report
	CREATE TABLE [dbo].#Report (
		[Customer Number] NVARCHAR(250)
	   ,[Intermediate Total Number of Records] BIGINT
	   ,[Intermediate Total Number of Migrated Records] BIGINT
	   ,[Intermediate Total Number of Failed Records] BIGINT
	   ,[Target Total Number of Records] BIGINT
	)

	INSERT INTO #Report ([Intermediate Total Number of Migrated Records],[Intermediate Total Number of Records],[Intermediate Total Number of Failed Records], [Target Total Number of Records], [Customer Number])
	SELECT
		0
		,COUNT(*)
		,0
		,0
		,a.CustomerNumber
	FROM stgActivity a
	GROUP BY a.CustomerNumber

	SELECT
		COUNT(*) Count ,a.CustomerNumber [Customer Number] INTO #IntermediateMigratedRecords
	FROM stgActivity a
	WHERE a.IsMigrated = 1	AND a.IsFailed = 0
	GROUP BY a.CustomerNumber;

	UPDATE #Report SET [Intermediate Total Number of Migrated Records] = td.Count
	FROM #IntermediateMigratedRecords td WHERE #Report.[Customer Number] = td.[Customer Number];

	SELECT
		COUNT(*) Count ,a.CustomerNumber [Customer Number] INTO #IntermediateFailedRecords
	FROM stgActivity a
	WHERE a.IsMigrated = 0 OR a.IsFailed = 1
	GROUP BY a.CustomerNumber;
			
	UPDATE #Report SET [Intermediate Total Number of Failed Records] = td.Count
	FROM #IntermediateFailedRecords td WHERE #Report.[Customer Number] = td.[Customer Number];

	SELECT
		P.PartyNumber [Customer Number],COUNT(a.Id) Count INTO #TargetDetails
	FROM Activities a
	JOIN ActivityForCustomers afc ON a.Id = afc.Id
	JOIN ActivityTypes at ON a.ActivityTypeId = at.Id
	JOIN Parties p ON afc.CustomerId = p.Id
	WHERE at.Name = 'Bankruptcy' OR at.Name = 'Receivership' OR at.Name ='Legal Placement' OR at.Name = 'Agency Placement'
	GROUP BY P.PartyNumber;

	UPDATE #Report SET [Target Total Number of Records] = td.Count
	FROM #TargetDetails td WHERE #Report.[Customer Number] = td.[Customer Number];

	SELECT	* FROM #Report;

END;

GO

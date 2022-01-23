SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetDashboardWorkItems](
	  @CurrentUserId int
	, @WHERECLAUSE NVARCHAR(2000)
	, @ADVWHERECLAUSE NVARCHAR(2000)
	, @ORDERBYCLAUSE NVARCHAR(2000)
	, @Start int
	, @End int
	, @WorkItemFilter NVARCHAR(20)
	, @UnAssigned NVARCHAR(20)
	, @Assigned NVARCHAR(20)
	, @Completed NVARCHAR(20)
	, @UnassignedWorkItems NVARCHAR(20)
	, @MyWorkItems NVARCHAR(20)
	, @MyTeamWorkItems NVARCHAR(20)
	, @OtherWorkItems NVARCHAR(20)
	, @AllWorkItems NVARCHAR(20)
	, @CurrentSubsystemId bigint
	, @PortfolioAccessScope NVARCHAR(20)
	, @PortfolioId bigint
	, @BusinessUnitAccessScope NVARCHAR(20)
	, @BusinessUnitId bigint
	, @LegalEntityAccessScope NVARCHAR(20)	
	, @LegalEntityIdsCSV NVARCHAR(MAX)
	)
AS
BEGIN
--exec sp_executesql N'exec GetDashboardWorkItems @CurrentUserId ,@WHERECLAUSE, @ADVWHERECLAUSE, @ORDERBYCLAUSE, @Start ,@End,@WorkItemFilter ,@Unassigned,@UnassignedWorkItems,@MyWorkItems,@MyTeamWorkItems,@OtherWorkItems,@AllWorkItems,@CurrentSubsystemName;',N'@CurrentUserId bigint,@WHERECLAUSE nvarchar(2000),@ADVWHERECLAUSE nvarchar(2000),@ORDERBYCLAUSE nvarchar(2000),@Start int,@End int,@WorkItemFilter nvarchar(20),@Unassigned nvarchar(20),@UnassignedWorkItems nvarchar(20),@MyWorkItems nvarchar(20),@MyTeamWorkItems nvarchar(20),@OtherWorkItems nvarchar(20),@AllWorkItems nvarchar(20),@CurrentSubsystemName nvarchar(30)',@CurrentUserId=4,@WHERECLAUSE=N'',@ADVWHERECLAUSE=N'',@ORDERBYCLAUSE=N' ',@Start=1,@End=25,@WorkItemFilter=N'MyWorkItems',@Unassigned=N'Unassigned',@UnassignedWorkItems=N'UnassignedWorkItems',@MyWorkItems=N'MyWorkItems',@MyTeamWorkItems=N'MyTeamWorkItems',@OtherWorkItems=N'OtherWorkItems',@AllWorkItems=N'AllWorkItems',@CurrentSubsystemName=N'LessorPortal'

IF @ORDERBYCLAUSE IS NULL OR LEN(@ORDERBYCLAUSE) = 0 
 BEGIN
 SET @ORDERBYCLAUSE = 'WorkItemId DESC';
END;

IF @ADVWHERECLAUSE IS NULL OR LEN(@ORDERBYCLAUSE) > 0 
BEGIN
	SET @ADVWHERECLAUSE = REPLACE(REPLACE(@ADVWHERECLAUSE, 'CreatedDate', 'CONVERT(DATE, CreatedDate)'), 'FollowupDate', 'CONVERT(DATE, FollowupDate)')
END

DECLARE @SQLStatement NVARCHAR(MAX)=N'

DECLARE @LegalEntityIds TABLE (Id bigint);
DECLARE @TotalRecordCount bigint;
INSERT INTO @LegalEntityIds 
SELECT Id FROM ConvertCSVToBigIntTable(@LegalEntityIdsCsv, '','')

CREATE TABLE #MyTeamUsers
(
	UserId BIGINT NOT NULL
);
CREATE TABLE #AllAssignedAndUnAssignedWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY Key,
	TransactionInstanceId BIGINT NOT NULL,
	CreatedDate DATETIMEOFFSET NOT NULL,
	HasAssignments TINYINT NOT NULL,
	OwnerUserId BIGINT NULL,
	Status nvarchar(20)
);
CREATE TABLE #AccessibleWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	TransactionInstanceId BIGINT NOT NULL,
	CreatedDate DATETIMEOFFSET NOT NULL,
	IsMyTeamAccessible BIT NOT NULL
);
CREATE TABLE #UnauthorizedDomainTransactionInstances
(
	TransactionInstanceId BIGINT NOT NULL
);
CREATE TABLE #RecentCompletedWorkItemIds
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	CompletedWorkItemId BIGINT NOT NULL
);
CREATE TABLE #RecentCompletedWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	MovedFrom NVARCHAR(500) NOT NULL,
	MovedBy NVARCHAR(500) NOT NULL
);

IF @WorkItemFilter = @MyWorkItems
BEGIN
	INSERT INTO #AccessibleWorkItems
	SELECT
		WI.Id as WorkItemId
		,WI.TransactionInstanceId
		,WI.CreatedDate
		,Cast(0 as bit) AS IsMyTeamAccessible
		from WorkItems WI
	Where WI.OwnerUserId = @CurrentUserId and Status=@Assigned;
END
ELSE
BEGIN
	INSERT INTO #MyTeamUsers
	SELECT UserId 
	FROM UserReportingToes WHERE ReportingToId = @CurrentUserId 
		AND IsActive = 1;
	
	INSERT INTO #AllAssignedAndUnAssignedWorkItems
	SELECT
			WI.Id [WorkItemId]
		,WI.TransactionInstanceId
		,WI.CreatedDate
		,(CASE WHEN EXISTS (SELECT TOP 1 Id FROM WorkItemAssignments WIA WHERE WIA.WorkItemId = WI.Id) 
				THEN 1
				ELSE 0 
			END) [HasAssignments]
		,WI.OwnerUserId
		,WI.Status as Status
	FROM WorkItems WI
	JOIN WorkItemConfigs WIC ON WIC.Id = WI.WorkItemConfigId
	WHERE (WI.Status = @Assigned OR (WI.Status = @UnAssigned AND WIC.DummyEndStep = 0));

	IF @WorkItemFilter = @MyTeamWorkItems
	BEGIN
			
		-- Accessible WorkItems for which configuration is not defined and Assigned to MyTeamUsers
			
		INSERT INTO #AccessibleWorkItems
		SELECT
				WI.WorkItemId
			,WI.TransactionInstanceId
			,WI.CreatedDate
			,1 AS IsMyTeamAccessible
		FROM #AllAssignedAndUnAssignedWorkItems WI
		JOIN #MyTeamUsers ON WI.OwnerUserId = #MyTeamUsers.UserId
		WHERE WI.HasAssignments = 0;

		--Accessible WorkItems which are configured for current User Team
			
		INSERT INTO #AccessibleWorkItems
		SELECT 
			DISTINCT 
			WI.WorkItemId
			,WI.TransactionInstanceId
			,WI.CreatedDate
			,1 AS IsMyTeamAccessible
		FROM #AllAssignedAndUnAssignedWorkItems WI
		JOIN WorkItemAssignments WIA ON WI.WorkItemId = WIA.WorkItemId
		JOIN #MyTeamUsers ON WIA.UserId = #MyTeamUsers.UserId
		WHERE WI.HasAssignments = 1
			AND (WI.OwnerUserId IS NULL OR (WI.OwnerUserId <> @CurrentUserId AND WI.OwnerUserId IN (SELECT UserId FROM #MyTeamUsers)));
	END
	ELSE
	BEGIN
	
		-- Accessible WorkItems for which configuration is not defined

		INSERT INTO #AccessibleWorkItems
		SELECT
				WI.WorkItemId
			,WI.TransactionInstanceId
			,WI.CreatedDate
			,(CASE WHEN 
					((OwnerUserId IS NULL OR OwnerUserId <> @CurrentUserId) 
						AND ((WI.OwnerUserId IS NOT NULL AND WI.OwnerUserId IN (SELECT UserId FROM #MyTeamUsers)) OR WI.Status = @Unassigned))
				THEN CAST(1 as bit)
				ELSE CAST(0 as bit)
				END) IsMyTeamAccessible
		FROM #AllAssignedAndUnAssignedWorkItems WI
		WHERE WI.HasAssignments = 0;

		-- Accessible WorkItems which are configured for Current User

		INSERT INTO #AccessibleWorkItems
		SELECT DISTINCT
				WI.WorkItemId
			,WI.TransactionInstanceId
			,WI.CreatedDate
			,(CASE WHEN (WI.OwnerUserId IS NULL OR WI.OwnerUserId <> @CurrentUserId) 
					AND ((WI.OwnerUserId IS NOT NULL AND WI.OwnerUserId IN (SELECT UserId FROM #MyTeamUsers)) OR (WIA.UserId IN (SELECT UserId FROM #MyTeamUsers)))
				THEN CAST(1 AS BIT)
				ELSE CAST(0 AS BIT)
				END) IsMyTeamAccessible
		FROM #AllAssignedAndUnAssignedWorkItems WI
		JOIN WorkItemAssignments WIA ON WI.WorkItemId = WIA.WorkItemId
		WHERE WI.HasAssignments = 1
			AND WIA.UserId = @CurrentUserId;
	END -- end for @WorkItemFilter != @MyTeamWorkItems
END -- end for @WorkItemFilter != @MyWorkItems

-- Fetch Recent Completed WorkItems to evaluate MovedFrom and MovedBy

INSERT INTO #RecentCompletedWorkItemIds
SELECT
	  #AccessibleWorkItems.WorkItemId
	 ,MAX(RCWI.Id) [CompletedWorkItemId]
FROM #AccessibleWorkItems
JOIN WorkItems RCWI ON RCWI.TransactionInstanceId = #AccessibleWorkItems.TransactionInstanceId
WHERE RCWI.Status = @Completed
  AND RCWI.EndDate <= #AccessibleWorkItems.CreatedDate
GROUP BY #AccessibleWorkItems.WorkItemId;

INSERT INTO #RecentCompletedWorkItems
SELECT
	  #RecentCompletedWorkItemIds.WorkItemId
	 ,RCWIC.Label [MovedFrom]
	 ,RCWIOwner.FullName [MovedBy]
FROM #RecentCompletedWorkItemIds
JOIN WorkItems RCWI ON RCWI.Id = #RecentCompletedWorkItemIds.CompletedWorkItemId
JOIN WorkItemConfigs RCWIC ON RCWI.WorkItemConfigId = RCWIC.Id
JOIN Users RCWIOwner ON RCWIOwner.Id = RCWI.OwnerUserId;

INSERT INTO #UnauthorizedDomainTransactionInstances
EXEC GetUnauthorizedDomainTransactionInstances @CurrentUserId;

WITH CTE_WorkItems
AS
(
SELECT
	  WI.Id
	 ,WI.Id [WorkItemId]
	 ,WI.DueDate
	 ,WI.IsOptional
	 ,WI.Status
	 ,WI.OwnerUserId
	 ,WIOwner.FullName [AssignedTo]
	 ,WI.CreatedDate
	 ,WI.FollowupDate
	 ,WI.Comment
	 ,WorkItemConfigs.Label	[WorkItem]
	 ,TransactionStageConfigs.Label [Stage]
	 ,TransactionInstances.Id [TransactionInstanceId]
	 ,TransactionInstances.EntityName
	 ,TransactionInstances.TransactionName
	 ,TransactionInstances.WorkflowSource
	 ,TransactionInstances.EntitySummary
	 ,TransactionInstances.Status [TransactionStatus]	
	 ,TIStarter.FullName [CreatedBy]
	 ,#RecentCompletedWorkItems.MovedFrom
	 ,#RecentCompletedWorkItems.MovedBy
	 ,#AccessibleWorkItems.IsMyTeamAccessible
	 ,WorkItemConfigs.AcquireFromOtherUser
FROM WorkItems WI
JOIN #AccessibleWorkItems ON #AccessibleWorkItems.WorkItemId = WI.Id
LEFT JOIN Users WIOwner ON WIOwner.Id = WI.OwnerUserId
JOIN WorkItemConfigs ON WorkItemConfigs.Id = WI.WorkItemConfigId
JOIN WorkItemSubSystemConfigs ON WorkItemConfigs.Id = WorkItemSubSystemConfigs.WorkItemConfigId 
	AND WorkItemSubSystemConfigs.SubSystemId = @CurrentSubsystemId 
	AND WorkItemSubSystemConfigs.Viewable = 1
JOIN TransactionStageConfigs ON TransactionStageConfigs.Id = WorkItemConfigs.TransactionStageConfigId
JOIN TransactionInstances ON TransactionInstances.Id = WI.TransactionInstanceId	
JOIN Users TIStarter ON TIStarter.Id = TransactionInstances.CreatedById
LEFT JOIN #RecentCompletedWorkItems ON #RecentCompletedWorkItems.WorkItemId = #AccessibleWorkItems.WorkItemId
LEFT JOIN #UnauthorizedDomainTransactionInstances ON TransactionInstances.Id = #UnauthorizedDomainTransactionInstances.TransactionInstanceId
WHERE
	(TransactionInstances.AccessScopeId IS NULL 
		OR (TransactionInstances.AccessScope = @PortfolioAccessScope AND TransactionInstances.AccessScopeId = @PortfolioId) 
		OR (TransactionInstances.AccessScope = @BusinessUnitAccessScope AND TransactionInstances.AccessScopeId = @BusinessUnitId)
		OR (TransactionInstances.AccessScope = @LegalEntityAccessScope AND TransactionInstances.AccessScopeId IN (SELECT Id FROM @LegalEntityIds)))
	AND
	(
	   (@WorkItemFilter = @AllWorkItems)
	OR (@WorkItemFilter = @MyWorkItems)
	OR (@WorkItemFilter = @MyTeamWorkItems)
	OR (@WorkItemFilter = @OtherWorkItems AND WI.Status = @Assigned AND WI.OwnerUserId IS NOT NULL AND WI.OwnerUserId != @CurrentUserId)
	OR (@WorkItemFilter = @UnassignedWorkItems AND WI.Status = @Unassigned AND WI.OwnerUserId IS NULL)
	)
	WHEREBUILDERCONDITION
	AND #UnauthorizedDomainTransactionInstances.TransactionInstanceId IS NULL
)
SELECT 
	Id
	, WorkItemId
	, DueDate
	, IsOptional
	, Status
	, OwnerUserId
	, AssignedTo	
	, CreatedDate
	, FollowupDate
	, Comment
	, WorkItem
	, Stage
	, EntityName	
	, TransactionName
	, WorkflowSource
	, EntitySummary
	, TransactionStatus
	, CreatedBy
	, MovedBy
	, MovedFrom
	, IsMyTeamAccessible
	, AcquireFromOtherUser
	, ROW_NUMBER() OVER(ORDER BY ORDERBYCLAUSE) Rownumber
INTO #AdvanceSearchWorkItems
FROM 
	CTE_WorkItems
WHERE ADVWHERECLAUSE 1=1

SELECT @TotalRecordCount = COUNT(1) FROM #AdvanceSearchWorkItems

SELECT *, @TotalRecordCount as TotalRecordCount
	FROM  #AdvanceSearchWorkItems WHERE Rownumber Between @Start and @End 
	ORDER BY RowNumber;';
		 
SET @SQLStatement = REPLACE(@SQLStatement,'WHEREBUILDERCONDITION',@WHERECLAUSE)   
SET @SQLStatement = REPLACE(@SQLStatement,'ORDERBYCLAUSE',@ORDERBYCLAUSE) 
SET @SQLStatement = REPLACE(@SQLStatement,'ADVWHERECLAUSE',@ADVWHERECLAUSE) 

EXEC sp_executesql @SQLStatement, N'  
	  @Start int  
	, @End int
	, @CurrentUserId INT
	, @UnAssigned NVARCHAR(20)
	, @Assigned NVARCHAR(20)
	, @Completed NVARCHAR(20)
	, @WHERECLAUSE NVARCHAR(200)
	, @ADVWHERECLAUSE NVARCHAR(2000)
	, @ORDERBYCLAUSE NVARCHAR (100)
	, @WorkItemFilter NVARCHAR(20)
	, @UnassignedWorkItems NVARCHAR(20)
	, @MyWorkItems NVARCHAR(20) 
	, @MyTeamWorkItems NVARCHAR(20) 
	, @AllWorkItems NVARCHAR(20)
	, @OtherWorkItems NVARCHAR(20)
	, @CurrentSubsystemId bigint
	, @PortfolioAccessScope NVARCHAR(20)
	, @PortfolioId bigint
	, @BusinessUnitAccessScope NVARCHAR(20)
	, @BusinessUnitId bigint
	, @LegalEntityAccessScope NVARCHAR(20)	
	, @LegalEntityIdsCSV NVARCHAR(MAX)'
	, @Start  
	, @End
	, @CurrentUserId 
	, @UnAssigned
	, @Assigned
	, @Completed
	, @WHERECLAUSE
	, @ADVWHERECLAUSE 
	, @ORDERBYCLAUSE 
	, @WorkItemFilter 
	, @UnassignedWorkItems 
	, @MyWorkItems 
	, MyTeamWorkItems
	, @AllWorkItems
	, @OtherWorkItems
	, @CurrentSubsystemId
	, @PortfolioAccessScope
	, @PortfolioId
	, @BusinessUnitAccessScope
	, @BusinessUnitId
	, @LegalEntityAccessScope
	, @LegalEntityIdsCSV;


IF OBJECT_ID('#AdvanceSearchWorkItems') IS NOT NULL DROP TABLE #AdvanceSearchWorkItems

END

GO

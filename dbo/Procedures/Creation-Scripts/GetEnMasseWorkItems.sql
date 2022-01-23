SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetEnMasseWorkItems](
	  @CurrentUserId int
	, @WHERECLAUSE NVARCHAR(2000)
	, @ADVWHERECLAUSE NVARCHAR(2000)
	, @ORDERBYCLAUSE NVARCHAR(2000)
	, @Start int
	, @End int
	, @AdminMode bit
	, @IsMyReporteesWorkItems bit
	, @IsMyWorkItems bit
	, @IsAcquire bit
	, @IsAssign bit
	, @IsReassign bit
	, @IsUnassign bit
	, @Assigned NVARCHAR(20)
	, @Unassigned NVARCHAR(20)
	, @Completed NVARCHAR(20)
 	, @NewUserId bigint = NULL
	, @OldUserId bigint = NULL
	, @ExistingWorkItemIdsCsv NVARCHAR(MAX)
	, @CurrentSubsystemId bigint
	, @PortfolioAccessScope NVARCHAR(20)
	, @CurrentUserPortfolioId bigint
	, @BusinessUnitAccessScope NVARCHAR(20)
	, @CurrentUserBusinessUnitId bigint
	, @LegalEntityAccessScope NVARCHAR(20)	
	, @CurrentUserLegalEntityIdsCsv NVARCHAR(MAX)
	, @NewUserPortfolioIdsCsv NVARCHAR(MAX)
	, @NewUserBusinessUnitIdsCsv NVARCHAR(MAX)
	, @NewUserLegalEntityIdsCsv NVARCHAR(MAX)
	)
AS
BEGIN

IF @ORDERBYCLAUSE IS NULL OR LEN(@ORDERBYCLAUSE) = 0 
 BEGIN
 SET @ORDERBYCLAUSE = 'WorkItemId DESC';
END;

IF @ADVWHERECLAUSE IS NULL OR LEN(@ORDERBYCLAUSE) > 0 
BEGIN
	SET @ADVWHERECLAUSE = REPLACE(REPLACE(@ADVWHERECLAUSE, 'CreatedDate', 'CONVERT(DATE, CreatedDate)'), 'FollowupDate', 'CONVERT(DATE, FollowupDate)')
END

DECLARE @SQLStatement NVARCHAR(MAX)=N'

DECLARE @TotalRecordCount bigint;

DECLARE @ExistingWorkItemIds TABLE (Id bigint);
INSERT INTO @ExistingWorkItemIds 
SELECT Id FROM ConvertCSVToBigIntTable(@ExistingWorkItemIdsCsv, '','')

DECLARE @CurrentUserLegalEntityIds TABLE (Id bigint);
INSERT INTO @CurrentUserLegalEntityIds 
SELECT Id FROM ConvertCSVToBigIntTable(@CurrentUserLegalEntityIdsCsv, '','')

DECLARE @NewUserPortfolioIds TABLE (Id bigint);
INSERT INTO @NewUserPortfolioIds 
SELECT Id FROM ConvertCSVToBigIntTable(@NewUserPortfolioIdsCsv, '','')

DECLARE @NewUserBusinessUnitIds TABLE (Id bigint);
INSERT INTO @NewUserBusinessUnitIds 
SELECT Id FROM ConvertCSVToBigIntTable(@NewUserBusinessUnitIdsCsv, '','')

DECLARE @NewUserLegalEntityIds TABLE (Id bigint);
INSERT INTO @NewUserLegalEntityIds 
SELECT Id FROM ConvertCSVToBigIntTable(@NewUserLegalEntityIdsCsv, '','')

CREATE TABLE #MyTeamUsers
(
	UserId BIGINT NOT NULL
);
CREATE TABLE #AllAssignedAndUnAssignedWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY Key,
	TransactionInstanceId BIGINT NOT NULL,
	CreatedDate DATETIMEOFFSET NOT NULL,
	HasAssignments BIT NOT NULL,
	OwnerUserId BIGINT NULL,
	Status NVARCHAR(20),
	AcquireFromOtherUser BIT NOT NULL,
	AllowTossing BIT NOT NULL
);
CREATE TABLE #AccessibleWorkItems
(
	WorkItemId BIGINT NOT NULL PRIMARY KEY,
	TransactionInstanceId BIGINT NOT NULL,
	CreatedDate DATETIMEOFFSET NOT NULL
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
		,WIC.AcquireFromOtherUser
		,WIC.AllowTossing
FROM WorkItems WI
JOIN WorkItemConfigs WIC on WI.WorkItemConfigId = WIC.Id
LEFT JOIN @ExistingWorkItemIds #ExWI ON WI.Id = #ExWI.Id
WHERE (WI.Status = @Assigned OR WI.Status = @UnAssigned) 
  AND #ExWI.Id IS NULL;

IF @IsMyWorkItems = 1
BEGIN

    IF @IsUnassign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
			 #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.OwnerUserId = @CurrentUserId 
		  AND #WI.Status = @Assigned
    END

    IF @IsAcquire = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.HasAssignments = 0 
		  AND ((#WI.Status = @Unassigned) OR (#WI.Status = @Assigned 
												AND #WI.OwnerUserId != @CurrentUserId 
												AND #WI.AcquireFromOtherUser = 1))

        INSERT INTO #AccessibleWorkItems
        SELECT DISTINCT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM WorkItemAssignments WIA
        JOIN #AllAssignedAndUnAssignedWorkItems #WI ON WIA.WorkItemId = #WI.WorkItemId
        WHERE #WI.HasAssignments = 1 
		  AND WIA.UserId = @CurrentUserId 
		  AND ((#WI.Status = @Unassigned) OR (#WI.Status = @Assigned 
												AND #WI.OwnerUserId != @CurrentUserId 
												AND #WI.AcquireFromOtherUser = 1))
    END

    IF @IsReassign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT 
			 #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.HasAssignments = 0 
		  AND #WI.Status = @Assigned 
		  AND #WI.OwnerUserId = @CurrentUserId 
		  AND #WI.AllowTossing = 1;

        INSERT INTO #AccessibleWorkItems
        SELECT DISTINCT
			 #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM WorkItemAssignments WIA
        JOIN #AllAssignedAndUnAssignedWorkItems #WI ON WIA.WorkItemId = #WI.WorkItemId
        WHERE #WI.HasAssignments = 1 
		  AND #WI.Status = @Assigned 
		  AND #WI.OwnerUserId = @CurrentUserId 
		  AND #WI.AllowTossing = 1 
		  AND WIA.UserId = @NewUserId;
    END

END

IF @IsMyReporteesWorkItems = 1
BEGIN

	INSERT INTO #MyTeamUsers
	SELECT UserId 
	FROM UserReportingToes 
	WHERE ReportingToId = @CurrentUserId 
	  AND IsActive = 1;
	
    IF @IsUnassign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
		JOIN #MyTeamUsers ON #WI.OwnerUserId = #MyTeamUsers.UserId
        WHERE #WI.Status = @Assigned 
		  AND (@OldUserId IS NULL OR #WI.OwnerUserId = @OldUserId)
    END

    IF @IsAssign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
		FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.HasAssignments = 0 
		  AND #WI.Status = @Unassigned

        INSERT INTO #AccessibleWorkItems
        SELECT DISTINCT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM WorkItemAssignments WIA
        JOIN #AllAssignedAndUnAssignedWorkItems #WI ON WIA.WorkItemId = #WI.WorkItemId
        WHERE #WI.HasAssignments = 1 
		  AND #WI.Status = @Unassigned 
		  AND WIA.UserId = @NewUserId
    END

    IF @IsReassign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
		JOIN #MyTeamUsers ON #WI.OwnerUserId = #MyTeamUsers.UserId
        WHERE #WI.HasAssignments = 0 
		  AND #WI.Status= @Assigned 
		  AND #WI.OwnerUserId != @NewUserId 
		  AND #WI.AllowTossing = 1
		  AND (@OldUserId IS NULL OR #WI.OwnerUserId = @OldUserId)

        INSERT INTO #AccessibleWorkItems
        SELECT DISTINCT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM WorkItemAssignments WIA
        JOIN #AllAssignedAndUnAssignedWorkItems #WI ON WIA.WorkItemId = #WI.WorkItemId
		JOIN #MyTeamUsers ON #WI.OwnerUserId = #MyTeamUsers.UserId
        WHERE #WI.HasAssignments = 1 
		  AND #WI.Status= @Assigned 
		  AND #WI.OwnerUserId != @NewUserId 
		  AND #WI.AllowTossing = 1 
		  AND WIA.UserId = @NewUserId
		  AND (@OldUserId IS NULL OR #WI.OwnerUserId = @OldUserId)
    END

END

IF @AdminMode = 1
BEGIN

    IF @IsUnassign = 1 OR @IsReassign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.Status = @Assigned 
		  AND #WI.OwnerUserId = @OldUserId
    END

    IF @IsAssign = 1
	BEGIN
        INSERT INTO #AccessibleWorkItems
        SELECT
             #WI.WorkItemId
			,#WI.TransactionInstanceId
			,#WI.CreatedDate
        FROM #AllAssignedAndUnAssignedWorkItems #WI
        WHERE #WI.Status = @Unassigned
    END

END

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
	((TransactionInstances.AccessScopeId IS NULL)
		OR (TransactionInstances.AccessScope = @PortfolioAccessScope AND (@AdminMode = 1 OR TransactionInstances.AccessScopeId = @CurrentUserPortfolioId) AND (@NewUserId IS NULL OR TransactionInstances.AccessScopeId IN (SELECT Id FROM @NewUserPortfolioIds)))
		OR (TransactionInstances.AccessScope = @BusinessUnitAccessScope AND (@AdminMode = 1 OR TransactionInstances.AccessScopeId = @CurrentUserBusinessUnitId) AND (@NewUserId IS NULL OR TransactionInstances.AccessScopeId IN (SELECT Id FROM @NewUserPortfolioIds)))
		OR (TransactionInstances.AccessScope = @LegalEntityAccessScope AND (@AdminMode = 1 OR TransactionInstances.AccessScopeId IN (SELECT Id FROM @CurrentUserLegalEntityIds)) AND (@NewUserId IS NULL OR TransactionInstances.AccessScopeId IN (SELECT Id FROM @NewUserLegalEntityIds))))
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
	, AcquireFromOtherUser
	, ROW_NUMBER() OVER(ORDER BY ORDERBYCLAUSE) Rownumber
INTO #AdvanceSearchWorkItems
FROM 
	CTE_WorkItems
WHERE ADVWHERECLAUSE 1=1

SELECT @TotalRecordCount = COUNT(1) FROM #AdvanceSearchWorkItems

SELECT *, @TotalRecordCount as TotalRecordCount
	FROM  #AdvanceSearchWorkItems WHERE Rownumber Between @Start and @End 
	ORDER BY RowNumber;
	
SELECT WorkItemId
	FROM  #AdvanceSearchWorkItems ;';
		 
SET @SQLStatement = REPLACE(@SQLStatement,'WHEREBUILDERCONDITION',@WHERECLAUSE)   
SET @SQLStatement = REPLACE(@SQLStatement,'ORDERBYCLAUSE',@ORDERBYCLAUSE) 
SET @SQLStatement = REPLACE(@SQLStatement,'ADVWHERECLAUSE',@ADVWHERECLAUSE)  

EXEC sp_executesql @SQLStatement, N'  
	  @CurrentUserId int
	, @WHERECLAUSE NVARCHAR(2000)
	, @ADVWHERECLAUSE NVARCHAR(2000)
	, @ORDERBYCLAUSE NVARCHAR(2000)
	, @Start int
	, @End int
	, @AdminMode bit
	, @IsMyReporteesWorkItems bit
	, @IsMyWorkItems bit
	, @IsAcquire bit
	, @IsAssign bit
	, @IsReassign bit
	, @IsUnassign bit
	, @Assigned NVARCHAR(20)
	, @Unassigned NVARCHAR(20)
	, @Completed NVARCHAR(20)
	, @NewUserId bigint
	, @OldUserId bigint
	, @ExistingWorkItemIdsCsv NVARCHAR(MAX)
	, @CurrentSubsystemId bigint
	, @PortfolioAccessScope NVARCHAR(20)
	, @CurrentUserPortfolioId bigint
	, @BusinessUnitAccessScope NVARCHAR(20)
	, @CurrentUserBusinessUnitId bigint
	, @LegalEntityAccessScope NVARCHAR(20)	
	, @CurrentUserLegalEntityIdsCsv NVARCHAR(MAX)
	, @NewUserPortfolioIdsCsv NVARCHAR(MAX)
	, @NewUserBusinessUnitIdsCsv NVARCHAR(MAX)
	, @NewUserLegalEntityIdsCsv NVARCHAR(MAX)'
	, @CurrentUserId
	, @WHERECLAUSE 
	, @ADVWHERECLAUSE
	, @ORDERBYCLAUSE
	, @Start
	, @End
	, @AdminMode
	, @IsMyReporteesWorkItems
	, @IsMyWorkItems
	, @IsAcquire
	, @IsAssign
	, @IsReassign
	, @IsUnassign
	, @Assigned
	, @Unassigned
	, @Completed
	, @NewUserId
	, @OldUserId
	, @ExistingWorkItemIdsCsv
	, @CurrentSubsystemId
	, @PortfolioAccessScope
	, @CurrentUserPortfolioId
	, @BusinessUnitAccessScope
	, @CurrentUserBusinessUnitId
	, @LegalEntityAccessScope
	, @CurrentUserLegalEntityIdsCsv
	, @NewUserPortfolioIdsCsv 
	, @NewUserBusinessUnitIdsCsv 
	, @NewUserLegalEntityIdsCsv;

IF OBJECT_ID('#AdvanceSearchWorkItems') IS NOT NULL DROP TABLE #AdvanceSearchWorkItems

END

GO

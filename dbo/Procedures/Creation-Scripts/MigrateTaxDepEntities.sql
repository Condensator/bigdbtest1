SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[MigrateTaxDepEntities]
(	
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT,
	@ToolIdentifier INT
)
AS
--DECLARE @UserId BIGINT, @ModuleIterationStatusId BIGINT, @CreatedTime DATETIMEOFFSET = NULL
--DECLARE @ProcessedRecords BIGINT 
--DECLARE @FailedRecords BIGINT  
--SET @UserId = 1
--SET @ModuleIterationStatusId = 91158
--SET @CreatedTime =  SYSDATETIMEOFFSET()
BEGIN
SET NOCOUNT ON
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
SET @FailedRecords = 0
SET @ProcessedRecords = 0
DECLARE @TakeCount INT = 50000
DECLARE @SkipCount INT = 0
DECLARE @MaxTaxDepEntityId INT = 0
DECLARE @TotalRecordsCount INT = (SELECT COUNT(Id) FROM stgTaxDepEntity IntermediateTaxDepEntity WHERE IsMigrated = 0 AND (ToolIdentifier = @ToolIdentifier OR ToolIdentifier IS NULL) )
WHILE @SkipCount <= @TotalRecordsCount
BEGIN
CREATE TABLE #ErrorLogs
(
	Id BIGINT NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId BIGINT,
	Result NVARCHAR(10),
	Message NVARCHAR(MAX)
)
CREATE TABLE #CreatedTaxDepEntityIds
(
	MergeAction NVARCHAR(20),
	InsertedId BIGINT,
	TaxDepEntityId BIGINT,
)
CREATE TABLE #CreatedProcessingLogs
(
	MergeAction NVARCHAR(20),
	InsertedId BIGINT
)
CREATE TABLE #FailedProcessingLogs
(
	MergeAction NVARCHAR(20),
	InsertedId BIGINT,
	ErrorId BIGINT
)
CREATE TABLE #BlendedItemTaxDepEntitySubset
(
	BlendedItemId BIGINT,
	BlendedItemName NVARCHAR(40),
	ContractSequenceNumber NVARCHAR(40)
);
SELECT 
	TOP(@TakeCount) * INTO #TaxDepEntitySubset 
FROM 
	stgTaxDepEntity IntermediateTaxDepEntity
WHERE
	IntermediateTaxDepEntity.Id > @MaxTaxDepEntityId AND IntermediateTaxDepEntity.IsMigrated = 0 AND (IntermediateTaxDepEntity.ToolIdentifier = @ToolIdentifier OR IntermediateTaxDepEntity.ToolIdentifier IS NULL)
ORDER BY 
	IntermediateTaxDepEntity.Id
INSERT INTO #BlendedItemTaxDepEntitySubset
SELECT 
BI.Id [BlendedItemName],
BI.Name [BlendedItemId],
C.SequenceNumber [ContractSequenceNumber]
FROM #TaxDepEntitySubset TD
JOIN Contracts C ON TD.LeaseSequenceNumber = C.SequenceNumber 
JOIN LeaseFinances LF ON C.Id = LF.ContractId
JOIN LeaseBlendedItems LBI ON LF.Id = LBI.LeaseFinanceId
JOIN BlendedItems BI ON LBI.BlendedItemId = BI.Id AND TD.BlendedItemName = BI.Name
WHERE TD.BlendedItemName IS NOT NULL AND TD.LeaseSequenceNumber IS NOT NULL
AND LF.IsCurrent = 1 AND BI.IsActive = 1;
SELECT TOP(@TakeCount)
	IntermediateTaxDepEntity.AssetAlias
	,IntermediateTaxDepEntity.Id [TaxDepEntityId]
	,IntermediateTaxDepEntity.TaxBasisAmount_Amount
	,IntermediateTaxDepEntity.TaxBasisAmount_Currency
	,IntermediateTaxDepEntity.DepreciationBeginDate
	,IntermediateTaxDepEntity.DepreciationEndDate
	,IntermediateTaxDepEntity.IsStraightLineMethodUsed
	,IntermediateTaxDepEntity.TaxDepreciationTemplateName
	,IntermediateTaxDepEntity.LeaseSequenceNumber
	,TaxDepTemplate.Id [TaxDepTemplateId]
	,Asset.Id [AssetId]
	,Contract.Id [ContractId]
	,TaxDepTemplate.IsActive [TaxDepTemplateActive]
	,IntermediateTaxDepEntity.FXTaxBasisAmount_Amount
	,IntermediateTaxDepEntity.FXTaxBasisAmount_Currency
	,IntermediateTaxDepEntity.TaxDepreciationDisposalTemplateName
	,IntermediateTaxDepEntity.PostDate
	,GLTemplate.Id [GLTemplateId]
	,IntermediateTaxDepEntity.TaxProceedsAmount_Amount
	,IntermediateTaxDepEntity.TaxProceedsAmount_Currency
	,BI.BlendedItemId [BlendedItemId]
	,IntermediateTaxDepEntity.BlendedItemName
	INTO #TaxDepEntitiesMappedWithTarget
FROM 
	#TaxDepEntitySubset IntermediateTaxDepEntity
LEFT JOIN TaxDepTemplates TaxDepTemplate
	ON IntermediateTaxDepEntity.TaxDepreciationTemplateName = TaxDepTemplate.Name
LEFT JOIN Assets Asset
	ON IntermediateTaxDepEntity.AssetAlias = Asset.Alias
LEFT JOIN Contracts Contract
    ON IntermediateTaxDepEntity.LeaseSequenceNumber = Contract.SequenceNumber
LEFT JOIN LegalEntities LegalEntity
	ON Asset.LegalEntityId = LegalEntity.Id
LEFT JOIN GLTemplates GLTemplate
    ON IntermediateTaxDepEntity.TaxDepreciationDisposalTemplateName = GLTemplate.Name
	AND GLTemplate.GLConfigurationId = LegalEntity.GLConfigurationId
	AND GLTemplate.IsActive=1
LEFT JOIN #BlendedItemTaxDepEntitySubset BI 
    ON ((IntermediateTaxDepEntity.BlendedItemName = BI.BlendedItemName) AND (IntermediateTaxDepEntity.LeaseSequenceNumber = BI.ContractSequenceNumber))
WHERE
	IntermediateTaxDepEntity.Id > @MaxTaxDepEntityId  
ORDER BY 
	IntermediateTaxDepEntity.Id
SELECT @MaxTaxDepEntityId = MAX(TaxDepEntityId) FROM #TaxDepEntitiesMappedWithTarget;
INSERT INTO #ErrorLogs
SELECT
TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('The filter criteria does not match for the Tax Dep Template with the Tax Dep Template Name '+ #TaxDepEntitiesMappedWithTarget.TaxDepreciationTemplateName + 'for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM 
	#TaxDepEntitiesMappedWithTarget 
WHERE 
	#TaxDepEntitiesMappedWithTarget.TaxDepreciationTemplateName IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.TaxDepTemplateId IS NULL
INSERT INTO #ErrorLogs
SELECT
TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('Selected Tax Dep Template must be active for TaxDepEntity' + CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM 
	#TaxDepEntitiesMappedWithTarget 
WHERE 
	#TaxDepEntitiesMappedWithTarget.TaxDepTemplateId IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.TaxDepTemplateActive = 0
INSERT INTO #ErrorLogs
SELECT
TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('The filter criteria does not match for the Asset with the Asset Alias '+ #TaxDepEntitiesMappedWithTarget.AssetAlias + ' for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM 
	#TaxDepEntitiesMappedWithTarget 
WHERE 
	#TaxDepEntitiesMappedWithTarget.AssetAlias IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.AssetId IS NULL
INSERT INTO #ErrorLogs
SELECT
TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('The filter criteria does not match for the Lease with the Lease Sequence Number '+IsNull(#TaxDepEntitiesMappedWithTarget.AssetAlias,'Null')+ ' for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM 
	#TaxDepEntitiesMappedWithTarget 
WHERE 
	#TaxDepEntitiesMappedWithTarget.LeaseSequenceNumber IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.ContractId IS NULL
INSERT INTO #ErrorLogs
SELECT
TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('The filter criteria does not match for the Tax Dep Disposal Template with the Tax Dep Disposal Template Name '+ #TaxDepEntitiesMappedWithTarget.TaxDepreciationTemplateName + 'for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM 
	#TaxDepEntitiesMappedWithTarget 
WHERE 
	#TaxDepEntitiesMappedWithTarget.TaxDepreciationDisposalTemplateName IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.GLTemplateId IS NULL
INSERT INTO #ErrorLogs
SELECT TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('The filter criteria does not match for the Blended Item with the Blended Item Name '+ #TaxDepEntitiesMappedWithTarget.BlendedItemName + ' for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM #TaxDepEntitiesMappedWithTarget 
WHERE #TaxDepEntitiesMappedWithTarget.BlendedItemName IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.BlendedItemId IS NULL;
INSERT INTO #ErrorLogs
SELECT TaxDepEntityId as StagingRootEntityId 
	,'Error'
	,('Both Blended Item and Asset Cannot be give for same record for the Tax Dep Entity :' +CONVERT(NVARCHAR(MAX), #TaxDepEntitiesMappedWithTarget.TaxDepEntityId)) AS Message
FROM #TaxDepEntitiesMappedWithTarget 
WHERE #TaxDepEntitiesMappedWithTarget.BlendedItemName IS NOT NULL AND #TaxDepEntitiesMappedWithTarget.AssetAlias IS NOT NULL;
MERGE TaxDepEntities AS TaxDepEntity
USING (SELECT
		#TaxDepEntitiesMappedWithTarget.* , #ErrorLogs.StagingRootEntityId
		FROM
		#TaxDepEntitiesMappedWithTarget
		LEFT JOIN #ErrorLogs
				ON #TaxDepEntitiesMappedWithTarget.TaxDepEntityId = #ErrorLogs.StagingRootEntityId) AS TaxDepEntitiesToMigrate
ON (1=0)
WHEN MATCHED AND TaxDepEntitiesToMigrate.StagingRootEntityId IS NULL THEN
	UPDATE SET TaxDepEntity.TaxBasisAmount_Amount = TaxDepEntitiesToMigrate.TaxBasisAmount_Amount
WHEN NOT MATCHED AND TaxDepEntitiesToMigrate.StagingRootEntityId IS NULL
THEN
	INSERT
    (EntityType
	,TaxBasisAmount_Amount
	,TaxBasisAmount_Currency
	,DepreciationBeginDate
	,DepreciationEndDate
	,IsConditionalSale
	,IsStraightLineMethodUsed
	,IsTaxDepreciationTerminated
	,TerminationDate
	,IsActive
	,IsComputationPending
	,TerminatedByLeaseId
	,CreatedById
	,CreatedTime
	,UpdatedById
	,UpdatedTime
	,TaxDepTemplateId
	,AssetId
	,ContractId
	,FXTaxBasisAmount_Amount
	,FXTaxBasisAmount_Currency
	,PostDate
	,IsGLPosted
	,TaxDepDisposalTemplateId
	,TaxProceedsAmount_Amount
	,TaxProceedsAmount_Currency
	,BlendedItemId)
VALUES
    (CASE WHEN TaxDepEntitiesToMigrate.AssetAlias IS NOT NULL THEN 'Asset' ELSE 'BlendedItem' END
	,TaxDepEntitiesToMigrate.TaxBasisAmount_Amount
	,TaxDepEntitiesToMigrate.TaxBasisAmount_Currency
	,TaxDepEntitiesToMigrate.DepreciationBeginDate
	,TaxDepEntitiesToMigrate.DepreciationEndDate
	,0
	,TaxDepEntitiesToMigrate.IsStraightLineMethodUsed
	,0
	,NULL
	,1
	,1
	,NULL
	,@UserId
    ,@CreatedTime
    ,NULL
	,NULL
    ,TaxDepEntitiesToMigrate.TaxDepTemplateId
    ,TaxDepEntitiesToMigrate.AssetId
    ,TaxDepEntitiesToMigrate.ContractId
	,TaxDepEntitiesToMigrate.FXTaxBasisAmount_Amount
	,TaxDepEntitiesToMigrate.FXTaxBasisAmount_Currency
	,TaxDepEntitiesToMigrate.PostDate
	,0
	,TaxDepEntitiesToMigrate.GLTemplateId
	,TaxDepEntitiesToMigrate.TaxProceedsAmount_Amount
	,TaxDepEntitiesToMigrate.TaxProceedsAmount_Currency
	,TaxDepEntitiesToMigrate.BlendedItemId)
OUTPUT $action, Inserted.Id, TaxDepEntitiesToMigrate.TaxDepEntityId INTO #CreatedTaxDepEntityIds;
	UPDATE LA 
	SET 
	LA.TaxDepStartDate = Target.DepreciationBeginDate,
	LA.TaxDepEndDate = Target.DepreciationEndDate,
	LA.TaxBasisAmount_Amount = Target.TaxBasisAmount_Amount, 
	LA.TaxBasisAmount_Currency = Target.TaxBasisAmount_Currency, 
	LA.FXTaxBasisAmount_Amount = Target.FXTaxBasisAmount_Amount, 
	LA.FXTaxBasisAmount_Currency = Target.FXTaxBasisAmount_Currency, 
	LA.IsTaxAccountingActive = 1,
	LA.IsTaxDepreciable = 1
	FROM 
	LeaseAssets LA
	JOIN #TaxDepEntitiesMappedWithTarget Target ON  Target.AssetId = LA.AssetId
	JOIN #CreatedTaxDepEntityIds TaxDep ON TaxDep.TaxDepEntityId= Target.TaxDepEntityId
UPDATE stgTaxDepEntity SET IsMigrated = 1 WHERE Id IN (SELECT TaxDepEntityId FROM #CreatedTaxDepEntityIds)
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT
		TaxDepEntityId
		FROM
		#CreatedTaxDepEntityIds
		) AS ProcessedEntities
ON (ProcessingLog.StagingRootEntityId = ProcessedEntities.TaxDepEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
	UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
	(
		StagingRootEntityId
		,CreatedById
		,CreatedTime
		,ModuleIterationStatusId
	)
VALUES
	(
		ProcessedEntities.TaxDepEntityId
		,@UserId
		,@CreatedTime
		,@ModuleIterationStatusId
	)
OUTPUT $action, Inserted.Id INTO #CreatedProcessingLogs;
INSERT INTO 
	stgProcessingLogDetail
	(
		Message
		,Type
		,CreatedById
		,CreatedTime	
		,ProcessingLogId
	)
SELECT
	'Successful'
	,'Information'
	,@UserId
	,@CreatedTime
	,InsertedId
FROM
	#CreatedProcessingLogs
MERGE stgProcessingLog AS ProcessingLog
USING (SELECT
			DISTINCT StagingRootEntityId
		FROM
		#ErrorLogs 
		) AS ErrorEntities
ON (ProcessingLog.StagingRootEntityId = ErrorEntities.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
	UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT
	(
		StagingRootEntityId
		,CreatedById
		,CreatedTime
		,ModuleIterationStatusId
	)
VALUES
	(
		ErrorEntities.StagingRootEntityId
		,@UserId
		,@CreatedTime
		,@ModuleIterationStatusId
	)
OUTPUT $action, Inserted.Id,ErrorEntities.StagingRootEntityId INTO #FailedProcessingLogs;	
DECLARE @TotalRecordsFailed INT = (SELECT  COUNT( DISTINCT InsertedId) FROM #FailedProcessingLogs)
INSERT INTO 
	stgProcessingLogDetail
	(
		Message
		,Type
		,CreatedById
		,CreatedTime	
		,ProcessingLogId
	)
SELECT
	#ErrorLogs.Message
	,#ErrorLogs.Result
	,@UserId
	,@CreatedTime
	,#FailedProcessingLogs.InsertedId
FROM
	#ErrorLogs
INNER JOIN #FailedProcessingLogs
		ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.ErrorId
SET @FailedRecords =  @FailedRecords + @TotalRecordsFailed
SET @SkipCount = @SkipCount + @TakeCount
DROP TABLE #ErrorLogs
DROP TABLE #CreatedTaxDepEntityIds
DROP TABLE #TaxDepEntitySubset
DROP TABLE #TaxDepEntitiesMappedWithTarget
DROP TABLE #CreatedProcessingLogs
DROP TABLE #FailedProcessingLogs
DROP TABLE #BlendedItemTaxDepEntitySubset
END	
SET @ProcessedRecords = @ProcessedRecords + @TotalRecordsCount
SET NOCOUNT OFF
END

GO

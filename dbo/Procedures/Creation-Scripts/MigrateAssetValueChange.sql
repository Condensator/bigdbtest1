SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MigrateAssetValueChange]
(
	@UserId bigint ,
	@ModuleIterationStatusId bigint,
	@CreatedTime datetimeoffset,
	@ProcessedRecords bigint OUTPUT,
	@FailedRecords bigint OUTPUT
)
AS BEGIN

SET XACT_ABORT ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON

IF OBJECT_ID('tempdb..#ProcessingRecords') IS NOT NULL
	DROP TABLE #ProcessingRecords;

IF OBJECT_ID('tempdb..#CreatedProcessingLogs') IS NOT NULL
	DROP TABLE #CreatedProcessingLogs;

IF OBJECT_ID('tempdb..#ReasonGlEntryConfig') IS NOT NULL
	DROP TABLE #ReasonGlEntryConfig;

IF OBJECT_ID('tempdb..#BookDepreciationGlEntryConfig') IS NOT NULL
	DROP TABLE #BookDepreciationGlEntryConfig;

CREATE TABLE #ProcessingRecords(
	Id bigint NOT NULL IDENTITY PRIMARY KEY,
	StagingID bigint NOT NULL,
	IsValid bit
);

CREATE TABLE #CreatedProcessingLogs(
	[Id] bigint NOT NULL,
	[StagingId] bigint NOT NULL
);

CREATE TABLE #ReasonGlEntryConfig(
	Reason nvarchar(50),
	GLEntry nvarchar(max)
);

CREATE TABLE #BookDepreciationGlEntryConfig(
	AssetStatus nvarchar(50),
	GLEntry nvarchar(max)
);

INSERT INTO #ProcessingRecords (StagingID , IsValid)
SELECT Id StagingID, 0 IsValid
FROM stgAssetsValueChange 
WHERE IsMigrated=0 ORDER BY id

INSERT INTO #BookDepreciationGlEntryConfig
VALUES
('Inventory','Inventory'),
('Inventory','AccumulatedAssetDepreciation');

INSERT INTO #ReasonGlEntryConfig
VALUES
('Impairment','Expense'),
('Impairment','AccumulatedImpairment'),
('ValueAdjustment','Expense'),
('ValueAdjustment','Inventory'),
('ShortFall','Expense'),
('ShortFall','Inventory'),
('MarktoMarketAdjustment','Expense'),
('MarktoMarketAdjustment','Inventory'),
('Other','Expense'),
('Other','Inventory')

DECLARE @TakeCount BIGINT = 5000
DECLARE @SkipCount BIGINT = 0  
DECLARE @TotalRecordsCount bigint = (SELECT COUNT(Id) FROM stgAssetsValueChange WHERE IsMigrated=0);
DECLARE @FromStagingId bigint=0;
DECLARE @ToStagingId bigint=0;
SET @FailedRecords=0;

WHILE (@TotalRecordsCount > 0 and @SkipCount < @TotalRecordsCount)
BEGIN
	

	SELECT @FromStagingId = MIN(StagingId), @ToStagingId = max(StagingId) 
	FROM (SELECT StagingID from #ProcessingRecords  ORDER BY ID OFFSET @SkipCount ROWS FETCH NEXT @TakeCount ROWS ONLY ) AS A

	EXEC [dbo].[ValidateAssetsValueChange] @UserId,@ModuleIterationStatusId,@CreatedTime,@FromStagingId,@ToStagingId

	UPDATE #ProcessingRecords SET IsValid =1 
	FROM stgAssetsValueChange
	JOIN #ProcessingRecords ON #ProcessingRecords.StagingID= stgAssetsValueChange.id
	WHERE stgAssetsValueChange.IsFailed=0 AND stgAssetsValueChange.IsMigrated=0
	AND #ProcessingRecords.StagingID BETWEEN @FromStagingId AND @ToStagingId

	Declare @IsValid bit =CASE WHEN (Select COUNT(ID) FROM #ProcessingRecords WHERE IsValid=1 AND #ProcessingRecords.StagingID BETWEEN @FromStagingId AND @ToStagingId)>0 THEN  1 ELSE 0 END
	
	IF (@IsValid=1)
	BEGIN
	BEGIN TRY  

	IF OBJECT_ID('tempdb..#AssetsValueChangeMappedWithTarget') IS NOT NULL
		DROP TABLE #AssetsValueChangeMappedWithTarget;
	
	IF OBJECT_ID('tempdb..#AssetValueHistories') IS NOT NULL
		DROP TABLE #AssetValueHistories;

	IF OBJECT_ID('tempdb..#InsertedValueIds') IS NOT NULL
		DROP TABLE #InsertedValueIds;
	
	IF OBJECT_ID('tempdb..#AssetsToClearBookDepreciation') IS NOT NULL
		DROP TABLE #AssetsToClearBookDepreciation;
	
	IF OBJECT_ID('tempdb..#CreatedGLJournalId') IS NOT NULL
		DROP TABLE #CreatedGLJournalId;

	IF OBJECT_ID('tempdb..#GLJournalDetails') IS NOT NULL
		DROP TABLE #GLJournalDetails;
	
	IF OBJECT_ID('tempdb..#AssetGL') IS NOT NULL
		DROP TABLE #AssetGL;
	
	CREATE TABLE #AssetsValueChangeMappedWithTarget(
		[StagingId] bigint,
		PostDate date,
		Reason nvarchar(100),
		AssetId bigint,
		AssetAlias nvarchar(100),
		AssetStatus nvarchar(100),
		AdjustmentAmount decimal(16,2),
		[AssetBookValueAdjustmentGLTemplateId] bigint,
		[BookDepreciationGLTemplateId] bigint,
		[InstrumentTypeId] bigint,
		[LegalEntityId] bigint,
		[LineofBusinessId] bigint,
		[BranchId] bigint,
		[CurrencyId] bigint,
		[CurrencyCode] nvarchar(50),
		[AssetValueStatusChangeId] bigint,
		[GLJournalId] bigint,
		[CostCenterId] bigint,
		[HasNonTerminatedBookDepreciation] bit,
		[HasAccumulatedBookDepreciation] bit,
		[ClearAccumulatedGLJournalId] bigint,
		[Cost] decimal(16,2),
		[CreatedById] bigint,
		[CreatedTime] datetimeoffset,
		[Rank] bigint
	);

	CREATE TABLE #InsertedValueIds(
		AssetsValueStatusChangeId bigint,
		StagingId bigint
	);

	CREATE TABLE #AssetsToClearBookDepreciation(
		AssetId bigint,
		SourceModuleId bigint,
		IncomeDate date,
		FromDate date,
		ToDate date,
		Value_Amount decimal (16,2),
		Cost_Amount decimal (16,2),
		EndBookValue_Amount decimal (16,2),
		StagingId bigint,
		AssetValueHistoryId bigint,
		GLJournalId bigint,
		PostDate date,
		CurrencyCode nvarchar(50),
		AssetValueStatusChangeId bigint,
		AdjustmentAmount bigint,
		[CreatedById] bigint,
		[CreatedTime] datetimeoffset
	);
	
	CREATE TABLE #AssetGL(
		StagingId bigint,
		AssetID bigint,
		PostDate date,
		[IsManualEntry] bit,
		[IsReversalEntry] bit,
		CreatedById bigint,
		CreatedTime datetimeoffset,
		LegalEntityId bigint ,
		[HasAccumulatedBookDepreciation] bit
	);

	CREATE TABLE #CreatedGLJournalId(
		GLJournalId bigint,
		StagingId bigint,
		AssetId bigint,
		[HasAccumulatedBookDepreciation] bit
	);

	CREATE TABLE #GLJournalDetails(
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[StagingId] [bigint] NOT NULL,
		[EntityId] [bigint]  NULL,
		[EntityType] [nvarchar](23) NOT NULL,
		[Amount_Amount] [decimal](16, 2) NOT NULL,
		[Amount_Currency] [nvarchar](3) NOT NULL,
		[IsDebit] [bit] NOT NULL,
		[GLAccountNumber] [nvarchar](129) NOT NULL,
		[Description] [nvarchar](250) NOT NULL,
		[SourceId] [bigint] NULL,
		[IsActive] [bit] NOT NULL,
		[CreatedById] [bigint] NOT NULL,
		[CreatedTime] [datetimeoffset](7) NOT NULL,
		[GLAccountId] [bigint]  NULL,
		[GLTemplateDetailId] [bigint] NULL,
		[MatchingGLTemplateDetailId] [bigint] NULL,
		[GLJournalId] [bigint] NOT NULL,
		[LineofBusinessId] [bigint] NOT NULL,
		[InstrumentTypeGLAccountId] [bigint] NULL,
		[IsBookDepreciation] [bit] NOT NULL
	)

	CREATE TABLE #AssetValueHistories(
		[Id] [bigint] IDENTITY(1,1) NOT NULL,
		[StagingId] bigint ,
		[Reason] nvarchar(100) ,
		[SourceModule] nvarchar(25) ,
		[SourceModuleId] bigint ,
		[FromDate] date,
		[ToDate] date ,
		[IncomeDate] date ,
		[Value_Amount] decimal(16, 2) ,
		[Value_Currency] nvarchar(3) ,
		[Cost_Amount] decimal(16, 2) ,
		[Cost_Currency] nvarchar(3) ,
		[NetValue_Amount] decimal(16, 2) ,
		[NetValue_Currency] nvarchar(3) ,
		[BeginBookValue_Amount] decimal(16, 2) ,
		[BeginBookValue_Currency] nvarchar(3) ,
		[EndBookValue_Amount] decimal(16, 2) ,
		[EndBookValue_Currency] nvarchar(3) ,
		[IsAccounted] bit ,
		[IsSchedule] bit ,
		[IsCleared] bit ,
		[PostDate] date,
		[ReversalPostDate] date ,
		[AdjustmentEntry] bit ,
		[CreatedById] bigint ,
		[CreatedTime] datetimeoffset(7) ,
		[UpdatedById] bigint ,
		[UpdatedTime] datetimeoffset(7) ,
		[AssetId] bigint ,
		[GLJournalId] bigint,
		[IsLessorOwned] bit ,
		[IsLeaseComponent] bit,
		[Rank] bigint
	)
	
	INSERT INTO #AssetsValueChangeMappedWithTarget
	SELECT
		AVC.ID [StagingId],
		AVC.PostDate,
		AVC.Reason,
		Assets.Id AS [AssetId] ,
		AVC.AssetAlias,
		Assets.[Status] [AssetStatus],
		AVC.AdjustmentAmount AS [AdjustmentAmount] ,
		CASE WHEN AssetGLDetails.AssetBookValueAdjustmentGLTemplateId IS NULL THEN GLTemplates.Id ELSE AssetGLDetails.AssetBookValueAdjustmentGLTemplateId END AS [AssetBookValueAdjustmentGLTemplateId],
		AssetGLDetails.[BookDepreciationGLTemplateId],
		CASE WHEN AssetGLDetails.InstrumentTypeId IS NULL THEN InstrumentTypes.Id ELSE AssetGLDetails.InstrumentTypeId END AS [InstrumentTypeId],
		LegalEntities.Id [LegalEntityId],
		CASE WHEN AssetGLDetails.LineofBusinessId IS NULL THEN LineofBusinesses.Id ELSE AssetGLDetails.[LineofBusinessId] END AS [LineofBusinessId],
		CASE WHEN AssetGLDetails.BranchId IS NULL THEN Branches.Id ELSE AssetGLDetails.BranchId END AS [BranchId],
		Currencies.Id [CurrencyID],
		Assets.CurrencyCode [CurrencyCode],
		NULL [AssetValueStatusChangeId],
		NULL [GLJournalId],
		CASE WHEN AssetGLDetails.CostCenterId IS NULL THEN CostCenterConfigs.Id ELSE AssetGLDetails.CostCenterId END AS [CostCenterId],
		0 [HasNonTerminatedBookDepreciation],
		0 [HasAccumulatedBookDepreciation],
		NULL [ClearAccumulatedGLJournalId],
		-1*AVC.AdjustmentAmount [Cost],
		@UserId [CreatedById],
		@CreatedTime [CreatedTime],
		DENSE_RANK() over (partition by AVC.assetalias order by AVC.Id) [Rank]
	FROM [dbo].[stgAssetsValueChange] AVC
	LEFT JOIN Assets ON AVC.AssetAlias = Assets.Alias
	LEFT JOIN AssetGLDetails ON Assets.id = AssetGLDetails.Id
	LEFT JOIN GLTemplates ON AVC.[AssetBookValueAdjustmentGLTemplateName] = GLTemplates.[Name] 
	LEFT JOIN InstrumentTypes ON AssetGLDetails.InstrumentTypeId = InstrumentTypes.Id
	LEFT JOIN LineofBusinesses ON AssetGLDetails.LineofBusinessId = LineofBusinesses.Id
	LEFT JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
	LEFT JOIN Branches ON Branches.ID = AssetGLDetails.BranchId
	LEFT JOIN CostCenterConfigs ON CostCenterConfigs.Id = AssetGLDetails.CostCenterId 
	LEFT JOIN CurrencyCodes ON Assets.CurrencyCode = CurrencyCodes.ISO
	LEFT JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
	WHERE IsMigrated=0 and AVC.IsFailed=0 AND AVC.Id between @FromStagingId AND @ToStagingId ;
	
	BEGIN TRANSACTION	
		----------SetAsset Value GLTemplate_InAssetGl--------------------
		
		UPDATE AssetGLDetails
			SET [AssetBookValueAdjustmentGLTemplateId]=AssetsMapped.AssetBookValueAdjustmentGLTemplateId
				,[UpdatedById] =AssetsMapped.CreatedById
				,UpdatedTime= AssetsMapped.CreatedTime
		FROM
		#AssetsValueChangeMappedWithTarget AssetsMapped
		WHERE AssetGLDetails.Id = AssetsMapped.AssetId
		
		------------Create AssetsValueStatusChange---------------------------------------
		
		MERGE AssetsValueStatusChanges AS tgt
		USING 
		(
			SELECT StagingId,PostDate,Reason,CreatedById,CreatedTime,LegalEntityId,CurrencyId,1 IsActive, '_' SourceModule,0 IsZeroMode 
			FROM #AssetsValueChangeMappedWithTarget
		) AS src (StagingId,PostDate,Reason,CreatedById,CreatedTime,LegalEntityId,CurrencyId, IsActive, SourceModule, IsZeroMode ) ON 1=0
		WHEN NOT MATCHED THEN
		INSERT (
			PostDate
			,Reason
			,CreatedById
			,CreatedTime
			,LegalEntityId
			,CurrencyId
			,IsActive
			,SourceModule
			,IsZeroMode
			,MigrationId
		)
		Values(
			 src.PostDate
			,src.Reason
			,src.CreatedById
			,src.CreatedTime
			,src.LegalEntityId
			,src.CurrencyId
			,src.IsActive
			,src.SourceModule
			,src.IsZeroMode
			,src.StagingId
		)
		OUTPUT Inserted.Id AssetsValueStatusChangeId, src.StagingId INTO #InsertedValueIds;
		
		UPDATE #AssetsValueChangeMappedWithTarget 
			SET AssetValueStatusChangeId=#InsertedValueIds.AssetsValueStatusChangeId
		FROM #InsertedValueIds
		WHERE #InsertedValueIds.StagingId = #AssetsValueChangeMappedWithTarget.StagingId;
		
		
		-----------------------------GET Assets to clear Accumulated depreciation------------------------------------------------------
		
		INSERT INTO #AssetsToClearBookDepreciation(
			AssetId,
			SourceModuleId,
			IncomeDate,
			FromDate,
			ToDate,
			Value_Amount,
			Cost_Amount,
			EndBookValue_Amount,
			StagingId,
			AssetValueHistoryId
		)
		SELECT t.AssetId, t.SourceModuleId,tM.IncomeDate, tm.FromDate,tm.ToDate, tM.Value_Amount , t.Cost_Amount,t.EndBookValue_Amount, tm.StagingId, t.Id AssetValueHistoryId
		FROM AssetValueHistories t
		INNER JOIN (
		SELECT AVH.AssetId,AVH.SourceModuleId, -1*SUM(AVH.Value_Amount) Value_Amount,
		MIN(AVH.FromDate) FromDate, MAX(AVH.ToDate) ToDate, MAX(AVH.IncomeDate) IncomeDate ,AssetsMapped.StagingId
		FROM #AssetsValueChangeMappedWithTarget AssetsMapped
		INNER JOIN AssetValueHistories AVH on AssetsMapped.AssetId = AVH.AssetId
		WHERE AVH.IsAccounted=1 and AVH.IncomeDate<= AssetsMapped.PostDate AND AVH.SourceModule IN ('InventoryBookDepreciation')
		GROUP BY AVH.AssetId,AVH.SourceModuleId,AssetsMapped.StagingId
		) tm on t.AssetId = tm.AssetId and t.IncomeDate = tm.IncomeDate AND t.SourceModuleId=tm.SourceModuleId and T.IsCleared=0
		
		UPDATE #AssetsValueChangeMappedWithTarget 
			SET [HasAccumulatedBookDepreciation]=1
		FROM #AssetsToClearBookDepreciation
		WHERE #AssetsToClearBookDepreciation.StagingId = #AssetsToClearBookDepreciation.StagingId;
		
		UPDATE #AssetsToClearBookDepreciation 
			SET PostDate=#AssetsValueChangeMappedWithTarget.PostDate,
				CreatedById = #AssetsValueChangeMappedWithTarget.CreatedById,
				CreatedTime = #AssetsValueChangeMappedWithTarget.CreatedTime
		FROM #AssetsValueChangeMappedWithTarget
		WHERE #AssetsValueChangeMappedWithTarget.StagingId = #AssetsToClearBookDepreciation.StagingId;
		
		------------Create GL JOURNAL--------------------
		
		INSERT INTO #AssetGL(
			StagingId,
			AssetID,
			PostDate,
			[IsManualEntry],
			[IsReversalEntry],
			CreatedById,
			CreatedTime,
			LegalEntityId ,
			[HasAccumulatedBookDepreciation]
		)
		SELECT StagingId, AssetID,PostDate, [IsManualEntry], [IsReversalEntry],CreatedById,CreatedTime,LegalEntityId ,[HasAccumulatedBookDepreciation]
		FROM
		(
			SELECT StagingId, AssetID,PostDate,0 [IsManualEntry],0 [IsReversalEntry],CreatedById,CreatedTime,LegalEntityId ,1 [HasAccumulatedBookDepreciation]
			FROM #AssetsValueChangeMappedWithTarget 
			WHERE AssetStatus='Inventory' AND [HasAccumulatedBookDepreciation]=1
			UNION ALL
			SELECT StagingId, AssetID,PostDate,0 [IsManualEntry],0 [IsReversalEntry],CreatedById,CreatedTime,LegalEntityId ,0 [HasAccumulatedBookDepreciation]
			FROM #AssetsValueChangeMappedWithTarget WHERE AssetStatus='Inventory'
		) t 
		ORDER BY t.StagingId , t.[HasAccumulatedBookDepreciation] DESC
		
		MERGE GLJournals AS tgt
		USING 
		(
			SELECT StagingId, AssetID,PostDate, [IsManualEntry], [IsReversalEntry],CreatedById,CreatedTime,LegalEntityId ,[HasAccumulatedBookDepreciation] 
			FROM #AssetGL
		) AS src (StagingId,AssetID,PostDate,IsManualEntry,IsReversalEntry,CreatedById,CreatedTime,LegalEntityId,[HasAccumulatedBookDepreciation]) ON 1=0
		WHEN NOT MATCHED THEN
		INSERT (
			PostDate
			,IsManualEntry
			,IsReversalEntry
			,CreatedById
			,CreatedTime
			,LegalEntityId
		)
		VALUES(
			src.PostDate
			,src.IsManualEntry
			,src.IsReversalEntry
			,src.CreatedById
			,src.CreatedTime
			,src.LegalEntityId
		)
		OUTPUT INSERTED.Id, src.StagingId, src.AssetId,src.[HasAccumulatedBookDepreciation] INTO #CreatedGLJournalId ;
		
		UPDATE #AssetsValueChangeMappedWithTarget 
			SET GLJournalId=#CreatedGLJournalId.GLJournalId
		FROM #CreatedGLJournalId
		WHERE #CreatedGLJournalId.StagingId = #AssetsValueChangeMappedWithTarget.StagingId AND #CreatedGLJournalId.AssetId =#AssetsValueChangeMappedWithTarget.AssetId
		AND #CreatedGLJournalId.[HasAccumulatedBookDepreciation]=0;
		
		UPDATE #AssetsValueChangeMappedWithTarget
			SET ClearAccumulatedGLJournalId=#CreatedGLJournalId.GLJournalId
		FROM #CreatedGLJournalId
		WHERE #CreatedGLJournalId.StagingId = #AssetsValueChangeMappedWithTarget.StagingId AND #CreatedGLJournalId.AssetId =#AssetsValueChangeMappedWithTarget.AssetId
		AND #CreatedGLJournalId.[HasAccumulatedBookDepreciation]=1;
		
		UPDATE #AssetsToClearBookDepreciation
			SET GLJournalId=#AssetsValueChangeMappedWithTarget.ClearAccumulatedGLJournalId
				,CurrencyCode = #AssetsValueChangeMappedWithTarget.CurrencyCode
				,AssetValueStatusChangeId = #AssetsValueChangeMappedWithTarget.AssetValueStatusChangeId
				,AdjustmentAmount = #AssetsValueChangeMappedWithTarget.AdjustmentAmount
		FROM #AssetsValueChangeMappedWithTarget
		WHERE #AssetsValueChangeMappedWithTarget.StagingId = #AssetsToClearBookDepreciation.StagingId;
		
		----------------------------ADD GLJOURNAL DETAIL-----------------------------------------------
  
	INSERT INTO #GLJournalDetails(
		StagingId,
		EntityId,
		EntityType,
		Amount_Amount,
		Amount_Currency,
		IsDebit,
		GLAccountNumber,
		[Description],
		SourceId,
		CreatedById,
		CreatedTime,
		GLAccountId,
		GLTemplateDetailId,
		GLJournalId,
		IsActive,
		LineofBusinessId,
		[IsBookDepreciation]
	)
	(SELECT
		#CreatedGLJournalId.StagingId [StagingId]
		,AssetsMapped.AssetValueStatusChangeId [EntityId]
		,'AssetValueAdjustment' [EntityType]
		,ABS(AdjustmentAmount) [Amount_Amount]
		,CurrencyCode [Amount_Currency]
		,(CASE WHEN AdjustmentAmount<0 THEN ~GLEntryItems.IsDebit ELSE GLEntryItems.IsDebit END) IsDebit
		,dbo.[GetGLAccountNumber] (AssetsMapped.InstrumentTypeId, GLTemplateDetails.Id,NULL,NULL, AssetsMapped.LegalEntityId,AssetsMapped.LineofBusinessId,'',AssetsMapped.CostCenterId,AssetsMapped.CurrencyId,0,'') GLAccountNumber
		,CASE WHEN #CreatedGLJournalId.HasAccumulatedBookDepreciation=1 THEN CAST(AssetsMapped.AssetId AS nvarchar(50))+','+ CAST(AssetsMapped.PostDate AS nvarchar(50)) ELSE 'Asset Value Adjustment' END [Description]
		,AssetsMapped.AssetValueStatusChangeId [SourceId]
		,AssetsMapped.CreatedById
		,AssetsMapped.CreatedTime
		,GLTemplateDetails.GLAccountId [GLAccountId]
		,GLTemplateDetails.Id [GLTemplateDetailId]
		,#CreatedGLJournalId.GLJournalId [GLJournalId]
		,1 [IsActive]
		,AssetsMapped.LineofBusinessId [LineofBusinessId]
		,0 [IsBookDepreciation]
	FROM #AssetsValueChangeMappedWithTarget AssetsMapped
	INNER JOIN #CreatedGLJournalId ON AssetsMapped.StagingId = #CreatedGLJournalId.StagingId
	INNER JOIN GLTemplateDetails ON AssetsMapped.AssetBookValueAdjustmentGLTemplateId=GLTemplateDetails.GLTemplateId
	INNER JOIN GLEntryItems ON GLTemplateDetails.EntryItemId=GLEntryItems.Id
	WHERE GLEntryItems.Name IN (
								SELECT GLEntry FROM #ReasonGlEntryConfig WHERE Reason=AssetsMapped.Reason
	) AND #CreatedGLJournalId.HasAccumulatedBookDepreciation=0

	UNION

	SELECT
		#CreatedGLJournalId.StagingId [StagingId]
		,AssetsMapped.AssetValueStatusChangeId [EntityId]
		,'AssetValueAdjustment' [EntityType]
		,ABS(#AssetsToClearBookDepreciation.Value_Amount) [Amount_Amount]
		,AssetsMapped.CurrencyCode [Amount_Currency]
		,GLEntryItems.IsDebit [IsDebit]
		,dbo.[GetGLAccountNumber] (AssetsMapped.InstrumentTypeId, GLTemplateDetails.Id,NULL,NULL, AssetsMapped.LegalEntityId,AssetsMapped.LineofBusinessId,'',AssetsMapped.CostCenterId,AssetsMapped.CurrencyId,0,'') GLAccountNumber
		,CASE WHEN #CreatedGLJournalId.HasAccumulatedBookDepreciation=1 THEN CAST(AssetsMapped.AssetId AS nvarchar(50))+','+ CAST(AssetsMapped.PostDate AS nvarchar(50)) ELSE 'Asset Value Adjustment' END [Description]
		,AssetsMapped.AssetValueStatusChangeId [SourceId]
		,AssetsMapped.CreatedById
		,AssetsMapped.CreatedTime
		,GLTemplateDetails.GLAccountId [GLAccountId]
		,GLTemplateDetails.Id [GLTemplateDetailId]
		,#CreatedGLJournalId.GLJournalId [GLJournalId]
		,1 [IsActive]
		,AssetsMapped.LineofBusinessId [LineofBusinessId]
		, 1 [IsBookDepreciation]
	FROM #AssetsValueChangeMappedWithTarget AssetsMapped
	INNER JOIN #AssetsToClearBookDepreciation on AssetsMapped.StagingId = #AssetsToClearBookDepreciation.StagingId
	INNER JOIN #CreatedGLJournalId ON #AssetsToClearBookDepreciation.StagingId = #CreatedGLJournalId.StagingId
	INNER JOIN GLTemplateDetails ON AssetsMapped.AssetBookValueAdjustmentGLTemplateId=GLTemplateDetails.GLTemplateId
	INNER JOIN GLEntryItems ON GLTemplateDetails.EntryItemId=GLEntryItems.Id
	WHERE GLEntryItems.Name IN (
								SELECT GLEntry FROM #BookDepreciationGlEntryConfig
								WHERE AssetStatus = AssetsMapped.AssetStatus AND AssetsMapped.HasAccumulatedBookDepreciation=1
								AND #CreatedGLJournalId.GLJournalId = AssetsMapped.ClearAccumulatedGLJournalId
	) AND #CreatedGLJournalId.HasAccumulatedBookDepreciation=1 ) ORDER BY StagingId, [IsBookDepreciation]

	Update #GLJournalDetails
	SET MatchingGLTemplateDetailId = A.GlTemplateDetailId
	, GLAccountId = A.GLAccountId
	, GLAccountNumber = A.GLAccountNumber
	, InstrumentTypeGLAccountId = A.InstrumentTypeGLAccountId
	FROM (select  acb.stagingid , gd.GlTemplateDetailId, gd.GLAccountNumber,gd.Description,gd.GLAccountId,gd.InstrumentTypeGLAccountId ,acb.Value_Amount 
	from #AssetsToClearBookDepreciation acb
	INNER JOIN AssetValueHistories avh on acb.AssetValueHistoryID = avh.Id
	INNER JOIN GLJournalDetails gd on gd.GlJournalId = avh.GlJournalId
	INNER JOIN GLTemplateDetails gtd on gd.GlTemplateDetailId = gtd.id
	INNER JOIN GLEntryItems gei on gtd.EntryItemId = gei.Id
	INNER JOIN GLTemplates gt on gtd.GLTemplateId= gt.id
	Inner Join GLTransactionTypes gtt on gt.GlTransactionTypeId= gtt.Id
	WHERE gei.Name = 'AccumulatedDepreciation' and gtt.Name = 'BookDepreciation') A WHERE #GLJournalDetails.IsBookDepreciation=1 AND #GLJournalDetails.StagingId = A.StagingId And #GLJournalDetails.GLAccountId IS NULL 


	INSERT INTO GLJournalDetails(
		EntityId,
		EntityType,
		Amount_Amount,
		Amount_Currency,
		IsDebit,
		GLAccountNumber,
		[Description],
		SourceId,
		CreatedById,
		CreatedTime,
		GLAccountId,
		GLTemplateDetailId,
		GLJournalId,
		IsActive,
		LineofBusinessId,
		MatchingGLTemplateDetailId,
		InstrumentTypeGLAccountId
	)
	SELECT
		EntityId,
		EntityType,
		Amount_Amount,
		Amount_Currency,
		IsDebit,
		GLAccountNumber,
		[Description],
		SourceId,
		CreatedById,
		CreatedTime,
		GLAccountId,
		GLTemplateDetailId,
		GLJournalId,
		IsActive,
		LineofBusinessId,
		MatchingGLTemplateDetailId,
		InstrumentTypeGLAccountId
	FROM #GLJournalDetails order by Id
		
		------------------------ADD ASSET VALUE STATUS CHANGE DETAIL-------------------------------------------
		
		
		INSERT INTO AssetsValueStatusChangeDetails(
			AdjustmentAmount_Amount
			,AdjustmentAmount_Currency
			,NewStatus
			,CreatedById
			,CreatedTime
			,AssetId
			,AssetsValueStatusChangeId
			,CostCenterId
			,GLTemplateId
			,InstrumentTypeId
			,LineofBusinessId
			,GLJournalId
		)
		SELECT
			AssetsMapped.AdjustmentAmount [AdjustmentAmount_Amount ]
			,AssetsMapped.CurrencyCode [AdjustmentAmount_Currency]
			,AssetsMapped.AssetStatus [NewStatus]
			,AssetsMapped.CreatedById
			,AssetsMapped.CreatedTime
			,AssetsMapped.AssetId
			,AssetsMapped.AssetValueStatusChangeId
			,AssetsMapped.CostCenterId
			,AssetsMapped.AssetBookValueAdjustmentGLTemplateId GLTemplateId
			,AssetsMapped.InstrumentTypeId
			,AssetsMapped.LineofBusinessId
			,AssetsMapped.GLJournalId
		FROM
		#AssetsValueChangeMappedWithTarget AssetsMapped
		
		
		------------------------Terminate Book Depreciation --------------------
		
		UPDATE BookDepreciations 
			SET TerminatedDate = #AssetsToClearBookDepreciation.PostDate,
				ClearAccumulatedGLJournalId = #AssetsToClearBookDepreciation.GLJournalId,
				UpdatedById =#AssetsToClearBookDepreciation.CreatedById,
				UpdatedTime= #AssetsToClearBookDepreciation.CreatedTime
		FROM #AssetsToClearBookDepreciation WHERE BookDepreciations.AssetId = #AssetsToClearBookDepreciation.AssetId
		AND TerminatedDate IS NULL

		INSERT into [dbo].[BookDepreciations](
			[CostBasis_Amount]
			,[CostBasis_Currency]
			,[Salvage_Amount]
			,[Salvage_Currency]
			,[BeginDate]
			,[EndDate]
			,[RemainingLifeInMonths]
			,[PerDayDepreciationFactor]
			,[IsActive]
			,[IsInOTP]
			,[CreatedById]
			,[CreatedTime]
			,[AssetId]
			,[GLTemplateId]
			,[InstrumentTypeId]
			,[LineofBusinessId]
			,[ContractId]
			,[BookDepreciationTemplateId]
			,[BranchId]
			,[CostCenterId]
			,[IsLessorOwned]
			,[IsLeaseComponent]
		)
		SELECT
			[CostBasis_Amount]=(#AssetsToClearBookDepreciation.EndBookValue_Amount+(-1*#AssetsToClearBookDepreciation.AdjustmentAmount)) 
			,[CostBasis_Currency]
			,[Salvage_Amount]
			,[Salvage_Currency]
			,[BeginDate]=DATEADD(DAY,1,[PostDate]) 
			,[EndDate]=DATEADD(MONTH,([RemainingLifeInMonths] - dbo.DaysDifferenceBy30360(BeginDate,PostDate) / 30.0), DATEADD(DAY,1,[PostDate])) 
			,[RemainingLifeInMonths] = ([RemainingLifeInMonths] - dbo.DaysDifferenceBy30360(BeginDate,PostDate) / 30.0)
			,[PerDayDepreciationFactor] = ((#AssetsToClearBookDepreciation.EndBookValue_Amount+(-1*#AssetsToClearBookDepreciation.AdjustmentAmount)) - [Salvage_Amount])/dbo.DaysDifferenceBy30360(BeginDate,PostDate)
			,1 [IsActive]
			,[IsInOTP]
			,#AssetsToClearBookDepreciation.CreatedById
			,#AssetsToClearBookDepreciation.CreatedTime
			,#AssetsToClearBookDepreciation.[AssetId]
			,[GLTemplateId]
			,[InstrumentTypeId]
			,[LineofBusinessId]
			,[ContractId]
			,[BookDepreciationTemplateId]
			,[BranchId]
			,[CostCenterId]
			,[IsLessorOwned]
			,[IsLeaseComponent]
		FROM BookDepreciations
		INNER JOIN #AssetsToClearBookDepreciation ON BookDepreciations.AssetId = #AssetsToClearBookDepreciation.AssetId
		
		
		---------------------- INSERT ASSETVALUEHISTORY CLEAR BOOK DEPRECIATION --------------------
		
		UPDATE AssetValueHistories 
			SET IsCleared=1
			,UpdatedById =#AssetsToClearBookDepreciation.CreatedById
			,UpdatedTime= #AssetsToClearBookDepreciation.CreatedTime							   
		FROM #AssetsToClearBookDepreciation 
		WHERE #AssetsToClearBookDepreciation.AssetValueHistoryId= AssetValueHistories.Id
		
		INSERT INTO AssetValueHistories(
			AssetId
			,SourceModule
			,SourceModuleId
			,IncomeDate
			,Value_Amount
			,Value_Currency
			,Cost_Amount
			,Cost_Currency
			,NetValue_Amount
			,NetValue_Currency
			,BeginBookValue_Amount
			,BeginBookValue_Currency
			,EndBookValue_Amount
			,EndBookValue_Currency
			,IsAccounted
			,IsSchedule
			,IsCleared
			,PostDate
			,GLJournalId
			,CreatedById
			,CreatedTime
			,IsLeaseComponent
			,IsLessorOwned
			,AdjustmentEntry			   
		)
		SELECT
			avh.AssetId
			,'ClearAccumulatedAccounts' SourceModule
			,avh.AssetValueStatusChangeId
			,avh.PostDate
			,avh.Value_Amount [Value_Amount]
			,avh.CurrencyCode [Value_Currency]
			,avh.Cost_Amount
			,avh.CurrencyCode
			,avh.EndBookValue_Amount NetValue_Amount
			,avh.CurrencyCode
			,avh.EndBookValue_Amount [BeginBookValue_Amount]
			,avh.CurrencyCode [BeginBookValue_Currency]
			,avh.EndBookValue_Amount [EndBookValue_Amount]
			,avh.CurrencyCode [EndBookValue_Currency]
			,[IsAccounted] =1
			,1 [IsSchedule]
			,1 [IsCleared]
			,avh.PostDate
			,avh.GLJournalId
			,avh.CreatedById
			,avh.CreatedTime
			,1 [IsLeaseComponent]
			,1 [IsLessorOwned]
			,0 [AdjustmentEntry]	   
		FROM #AssetsToClearBookDepreciation avh																								 
		
		-----------------------------CREATE ASSET VALUE HISTORY----------------------------------------
		
		INSERT INTO #AssetValueHistories
		(
			 AssetId
			,SourceModule
			,[SourceModuleId]
			,IncomeDate
			,Value_Amount
			,Value_Currency 
			,Cost_Currency  
			,NetValue_Currency		 
			,BeginBookValue_Currency	   
			,EndBookValue_Currency
			,IsAccounted
			,IsSchedule
			,IsCleared
			,PostDate
			,GLJournalId
			,CreatedById
			,CreatedTime
			,IsLeaseComponent
			,IsLessorOwned
			,AdjustmentEntry
			,StagingId
			,[Rank]
			,Reason
		)
		SELECT
			 AssetId
			,[SourceModule]=CASE WHEN Reason='Impairment' THEN 'NBVImpairments' ELSE 'AssetValueAdjustment' END
			,[SourceModuleId]=AssetValueStatusChangeId
			,IncomeDate = PostDate
			,[Value_Amount]=(-1*AdjustmentAmount)
			,[Value_Currency]=CurrencyCode
			,Cost_Currency=CurrencyCode
			,NetValue_Currency=CurrencyCode
			,BeginBookValue_Currency=CurrencyCode
			,EndBookValue_Currency=CurrencyCode
			,[IsAccounted] = CASE WHEN AssetStatus='Investor' THEN 0 ELSE 1 END
			,[IsSchedule]=1
			,[IsCleared] = CASE WHEN Reason='Impairment' THEN 0 ELSE 1 END
			,PostDate
			,GLJournalId
			,CreatedById
			,CreatedTime
			,IsLeaseComponent=1 
			,IsLessorOwned = CASE WHEN AssetStatus='Investor' THEN 0 ELSE 1 END
			,AdjustmentEntry=0 
			,StagingId
			,[Rank]
			,Reason
		FROM #AssetsValueChangeMappedWithTarget
		
		UPDATE #AssetValueHistories
			SET Cost_Amount =(-1*avh.AdjustmentAmount)
			,[NetValue_Amount]=(-1*avh.AdjustmentAmount)
			,[BeginBookValue_Amount]=(-1*avh.AdjustmentAmount)
			,[EndBookValue_Amount]=(-1*avh.AdjustmentAmount)
		FROM #AssetsValueChangeMappedWithTarget avh
		LEFT JOIN AssetValueHistories ON avh.AssetId = AssetValueHistories.AssetId
		WHERE AssetValueHistories.Id IS NULL AND #AssetValueHistories.[RANK] =1 AND AVH.[Rank]=1 and #AssetValueHistories.StagingId = avh.StagingId
		
		UPDATE #AssetValueHistories
			SET [Cost_Amount] =avh.Cost_Amount	
			,[NetValue_Amount]=CASE WHEN avh.Reason='Impairment' THEN avh.NetValue_Amount ELSE (avh.EndBookValue_Amount +(-1*avh.AdjustmentAmount)) END					
			,[BeginBookValue_Amount]=avh.EndBookValue_Amount							  
			,[EndBookValue_Amount]=(avh.EndBookValue_Amount + (-1*avh.AdjustmentAmount))	   
		FROM
		(
			SELECT #AssetsValueChangeMappedWithTarget.*,t.*
			FROM #AssetsValueChangeMappedWithTarget
			JOIN (
					SELECT AssetId avhAsset, Cost_Amount,Cost_Currency,NetValue_Amount,EndBookValue_Amount,BeginBookValue_Amount, IsLeaseComponent,IsLessorOwned, AdjustmentEntry FROM AssetValueHistories A
					WHERE [IsSchedule]=1 AND A.Id IN
					(
						SELECT TOP(1) Id FROM AssetValueHistories WHERE AssetValueHistories.AssetId = A.AssetId
						ORDER By AssetValueHistories.id DESC
					)
				) t on #AssetsValueChangeMappedWithTarget.AssetId = t.avhAsset
		) AS avh where avh.[RANK] =1 AND #AssetValueHistories.[Rank]=1 AND #AssetValueHistories.AssetId = AVH.AssetId
				
		UPDATE #AssetValueHistories
			SET [Cost_Amount] =avh.Cost_Amount
			,[NetValue_Amount]=avh.NetValue_Amount
			,[BeginBookValue_Amount]=avh.[BeginBookValue_Amount]
			,[EndBookValue_Amount]= avh.[EndBookValue_Amount]
		FROM
		(
			SELECT [Stagingid]
			,[Cost_Amount]= CASE WHEN [Rank]<>1 THEN Lag([Cost_Amount],1,0) over (partition by assetid order by stagingid) END
			,[NetValue_Amount]=CASE WHEN [Rank]<>1 THEN CASE WHEN Reason='Impairment' THEN Lag([NetValue_Amount],1,0) over (partition by assetid order by stagingid) ELSE (Lag([EndBookValue_Amount],1,0) over (partition by assetid order by stagingid) +[Value_Amount]) END END
			,[EndBookValue_Amount] = CASE WHEN [Rank]<>1 THEN (Lag([EndBookValue_Amount],1,0) over (partition by assetid order by stagingid) +[Value_Amount]) END
			,[BeginBookValue_Amount]= CASE WHEN [Rank]<>1 THEN Lag([EndBookValue_Amount]) over (partition by assetid order by stagingid) END
			,[Rank]
			FROM #AssetValueHistories
		) avh
		WHERE #AssetValueHistories.StagingId = avh.StagingId AND avh.Rank<>1 AND #AssetValueHistories.Rank<>1

		
		INSERT INTO AssetValueHistories(
			AssetId
			,SourceModule
			,SourceModuleId
			,IncomeDate
			,Value_Amount
			,Value_Currency
			,Cost_Amount
			,Cost_Currency
			,NetValue_Amount
			,NetValue_Currency
			,BeginBookValue_Amount
			,BeginBookValue_Currency
			,EndBookValue_Amount
			,EndBookValue_Currency
			,IsAccounted
			,IsSchedule
			,IsCleared
			,PostDate
			,GLJournalId
			,CreatedById
			,CreatedTime
			,IsLeaseComponent
			,IsLessorOwned
			,AdjustmentEntry
		)
		SELECT
			 AssetId
			,SourceModule
			,SourceModuleId
			,IncomeDate
			,Value_Amount
			,Value_Currency
			,Cost_Amount
			,Cost_Currency
			,NetValue_Amount
			,NetValue_Currency
			,BeginBookValue_Amount
			,BeginBookValue_Currency
			,EndBookValue_Amount
			,EndBookValue_Currency
			,IsAccounted
			,IsSchedule
			,IsCleared
			,PostDate
			,GLJournalId
			,CreatedById
			,CreatedTime
			,IsLeaseComponent
			,IsLessorOwned
			,AdjustmentEntry
		FROM #AssetValueHistories order by Id

		UPDATE stgAssetsValueChange SET IsMigrated =1 
		FROM stgAssetsValueChange
		JOIN #ProcessingRecords ON #ProcessingRecords.StagingID= stgAssetsValueChange.id
		WHERE stgAssetsValueChange.IsMigrated=0
		AND #ProcessingRecords.StagingID BETWEEN @FromStagingId AND @ToStagingId
		AND #ProcessingRecords.IsValid=1
		
		DROP TABLE #AssetsValueChangeMappedWithTarget;
		DROP TABLE #AssetValueHistories;
		DROP TABLE #InsertedValueIds;
		DROP TABLE #AssetsToClearBookDepreciation;
		DROP TABLE #CreatedGLJournalId;
		DROP TABLE #GLJournalDetails;

		COMMIT TRANSACTION
		END TRY
		BEGIN CATCH
		
		DECLARE @ErrorMessage Nvarchar(max);
		DECLARE @ErrorLine Nvarchar(max);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @ErrorLogs ErrorMessageList;
		DECLARE @ModuleName Nvarchar(max) = 'CreateAssetValueChange'
		INSERT INTO @ErrorLogs(StagingRootEntityId, ModuleIterationStatusId, Message,Type) VALUES (0,@ModuleIterationStatusId,ERROR_MESSAGE(),'Error')
		SELECT  @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(),@ErrorLine=ERROR_LINE(),@ErrorMessage=ERROR_MESSAGE()
		IF (XACT_STATE()) = -1  
		BEGIN  
			ROLLBACK TRANSACTION;
			EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
			SET @FailedRecords = @FailedRecords+@TakeCount;
		END;  
		ELSE IF (XACT_STATE()) = 1  
		BEGIN
			COMMIT TRANSACTION;
			RAISERROR (@ErrorMessage,@ErrorSeverity, @ErrorState);     
		END;  
		ELSE
		BEGIN
			EXEC [dbo].[ExceptionLog] @ErrorLogs,@ErrorLine,@UserId,@CreatedTime,@ModuleName
		    SET @FailedRecords = @FailedRecords+@TakeCount;
		END;

		UPDATE  #ProcessingRecords
		SET IsValid=0
		Where IsValid=1 AND StagingId BETWEEN @FromStagingId AND @ToStagingId

		END CATCH
	END
	
	SET @SkipCount = @SkipCount+ @TakeCount;
	
	END


MERGE stgProcessingLog AS ProcessingLog
USING 
(
	SELECT DISTINCT StagingId FROM #ProcessingRecords Where IsValid=1
) AS ProcessedAssetsValueChange
ON (ProcessingLog.StagingRootEntityId = ProcessedAssetsValueChange.StagingId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
	UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT(
	StagingRootEntityId
	,CreatedById
	,CreatedTime
	,ModuleIterationStatusId
)
VALUES
(
	ProcessedAssetsValueChange.StagingId
	,@UserId
	,@CreatedTime
	,@ModuleIterationStatusId
)
OUTPUT Inserted.Id , ProcessedAssetsValueChange.StagingId INTO #CreatedProcessingLogs;

INSERT INTO stgProcessingLogDetail(
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
	,Id
FROM
#CreatedProcessingLogs

SET @FailedRecords = (SELECT COUNT(DISTINCT StagingId) FROM #ProcessingRecords Where IsValid=0);
SET @ProcessedRecords= @TotalRecordsCount;

DROP TABLE #CreatedProcessingLogs;
DROP TABLE #ProcessingRecords;
DROP TABLE #ReasonGlEntryConfig;
DROP TABLE #BookDepreciationGlEntryConfig;

SET NOCOUNT OFF
SET XACT_ABORT OFF
SET ANSI_WARNINGS OFF

END;

GO

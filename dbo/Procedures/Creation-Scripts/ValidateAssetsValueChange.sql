SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateAssetsValueChange]
(
	@UserId bigint ,
	@ModuleIterationStatusId bigint,
	@CreatedTime datetimeoffset,
	@FromStagingId bigint,
	@ToStagingId bigint
)
AS BEGIN

SET XACT_ABORT ON
SET NOCOUNT ON
SET ANSI_WARNINGS ON


IF OBJECT_ID('tempdb..#ErrorLogs') IS NOT NULL
	DROP TABLE #ErrorLogs;

IF OBJECT_ID('tempdb..#AVHErrorLogs') IS NOT NULL
	DROP TABLE #AVHErrorLogs;

IF OBJECT_ID('tempdb..#FailedProcessingLogs') IS NOT NULL
	DROP TABLE #FailedProcessingLogs;

IF OBJECT_ID('tempdb..#AssetsValueChangeMappedWithTarget') IS NOT NULL
	DROP TABLE #AssetsValueChangeMappedWithTarget;

IF OBJECT_ID('tempdb..#AssetValueHistory') IS NOT NULL
	DROP TABLE #AssetValueHistory;
	
CREATE TABLE #ErrorLogs(
	Id bigint NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId bigint,
	Result nvarchar(10),
	Message nvarchar(max)
);

CREATE TABLE #AVHErrorLogs(
	Id bigint NOT NULL IDENTITY PRIMARY KEY,
	StagingRootEntityId bigint,
	AssetAlias nvarchar(100),
	Result nvarchar(10),
	Message nvarchar(max)
);

CREATE TABLE #FailedProcessingLogs(
	[Id] bigint NOT NULL,
	[StagingId] bigint NOT NULL
);

CREATE TABLE #AssetsValueChangeMappedWithTarget(
	[StagingId] bigint,
	PostDate date,
	Reason nvarchar(100),
	AssetId bigint,
	AssetAlias nvarchar(100),
	AssetStatus nvarchar(100),
	[FinancialType] nvarchar(15),
	[SalvageAmount] decimal(16,2),
	[HoldingStatus] nvarchar(3),
	AdjustmentAmount decimal(16,2),
	[AssetBookValueAdjustmentGLTemplateId] bigint,
	[AssetBookValueAdjustmentGLTemplateName] nvarchar(100),
	[LegalEntityId] bigint,
	[LegalEntityNumber] nvarchar(20),
	[CurrencyId] bigint
);

CREATE TABLE #AssetValueHistory
(
	StagingId bigint,
	AssetAlias nvarchar(200),
	StagingAssetId bigint,
	StagingAssetPostDate date,
	AssetStatus nvarchar(200),
	SalvageAmount decimal(16,2),
	AdjustmentAmount decimal(16,2),
	Reason nvarchar(200),
	NewNBV decimal(19,2),
	AssetValueHistoryId bigint,
	IncomeDate date,
	EndBookValue_Amount decimal(16,2),
	PostDate date,
	IsLatest bit,
	rank_ bigint
)

INSERT INTO #AssetsValueChangeMappedWithTarget
SELECT
AVC.ID [StagingId],
AVC.PostDate,
AVC.Reason,
Assets.Id AS [AssetId] ,
AVC.AssetAlias,
Assets.[Status] [AssetStatus],
Assets.FinancialType [FinancialType],
Assets.Salvage_Amount [SalvageAmount],
AssetGLDetails.HoldingStatus [HoldingStatus],
AVC.AdjustmentAmount AS [AdjustmentAmount] ,
GLTemplates.Id AS [AssetBookValueAdjustmentGLTemplateId],
AVC.AssetBookValueAdjustmentGLTemplateName,	
LegalEntities.Id [LegalEntityId],
LegalEntities.LegalEntityNumber,
Currencies.Id CurrencyId
FROM [dbo].[stgAssetsValueChange] AVC
LEFT JOIN Assets ON AVC.AssetAlias = Assets.Alias
LEFT JOIN AssetGLDetails ON Assets.id = AssetGLDetails.Id
LEFT JOIN GLTemplates ON AVC.[AssetBookValueAdjustmentGLTemplateName] = GLTemplates.[Name]
LEFT JOIN LegalEntities ON Assets.LegalEntityId = LegalEntities.Id
LEFT JOIN CurrencyCodes ON Assets.CurrencyCode = CurrencyCodes.ISO
LEFT JOIN Currencies ON CurrencyCodes.Id = Currencies.CurrencyCodeId
Where AVC.Id BETWEEN @FromStagingId AND @ToStagingId AND IsMigrated=0

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Matching Asset not found for Asset Alias:' + AssetAlias As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped
WHERE AssetId IS NULL 

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Asset Value change can be done only for assets with status Inventory / Investor / Collateral' As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped
WHERE AssetsMapped.[AssetStatus] NOT IN ('Inventory','Investor','Collateral') 

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Asset : '+AssetsMapped.AssetAlias+' must have Financial Type as Real' As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped  
WHERE AssetsMapped.FinancialType !='Real' 

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT DISTINCT 
AssetsMapped.StagingId,
'Asset : '+AssetsMapped.AssetAlias+' feature currency is not matching with Value Status Change Currency' As [message] 
FROM #AssetsValueChangeMappedWithTarget AssetsMapped
JOIN AssetFeatures on  AssetsMapped.AssetId = AssetFeatures.AssetId
where AssetFeatures.IsActive=1 and AssetFeatures.CurrencyId!=AssetsMapped.CurrencyId

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Asset :'+AssetsMapped.AssetAlias+' of Status Collateral and Investor cannot have  Reason as Impairment' As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped  
WHERE AssetsMapped.[AssetStatus] IN ('Investor','Collateral') AND AssetsMapped.Reason='Impairment'

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Since asset holding status of Asset:'+AssetsMapped.AssetAlias+' is Held For Sale, reason can only be ''MarktoMarketAdjustment''' As [message]
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped
WHERE AssetsMapped.HoldingStatus ='HFS' AND AssetsMapped.Reason<>'MarktoMarketAdjustment'

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Reason can be set to ''MarktoMarketAdjustment'' for the Asset :'+AssetsMapped.AssetAlias+' only if holding status is Held For Sale' As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped  
WHERE AssetsMapped.HoldingStatus !='HFS' AND AssetsMapped.Reason='MarktoMarketAdjustment'


Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Legal Entity { '+AssetsMapped.LegalEntityNumber+' } Associated with Asset :'+AssetsMapped.AssetAlias+' should have at least one GL Financial Open Period' As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped 
LEFT JOIN GLFinancialOpenPeriods ON AssetsMapped.LegalEntityId = GLFinancialOpenPeriods.LegalEntityId
WHERE AssetsMapped.AssetId IS NOT NULL AND GLFinancialOpenPeriods.Id IS NULL


Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'PostDate should be within the financial open period : '+CAST(GLFinancialOpenPeriods.FromDate AS Varchar(100))+' and '+CAST(GLFinancialOpenPeriods.ToDate AS Varchar(100)) As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped 
LEFT JOIN GLFinancialOpenPeriods ON AssetsMapped.LegalEntityId = GLFinancialOpenPeriods.LegalEntityId AND GLFinancialOpenPeriods.IsCurrent=1
WHERE (AssetsMapped.PostDate < GLFinancialOpenPeriods.FromDate OR AssetsMapped.PostDate > GLFinancialOpenPeriods.ToDate) 

	 
Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Matching Asset Book Value Adjustment GLTemplate not found for : '+ AssetBookValueAdjustmentGLTemplateName  As [message] 
FROM   
#AssetsValueChangeMappedWithTarget AssetsMapped 
WHERE AssetBookValueAdjustmentGLTemplateId IS NULL

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'GL Template selected should be Active'  As [message] 
FROM     
#AssetsValueChangeMappedWithTarget AssetsMapped
LEFT JOIN GLTemplates on AssetsMapped.AssetBookValueAdjustmentGLTemplateId = GLTemplates.Id
WHERE GLTemplates.IsActive = 0

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'GL Template selected should have GL Transaction type as Asset Book Value Adjustment'  As [message] 
FROM    
#AssetsValueChangeMappedWithTarget AssetsMapped
LEFT JOIN GLTemplates on AssetsMapped.AssetBookValueAdjustmentGLTemplateId = GLTemplates.Id
LEFT JOIN GLTransactionTypes on GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id			
WHERE GLTransactionTypes.Name != 'AssetBookValueAdjustment' 

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'GL configuration of the GL Template should match the GL Configuration of the Legal Entity of Asset'  As [message] 
FROM 
#AssetsValueChangeMappedWithTarget AssetsMapped
LEFT JOIN GLTemplates on AssetsMapped.AssetBookValueAdjustmentGLTemplateId = GLTemplates.Id			
LEFT JOIN Assets on AssetsMapped.AssetId = Assets.Id
LEFT JOIN LegalEntities on Assets.LegalEntityId = LegalEntities.Id
WHERE LegalEntities.GLConfigurationId != GLTemplates.GLConfigurationId

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT
StagingId,
'Book Depreciation must be run until Post Date. Please run the book dep for Asset Alias:'+ AssetsMapped.AssetAlias +' till '+ CAST(AssetsMapped.PostDate AS Varchar(100))  As [message] 
FROM #AssetsValueChangeMappedWithTarget AssetsMapped
INNER JOIN BookDepreciations bookDep ON AssetsMapped.AssetId = bookDep.AssetId
WHERE bookDep.IsActive=1 and bookDep.BeginDate<=AssetsMapped.PostDate
and (bookDep.LastAmortRunDate is null or  (1=(CASE WHEN (booKDep.TerminatedDate IS NOT NULL)
										   THEN  CASE WHEN (bookdep.LastAmortRunDate<bookdep.TerminatedDate) THEN 1 ELSE 0 END
										   ELSE CASE WHEN (bookdep.LastAmortRunDate < bookdep.EndDate) THEN 1 ELSE 0 END
										   END) and bookdep.LastAmortRunDate <AssetsMapped.postDate))

INSERT INTO #AssetValueHistory 
			(StagingId
			,AssetAlias
			,StagingAssetId
			,StagingAssetPostDate
			,AssetStatus
			,SalvageAmount
			,AdjustmentAmount
			,Reason
			,IsLatest
			,rank_)
	SELECT
			AssetsMapped.StagingId
			,AssetsMapped.AssetAlias
			,AssetsMapped.AssetId [StagingAssetId]
			,AssetsMapped.PostDate [StagingAssetPostDate]
			,AssetsMapped.AssetStatus
			,AssetsMapped.SalvageAmount
			,AssetsMapped.AdjustmentAmount
			,AssetsMapped.Reason
			,0 IsLatest
			,DENSE_RANK() over (partition by AssetsMapped.assetalias order by AssetsMapped.stagingid) rank_
	FROM #AssetsValueChangeMappedWithTarget AssetsMapped
	WHERE AssetsMapped.AssetId IS NOT NULL

UPDATE #AssetValueHistory
SET  NewNBV = CASE WHEN #AssetValueHistory.Reason='Impairment' THEN AVH.NetValue_Amount ELSE (AVH.EndBookValue_Amount +(-1*#AssetValueHistory.AdjustmentAmount)) END  
	,[IncomeDate]=AVH.IncomeDate
	,[EndBookValue_Amount] = AVH.EndBookValue_Amount
	,[PostDate]= AVH.PostDate
	,[AssetValueHistoryId] = AVH.Id
	,IsLatest=1
FROM  (
				SELECT A.ID, A.AssetId,A.NetValue_Amount, A.EndBookValue_Amount,A.IncomeDate,A.PostDate FROM AssetValueHistories A
				WHERE IsSchedule=1 AND A.Id IN 
				(
					SELECT TOP(1) Id FROM AssetValueHistories WHERE AssetValueHistories.AssetId = A.AssetId
					ORDER By AssetValueHistories.id DESC
				) 
		 ) AVH 
WHERE #AssetValueHistory.rank_=1  AND #AssetValueHistory.StagingAssetId = AVH.AssetId

UPDATE #AssetValueHistory
	SET  NewNBV = -1*[AdjustmentAmount]
		,[IncomeDate]=StagingAssetPostDate
		,[EndBookValue_Amount] = (-1*AdjustmentAmount)
		,[PostDate]= StagingAssetPostDate
		,IsLatest=1
WHERE rank_=1 AND [AssetValueHistoryId] IS NULL

UPDATE #AssetValueHistory
SET  [NewNBV]= A.NewNBV
	,[IncomeDate] = A.[IncomeDate]
	,[EndBookValue_Amount] = A.[EndBookValue_Amount]
	,[PostDate]= A.PostDate
FROM
(
	SELECT [Stagingid]
		  ,[NewNBV]= CASE WHEN IsLatest=0 THEN Lag([NewNBV],1,0) over (partition by assetalias order by stagingid) + (-1*AdjustmentAmount) END
		  ,[IncomeDate]=CASE WHEN IsLatest=0 THEN Lag([StagingAssetPostDate]) over (partition by assetalias order by stagingid) END
		  ,[EndBookValue_Amount] = CASE WHEN IsLatest=0 THEN Lag([NewNBV],1,0) over (partition by assetalias order by stagingid) END
		  ,[PostDate]= CASE WHEN IsLatest=0 THEN Lag([StagingAssetPostDate]) over (partition by assetalias order by stagingid) END
		  ,[IsLatest]
	  FROM #AssetValueHistory  
) A
WHERE  #AssetValueHistory.StagingId = A.StagingId AND A.IsLatest=0 

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'Impairment can''t be done for the Asset: '+AssetsMapped.AssetAlias+' because there is no AssetValueHistories record'  As [message] ,
AssetsMapped.AssetAlias
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.IsLatest=1 AND AssetsMapped.AssetValueHistoryId IS NULL
AND AssetsMapped.Reason ='Impairment'

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'Latest Asset Value History record for the Asset: '+AssetsMapped.AssetAlias+' must be GL Posted'  As [message] ,
AssetsMapped.AssetAlias
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.IsLatest=1 AND AssetsMapped.PostDate IS NULL

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'Asset Value Histories cannot have records with income date greater than current income date for the Asset :'+ AssetsMapped.AssetAlias  As [message],
AssetsMapped.AssetAlias
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.IncomeDate > AssetsMapped.StagingAssetPostDate

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'Asset :'+ AssetsMapped.AssetAlias+' New NBV must be zero/positive'  As [message],
AssetsMapped.AssetAlias 
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.EndBookValue_Amount > 0 AND AssetsMapped.NewNBV < 0

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'Asset :'+ AssetsMapped.AssetAlias+' New NBV must be zero/negative'  As [message],
AssetsMapped.AssetAlias 
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.EndBookValue_Amount < 0 AND AssetsMapped.NewNBV > 0

Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'New NBV of Collateral and Investor Assets cannot be negative, please update the Adjustment Amount, Check for Asset : '+Assetsmapped.AssetAlias  As [message],
AssetsMapped.AssetAlias 
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.[AssetStatus] IN ('Investor','Collateral') AND AssetsMapped.NewNBV < 0


Insert Into #AVHErrorLogs ([StagingRootEntityId],[Message],[AssetAlias])
SELECT
AssetsMapped.StagingId,
'New NBV value of the Asset should not be less than its Salvage Value. Asset: '+AssetsMapped.AssetAlias  As [message],
AssetsMapped.AssetAlias
FROM 
#AssetValueHistory AssetsMapped
WHERE AssetsMapped.NewNBV < AssetsMapped.SalvageAmount

UPDATE stgAssetsValueChange
SET IsFailed=1
Where IsMigrated=0 AND AssetAlias IN (
SELECT DISTINCT [AssetAlias] FROM  #AVHErrorLogs
)

UPDATE stgAssetsValueChange
SET IsFailed=1
WHERE Id IN (SELECT DISTINCT StagingRootEntityId FROM  #ErrorLogs)

Insert Into #ErrorLogs ([StagingRootEntityId],[Message])
SELECT [StagingRootEntityId], [Message] FROM #AVHErrorLogs

	
MERGE stgProcessingLog AS ProcessingLog
USING 
(
	SELECT DISTINCT StagingRootEntityId FROM #ErrorLogs 
) AS ErrorAssetsValueChange
ON (ProcessingLog.StagingRootEntityId = ErrorAssetsValueChange.StagingRootEntityId AND ProcessingLog.ModuleIterationStatusId = @ModuleIterationStatusId)
WHEN MATCHED THEN
UPDATE SET UpdatedTime = @CreatedTime
WHEN NOT MATCHED THEN
INSERT (
	StagingRootEntityId
	,CreatedById
	,CreatedTime
	,ModuleIterationStatusId
)
VALUES
(
	ErrorAssetsValueChange.StagingRootEntityId
	,@UserId
	,@CreatedTime
	,@ModuleIterationStatusId
)
OUTPUT Inserted.Id,ErrorAssetsValueChange.StagingRootEntityId INTO #FailedProcessingLogs;

INSERT INTO stgProcessingLogDetail(
	Message
	,Type
	,CreatedById
	,CreatedTime
	,ProcessingLogId
)
SELECT
	#ErrorLogs.[Message]
	,'Error'
	,@UserId
	,@CreatedTime
	,#FailedProcessingLogs.Id
FROM
#ErrorLogs
INNER JOIN #FailedProcessingLogs ON #ErrorLogs.StagingRootEntityId = #FailedProcessingLogs.StagingID

DROP TABLE #AssetsValueChangeMappedWithTarget;
DROP TABLE #AssetValueHistory;
DROP TABLE #AVHErrorLogs;
DROP TABLE #ErrorLogs;
DROP TABLE #FailedProcessingLogs;

SET NOCOUNT OFF
SET XACT_ABORT OFF
SET ANSI_WARNINGS OFF

END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateAssetValueHistoryFromChargeoff]
(	
    @LeaseFinanceId BIGINT,
	@ChargeOffDate DATE, 
    @ChargeOffId BIGINT,
	@CreatedById BIGINT,
    @UpdatedTime DATETIMEOFFSET,
	@SourceModule NVARCHAR(20)
)
AS

BEGIN

--DECLARE @LeaseFinanceId  BIGINT = 802100
--DECLARE @ChargeOffDate DATETIME = '12/1/2016';
--DECLARE @CreatedById  BIGINT = 1 ;
--DECLARE @ChargeOffId  BIGINT  = 60633;
--DECLARE @UpdatedTime DATETIMEOFFSET = getdate();
--DECLARE @SourceModule NVARCHAR = 'ChargeOff';

-- Picking active lease assets belonging to lease which is being charged-off
SELECT AssetId 
INTO #LeaseAssets
FROM LeaseAssets
WHERE LeaseFinanceId = @LeaseFinanceId AND IsActive = 1;

-- Finding GL Posted AVH Records for each asset on or after charge-off date
SELECT 
	AssetId = AVH.AssetId, 
	IncomeDate = AVH.IncomeDate, 
	RowNumber = ROW_NUMBER() OVER (PARTITION BY AVH.AssetId ORDER BY AVH.IncomeDate DESC, AVH.Id DESC) 
INTO #GLPostedAssetValueHistories
FROM #LeaseAssets LeaseAsset
LEFT JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId
WHERE
AVH.Id IS NULL OR 
(
	AVH.IsAccounted = 1
	AND AVH.GLJournalId IS NOT NULL 
	AND AVH.AdjustmentEntry = 0 
	AND AVH.IsLessorOwned = 1
	AND AVH.IncomeDate >= @ChargeOffDate
);

-- Finding maximum GL posted record for each asset
SELECT 
	AssetId, 
	MaxGLPostedDate = IncomeDate
INTO #AssetMaxGLPostedInfo
FROM #GLPostedAssetValueHistories
WHERE RowNumber = 1;

-- Finding schedule records (used to create record as of charge-off date to drop value to zero)
SELECT 
	AVH.AssetId,
	AsOfDate = ISNULL(MaxGLPostedAVH.MaxGLPostedDate, @ChargeOffDate),
	AVH.EndBookValue_Amount,
	AVH.EndBookValue_Currency,
	AVH.Cost_Amount,
	RowNumber = ROW_NUMBER() OVER (PARTITION BY AVH.AssetId,AVH.IsLeaseComponent ORDER BY AVH.IncomeDate DESC, AVH.Id DESC),
    IsLeaseComponent = AVH.IsLeaseComponent 
INTO #AVHSchedules
FROM #LeaseAssets LeaseAsset
JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId
LEFT JOIN #AssetMaxGLPostedInfo MaxGLPostedAVH ON AVH.AssetId = MaxGLPostedAVH.AssetId 
WHERE AVH.IncomeDate <= ISNULL(MaxGLPostedAVH.MaxGLPostedDate, DATEADD(DAY,-1,@ChargeOffDate))
AND AVH.IsSchedule = 1
AND AVH.IsLessorOwned = 1;

-- Inserting AVH records to drop value of assets to zero

INSERT INTO AssetValueHistories
(
	SourceModule
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
	,AdjustmentEntry
	,CreatedById
	,CreatedTime
	,AssetId
	,IsLessorOwned
	,IsLeaseComponent
)
SELECT 
	SourceModule = @SourceModule,
	SourceModuleId = @ChargeOffId,
	IncomeDate = AVH.AsOfDate,
	Value_Amount = (0 - AVH.EndBookValue_Amount),
	Value_Currency = AVH.EndBookValue_Currency,
	Cost_Amount = AVH.Cost_Amount,
	Cost_Currency = AVH.EndBookValue_Currency,
	NetValue_Amount = 0,
	NetValue_Currency = AVH.EndBookValue_Currency,
	BeginBookValue_Amount = AVH.EndBookValue_Amount,
	BeginBookValue_Currency = AVH.EndBookValue_Currency,
	EndBookValue_Amount = 0,
	EndBookValue_Currency = AVH.EndBookValue_Currency,
	IsAccounted = 1,
	IsSchedule = 1,
	IsCleared = 1,
	AdjustmentEntry = 1,
	CreatedById = @CreatedById,
	CreatedTime = @UpdatedTime,
	AssetId = AVH.AssetId,
	IsLessorOwned = 1,
	IsLeaseComponent = AVH.IsLeaseComponent
FROM #AVHSchedules AS AVH
WHERE RowNumber = 1;

-- Inactivating AVH records beyond Max GL posted date
UPDATE AVH 
SET 
	IsSchedule = 0, 
	IsAccounted = 0, 
	UpdatedById = @CreatedById, 
	UpdatedTime = @UpdatedTime
FROM #LeaseAssets LeaseAsset
JOIN AssetValueHistories AVH ON LeaseAsset.AssetId = AVH.AssetId
LEFT JOIN #AssetMaxGLPostedInfo MaxGLPostedAVH ON AVH.AssetId = MaxGLPostedAVH.AssetId 
WHERE (AVH.IsSchedule = 1 OR AVH.IsAccounted = 1) 
AND AVH.AdjustmentEntry = 0 
AND AVH.IncomeDate > ISNULL(MaxGLPostedAVH.MaxGLPostedDate, DATEADD(day,-1,@ChargeOffDate));

END

GO

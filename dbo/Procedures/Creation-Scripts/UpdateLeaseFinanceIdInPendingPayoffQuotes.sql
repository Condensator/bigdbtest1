SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 

CREATE PROC [dbo].[UpdateLeaseFinanceIdInPendingPayoffQuotes]
(
	@NewLeaseFinanceId BIGINT,
	@OldLeaseFinanceId BIGINT,
	@PayoffStatusActivated NVARCHAR(20),
	@PayoffStatusInactive NVARCHAR(20),
	@PayoffId BIGINT,
	@CurrentUserId BIGINT,
	@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

Select 
	LeaseAssets.Id LeaseAssetId, 
	LeaseAssets.AssetId 
INTO #NewLeaseAssets
FROM LeaseAssets WITH (NOLOCK)  
WHERE 
	LeaseFinanceId = @NewLeaseFinanceId 

SELECT
	NLA.AssetId,
	LAS.Id LeaseAssetSKUId,
	LAS.AssetSKUId
INTO #NewLeaseAssetSKUs
FROM #NewLeaseAssets NLA
JOIN LeaseAssetSKUs LAS ON NLA.LeaseAssetId = LAS.LeaseAssetId

SELECT 
	PA.Id PayoffAssetId, 
	LA.AssetId, 
	PA.LeaseAssetId,
	P.Id PayoffId
INTO #OldLeaseAssets
FROM Payoffs P WITH (NOLOCK)
Join PayoffAssets PA WITH (NOLOCK) ON P.Id = PA.PayoffId 
	AND P.LeaseFinanceId = @OldLeaseFinanceId 
	AND P.Id != @PayoffId
	AND P.Status NOT IN (@PayoffStatusActivated,@PayoffStatusInactive)
	AND PA.IsActive = 1
JOIN LeaseAssets LA WITH (NOLOCK) ON PA.LeaseAssetId = LA.Id

SELECT
	PAS.Id PayoffAssetSKUId,
	OLA.AssetId,
	LAS.AssetSKUId
INTO #OldLeaseAssetSKUs
FROM #OldLeaseAssets OLA
JOIN PayoffAssetSKUs PAS ON OLA.PayoffAssetId = PAS.PayoffAssetId
JOIN LeaseAssetSKUs LAS ON PAS.LeaseAssetSKUId = LAS.Id

 

SELECT 
	O.PayoffAssetSKUId,
	N.LeaseAssetSKUId
INTO #PayoffAssetSKUs
FROM #NewLeaseAssetSKUs N
JOIN #OldLeaseAssetSKUs O ON N.AssetId = O.AssetId AND N.AssetSKUId = O.AssetSKUId


SELECT 
	O.PayoffAssetId, 
	N.LeaseAssetId 
INTO #PayoffAsset 
FROM #NewLeaseAssets N
Join #OldLeaseAssets O 
	ON N.AssetId = O.AssetId

UPDATE PayoffAssetSKUs SET
LeaseAssetSKUId = PAST.LeaseAssetSKUId,
UpdatedById = @CurrentUserId , 
UpdatedTime = @CurrentTime
FROM PayoffAssetSKUs PAS 
JOIN #PayoffAssetSKUs PAST ON PAS.Id = PAST.PayoffAssetSKUId


UPDATE PayoffAssets SET 
	LeaseAssetId = PAT.LeaseAssetId, 
	UpdatedById = @CurrentUserId , 
	UpdatedTime = @CurrentTime
FROM PayoffAssets PA
JOIN #PayoffAsset PAT 
	ON PA.Id = PAT.PayoffAssetId

UPDATE Payoffs SET 
	LeaseFinanceId = @NewLeaseFinanceId, 
	IsParametersChanged = 1 , 
	UpdatedById = @CurrentUserId , 
	UpdatedTime = @CurrentTime,
	LeasePaymentScheduleId = NewLPS.Id
FROM Payoffs P WITH (NOLOCK) 
JOIN (SELECT DISTINCT PayoffId FROM #OldLeaseAssets) O 
	ON P.Id = O.PayoffId
LEFT JOIN LeasePaymentSchedules LPS 
    ON P.LeasePaymentScheduleId = LPS.ID 
	AND LPS.LeaseFinanceDetailId = @OldLeaseFinanceId
LEFT JOIN LeasePaymentSchedules NewLPS 
    ON LPS.PaymentNumber = NewLPS.PaymentNumber 
	AND LPS.PaymentType = NewLPS.PaymentType  
	AND NewLPS.LeaseFinanceDetailId = @NewLeaseFinanceId
END

GO

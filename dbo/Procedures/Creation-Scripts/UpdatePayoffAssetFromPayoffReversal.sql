SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePayoffAssetFromPayoffReversal]
(
@AssetsToUpdate AssetToUpdateStatus READONLY,
@CustomerId BIGINT,
@PayoffId BIGINT,
@EffectiveDate DATETIME,
@PayoffReversalId BIGINT,
@ContractId BIGINT,
@AssetHistoryReason NVARCHAR(MAX),
@SourceModule NVARCHAR (MAX),
@UserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

SELECT AssetID AS ID INTO #AssetIDs FROM @AssetsToUpdate

UPDATE Assets SET Status = AU.AssetStatus , IsOffLease = 0,RemarketingVendorId = NULL, CustomerId = @CustomerId,IsOnCommencedLease = 1  ,UpdatedById = @UserId , UpdatedTime = @CurrentTime
FROM Assets
JOIN @AssetsToUpdate AU ON Assets.Id = AU.AssetId
SELECT #AssetIDs.ID AS 'AssetId', MAX(Payoffs.Id) AS 'MaxPayoffId' INTO #PreviousPayoffs
FROM PayoffAssets
INNER JOIN LeaseAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId
INNER JOIN Assets ON Assets.Id = LeaseAssets.AssetId
INNER JOIN Payoffs ON Payoffs.Id = PayoffAssets.PayoffId
INNER JOIN #AssetIDs ON #AssetIDs.ID = Assets.Id
WHERE Payoffs.Id != @PayoffId AND Payoffs.Status = 'Activated' AND PayoffAssets.IsActive=1
GROUP BY #AssetIDs.ID

UPDATE Assets SET PreviousSequenceNumber = Contracts.SequenceNumber , UpdatedById = @UserId , UpdatedTime = @CurrentTime
FROM Assets
INNER JOIN #PreviousPayoffs ON #PreviousPayoffs.AssetId = Assets.Id
INNER JOIN Payoffs ON Payoffs.Id = #PreviousPayoffs.MaxPayoffId
INNER JOIN LeaseFinances ON LeaseFinances.Id = Payoffs.LeaseFinanceId
INNER JOIN Contracts ON Contracts.Id = LeaseFinances.ContractId
WHERE Payoffs.Status = 'Activated'

UPDATE Assets SET PreviousSequenceNumber = NULL , UpdatedById = @UserId , UpdatedTime = @CurrentTime
FROM Assets
INNER JOIN #AssetIDs ON Assets.Id = #AssetIDs.ID
LEFT JOIN #PreviousPayoffs ON #PreviousPayoffs.AssetId = Assets.Id
WHERE #PreviousPayoffs.MaxPayoffId IS NULL
SELECT #AssetIDs.ID AS 'AssetId', MAX(AssetLocations.Id)  AS 'DropOffLocationId'
into #DropOffLocationInfo
FROM PayoffAssets
INNER JOIN LeaseAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId
INNER JOIN AssetLocations ON PayoffAssets.DropOffLocationId = AssetLocations.LocationId
AND AssetLocations.AssetId = LeaseAssets.AssetId
INNER JOIN #AssetIDs ON #AssetIDs.ID = LeaseAssets.AssetId
WHERE PayoffAssets.PayoffId = @PayoffId AND PayoffAssets.IsAssetDroppedOff = 1
AND IsCurrent = 1 AND AssetLocations.IsActive = 1
GROUP BY #AssetIDs.ID

UPDATE AssetLocations SET IsCurrent = 0, IsActive = 0 , UpdatedById =@UserId , UpdatedTime= @CurrentTime
FROM AssetLocations
JOIN #DropOffLocationInfo ON AssetLocations.Id = #DropOffLocationInfo.DropOffLocationId

UPDATE AssetLocations SET AssetLocations.IsCurrent = 1 , UpdatedById=@UserId, UpdatedTime=@CurrentTime 
WHERE Id IN 
(
	SELECT MAX(AssetLocations.Id) AssetLocationId
	FROM AssetLocations
	INNER JOIN 
		(
			SELECT MAX(EffectiveFromDate) EffectiveFromDate, AssetLocations.AssetId FROM AssetLocations	
			INNER JOIN #AssetIDs AssetInfo ON AssetLocations.AssetId = AssetInfo.ID
			WHERE AssetLocations.IsActive=1
			GROUP BY AssetLocations.AssetId
		) AS AER 
		ON AssetLocations.AssetId = AER.AssetId
	WHERE AssetLocations.EffectiveFromDate = AER.EffectiveFromDate AND IsActive=1
	GROUP BY AssetLocations.AssetId
) AND IsCurrent = 0 AND IsActive=1

UPDATE AssetLocations SET IsActive=0 
WHERE Id in(
	SELECT MIN(AL.Id) FROM AssetLocations AL
	JOIN #AssetIDs A ON AL.AssetId = A.ID and AL.IsActive=1
	GROUP BY AL.AssetId,AL.EffectiveFromDate 
	HAVING COUNT(*) > 1
	); 

INSERT INTO AssetHistories
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[LegalEntityId]
,[FinancialType]
,[Status]
,[PropertyTaxReportCodeId]
,[CustomerId]
,[ParentAssetId]
,[SourceModule]
,[SourceModuleId]
,[ContractId]
,[CreatedById]
,[CreatedTime]
,[UpdatedById]
,[UpdatedTime]
,[AssetId]
,[IsReversed])
SELECT
@AssetHistoryReason
,@EffectiveDate
,Assets.AcquisitionDate
,Assets.LegalEntityId
,Assets.FinancialType
,Assets.Status
,Assets.PropertyTaxReportCodeId
,@CustomerId
,Assets.ParentAssetId
,@SourceModule
,@PayoffReversalId
,@ContractId
,@UserId
,@CurrentTime
,NULL
,NULL
,Assets.Id
,0
FROM Assets
INNER JOIN #AssetIDs ON #AssetIDs.ID = Assets.Id
DROP TABLE #AssetIDs
DROP TABLE #PreviousPayoffs

END

GO

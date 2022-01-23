SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdatePaidoffAssets]
(
@PaidoffAssetUpdationInfo PaidoffAssetUpdationInfo READONLY,
@PayoffId BIGINT,
@PayoffEffectiveDate DATETIME,
@ContractId BIGINT,
@SourceModule NVARCHAR(40),
@AssetHistoryReason NVARCHAR(40),
@SequenceNumber NVARCHAR(40),
@PayoffAssetStatusAbandoned NVARCHAR(40),
@AssetStatusInventory NVARCHAR(40),
@AssetStatusInvestor NVARCHAR(40),
@AssetStatusSold NVARCHAR(40),
@AssetSubStatusRepossessed NVARCHAR(40),
@AssetSubStatusAbandoned NVARCHAR(40),
@IsRepossessionTermination BIT,
@UserId BIGINT,
@Currency NVARCHAR(3),
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

UPDATE Assets
SET Status = AssetInfo.Status,
PreviousSequenceNumber = @SequenceNumber,
CustomerId = CASE WHEN AssetInfo.Status in (@AssetStatusInventory,@AssetStatusInvestor) THEN AssetInfo.CustomerId ELSE Assets.CustomerId END,
IsOffLease = CASE WHEN AssetInfo.Status in (@AssetStatusInventory,@AssetStatusInvestor) THEN 1 ELSE Assets.IsOffLease END,
PlaceholderAssetId = AssetInfo.PlaceholderAssetId,
RemarketingVendorId = CASE WHEN @IsRepossessionTermination = 1 AND AssetInfo.RepossessionAgentId IS NOT NULL THEN AssetInfo.RepossessionAgentId ELSE AssetInfo.RemarketingVendorId END,
IsOnCommencedLease = 0,
SubStatus = CASE WHEN @IsRepossessionTermination = 1 THEN @AssetSubStatusRepossessed
WHEN AssetInfo.PayoffAssetStatus = @PayoffAssetStatusAbandoned THEN @AssetSubStatusAbandoned
ELSE Assets.SubStatus END,
ProspectiveContract = AssetInfo.ProspectiveContract,
UpdatedById = @UserId,
UpdatedTime = @UpdatedTime
FROM Assets
JOIN @PaidoffAssetUpdationInfo AssetInfo ON Assets.Id = AssetInfo.AssetId

UPDATE AssetGLDetails
SET AssetBookValueAdjustmentGLTemplateId = CASE WHEN AssetInfo.AssetBookValueAdjustmentGLTemplateId IS NOT NULL THEN AssetInfo.AssetBookValueAdjustmentGLTemplateId ELSE AssetGLDetails.BookDepreciationGLTemplateId END,
BookDepreciationGLTemplateId = CASE WHEN AssetInfo.BookDepGLTemplateId IS NOT NULL THEN AssetInfo.BookDepGLTemplateId ELSE AssetGLDetails.BookDepreciationGLTemplateId END
FROM AssetGLDetails
JOIN @PaidoffAssetUpdationInfo AssetInfo ON AssetGLDetails.Id = AssetInfo.AssetId
WHERE AssetInfo.AssetBookValueAdjustmentGLTemplateId IS NOT NULL OR AssetInfo.BookDepGLTemplateId IS NOT NULL

UPDATE AssetLocations
SET IsCurrent = 0,
UpdatedById = @UserId,
UpdatedTime = @UpdatedTime
FROM Assets
JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
JOIN Locations ON AssetLocations.LocationId = Locations.Id
JOIN @PaidoffAssetUpdationInfo AssetInfo ON AssetLocations.AssetId = AssetInfo.AssetId
WHERE AssetLocations.IsCurrent = 1
AND Locations.CustomerId IS NOT NULL
AND (AssetInfo.CustomerId IS NULL OR Locations.CustomerId != AssetInfo.CustomerId)
AND (AssetInfo.DropOffLocationId IS NULL OR AssetInfo.DropOffLocationId != Locations.Id)

IF(@IsRepossessionTermination = 1)
BEGIN

SELECT * INTO #DroppedOffAssetUpdationInfo FROM @PaidoffAssetUpdationInfo Where IsAssetDroppedOff = 1; 

UPDATE AssetLocations
SET IsCurrent = 0,
UpdatedById = @UserId,
UpdatedTime = @UpdatedTime
FROM AssetLocations
JOIN #DroppedOffAssetUpdationInfo AssetInfo ON AssetLocations.AssetId = AssetInfo.AssetId
AND IsCurrent = 1

INSERT INTO AssetLocations
(EffectiveFromDate
,IsCurrent
,UpfrontTaxMode
,TaxBasisType
,IsActive
,CreatedById
,CreatedTime
,LocationId
,AssetId
,IsFLStampTaxExempt
,ReciprocityAmount_Amount
,ReciprocityAmount_Currency
,LienCredit_Amount
,LienCredit_Currency
,UpfrontTaxAssessedInLegacySystem)
SELECT
DropOffDate
,0
,Locations.UpfrontTaxMode
,Locations.TaxBasisType
,1
,@UserId
,@UpdatedTime
,DropOffLocationId
,AssetId
,0
,0.00
,@Currency
,0.00
,@Currency
,CAST(0 AS BIT)
FROM #DroppedOffAssetUpdationInfo AssetInfo
JOIN Locations ON AssetInfo.DropOffLocationId = Locations.Id
JOIn States ON Locations.StateId = States.Id

UPDATE AssetLocations SET AssetLocations.IsCurrent = 1 , UpdatedById=@UserId, UpdatedTime=@UpdatedTime 
WHERE Id IN 
(
	SELECT MAX(AssetLocations.Id) AssetLocationId
	FROM AssetLocations
	INNER JOIN 
		(
			SELECT MAX(EffectiveFromDate) EffectiveFromDate, AssetLocations.AssetId FROM AssetLocations	
			INNER JOIN #DroppedOffAssetUpdationInfo AssetInfo ON AssetLocations.AssetId = AssetInfo.AssetId
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
	JOIN #DroppedOffAssetUpdationInfo A ON AL.AssetId = A.AssetId and AL.IsActive=1
	GROUP BY AL.AssetId,AL.EffectiveFromDate 
	HAVING COUNT(*) > 1
	); 
END

INSERT INTO AssetHistories
(Reason
,AsOfDate
,AcquisitionDate
,Status
,FinancialType
,SourceModule
,SourceModuleId
,CreatedById
,CreatedTime
,CustomerId
,ParentAssetId
,LegalEntityId
,AssetId
,ContractId
,PropertyTaxReportCodeId
,IsReversed)
SELECT
@AssetHistoryReason
,@PayoffEffectiveDate
,Assets.AcquisitionDate
,Assets.Status
,Assets.FinancialType
,@SourceModule
,@PayoffId
,@UserId
,@UpdatedTime
,Assets.CustomerId
,Assets.ParentAssetId
,Assets.LegalEntityId
,Assets.Id
,CASE WHEN AssetInfo.Status in (@AssetStatusInventory,@AssetStatusInvestor) THEN NULL ELSE @ContractId END
,Assets.PropertyTaxReportCodeId
,0
FROM Assets
JOIN @PaidoffAssetUpdationInfo AssetInfo ON Assets.Id = AssetInfo.AssetId
SET NOCOUNT OFF;
END

GO

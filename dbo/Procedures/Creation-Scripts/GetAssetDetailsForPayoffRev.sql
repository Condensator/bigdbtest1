SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetAssetDetailsForPayoffRev]
(
@PayoffId BIGINT,
@OldLeaseFinanceId BIGINT,
@NewLeaseFinanceId BIGINT,
@ContractId BIGINT,
@EffectiveDate DATETIME
)
AS
BEGIN
SELECT AGD.Id as AssetId, PayoffAssets.Id as PayoffAssetId, AGD.InstrumentTypeId as InstrumentTypeId, AGD.LineofBusinessId as LineOfBusinessId  FROM AssetGLDetails AGD
JOIN LeaseAssets ON AGD.Id = LeaseAssets.AssetId
JOIN PayoffAssets ON LeaseAssets.Id = PayoffAssets.LeaseAssetId
WHERE PayoffAssets.PayoffId = @PayoffId
AND PayoffAssets.IsActive =1
AND LeaseAssets.LeaseFinanceId = @OldLeaseFinanceId
SELECT ReceivableId = R.Id FROM Receivables R
JOIN ReceivableDetails RD on R.Id = RD.ReceivableId
JOIN LeasePaymentSchedules LPS on R.PaymentScheduleId = LPS.Id
JOIN ReceivableCodes RC on R.ReceivableCodeId = RC.Id
JOIN ReceivableTypes RT on RC.ReceivableTypeId = RT.Id
where R.EntityId = @ContractId
AND LPS.LeaseFinanceDetailId = @NewLeaseFinanceId
AND R.EntityType = 'CT'
AND R.SourceTable = '_'
AND LPS.StartDate >= @EffectiveDate
AND R.IsActive = 1
AND LPS.IsActive = 1
AND RD.AdjustmentBasisReceivableDetailId IS NULL
AND RT.Name NOT IN('LeaseFloatRateAdj' , 'OverTermRental' , 'Supplemental')
AND (R.SourceId IS NULL OR (R.SourceId != @PayoffId AND R.SourceTable != 'LeasePayoff'))
SELECT ReceivableId = R.Id
FROM Receivables R
JOIN ReceivableCodes RC on RC.Id = R.ReceivableCodeId
JOIN ReceivableTypes RT on RC.ReceivableTypeId = RT.Id
JOIN ReceivableCategories RCT on RCT.Id = RC.ReceivableCategoryId
WHERE R.EntityId = @ContractId AND RT.Name IN ('LeasePayOff','BuyOut') AND RCT.Name = 'Payoff'
AND R.EntityType = 'CT'
AND R.IsActive = 1
AND R.SourceId = @PayoffId
AND R.SourceTable = 'LeasePayoff'
END

GO

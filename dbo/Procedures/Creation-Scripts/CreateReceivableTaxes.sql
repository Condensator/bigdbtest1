SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CreateReceivableTaxes]
(@receivableTaxesParameters              RECEIVABLETAXESPARAMETERS READONLY,
@receivableTaxDetailsParameters         RECEIVABLETAXDETAILSPARAMETERS READONLY,
@receivableTaxImpositionsParameters     RECEIVABLETAXIMPOSITIONSPARAMETERS READONLY,
@receivableTaxReversalDetailsParameters RECEIVABLETAXREVERSALDETAILSPARAMETERS READONLY,
@CreatedById                            BIGINT,
@CreatedTime                            DATETIMEOFFSET,
@ErrorMessage							 NVARCHAR(MAX) OUT)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION ProcessReceivableTax
CREATE TABLE #InsertedReceivableTaxes
(
ReceivableTaxId BIGINT,
ReceivableId    BIGINT
);
CREATE TABLE #InsertedReceivableTaxDetails
(
ReceivableTaxDetailId	BIGINT,
ReceivableDetailId		BIGINT,
ReceivableDetailAssetId BIGINT NULL
);
MERGE [ReceivableTaxes] AS TargetReceivableTax
USING @receivableTaxesParameters AS SourceReceivableTax
ON (TargetReceivableTax.Id = SourceReceivableTax.ReceivableTaxId AND TargetReceivableTax.IsActive = 1)
WHEN NOT MATCHED THEN
INSERT
([CreatedById],
[CreatedTime],
[ReceivableId],
[IsActive],
[IsGLPosted],
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency],
[IsDummy]
)
VALUES(@CreatedById,
@CreatedTime,
[ReceivableId],
1,
0,
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency],
0)
WHEN MATCHED THEN
UPDATE SET TargetReceivableTax.UpdatedById = @CreatedById, TargetReceivableTax.UpdatedTime = @CreatedTime,
TargetReceivableTax.Amount_Amount = TargetReceivableTax.Amount_Amount + SourceReceivableTax.Amount_Amount,
TargetReceivableTax.Balance_Amount = TargetReceivableTax.Balance_Amount + SourceReceivableTax.Balance_Amount,
TargetReceivableTax.EffectiveBalance_Amount = TargetReceivableTax.EffectiveBalance_Amount + SourceReceivableTax.EffectiveBalance_Amount
OUTPUT INSERTED.Id AS ReceivableTaxId, INSERTED.ReceivableId AS ReceivableId INTO #InsertedReceivableTaxes;
INSERT INTO [dbo].[ReceivableTaxDetails]
([TaxBasisType],
[Revenue_Amount],
[Revenue_Currency],
[FairMarketValue_Amount],
[FairMarketValue_Currency],
[Cost_Amount],
[Cost_Currency],
[TaxAreaId],
[IsActive],
[ManuallyAssessed],
[CreatedById],
[CreatedTime],
[AssetLocationId],
[LocationId],
[AssetId],
[ReceivableDetailId],
[ReceivableTaxId],
[IsGLPosted],
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency]
)
OUTPUT INSERTED.Id AS ReceivableTaxDetailId,
INSERTED.ReceivableDetailId AS ReceivableDetailId,
INSERTED.AssetId AS ReceivableDetailAssetId
INTO #InsertedReceivableTaxDetails
SELECT  [TaxBasisType],
[Revenue_Amount],
[Revenue_Currency],
[FairMarketValue_Amount],
[FairMarketValue_Currency],
[Cost_Amount],
[Cost_Currency],
[TaxAreaId],
1,
0,
@CreatedById,
@CreatedTime,
[AssetLocationId],
[LocationId],
[AssetId],
[ReceivableDetailId],
IRT.ReceivableTaxId,
0,
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency]
FROM @receivableTaxDetailsParameters RTP
INNER JOIN #InsertedReceivableTaxes IRT ON RTP.ReceivableId = IRT.ReceivableId;
INSERT INTO [dbo].[ReceivableTaxImpositions]
([ExemptionType],
[ExemptionRate],
[ExemptionAmount_Amount],
[ExemptionAmount_Currency],
[TaxableBasisAmount_Amount],
[TaxableBasisAmount_Currency],
[AppliedTaxRate],
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency],
[ExternalTaxImpositionType],
[CreatedById],
[CreatedTime],
[TaxTypeId],
[ExternalJurisdictionLevelId],
[ReceivableTaxDetailId],
[IsActive]
)
SELECT [ExemptionType],
[ExemptionRate],
[ExemptionAmount_Amount],
[ExemptionAmount_Currency],
[TaxableBasisAmount_Amount],
[TaxableBasisAmount_Currency],
[AppliedTaxRate],
[Amount_Amount],
[Amount_Currency],
[Balance_Amount],
[Balance_Currency],
[EffectiveBalance_Amount],
[EffectiveBalance_Currency],
[ExternalTaxImpositionType],
@CreatedById,
@CreatedTime,
[TaxTypeId],
[ExternalJurisdictionLevelId],
[ReceivableTaxDetailId],
1
FROM @receivableTaxImpositionsParameters RTIP
INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTIP.ReceivableDetailId = IRTD.ReceivableDetailId
WHERE IRTD.ReceivableDetailAssetId = RTIP.AssetId OR RTIP.AssetId IS NULL;
;
INSERT INTO [dbo].[ReceivableTaxReversalDetails]
([Id],
[IsExemptAtAsset],
[IsExemptAtLease],
[IsExemptAtSundry],
[Company],
[Product],
[ContractType],
[AssetType],
[LeaseType],
[LeaseTerm],
[TitleTransferCode],
[TransactionCode],
[AmountBilledToDate],
[CreatedById],
[CreatedTime],
[AssetId],
[AssetLocationId],
[ToStateName],
[FromStateName],
[UpfrontTaxAssessedInLegacySystem]
)
SELECT  IRTD.ReceivableTaxDetailId,
[IsExemptAtAsset],
[IsExemptAtLease],
[IsExemptAtSundry],
[Company],
[Product],
[ContractType],
[AssetType],
[LeaseType],
[LeaseTerm],
[TitleTransferCode],
[TransactionCode],
[AmountBilledToDate],
@CreatedById,
@CreatedTime,
[AssetId],
[AssetLocationId],
[ToStateName],
[FromStateName],
CAST(0 AS BIT)
FROM @receivableTaxReversalDetailsParameters RTRDP
INNER JOIN #InsertedReceivableTaxDetails IRTD ON RTRDP.ReceivableDetailId = IRTD.ReceivableDetailId
WHERE (IRTD.ReceivableDetailAssetId = RTRDP.AssetId OR RTRDP.AssetId IS NULL);
UPDATE ReceivableDetails
SET IsTaxAssessed = 1 , UpdatedById = @CreatedById, UpdatedTime = @CreatedTime
FROM ReceivableDetails
JOIN #InsertedReceivableTaxDetails InsertedReceivableTaxDetail
ON ReceivableDetails.Id = InsertedReceivableTaxDetail.ReceivableDetailId
DROP TABLE #InsertedReceivableTaxDetails;
DROP TABLE #InsertedReceivableTaxes;
COMMIT TRANSACTION ProcessReceivableTax
END TRY
BEGIN CATCH
SET @ErrorMessage = CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
PRINT  CAST(ERROR_MESSAGE() AS NVARCHAR(MAX));
ROLLBACK TRANSACTION ProcessReceivableTax
END CATCH
END;

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ChangeAssetStatusToSoldForAssetSale]
(
@AssetSaleId BIGINT,
@TransactionDate DATETIMEOFFSET,
@AssetSoldStatus VARCHAR(15),
@AssetHistoryReason VARCHAR(15),
@Module NVARCHAR(20),
@CreatedById BIGINT,
@CurrentTime DATETIMEOFFSET,
@ErrorAssetCount INT OUT
)
AS
SET NOCOUNT ON;

SELECT ASD.AssetId
,ASL.BuyerId
,ASL.TaxLocationId
,ASL.Amount_Currency Currency
INTO #ChangedAssets
FROM AssetSales ASL
JOIN AssetSaleDetails ASD ON ASL.Id = ASD.AssetSaleId
WHERE ASL.Id = @AssetSaleId AND IsActive = 1
Update Assets SET Status = @AssetSoldStatus, CustomerId = CH.BuyerId, UpdatedById = @CreatedById, UpdatedTime = @CurrentTime
FROM #ChangedAssets CH
INNER JOIN dbo.Assets A on CH.AssetId = A.Id


INSERT INTO [dbo].[AssetHistories]
([Reason]
,[AsOfDate]
,[AcquisitionDate]
,[Status]
,[FinancialType]
,[SourceModule]
,[SourceModuleId]
,[CreatedById]
,[CreatedTime]
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,[IsReversed]
,[PropertyTaxReportCodeId])
SELECT @AssetHistoryReason
,@TransactionDate
,[AcquisitionDate]
,@AssetSoldStatus
,[FinancialType]
,@Module
,@AssetSaleId
,@CreatedById
,@CurrentTime
,[CustomerId]
,[ParentAssetId]
,[LegalEntityId]
,[AssetId]
,0
,A.PropertyTaxReportCodeId
FROM #ChangedAssets C INNER JOIN dbo.Assets A on C.AssetId = A.Id
UPDATE [dbo].[AssetLocations] SET IsCurrent=0 , UpdatedById = @CreatedById, UpdatedTime = @CurrentTime
FROM #ChangedAssets C INNER JOIN dbo.AssetLocations AL on C.AssetId = AL.AssetId AND AL.IsActive = 1
INSERT INTO [dbo].[AssetLocations]
([EffectiveFromDate]
,[IsCurrent]
,[UpfrontTaxMode]
,[TaxBasisType]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[LocationId]
,[AssetId]
,[IsFLStampTaxExempt]
,[ReciprocityAmount_Amount]
,[ReciprocityAmount_Currency]
,[LienCredit_Amount]
,[LienCredit_Currency]
,[UpfrontTaxAssessedInLegacySystem])
SELECT
@TransactionDate
,1
,L.UpfrontTaxMode
,L.TaxBasisType
,1
,@CreatedById
,@CurrentTime
,CH.TaxLocationId
,CH.AssetId
,0
,0.0
,CH.Currency
,0.0
,CH.Currency
,CAST(0 AS BIT)
FROM Locations L
JOIN #ChangedAssets CH ON L.Id = CH.TaxLocationId
DROP TABLE #ChangedAssets

GO

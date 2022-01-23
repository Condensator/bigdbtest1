SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertSplittedContractBasedReceivables]
(
@receivableAssetAmountDetails	ReceivableAssetAmountDetails READONLY,
@JobStepInstanceId BIGINT
)
AS
BEGIN
SELECT
RA.ReceivableDetailId
,RA.AssetId
,STR.ReceivableId
,STR.ReceivableDueDate
,STR.ContractId
,STR.CustomerId
,STR.EntityType
,RA.AssetExtendedPrice AS ExtendedPrice
,STR.Currency
,STR.LocationId
,STR.ReceivableCodeId
,STR.AmountBilledToDate
,STR.IsExemptAtSundry
,STR.PaymentScheduleId
,STR.LegalEntityId
,STR.IsVertexSupported
,STR.TaxPayer
,STR.LegalEntityTaxRemittancePreference
,STR.GLTemplateId
,STR.LegalEntityName
,STR.IsAssessSalesTaxAtSKULevel
,STR.ReceivableTaxType
,STR.SourceId
,STR.SourceTable
INTO #SplittedReceivableDetails
FROM
SalesTaxReceivableDetailExtract STR
JOIN
@receivableAssetAmountDetails RA ON STR.ReceivableDetailId = RA.ReceivableDetailId
WHERE STR.AssetId IS NULL AND STR.JobStepInstanceId = @JobStepInstanceId
DELETE FROM SalesTaxReceivableDetailExtract
WHERE ReceivableDetailId IN (SELECT ReceivableDetailId FROM  #SplittedReceivableDetails)
INSERT INTO SalesTaxReceivableDetailExtract
(ReceivableDetailId
,AssetId
,ReceivableId
,ReceivableDueDate
,ContractId
,CustomerId
,EntityType
,ExtendedPrice
,Currency
,LocationId
,ReceivableCodeId
,AmountBilledToDate
,IsExemptAtSundry
,PaymentScheduleId
,LegalEntityId
,IsVertexSupported
,JobStepInstanceId
,TaxPayer
,LegalEntityTaxRemittancePreference
,GLTemplateId
,LegalEntityName
,IsAssessSalesTaxAtSKULevel
,SourceId
,SourceTable
,ReceivableTaxType)
SELECT
ReceivableDetailId
,AssetId
,ReceivableId
,ReceivableDueDate
,ContractId
,CustomerId
,EntityType
,ExtendedPrice
,Currency
,LocationId
,ReceivableCodeId
,AmountBilledToDate
,IsExemptAtSundry
,PaymentScheduleId
,LegalEntityId
,IsVertexSupported
,@JobStepInstanceId
,TaxPayer
,LegalEntityTaxRemittancePreference
,GLTemplateId
,LegalEntityName
,IsAssessSalesTaxAtSKULevel
,SourceId
,SourceTable
,ReceivableTaxType
FROM #SplittedReceivableDetails
UPDATE
STC
SET STC.IsProcessed = 1
FROM
SalesTaxContractBasedSplitupReceivableDetailExtract STC
INNER JOIN @receivableAssetAmountDetails RA
ON STC.ReceivableDetailId = RA.ReceivableDetailId AND STC.AssetId = RA.AssetId AND STC.JobStepInstanceId = @JobStepInstanceId
END

GO

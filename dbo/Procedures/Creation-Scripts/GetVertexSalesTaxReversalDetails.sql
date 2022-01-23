SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetVertexSalesTaxReversalDetails]
(
@BatchSize INT,
@TaskChunkServiceInstanceId BIGINT = NULL,
@ProcessingChunkStatus NVARCHAR(20),
@NewChunkStatus NVARCHAR(10),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET,
@JobStepInstanceId BIGINT
)
AS
BEGIN

CREATE TABLE #Updated
(
Id BIGINT
)

UPDATE TOP (@BatchSize) ReceivableDetailsForReversalProcess_Extract
SET TaskChunkServiceInstanceId = @TaskChunkServiceInstanceId,
ChunkStatus = @ProcessingChunkStatus,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
OUTPUT DELETED.Id INTO #Updated
WHERE IsVertexSupportedLocation = 1 AND ChunkStatus = @NewChunkStatus AND JobStepInstanceId = @JobStepInstanceId
;

SELECT ROW_NUMBER() OVER (ORDER BY RD.Id) as LineItemNumber,ReceivableDetailId,ReceivableCodeId, ReceivableId, DueDate,FairMarketValue,Cost,AmountBilledToDate,ExtendedPrice,Currency,AssetId,Company,
		CustomerNumber AS CustomerCode,ClassCode,AssetLocationId,MainDivision,Country,City,TaxAreaId,ContractId,IsExemptAtLease,
		IsExemptAtSundry, Product,ReceivableType,TransactionType,ContractType,LeaseUniqueId,SundryReceivableCode,AssetType,LeaseType,LeaseTerm,
		TitleTransferCode,LocationEffectiveDate,TaxBasisType,TransactionCode,IsVertexSupportedLocation,IsElectronicallyDelivered,SaleLeasebackCode,
		FromState,ToState,TaxRemittanceType,ReciprocityAmount,LienCredit,GrossVehicleWeight,LocationCode,SalesTaxExemptionLevel,IsExemptAtReceivableCode, ContractTypeValue,
		AssetTypeId,IsSyndicated,AssetCatalogNumber,IsTaxExempt,ISOCountryCode,TaxRegistrationNumber,IsExemptAtAsset, LegalEntityId,IsInvoiced, IsCashPosted,
		ReceivableTaxId,ReceivableTaxDetailId,EntityType,PartyName,IsRental,ReceivableTaxDetailRowVersion,ReceivableTaxRowVersion,ReceivableDetailRowVersion,
		AssetLocationRowVersion, VertexBilledRentalReceivableId,VertexBilledRentalReceivableRowVersion,Usage,UpfrontTaxSundryId,AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry
		,CommencementDate,MaturityDate,SalesTaxRemittanceResponsibility,
		AssetUsageCondition,AssetSerialOrVIN,AssetSKUId,IsSKU,IsExemptAtAssetSKU,
		UpfrontTaxAssessedInLegacySystem, BusCode
FROM ReceivableDetailsForReversalProcess_Extract RD
INNER JOIN #Updated UP ON RD.Id = UP.Id
WHERE RD.JobStepInstanceId = @JobStepInstanceId
;
END

GO

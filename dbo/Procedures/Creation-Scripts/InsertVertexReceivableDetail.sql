SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Main SP to populate the receivable detail in Lease, Loan and customer level
CREATE PROCEDURE [dbo].[InsertVertexReceivableDetail]
(
	@ORIGTransactionCode				NVARCHAR(100),
	@INVTransactionCode					NVARCHAR(100),
	@URTaxBasisTypeName					NVARCHAR(100),
	@URDMVTaxBasisTypeName				NVARCHAR(100),
	@UCTaxBasisTypeName					NVARCHAR(100),
	@UCDMVTaxBasisTypeName				NVARCHAR(100),
	@STTaxBasisTypeName					NVARCHAR(100),
	@CUEntityTypeName					NVARCHAR(100),
	@DTEntityTypeName					NVARCHAR(100),
	@CapitalLeaseRentalReceivableType	NVARCHAR(100),
	@OperatingLeaseRentalReceivableType NVARCHAR(100),
	@LeaseInterimInterestReceivableType NVARCHAR(100),
	@NewBatchStatus						NVARCHAR(40),
	@JobStepInstanceId					BIGINT,
	@AssessCapitalizedUpfrontTaxAtInception BIT,
	@CPIBaseRentalReceivableType		NVARCHAR(100)
)
AS
BEGIN
SET NOCOUNT ON;

CREATE TABLE #VertexWSTransactions
(
	 AmountBilledToDate DECIMAL(16,2),
	 City NVARCHAR(100) NULL,
	 CustomerCode NVARCHAR(100) NULL,
	 Currency NVARCHAR(100) NULL,
	 Cost DECIMAL(16,2),
	 Company NVARCHAR(100) NULL,
	 DueDate DATE,
	 MainDivision NVARCHAR(100) NULL,
	 Country NVARCHAR(100) NULL,
	 ExtendedPrice DECIMAL(16,2),
	 Term  DECIMAL(16,2),
	 GrossVehicleWeight DECIMAL(16,2),
	 ReciprocityAmount DECIMAL(16,2),
	 LienCredit DECIMAL(16,2),
	 LocationEffectiveDate DATE NULL,
	 TransCode NVARCHAR(100) NULL,
	 ContractTypeName NVARCHAR(100) NULL,
	 ShortLeaseType NVARCHAR(100) NULL,
	 TaxBasis NVARCHAR(100) NULL,
	 LeaseUniqueID  NVARCHAR(100) NULL,
	 TitleTransferCode  NVARCHAR(100) NULL,
	 SundryReceivableCode NVARCHAR(200) NULL,
	 AssetType NVARCHAR(100) NULL,
	 SaleLeasebackCode NVARCHAR(100) NULL,
	 IsElectronicallyDelivered BIT,
	 TaxRemittanceType NVARCHAR(100) NULL,
	 FromState NVARCHAR(100) NULL,
	 ToState NVARCHAR(100) NULL,
	 AssetId BIGINT NULL,
	 AssetSKUId BIGINT NULL,
	 SalesTaxExemptionLevel NVARCHAR(100) NULL,
	 TaxReceivableName NVARCHAR(100) NULL,
	 IsSyndicated BIT,
	 BusCode NVARCHAR(100) NULL,
	 AssetCatalogNumber  NVARCHAR(100) NULL,
	 FairMarketValue DECIMAL(16,2),
	 LocationCode NVARCHAR(100) NULL,
	 Product NVARCHAR(100) NULL,
	 TaxAreaId BIGINT NULL,
	 TransactionType NVARCHAR(100) NULL,
	 ClassCode NVARCHAR(100) NULL,
	 ReceivableId BIGINT,
	 ReceivableDetailId BIGINT,
	 ReceivableCodeId BIGINT,
	 ContractId BIGINT,
	 CustomerId BIGINT,
	 LocationId BIGINT,
	 LocationStatus  NVARCHAR(100) NULL,
	 IsExemptAtSundry BIT,
	 IsPrepaidUpfrontTax BIT,
	 IsCapitalizedRealAsset BIT,
	 IsCapitalizedSalesTaxAsset BIT,
	 IsExemptAtAsset BIT,
	 IsExemptAtReceivableCode BIT,
	 LegalEntityId BIGINT,
	 Usage NVARCHAR(100) NULL,
	 AssetLocationId BIGINT,
	 GLTemplateId BIGINT,
	 IsCapitalizedFirstRealAsset BIT NOT NULL,
	 CommencementDate DATE NULL,
	 SalesTaxRemittanceResponsibility NVARCHAR(8) NULL,
	 AcquisitionLocationTaxAreaId BIGINT,
	 AcquisitionLocationCity NVARCHAR(100),
	 AcquisitionLocationMainDivision NVARCHAR(100),
	 AcquisitionLocationCountry NVARCHAR(100),
	 MaturityDate DATE NULL,
	 AssetSerialOrVIN NVARCHAR(100),
	 AssetUsageCondition NVARCHAR(4),
	 IsSKU BIT NOT NULL,
	 IsExemptAtAssetSKU BIT NOT NULL ,
	 ReceivableSKUId BIGINT NULL,
	 UpfrontTaxAssessedInLegacySystem BIT NOT NULL
) 

CREATE TABLE #SalesTaxTaxAreaDetails(
              [ReceivableDetailId] [bigint] NOT NULL,
              [AssetId] [bigint] NULL,
              [ReceivableDueDate] [date] NOT NULL,
              [LocationId] [bigint] NULL,
              [TaxAreaId] [bigint] NULL,
              [TaxAreaEffectiveDate] [date] NOT NULL,
              [JobStepInstanceId] [bigint] NOT NULL
) 

CREATE  CLUSTERED INDEX [IX_ReceivableDetailId] ON #SalesTaxTaxAreaDetails (ReceivableDetailId);

INSERT INTO #SalesTaxTaxAreaDetails    
SELECT     
  STR.ReceivableDetailId, STR.AssetId, STR.ReceivableDueDate, STR.LocationId,     
  STA.TaxAreaId, STA.TaxAreaEffectiveDate, STR.JobStepInstanceId        
FROM SalesTaxReceivableDetailExtract STR    
INNER JOIN VertexLocationTaxAreaDetailExtract STA ON STR.LocationId = STA.LocationId     
AND STR.ReceivableDueDate = STA.ReceivableDueDate AND STR.AssetId = STA.AssetId AND STA.JobStepInstanceId = STR.JobStepInstanceId    
WHERE STR.IsVertexSupported = 1 AND InvalidErrorCode IS NULL     
AND STR.AssetId IS NOT NULL AND STA.AssetId IS NOT NULL    
AND STR.JobStepInstanceId = @JobStepInstanceId;     
    
INSERT INTO #SalesTaxTaxAreaDetails    
SELECT     
  STR.ReceivableDetailId, STR.AssetId, STR.ReceivableDueDate, STR.LocationId,    
  STA.TaxAreaId, STA.TaxAreaEffectiveDate, STR.JobStepInstanceId      
FROM SalesTaxReceivableDetailExtract STR    
INNER JOIN VertexLocationTaxAreaDetailExtract STA ON STR.LocationId = STA.LocationId    
AND STR.ReceivableDueDate = STA.ReceivableDueDate AND STA.JobStepInstanceId = STR.JobStepInstanceId    
WHERE STR.IsVertexSupported = 1 AND InvalidErrorCode IS NULL     
AND STR.AssetId IS NULL AND STA.AssetId IS NULL    
AND STR.JobStepInstanceId = @JobStepInstanceId;     
    
-- Lease - Asset Based & Lease Based (No Asset or No Location) Receivables  With OUT SKU Details    
INSERT INTO #VertexWSTransactions     
   (AmountBilledToDate, City, CustomerCode, Currency, Cost, Company, DueDate, MainDivision,     
    Country, ExtendedPrice, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,    
    TransCode, ContractTypeName, ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode,     
    AssetType, SaleLeasebackCode, IsElectronicallyDelivered, TaxRemittanceType, FromState, ToState, AssetId,     
    SalesTaxExemptionLevel, TaxReceivableName, IsSyndicated, BusCode, AssetCatalogNumber, FairMarketValue,     
    LocationCode, Product, TaxAreaId, TransactionType, ClassCode, ReceivableId, ReceivableDetailId,     
    ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus, IsExemptAtSundry, IsPrepaidUpfrontTax ,     
    IsCapitalizedRealAsset, IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode, LegalEntityId,     
    Usage, AssetLocationId,GLTemplateId, IsCapitalizedFirstRealAsset, CommencementDate,SalesTaxRemittanceResponsibility,  
    AcquisitionLocationTaxAreaId, AcquisitionLocationCity, AcquisitionLocationMainDivision, AcquisitionLocationCountry,
	AssetSerialOrVIN, MaturityDate, AssetUsageCondition, IsSKU, AssetSKUId, IsExemptAtAssetSKU, ReceivableSKUId, UpfrontTaxAssessedInLegacySystem
)
SELECT
 AmountBilledToDate = RD.AmountBilledToDate,
 City = L.City,
 CustomerCode = CustomerNumber,
 Currency = RD.Currency,
 Cost =  CAST(0.00 AS DECIMAL(16,2)),
 Company = RD.TaxPayer,
 DueDate = RD.ReceivableDueDate,
 MainDivision = L.StateShortName,
 Country = L.CountryShortName,
 ExtendedPrice = RD.ExtendedPrice,
 Term = CD.Term,
 GrossVehicleWeight = AV.GrossVehicleWeight,
 ReciprocityAmount = AL.ReciprocityAmount,
 LienCredit = AL.LienCredit,
 LocationEffectiveDate = CASE WHEN RT.IsRental = 1 THEN AL.LocationEffectiveDate ELSE NULL END,
 TransCode = CAST(@INVTransactionCode AS NVARCHAR(10)),
 ContractTypeName = CASE WHEN RT.IsRental = 1 THEN AV.ContractTypeName ELSE NULL END,
 ShortLeaseType = CD.ShortLeaseType,
 TaxBasis = CASE WHEN (((AL.LocationTaxBasisType = @UCTaxBasisTypeName
        OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
        AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
		OR RT.TaxReceivableName = @CPIBaseRentalReceivableType))
       OR
         ((AL.LocationTaxBasisType = @URTaxBasisTypeName
        OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
        AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
        AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
       OR
         (RT.IsRental = 0)
		 OR RD.IsRenewal = 1)
     THEN @STTaxBasisTypeName
    ELSE AL.LocationTaxBasisType
    END,
 LeaseUniqueID = CD.SequenceNumber,
 TitleTransferCode = AV.TitleTransferCode,
 SundryReceivableCode = RT.SundryReceivableCode,
 AssetType =  AV.AssetType ,
 SaleLeasebackCode = AV.SaleLeasebackCode,
 IsElectronicallyDelivered = AV.IsElectronicallyDelivered,
 TaxRemittanceType = CD.TaxRemittanceType,
 FromState =  PL.StateShortName,
 ToState = L.StateShortName,
 AssetId =  RD.AssetId,
 SalesTaxExemptionLevel =  AV.SalesTaxExemptionLevel,
 TaxReceivableName = RT.TaxReceivableName,
 IsSyndicated = CD.IsSyndicated ,
 BusCode = CD.BusCode,
 AssetCatalogNumber = AV.AssetCatalogNumber ,
 FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
 LocationCode = L.LocationCode,
 Product = CASE WHEN RT.IsRental = 1 THEN AV.AssetType ELSE RT.TaxReceivableName END,
 TaxAreaId = LT.TaxAreaId,
 TransactionType = RT.TransactionType,
 ClassCode = CU.ClassCode,
 ReceivableId = RD.ReceivableId,
 ReceivableDetailId = RD.ReceivableDetailId,
 RD.ReceivableCodeId,
 RD.ContractId,
 RD.CustomerId,
 L.LocationId,
 L.LocationStatus,
 RD.IsExemptAtSundry,
 CASE
  WHEN ((AL.LocationTaxBasisType = @STTaxBasisTypeName)
    OR
     (RT.IsRental = 0)
       OR
     ((AL.LocationTaxBasisType = @URTaxBasisTypeName
      OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
      AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
      AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
      OR
      ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
	OR RT.TaxReceivableName = @CPIBaseRentalReceivableType))
    OR
    ((AL.LocationTaxBasisType = @URTaxBasisTypeName
    OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)
    OR
    ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)) THEN
  CAST(0 AS BIT)
 ELSE
  STA.IsPrepaidUpfrontTax END,
  CASE
  WHEN ((AL.LocationTaxBasisType = @STTaxBasisTypeName)
    OR
     (RT.IsRental = 0)
       OR
     ((AL.LocationTaxBasisType = @URTaxBasisTypeName
      OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
      AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
      AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
      OR
      ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
	OR RT.TaxReceivableName  = @CPIBaseRentalReceivableType))
    OR
    ((AL.LocationTaxBasisType = @URTaxBasisTypeName
    OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)
    OR
    ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)) THEN
  CAST(0 AS BIT)
 ELSE
  CD.IsContractCapitalizeUpfront END,
 STA.IsCapitalizedSalesTaxAsset,
 STA.IsExemptAtAsset,
 IsExemptAtReceivableCode,
 RD.LegalEntityId,
 AV.Usage,
 AL.AssetlocationId,
 RD.GLTemplateId,
 CAST(0 AS BIT),
 CD.CommencementDate,
 CASE WHEN AV.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND AV.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN AV.PreviousSalesTaxRemittanceResponsibility ELSE AV.SalesTaxRemittanceResponsibility END,
 ALD.AcquisitionLocationTaxAreaId,
 ALD.City,
 ALD.StateShortName,
 ALD.CountryShortName,
 AV.AssetSerialOrVIN,
 CD.MaturityDate,
 AV.AssetUsageCondition,
 -- New Columns
 AV.IsSKU,
 NULL,
 0,
 NULL,
 AL.UpfrontTaxAssessedInLegacySystem
FROM SalesTaxReceivableDetailExtract RD     
INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId     
 AND RD.JobStepInstanceId = RT.JobStepInstanceId    
INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId    
INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId    
INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId    
 AND RD.ContractId = AV.ContractId AND (AV.IsSKU = 0  OR RT.IsRental = 0)  
INNER JOIN SalesTaxAssetDetailExtract STA ON STA.AssetId = RD.AssetId AND CD.LeaseFinanceId = STA.LeaseFinanceId     
 AND RD.JobStepInstanceId = STA.JobStepInstanceId    
INNER JOIN SalesTaxAssetLocationDetailExtract AL ON RD.ReceivableDetailId  = AL.ReceivableDetailId     
 AND AL.AssetId = RD.AssetId AND RD.JobStepInstanceId = AL.JobStepInstanceId    
INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId    
INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.AssetId = LT.AssetId     
 AND RD.JobStepInstanceId = LT.JobStepInstanceId    
LEFT JOIN SalesTaxLocationDetailExtract PL ON RD.PreviousLocationId = PL.LocationId AND PL.JobStepInstanceId = RD.JobStepInstanceId    
LEFT JOIN SalesTaxLocationDetailExtract ALD ON ALD.LocationId = STA.AcquisitionLocationId AND ALD.JobStepInstanceId = RD.JobStepInstanceId   
WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId       
;    
    
/* Added for SKU'S */    
-- Lease - Asset Based & Lease Based (No Asset or No Location) Receivables With SKU Details    
INSERT INTO #VertexWSTransactions     
   (AmountBilledToDate, City, CustomerCode, Currency, Cost, Company, DueDate, MainDivision,     
    Country, ExtendedPrice, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,    
    TransCode, ContractTypeName, ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode,     
    AssetType, SaleLeasebackCode, IsElectronicallyDelivered, TaxRemittanceType, FromState, ToState, AssetId,     
    SalesTaxExemptionLevel, TaxReceivableName, IsSyndicated, BusCode, AssetCatalogNumber, FairMarketValue,     
    LocationCode, Product, TaxAreaId, TransactionType, ClassCode, ReceivableId, ReceivableDetailId,     
    ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus, IsExemptAtSundry, IsPrepaidUpfrontTax ,     
    IsCapitalizedRealAsset, IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode, LegalEntityId,     
    Usage, AssetLocationId,GLTemplateId, IsCapitalizedFirstRealAsset, CommencementDate,SalesTaxRemittanceResponsibility,  
 AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry  
 ,AssetSerialOrVIN,MaturityDate,AssetUsageCondition,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId, UpfrontTaxAssessedInLegacySystem   
)    
SELECT     
 AmountBilledToDate = RS.AmountBilledToDate ,    
 City = L.City,    
 CustomerCode = CustomerNumber,    
 Currency = RD.Currency,    
 Cost =  CAST(0.00 AS DECIMAL(16,2)),    
 Company = RD.TaxPayer,    
 DueDate = RD.ReceivableDueDate,    
 MainDivision = L.StateShortName,    
 Country = L.CountryShortName,    
 ExtendedPrice = RS.ExtendedPrice,    
 Term = CD.Term,     
 GrossVehicleWeight = AV.GrossVehicleWeight,    
 ReciprocityAmount = AL.ReciprocityAmount,    
 LienCredit = AL.LienCredit,    
 LocationEffectiveDate = CASE WHEN RT.IsRental = 1 THEN AL.LocationEffectiveDate ELSE NULL END,    
 TransCode = CAST(@INVTransactionCode AS NVARCHAR(10)),    
 ContractTypeName = CASE WHEN RT.IsRental = 1 THEN AV.ContractTypeName ELSE NULL END,     
 ShortLeaseType = CD.ShortLeaseType,    
 TaxBasis = CASE WHEN (((AL.LocationTaxBasisType = @UCTaxBasisTypeName     
        OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)     
        AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
		OR RT.TaxReceivableName = @CPIBaseRentalReceivableType))
       OR
         ((AL.LocationTaxBasisType = @URTaxBasisTypeName
        OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
        AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
        AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
       OR
         (RT.IsRental = 0))
     THEN @STTaxBasisTypeName      ELSE AL.LocationTaxBasisType
    END,
 LeaseUniqueID = CD.SequenceNumber,
 TitleTransferCode = AV.TitleTransferCode,
 SundryReceivableCode = RT.SundryReceivableCode,
 AssetType =  AVSK.AssetType,
 SaleLeasebackCode = AV.SaleLeasebackCode,
 IsElectronicallyDelivered = AV.IsElectronicallyDelivered,
 TaxRemittanceType = CD.TaxRemittanceType,
 FromState =  PL.StateShortName,
 ToState = L.StateShortName,
 AssetId =  RD.AssetId,
 SalesTaxExemptionLevel =  AV.SalesTaxExemptionLevel,
 TaxReceivableName = RT.TaxReceivableName,
 IsSyndicated = CD.IsSyndicated ,
 BusCode = CD.BusCode,
 AssetCatalogNumber = AVSK.AssetCatalogNumber ,
 FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
 LocationCode = L.LocationCode,
 Product = CASE WHEN RT.IsRental = 1 THEN  AVSK.AssetType  ELSE RT.TaxReceivableName END,
 TaxAreaId = LT.TaxAreaId,
 TransactionType = RT.TransactionType,
 ClassCode = CU.ClassCode,
 ReceivableId = RD.ReceivableId,
 ReceivableDetailId = RD.ReceivableDetailId,
 RD.ReceivableCodeId,
 RD.ContractId,
 RD.CustomerId,
 L.LocationId,
 L.LocationStatus,
 RD.IsExemptAtSundry,
 CASE
  WHEN ((AL.LocationTaxBasisType = @STTaxBasisTypeName)
    OR
     (RT.IsRental = 0)
       OR
     ((AL.LocationTaxBasisType = @URTaxBasisTypeName
      OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
      AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
      AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
      OR
      ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
	OR RT.TaxReceivableName  = @CPIBaseRentalReceivableType))
    OR
    ((AL.LocationTaxBasisType = @URTaxBasisTypeName
    OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)
    OR
    ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)) THEN
  CAST(0 AS BIT)
 ELSE
  STA.IsPrepaidUpfrontTax END,
  CASE
  WHEN ((AL.LocationTaxBasisType = @STTaxBasisTypeName)
    OR
     (RT.IsRental = 0)
       OR
     ((AL.LocationTaxBasisType = @URTaxBasisTypeName
      OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
      AND RT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
      AND RT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
      OR
      ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND (RT.TaxReceivableName  = @LeaseInterimInterestReceivableType
	OR RT.TaxReceivableName  = @CPIBaseRentalReceivableType))
    OR
    ((AL.LocationTaxBasisType = @URTaxBasisTypeName
    OR AL.LocationTaxBasisType = @URDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)
    OR
    ((AL.LocationTaxBasisType = @UCTaxBasisTypeName
    OR AL.LocationTaxBasisType = @UCDMVTaxBasisTypeName)
    AND AL.LocationTaxBasisType <> STA.OriginalTaxBasisType)) THEN
  CAST(0 AS BIT)
 ELSE
  CD.IsContractCapitalizeUpfront END,
 STA.IsCapitalizedSalesTaxAsset,
 STA.IsExemptAtAsset,
 IsExemptAtReceivableCode,
 RD.LegalEntityId,
 AV.Usage,
 AL.AssetlocationId,
 RD.GLTemplateId,
 CAST(0 AS BIT),
 CD.CommencementDate,
 CASE WHEN AV.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND AV.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN AV.PreviousSalesTaxRemittanceResponsibility ELSE AV.SalesTaxRemittanceResponsibility END,
 ALD.AcquisitionLocationTaxAreaId,
 ALD.City,
 ALD.StateShortName,
 ALD.CountryShortName,
 AV.AssetSerialOrVIN,
 CD.MaturityDate,
 AV.AssetUsageCondition,
 -- New Columns
 AV.IsSKU,
 AVSK.AssetSKUId,
 STASK.IsExemptAtAssetSKU,
 RS.ReceivableSKUId,
 AL.UpfrontTaxAssessedInLegacySystem    
FROM SalesTaxReceivableDetailExtract RD     
INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId     
 AND RD.JobStepInstanceId = RT.JobStepInstanceId    
INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId    
INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId    
INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId    
 AND RD.ContractId = AV.ContractId AND AV.IsSKU = 1    
INNER JOIN SalesTaxAssetDetailExtract STA ON STA.AssetId = RD.AssetId AND CD.LeaseFinanceId = STA.LeaseFinanceId     
 AND RD.JobStepInstanceId = STA.JobStepInstanceId    
INNER JOIN SalesTaxAssetLocationDetailExtract AL ON RD.ReceivableDetailId  = AL.ReceivableDetailId     
 AND AL.AssetId = RD.AssetId AND RD.JobStepInstanceId = AL.JobStepInstanceId    
INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId    
INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.AssetId = LT.AssetId     
 AND RD.JobStepInstanceId = LT.JobStepInstanceId    
LEFT JOIN SalesTaxLocationDetailExtract PL ON RD.PreviousLocationId = PL.LocationId AND PL.JobStepInstanceId = RD.JobStepInstanceId   
LEFT JOIN SalesTaxLocationDetailExtract ALD ON ALD.LocationId = STA.AcquisitionLocationId AND ALD.JobStepInstanceId = RD.JobStepInstanceId    
--Added For SKU       
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON RD.ReceivableDetailId = RS.ReceivableDetailId     
AND RD.AssetId = RS.Assetid  AND RD.JobStepInstanceId = RS.JobStepInstanceId    
INNER JOIN VertexAssetSKUDetailExtract AVSK ON RS.AssetId = AVSK.AssetId AND RS.AssetSKUId = AVSK.AssetSKUId       
AND RS.JobStepInstanceId = AVSK.JobStepInstanceId       
INNER JOIN SalesTaxAssetSKUDetailExtract STASK ON STASK.AssetId = RS.AssetId AND STASK.AssetSKUId = RS.AssetSKUId        
AND RS.JobStepInstanceId = STASK.JobStepInstanceId      
WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId
AND STASK.JobstepInstanceId = @JobStepInstanceId
AND RS.JobstepInstanceId = @JobStepInstanceId;    
   
IF EXISTS (SELECT TOP 1 Id FROM SalesTaxReceivableDetailExtract WHERE JobstepInstanceId = @JobStepInstanceId AND AdjustmentBasisReceivableDetailId IS NOT NULL)  
BEGIN
UPDATE #VertexWSTransactions
SET IsCapitalizedRealAsset = RTRD.IsCapitalizeUpfrontSalesTax,
	IsExemptAtAsset = RTRD.IsExemptAtAsset
FROM #VertexWSTransactions VT
	INNER JOIN SalesTaxReceivableDetailExtract RD ON VT.ReceivableDetailId = RD.ReceivableDetailId AND RD.AdjustmentBasisReceivableDetailId IS NOT NULL
	INNER JOIN ReceivableTaxDetails RTD ON RD.AdjustmentBasisReceivableDetailId = RTD.ReceivableDetailId AND RTD.IsActive = 1
	INNER JOIN ReceivableTaxReversalDetails RTRD ON RTD.Id = RTRD.Id
	WHERE RD.JobstepInstanceId = @JobStepInstanceId;
END
    
UPDATE #VertexWSTransactions     
 SET FairMarketValue = URD.FairMarketValue,     
  TransCode = @ORIGTransactionCode,    
  IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN     
          CAST(1 AS BIT)     
           ELSE    
          CAST(0 AS BIT)     
           END,    
  DueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.DueDate END    
FROM #VertexWSTransactions RD     
INNER JOIN VertexUpfrontRentalDetailExtract URD ON RD.ReceivableDetailId = URD.ReceivableDetailId     
AND RD.AssetSKUId IS NULL AND URD.AssetSKUId IS NULL AND URD.JobStepInstanceId = @JobStepInstanceId    
 ;    
  
  
 UPDATE #VertexWSTransactions     
 SET FairMarketValue = URD.FairMarketValue,     
  TransCode = @ORIGTransactionCode,    
  IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN     
          CAST(1 AS BIT)     
           ELSE    
          CAST(0 AS BIT)     
           END,    
  DueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.DueDate END    
FROM #VertexWSTransactions RD     
INNER JOIN VertexUpfrontRentalDetailExtract URD ON RD.ReceivableDetailId = URD.ReceivableDetailId    
AND RD.AssetSKUId IS NOT NULL AND URD.AssetSKUId IS NOT NULL   
AND RD.AssetSKUId = URD.AssetSKUId  
AND URD.JobStepInstanceId = @JobStepInstanceId    
 ;  
    
UPDATE #VertexWSTransactions     
 SET Cost = UCD.AssetCost,     
  TransCode = @ORIGTransactionCode,    
  IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN     
          CAST(1 AS BIT)     
           ELSE    
          CAST(0 AS BIT)     
           END,    
  DueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.DueDate END    
FROM #VertexWSTransactions RD     
INNER JOIN VertexUpfrontCostDetailExtract UCD  ON UCD.ReceivableDetailId = RD.ReceivableDetailId   
AND RD.AssetSKUId IS NULL AND UCD.AssetSKUId IS NULL AND UCD.JobStepInstanceId = @JobStepInstanceId    
 ;   
   
 UPDATE #VertexWSTransactions     
 SET Cost = UCD.AssetCost,     
  TransCode = @ORIGTransactionCode,    
  IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN     
          CAST(1 AS BIT)     
           ELSE    
          CAST(0 AS BIT)     
           END,    
  DueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.DueDate END    
FROM #VertexWSTransactions RD     
INNER JOIN VertexUpfrontCostDetailExtract UCD ON UCD.ReceivableDetailId = RD.ReceivableDetailId    
AND RD.AssetSKUId IS NOT NULL AND UCD.AssetSKUId IS NOT NULL   
AND RD.AssetSKUId = UCD.AssetSKUId AND UCD.JobStepInstanceId = @JobStepInstanceId    
 ;   
    
    
 IF(@AssessCapitalizedUpfrontTaxAtInception = 1)    
 BEGIN    
 DELETE FROM #VertexWSTransactions WHERE TransCode <> @ORIGTransactionCode    
 END    
 ELSE    
 BEGIN    
    --As Assed Id NULL Check we are doing we should not get SKU Logic     
 -- Lease - Lease Based (No Asset and Location Exists) Receivables    
  INSERT INTO #VertexWSTransactions     
    (AmountBilledToDate, City, CustomerCode, Currency, Cost, Company, DueDate, MainDivision,     
     Country, ExtendedPrice, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,    
     TransCode, ContractTypeName, ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode,     
     AssetType, SaleLeasebackCode, IsElectronicallyDelivered, TaxRemittanceType, ToState, AssetId, SalesTaxExemptionLevel, TaxReceivableName,     
     IsSyndicated, BusCode, AssetCatalogNumber, FairMarketValue, LocationCode, Product, TaxAreaId, TransactionType,     
     ClassCode, ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,    
     IsExemptAtSundry, IsPrepaidUpfrontTax , IsCapitalizedRealAsset, IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode,    
     LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,MaturityDate,CommencementDate,AssetUsageCondition,
	 IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId, UpfrontTaxAssessedInLegacySystem
 )
 SELECT
  AmountBilledToDate = RD.AmountBilledToDate,
  City = L.City,
  CustomerCode = CustomerNumber,
  Currency = RD.Currency,
  Cost =  CAST(0.00 AS DECIMAL(16,2)),
  Company = RD.TaxPayer,
  DueDate = RD.ReceivableDueDate,
  MainDivision = L.StateShortName,
  Country = L.CountryShortName,
  ExtendedPrice = RD.ExtendedPrice,
  Term = CD.Term,
  GrossVehicleWeight = 0,
  ReciprocityAmount = 0,
  LienCredit = 0,
  LocationEffectiveDate = NULL,
  TransCode = CAST(@INVTransactionCode AS NVARCHAR(10)),
  ContractTypeName = NULL,
  ShortLeaseType = CD.ShortLeaseType,
  TaxBasis = @STTaxBasisTypeName,
  LeaseUniqueID = CD.SequenceNumber,
  TitleTransferCode = NULL,
  SundryReceivableCode = RT.SundryReceivableCode,
  AssetType = NULL,
  SaleLeasebackCode = NULL,
  IsElectronicallyDelivered = 0,
  TaxRemittanceType = CD.TaxRemittanceType,
  ToState =  L.StateShortName,
  AssetId =  RD.AssetId,
  SalesTaxExemptionLevel =  NULL,
  TaxReceivableName = RT.TaxReceivableName,
  IsSyndicated = CD.IsSyndicated ,
  BusCode = CD.BusCode,
  AssetCatalogNumber = NULL,
  FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
  LocationCode = L.LocationCode,
  Product = CASE WHEN RT.IsRental = 1 THEN CU.ClassCode ELSE RT.TaxReceivableName END,
  TaxAreaId = LT.TaxAreaId,
  TransactionType = RT.TransactionType,
  ClassCode = CU.ClassCode,
  ReceivableId = RD.ReceivableId,
  ReceivableDetailId = RD.ReceivableDetailId,
  RD.ReceivableCodeId,
  RD.ContractId,
  RD.CustomerId,
  L.LocationId,
  L.LocationStatus,
  RD.IsExemptAtSundry,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT),
  IsExemptAtReceivableCode,
  RD.LegalEntityId,
  RD.GLTemplateId,
  CAST(0 AS BIT) ,
  '_' AS SalesTaxRemittanceResponsibility,
 CD.MaturityDate,
 CD.CommencementDate,
 '_' AS AssetUsageCondition,
 -- New Columns
 0,
 NULL,
 0,
 NULL,
 0
   
 FROM SalesTaxReceivableDetailExtract RD     
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId     
  AND RD.JobStepInstanceId = RT.JobStepInstanceId    
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId    
 INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId    
 INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId    
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId    
 WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL     
 AND RD.AssetId IS NULL AND CD.IsLease = 1 AND RD.JobStepInstanceId = @JobStepInstanceId    
 ;    
     
 --As Assed Id NULL Check we are doing we should not be SKU Logic     
 -- Customer Level Non Asset Based Receivables    
 INSERT INTO #VertexWSTransactions     
    (AmountBilledToDate, City, CustomerCode, Currency, Company, DueDate, MainDivision,     
     Country, ExtendedPrice, LocationEffectiveDate,TransCode,TaxBasis, SundryReceivableCode, TaxRemittanceType,    
     ToState, TaxReceivableName, IsSyndicated, LocationCode, Product, TaxAreaId, TransactionType, ClassCode,     
     ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,     
     IsExemptAtSundry, IsPrepaidUpfrontTax, IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset,     
     IsExemptAtReceivableCode, LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,
	 AssetUsageCondition,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId,UpfrontTaxAssessedInLegacySystem)
 SELECT
  AmountBilledToDate = RD.AmountBilledToDate,
  City = L.City,
  CustomerCode = CU.CustomerNumber,
  Currency = RD.Currency,
  Company = RD.TaxPayer,
  DueDate = RD.ReceivableDueDate,
  MainDivision = L.StateShortName,
  Country = L.CountryShortName,
  ExtendedPrice = RD.ExtendedPrice,
  LocationEffectiveDate = NULL,
  TransCode = @INVTransactionCode,
  TaxBasis = @STTaxBasisTypeName,
  SundryReceivableCode = RT.SundryReceivableCode,
  TaxRemittanceType =  RD.LegalEntityTaxRemittancePreference,
  ToState =  L.StateShortName,
  TaxReceivableName = RT.TaxReceivableName,
  IsSyndicated = 0,
  LocationCode = L.LocationCode,
  Product = RT.TaxReceivableName,
  TaxAreaId = LT.TaxAreaId,
  TransactionType = RT.TransactionType,
  ClassCode = CU.ClassCode,
  ReceivableId = RD.ReceivableId,
  ReceivableDetailId = RD.ReceivableDetailId,
  RD.ReceivableCodeId,
  RD.ContractId,
  RD.CustomerId,
  L.LocationId,
  L.LocationStatus,
  RD.IsExemptAtSundry,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  IsExemptAtReceivableCode,
  RD.LegalEntityId,
  RD.GLTemplateId,
  CAST(0 AS BIT),
 '_' AS SalesTaxRemittanceResponsibility,
  '_' AS AssetUsageCondition,
  -- New Columns
 0,
 NULL,
 0 ,
 NULL,
 0

FROM SalesTaxReceivableDetailExtract RD
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId
  AND RD.JobStepInstanceId = RT.JobStepInstanceId
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.EntityType = @CUEntityTypeName
  AND RD.JobStepInstanceId = CU.JobStepInstanceId
 INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND L.IsVertexSupportedLocation = 1
  AND RD.JobStepInstanceId = L.JobStepInstanceId
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId
 WHERE RD.ContractId IS NULL AND RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL
 AND RD.JobStepInstanceId = @JobStepInstanceId AND RD.AssetId IS NULL;

-- Lease - Lease Based (Asset and Location Exists without Asset Location) Receivables -- Without SKU
INSERT INTO #VertexWSTransactions 
		(AmountBilledToDate, City, CustomerCode, Currency, Cost, Company, DueDate, MainDivision, 
			Country, ExtendedPrice, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,
			TransCode, ContractTypeName, ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode, 
			AssetType, SaleLeasebackCode, IsElectronicallyDelivered, TaxRemittanceType, ToState, AssetId, SalesTaxExemptionLevel, TaxReceivableName, 
			IsSyndicated, BusCode, AssetCatalogNumber, FairMarketValue, LocationCode, Product,	TaxAreaId, TransactionType, 
			ClassCode, ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,
			IsExemptAtSundry, IsPrepaidUpfrontTax , IsCapitalizedRealAsset, IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode,
			LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,MaturityDate,CommencementDate,AssetUsageCondition, Usage,
			AssetSerialOrVIN, IsSKU, AssetSKUId, IsExemptAtAssetSKU, ReceivableSKUId, UpfrontTaxAssessedInLegacySystem
)
SELECT 
	AmountBilledToDate = RD.AmountBilledToDate,
	City = L.City,
	CustomerCode = CustomerNumber,
	Currency = RD.Currency,
	Cost =  CAST(0.00 AS DECIMAL(16,2)),
	Company = RD.TaxPayer,
	DueDate = RD.ReceivableDueDate,
	MainDivision = L.StateShortName,
	Country = L.CountryShortName,
	ExtendedPrice = RD.ExtendedPrice,
	Term = CD.Term, 
	GrossVehicleWeight = AV.GrossVehicleWeight,
	ReciprocityAmount = 0,
	LienCredit = 0,
	LocationEffectiveDate = NULL,
	TransCode = CAST(@INVTransactionCode AS NVARCHAR(10)),
	ContractTypeName = NULL, 
	ShortLeaseType = CD.ShortLeaseType,
	TaxBasis = @STTaxBasisTypeName,
	LeaseUniqueID = CD.SequenceNumber, 
	TitleTransferCode = AV.TitleTransferCode,
	SundryReceivableCode = RT.SundryReceivableCode, 
	AssetType = AV.AssetType, 
	SaleLeasebackCode = AV.SaleLeasebackCode, 
	IsElectronicallyDelivered = AV.IsElectronicallyDelivered, 
	TaxRemittanceType = CD.TaxRemittanceType, 
	ToState =  L.StateShortName,
	AssetId =  RD.AssetId,
	SalesTaxExemptionLevel =  AV.SalesTaxExemptionLevel,  
	TaxReceivableName = RT.TaxReceivableName, 
	IsSyndicated = CD.IsSyndicated , 
	BusCode = CD.BusCode,
	AssetCatalogNumber = AV.AssetCatalogNumber,
	FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
	LocationCode = L.LocationCode, 
	Product = CASE WHEN RT.IsRental = 1 THEN AV.AssetType ELSE RT.TaxReceivableName END,
	TaxAreaId = LT.TaxAreaId,
	TransactionType = RT.TransactionType,
	ClassCode = CU.ClassCode,
	ReceivableId = RD.ReceivableId,
	ReceivableDetailId = RD.ReceivableDetailId,
	RD.ReceivableCodeId,
	RD.ContractId,
	RD.CustomerId,
	L.LocationId,
	L.LocationStatus,
	RD.IsExemptAtSundry,
	CAST(0 AS BIT) ,
	CAST(0 AS BIT) ,
	CAST(0 AS BIT) ,
	STA.IsExemptAtAsset,
	IsExemptAtReceivableCode,
	RD.LegalEntityId,
	RD.GLTemplateId,
	CAST(0 AS BIT),
	'_' AS SalesTaxRemittanceResponsibility,
	CD.MaturityDate,
	CD.CommencementDate,
	AV.AssetUsageCondition,
	AV.Usage,
	AV.AssetSerialOrVIN,
	AV.IsSKU,
	CAST(NULL AS BIGINT),
	CAST(0 AS BIT),
	CAST(NULL AS BIGINT),
	CAST(0 AS BIT)
FROM SalesTaxReceivableDetailExtract RD 
INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId 
	AND RD.JobStepInstanceId = RT.JobStepInstanceId
INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId
INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId
INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId
INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId
INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId 
	AND RD.ContractId = AV.ContractId AND AV.IsSKU = 0
INNER JOIN SalesTaxAssetDetailExtract STA ON STA.AssetId = RD.AssetId AND CD.LeaseFinanceId = STA.LeaseFinanceId 
	AND RD.JobStepInstanceId = STA.JobStepInstanceId AND STA.IsSKU = 0
LEFT JOIN SalesTaxAssetLocationDetailExtract AL ON RD.ReceivableDetailId  = AL.ReceivableDetailId
	AND AL.AssetId = RD.AssetId AND RD.JobStepInstanceId = AL.JobStepInstanceId
WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL 
AND RD.AssetId IS NOT NULL AND RD.LocationId IS NOT NULL 
AND CD.IsLease = 1 AND RD.JobStepInstanceId = @JobStepInstanceId
AND AL.ReceivableDetailId IS NULL
;

-- Lease - Lease Based (Asset and Location Exists without Asset Location) Receivables -- With SKU
INSERT INTO #VertexWSTransactions 
		(AmountBilledToDate, City, CustomerCode, Currency, Cost, Company, DueDate, MainDivision, 
			Country, ExtendedPrice, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,
			TransCode, ContractTypeName, ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode, 
			AssetType, SaleLeasebackCode, IsElectronicallyDelivered, TaxRemittanceType, ToState, AssetId, SalesTaxExemptionLevel, TaxReceivableName, 
			IsSyndicated, BusCode, AssetCatalogNumber, FairMarketValue, LocationCode, Product,	TaxAreaId, TransactionType, 
			ClassCode, ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,
			IsExemptAtSundry, IsPrepaidUpfrontTax , IsCapitalizedRealAsset, IsCapitalizedSalesTaxAsset, IsExemptAtAsset, IsExemptAtReceivableCode,
			LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,MaturityDate,CommencementDate,AssetUsageCondition, Usage,
			AssetSerialOrVIN, IsSKU, AssetSKUId, IsExemptAtAssetSKU, ReceivableSKUId, UpfrontTaxAssessedInLegacySystem
)
SELECT 
	AmountBilledToDate = RD.AmountBilledToDate,
	City = L.City,
	CustomerCode = CustomerNumber,
	Currency = RD.Currency,
	Cost =  CAST(0.00 AS DECIMAL(16,2)),
	Company = RD.TaxPayer,
	DueDate = RD.ReceivableDueDate,
	MainDivision = L.StateShortName,
	Country = L.CountryShortName,
	ExtendedPrice = RD.ExtendedPrice,
	Term = CD.Term, 
	GrossVehicleWeight = AV.GrossVehicleWeight,
	ReciprocityAmount = 0,
	LienCredit = 0,
	LocationEffectiveDate = NULL,
	TransCode = CAST(@INVTransactionCode AS NVARCHAR(10)),
	ContractTypeName = NULL, 
	ShortLeaseType = CD.ShortLeaseType,
	TaxBasis = @STTaxBasisTypeName,
	LeaseUniqueID = CD.SequenceNumber, 
	TitleTransferCode = AV.TitleTransferCode,
	SundryReceivableCode = RT.SundryReceivableCode, 
	AssetType = AV.AssetType, 
	SaleLeasebackCode = AV.SaleLeasebackCode, 
	IsElectronicallyDelivered = AV.IsElectronicallyDelivered, 
	TaxRemittanceType = CD.TaxRemittanceType, 
	ToState =  L.StateShortName,
	AssetId =  RD.AssetId,
	SalesTaxExemptionLevel =  AV.SalesTaxExemptionLevel,  
	TaxReceivableName = RT.TaxReceivableName, 
	IsSyndicated = CD.IsSyndicated , 
	BusCode = CD.BusCode,
	AssetCatalogNumber = AV.AssetCatalogNumber,
	FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
	LocationCode = L.LocationCode, 
	Product = CASE WHEN RT.IsRental = 1 THEN AV.AssetType ELSE RT.TaxReceivableName END,
	TaxAreaId = LT.TaxAreaId,
	TransactionType = RT.TransactionType,
	ClassCode = CU.ClassCode,
	ReceivableId = RD.ReceivableId,
	ReceivableDetailId = RD.ReceivableDetailId,
	RD.ReceivableCodeId,
	RD.ContractId,
	RD.CustomerId,
	L.LocationId,
	L.LocationStatus,
	RD.IsExemptAtSundry,
	CAST(0 AS BIT) ,
	CAST(0 AS BIT) ,
	CAST(0 AS BIT) ,
	STA.IsExemptAtAsset,
	IsExemptAtReceivableCode,
	RD.LegalEntityId,
	RD.GLTemplateId,
	CAST(0 AS BIT),
	'_' AS SalesTaxRemittanceResponsibility,
	CD.MaturityDate,
	CD.CommencementDate,
	AV.AssetUsageCondition,
	AV.Usage,
	AV.AssetSerialOrVIN,
	AV.IsSKU,
	AVSK.AssetSKUId,
	STASK.IsExemptAtAssetSKU,
	RS.ReceivableSKUId,
	CAST(0 AS BIT)
FROM SalesTaxReceivableDetailExtract RD 
INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId 
	AND RD.JobStepInstanceId = RT.JobStepInstanceId
INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId
INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RD.JobStepInstanceId = CD.JobStepInstanceId
INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId
INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId
INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId 
	AND RD.ContractId = AV.ContractId AND AV.IsSKU = 1
INNER JOIN SalesTaxAssetDetailExtract STA ON STA.AssetId = RD.AssetId AND CD.LeaseFinanceId = STA.LeaseFinanceId 
	AND RD.JobStepInstanceId = STA.JobStepInstanceId AND STA.IsSKU = 1
	--Added For SKU
INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON RD.ReceivableDetailId = RS.ReceivableDetailId AND RD.AssetId = RS.AssetId
INNER JOIN VertexAssetSKUDetailExtract AVSK ON RS.AssetId = AVSK.AssetId AND RS.AssetSKUId = AVSK.AssetSKUId
INNER JOIN SalesTaxAssetSKUDetailExtract STASK ON STASK.AssetId = RS.AssetId AND STASK.AssetSKUId = RS.AssetSKUId
	AND RD.JobStepInstanceId = STA.JobStepInstanceId
LEFT JOIN SalesTaxAssetLocationDetailExtract AL ON RD.ReceivableDetailId  = AL.ReceivableDetailId
	AND AL.AssetId = RD.AssetId AND RD.JobStepInstanceId = AL.JobStepInstanceId
WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL 
AND RD.AssetId IS NOT NULL AND RD.LocationId IS NOT NULL 
AND CD.IsLease = 1 AND RD.JobStepInstanceId = @JobStepInstanceId
AND AL.ReceivableDetailId IS NULL
;


 -- Customer Level Asset Based Receivables With out SKUS
 INSERT INTO #VertexWSTransactions
   (AmountBilledToDate, City, CustomerCode, Currency, Company, DueDate, MainDivision,
   Country, ExtendedPrice, LocationEffectiveDate,TransCode, TaxBasis, SundryReceivableCode, TaxRemittanceType,
   FromState, ToState, TaxReceivableName, IsSyndicated, LocationCode, Product, TaxAreaId, TransactionType, ClassCode,
   ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,
   IsExemptAtSundry, IsPrepaidUpfrontTax, IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode,
   LegalEntityId, ReciprocityAmount, LienCredit, AssetId, Usage, AssetLocationId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,
   AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry,AssetSerialOrVIN,AssetUsageCondition
   ,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId,UpfrontTaxAssessedInLegacySystem)

 SELECT
  AmountBilledToDate = RD.AmountBilledToDate,
  City = L.City,
  CustomerCode = CustomerNumber,
  Currency = RD.Currency,
  Company = RD.TaxPayer,
  DueDate = RD.ReceivableDueDate,
  MainDivision = L.StateShortName,
  Country = L.CountryShortName,
  ExtendedPrice = RD.ExtendedPrice,
  LocationEffectiveDate = AL.LocationEffectiveDate,
  TransCode = @INVTransactionCode,
  TaxBasis = AL.LocationTaxBasisType,
  SundryReceivableCode = RT.SundryReceivableCode,
  TaxRemittanceType =  RD.LegalEntityTaxRemittancePreference,
  FromState =  PL.StateShortName,
  ToState = L.StateShortName,
  TaxReceivableName = RT.TaxReceivableName,
  IsSyndicated = 0,
  LocationCode = L.LocationCode,
  Product = RT.TaxReceivableName,
  TaxAreaId = LT.TaxAreaId,
  TransactionType = RT.TransactionType,
  ClassCode = CU.ClassCode,
  ReceivableId = RD.ReceivableId,
  ReceivableDetailId = RD.ReceivableDetailId,
  RD.ReceivableCodeId,
  RD.ContractId,
  RD.CustomerId,
  L.LocationId,
  L.LocationStatus,
  RD.IsExemptAtSundry,
  CAST(0 AS BIT) IsPrepaidUpfrontTax,
  CAST(0 AS BIT) IsCapitalizedSalesTaxAsset,
  CAST(0 AS BIT) IsCapitalizedRealAsset,
  IsExemptAtAsset,
  IsExemptAtReceivableCode,
  RD.LegalEntityId,
  ReciprocityAmount,
  LienCredit,
  A.AssetId
  ,AV.Usage
  ,AL.AssetlocationId
  ,RD.GLTemplateId
  ,CAST(0 AS BIT)
  ,CASE WHEN AV.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND AV.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN AV.PreviousSalesTaxRemittanceResponsibility ELSE AV.SalesTaxRemittanceResponsibility END
 ,ALD.AcquisitionLocationTaxAreaId
 ,ALD.City
 ,ALD.StateShortName
 ,ALD.CountryShortName
 ,AV.AssetSerialOrVIN
 ,AV.AssetUsageCondition
  -- New Columns
  ,AV.IsSKU
  ,NULL
  ,0
  ,NULL
  ,0
 FROM SalesTaxReceivableDetailExtract RD     
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId AND RD.JobStepInstanceId = RT.JobStepInstanceId    
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId    
 INNER JOIN SalesTaxAssetDetailExtract A ON RD.AssetId = A.AssetId AND RD.EntityType = @CUEntityTypeName AND RD.JobStepInstanceId = A.JobStepInstanceId  AND A.LeaseFinanceId IS NULL    
 AND A.IsSKU = 0    
 INNER JOIN SalesTaxAssetLocationDetailExtract AL ON A.AssetId  = AL.AssetId  AND AL.ReceivableDetailId = RD.ReceivableDetailId AND RD.JobStepInstanceId = AL.JobStepInstanceId    
 INNER JOIN SalesTaxLocationDetailExtract L ON AL.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId    
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId    
 INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId     
 AND (AV.IsSKU = 0  OR RT.IsRental = 0)  
 LEFT JOIN SalesTaxLocationDetailExtract PL ON AL.PreviousLocationId = PL.LocationId AND RD.JobStepInstanceId = PL.JobStepInstanceId    
 LEFT JOIN SalesTaxLocationDetailExtract ALD ON ALD.LocationId = A.AcquisitionLocationId AND ALD.JobStepInstanceId = RD.JobStepInstanceId   
 WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId;    
    
    
 /**/    
 -- Customer Level Asset Based Receivables With  SKUS    
 INSERT INTO #VertexWSTransactions     
   (AmountBilledToDate, City, CustomerCode, Currency, Company, DueDate, MainDivision,     
   Country, ExtendedPrice, LocationEffectiveDate,TransCode, TaxBasis, SundryReceivableCode, TaxRemittanceType,    
   FromState, ToState, TaxReceivableName, IsSyndicated, LocationCode, Product, TaxAreaId, TransactionType, ClassCode,     
   ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,     
   IsExemptAtSundry, IsPrepaidUpfrontTax, IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode,    
   LegalEntityId, ReciprocityAmount, LienCredit, AssetId, Usage, AssetLocationId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,  
   AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry    
   ,AssetSerialOrVIN,AssetUsageCondition,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId,UpfrontTaxAssessedInLegacySystem)    
       
 SELECT     
  AmountBilledToDate =  RS.AmountBilledToDate,    
  City = L.City,    
  CustomerCode = CustomerNumber,    
  Currency = RD.Currency,    
  Company = RD.TaxPayer,    
  DueDate = RD.ReceivableDueDate,    
  MainDivision = L.StateShortName,    
  Country = L.CountryShortName,    
  ExtendedPrice =  RS.ExtendedPrice,    
  LocationEffectiveDate = AL.LocationEffectiveDate,    
  TransCode = @INVTransactionCode,    
  TaxBasis = AL.LocationTaxBasisType,     
  SundryReceivableCode = RT.SundryReceivableCode,     
  TaxRemittanceType =  RD.LegalEntityTaxRemittancePreference,    
  FromState =  PL.StateShortName,    
  ToState = L.StateShortName,    
  TaxReceivableName = RT.TaxReceivableName,     
  IsSyndicated = 0,     
  LocationCode = L.LocationCode,     
  Product = RT.TaxReceivableName,    
  TaxAreaId = LT.TaxAreaId,    
  TransactionType = RT.TransactionType,    
  ClassCode = CU.ClassCode,    
  ReceivableId = RD.ReceivableId,    
  ReceivableDetailId = RD.ReceivableDetailId,    
  RD.ReceivableCodeId,    
  RD.ContractId,    
  RD.CustomerId,    
  L.LocationId,    
  L.LocationStatus,    
  RD.IsExemptAtSundry,    
  CAST(0 AS BIT) IsPrepaidUpfrontTax,    
  CAST(0 AS BIT) IsCapitalizedSalesTaxAsset,    
  CAST(0 AS BIT) IsCapitalizedRealAsset,    
  IsExemptAtAsset,    
  IsExemptAtReceivableCode,    
  RD.LegalEntityId,    
  ReciprocityAmount,    
  LienCredit,    
  A.AssetId    
  ,AV.Usage    
  ,AL.AssetlocationId    
  ,RD.GLTemplateId    
  ,CAST(0 AS BIT)  
  ,CASE WHEN AV.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND AV.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN AV.PreviousSalesTaxRemittanceResponsibility ELSE AV.SalesTaxRemittanceResponsibility END  
 ,ALD.AcquisitionLocationTaxAreaId  
 ,ALD.City  
 ,ALD.StateShortName  
 ,ALD.CountryShortName  
 ,AV.AssetSerialOrVIN  
 ,AV.AssetUsageCondition  
  -- New Columns    
  ,AV.IsSKU    
  ,AVSK.AssetSKUId    
  ,STASK.IsExemptAtAssetSKU   
  ,RS.ReceivableSKUId
  ,0   
 FROM SalesTaxReceivableDetailExtract RD     
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId AND RD.JobStepInstanceId = RT.JobStepInstanceId    
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.JobStepInstanceId = CU.JobStepInstanceId    
 INNER JOIN SalesTaxAssetDetailExtract A ON RD.AssetId = A.AssetId AND RD.EntityType = @CUEntityTypeName AND RD.JobStepInstanceId = A.JobStepInstanceId  AND A.LeaseFinanceId IS NULL    
 AND A.IsSKU = 1  
 INNER JOIN SalesTaxAssetLocationDetailExtract AL ON A.AssetId  = AL.AssetId  AND AL.ReceivableDetailId = RD.ReceivableDetailId AND RD.JobStepInstanceId = AL.JobStepInstanceId    
 INNER JOIN SalesTaxLocationDetailExtract L ON AL.LocationId = L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId    
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId    
 INNER JOIN VertexAssetDetailExtract AV ON RD.AssetId = AV.AssetId AND RD.JobStepInstanceId = AV.JobStepInstanceId AND AV.ContractId IS NULL    
 AND AV.IsSKU = 1    
 LEFT JOIN SalesTaxLocationDetailExtract PL ON AL.PreviousLocationId = PL.LocationId AND RD.JobStepInstanceId = PL.JobStepInstanceId    
 LEFT JOIN SalesTaxLocationDetailExtract ALD ON ALD.LocationId = A.AcquisitionLocationId AND ALD.JobStepInstanceId = RD.JobStepInstanceId   
   --Added For SKU     
 INNER JOIN SalesTaxReceivableSKUDetailExtract RS ON RD.ReceivableDetailId = RS.ReceivableDetailId AND RD.AssetId = RS.AssetId    
 INNER JOIN VertexAssetSKUDetailExtract AVSK ON RS.AssetId = AVSK.AssetId AND RS.AssetSKUId = AVSK.AssetSKUId     
 AND RD.JobStepInstanceId = AV.JobStepInstanceId AND RD.ContractId = AV.ContractId    
 INNER JOIN SalesTaxAssetSKUDetailExtract STASK ON STASK.AssetId = RS.AssetId AND STASK.AssetSKUId = RS.AssetSKUId      
 AND RD.JobStepInstanceId = A.JobStepInstanceId    
 WHERE RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId;    
    
/**/    
 -- Loan Receivables    
 INSERT INTO #VertexWSTransactions     
    (AmountBilledToDate, City, CustomerCode, Currency, Company, DueDate, MainDivision,     
     Country, ExtendedPrice, LocationEffectiveDate,TransCode,TaxBasis, SundryReceivableCode, TaxRemittanceType,    
     ToState, TaxReceivableName, IsSyndicated, BusCode, LocationCode, Product, TaxAreaId, TransactionType, ClassCode,     
     ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,     
     IsExemptAtSundry, IsPrepaidUpfrontTax, IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode,    
     LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,MaturityDate,CommencementDate,
	 AssetUsageCondition,IsSKU,IsExemptAtAssetSKU,UpfrontTaxAssessedInLegacySystem)
 SELECT
  AmountBilledToDate = RD.AmountBilledToDate,
  City = L.City,
  CustomerCode = CU.CustomerNumber,
  Currency = RD.Currency,
  Company = RD.TaxPayer,
  DueDate = RD.ReceivableDueDate,
  MainDivision = L.StateShortName,
  Country = L.CountryShortName,
  ExtendedPrice = RD.ExtendedPrice,
  LocationEffectiveDate = NULL,
  TransCode = @INVTransactionCode,
  TaxBasis = @STTaxBasisTypeName,
  SundryReceivableCode = RT.SundryReceivableCode,
  TaxRemittanceType =  CD.TaxRemittanceType,
  ToState =  L.StateShortName,
  TaxReceivableName = RT.TaxReceivableName,
  IsSyndicated = 0,
  BusCode = CD.BusCode,
  LocationCode = L.LocationCode,
  Product = RT.TaxReceivableName,
  TaxAreaId = LT.TaxAreaId,
  TransactionType = RT.TransactionType,
  ClassCode = CU.ClassCode,
  ReceivableId = RD.ReceivableId,
  ReceivableDetailId = RD.ReceivableDetailId,
  RD.ReceivableCodeId,
  RD.ContractId,
  RD.CustomerId,
  L.LocationId,
  L.LocationStatus,
  RD.IsExemptAtSundry,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  CAST(0 AS BIT) ,
  IsExemptAtReceivableCode,
  RD.LegalEntityId,
  RD.GLTemplateId,
  CAST(0 AS BIT),
  '_' AS SalesTaxRemittanceResponsibility,
  CD.MaturityDate,
  CD.CommencementDate,
  '_' AS AssetUsageCondition,
  0,
  0,
  0
 FROM SalesTaxReceivableDetailExtract RD     
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId AND RD.JobStepInstanceId = RT.JobStepInstanceId    
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RT.JobStepInstanceId = CU.JobStepInstanceId    
 INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND RT.JobStepInstanceId = L.JobStepInstanceId    
 INNER JOIN VertexContractDetailExtract CD ON RD.ContractId = CD.ContractId AND RT.JobStepInstanceId = CD.JobStepInstanceId    
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId    
 WHERE CD.IsLease =0 AND RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL    
 AND RD.JobStepInstanceId = @JobStepInstanceId;    
    
    
 -- Discounting Receivables    
 INSERT INTO #VertexWSTransactions     
    (AmountBilledToDate, City, CustomerCode, Currency, Company, DueDate, MainDivision,     
     Country, ExtendedPrice, LocationEffectiveDate,TransCode,TaxBasis, SundryReceivableCode, TaxRemittanceType,    
     ToState, TaxReceivableName, IsSyndicated, LocationCode, Product, TaxAreaId, TransactionType, ClassCode,     
     ReceivableId, ReceivableDetailId, ReceivableCodeId, ContractId, CustomerId, LocationId, LocationStatus,     
     IsExemptAtSundry, IsPrepaidUpfrontTax, IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode,    
     LegalEntityId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility,AssetUsageCondition,IsSKU,IsExemptAtAssetSKU, UpfrontTaxAssessedInLegacySystem)    
 SELECT     
  AmountBilledToDate = RD.AmountBilledToDate,    
  City = L.City,    
  CustomerCode = CU.CustomerNumber,    
  Currency = RD.Currency,    
  Company = RD.TaxPayer,    
  DueDate = RD.ReceivableDueDate,    
  MainDivision = L.StateShortName,    
  Country = L.CountryShortName,    
  ExtendedPrice = RD.ExtendedPrice,    
  LocationEffectiveDate = NULL,    
  TransCode = @INVTransactionCode,    
  TaxBasis = @STTaxBasisTypeName,     
  SundryReceivableCode = RT.SundryReceivableCode,     
  TaxRemittanceType =  RD.LegalEntityTaxRemittancePreference,    
  ToState =  L.StateShortName,    
  TaxReceivableName = RT.TaxReceivableName,     
  IsSyndicated = 0,     
  LocationCode = L.LocationCode,     
  Product = RT.TaxReceivableName,    
  TaxAreaId = LT.TaxAreaId,    
  TransactionType = RT.TransactionType,    
  ClassCode = CU.ClassCode,    
  ReceivableId = RD.ReceivableId,    
  ReceivableDetailId = RD.ReceivableDetailId,    
  RD.ReceivableCodeId,    
  RD.ContractId,    
  RD.CustomerId,    
  L.LocationId,    
  L.LocationStatus,    
  RD.IsExemptAtSundry,    
  CAST(0 AS BIT) ,    
  CAST(0 AS BIT) ,    
  CAST(0 AS BIT) ,    
  CAST(0 AS BIT) ,    
  IsExemptAtReceivableCode,    
  RD.LegalEntityId,    
  RD.GLTemplateId,    
  CAST(0 AS BIT),  
  '_' AS SalesTaxRemittanceResponsibility,  
  '_' AS AssetUsageCondition,  
  0,  
  0,
  0  
 FROM SalesTaxReceivableDetailExtract RD     
 INNER JOIN VertexReceivableCodeDetailExtract RT ON RD.ReceivableCodeId = RT.ReceivableCodeId     
  AND RD.JobStepInstanceId = RT.JobStepInstanceId    
 INNER JOIN VertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND RD.EntityType = @DTEntityTypeName    
  AND RD.JobStepInstanceId = CU.JobStepInstanceId    
 INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId = L.LocationId AND L.IsVertexSupportedLocation = 1    
  AND RD.JobStepInstanceId = L.JobStepInstanceId    
 INNER JOIN #SalesTaxTaxAreaDetails LT ON RD.ReceivableDetailId = LT.ReceivableDetailId AND RD.JobStepInstanceId = LT.JobStepInstanceId    
 WHERE RD.ContractId IS NULL AND RD.IsVertexSupported = 1 AND RD.InvalidErrorCode IS NULL AND RD.DiscountingId IS NOT NULL    
 AND RD.JobStepInstanceId = @JobStepInstanceId;    
END
    
INSERT INTO VertexWSTransactionExtract    
 (ReceivableId, ReceivableDetailId, AmountBilledToDate, City, LineItemNumber, CustomerCode, CurrencyCode, Cost,    
  CompanyCode, DueDate, MainDivision, Country, ExtendedPrice, FairMarketValue, LocationCode, Product, TaxAreaId, TransactionType,    
  CustomerClass, Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate, TransCode, ContractTypeName,    
  ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode, AssetType, SaleLeasebackCode,    
  IsElectronicallyDelivered, TaxRemittanceType, FromState, ToState, AssetId, SalesTaxExemptionLevel, TaxReceivableName,    
  IsSyndicated, BusCode, HorsePower, AssetCatalogNumber, IsTaxExempt, TaxExemptReason ,IsPrepaidUpfrontTax ,    
  IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode, IsExemptAtSundry, LocationId, LocationStatus,    
  LegalEntityId, BatchStatus, JobStepInstanceId,Usage,AssetLocationId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility  
 ,AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry    
  ,AssetUsageCondition,AssetSerialOrVIN,MaturityDate,CommencementDate,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId
  ,UpfrontTaxAssessedInLegacySystem)

SELECT ReceivableId, ReceivableDetailId, AmountBilledToDate, City, LineItemNumber, CustomerCode,	CurrencyCode, Cost,
		CompanyCode, DueDate, MainDivision, Country, ExtendedPrice, FairMarketValue, LocationCode,	Product, TaxAreaId,	TransactionType,
		CustomerClass,	Term, GrossVehicleWeight, ReciprocityAmount, LienCredit, LocationEffectiveDate,	TransCode, ContractTypeName,
		ShortLeaseType, TaxBasis, LeaseUniqueID, TitleTransferCode, SundryReceivableCode, AssetType, SaleLeasebackCode,
		IsElectronicallyDelivered, TaxRemittanceType, FromState, ToState, AssetId,	SalesTaxExemptionLevel,	TaxReceivableName,
		IsSyndicated, BusCode, HorsePower, AssetCatalogNumber,	IsTaxExempt, TaxExemptReason ,IsPrepaidUpfrontTax ,
		IsCapitalizedSalesTaxAsset, IsCapitalizedRealAsset, IsExemptAtAsset, IsExemptAtReceivableCode, IsExemptAtSundry, LocationId, LocationStatus,
		LegalEntityId, BatchStatus, JobStepInstanceId,Usage,AssetLocationId,GLTemplateId,IsCapitalizedFirstRealAsset,SalesTaxRemittanceResponsibility
	 ,AcquisitionLocationTaxAreaId,AcquisitionLocationCity,AcquisitionLocationMainDivision,AcquisitionLocationCountry,AssetUsageCondition,AssetSerialOrVIN,MaturityDate,CommencementDate
	 ,IsSKU,AssetSKUId,IsExemptAtAssetSKU,ReceivableSKUId, UpfrontTaxAssessedInLegacySystem FROM
(
SELECT
 ReceivableId
	,ReceivableDetailId
	,AmountBilledToDate
	,City
	,ReceivableDetailId LineItemNumber
	,CustomerCode
	,Currency CurrencyCode
	,Cost
	,Company CompanyCode
	,DueDate
	,MainDivision
	,Country
	,ExtendedPrice
	,FairMarketValue
	,LocationCode
	,Product
	,TaxAreaId
	,TransactionType
	,ClassCode CustomerClass
	,Term
	,GrossVehicleWeight
	,ReciprocityAmount
	,LienCredit
	,LocationEffectiveDate
	,TransCode
	,ContractTypeName
	,ShortLeaseType
	,TaxBasis
	,LeaseUniqueID
	,TitleTransferCode
	,SundryReceivableCode
	,AssetType
	,SaleLeasebackCode
	,ISNULL(IsElectronicallyDelivered,0) IsElectronicallyDelivered
	,TaxRemittanceType
	,FromState
	,ToState
	,AssetId
	,SalesTaxExemptionLevel
	,TaxReceivableName
	,IsSyndicated
	,BusCode
	,0 HorsePower
	,AssetCatalogNumber
	,0 IsTaxExempt
	,NULL TaxExemptReason
	,IsPrepaidUpfrontTax
	,IsCapitalizedSalesTaxAsset
	,IsCapitalizedRealAsset
	,IsExemptAtAsset
	,IsExemptAtReceivableCode
	,IsExemptAtSundry
	,LocationId
	,LocationStatus
	,LegalEntityId
	,@NewBatchStatus BatchStatus
	,@JobStepInstanceId JobStepInstanceId
	,Usage
	,AssetLocationId
	,GLTemplateId
	,IsCapitalizedFirstRealAsset
	,SalesTaxRemittanceResponsibility
	,AcquisitionLocationTaxAreaId
	,AcquisitionLocationCity
	,AcquisitionLocationMainDivision
	,AcquisitionLocationCountry
	,AssetUsageCondition
	,AssetSerialOrVIN
	,MaturityDate
	,CommencementDate
	,IsSKU
	,AssetSKUId
	,IsExemptAtAssetSKU
	,ReceivableSKUId
	,ROW_NUMBER() OVER(PARTITION BY ReceivableSKUId,ReceivableDetailId,AssetSKUId,AssetId ORDER BY ReceivableSKUId,ReceivableDetailId,AssetSKUId,AssetId) RowNumber
	,UpfrontTaxAssessedInLegacySystem
FROM #VertexWSTransactions)AS VertexReceivableDetails
WHERE VertexReceivableDetails.RowNumber = 1
ORDER BY DueDate

END

GO

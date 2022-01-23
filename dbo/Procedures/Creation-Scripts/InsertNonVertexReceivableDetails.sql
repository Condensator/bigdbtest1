SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InsertNonVertexReceivableDetails]
(
@CustomerEntityType NVarChar(10),
@URTaxBasisTypeName NVARCHAR(100),
@STTaxBasisTypeName NVARCHAR(100),
@UCTaxBasisTypeName NVARCHAR(100),
@CapitalLeaseRentalReceivableType NVARCHAR(100),
@OperatingLeaseRentalReceivableType NVARCHAR(100),
@LeaseInterimInterestReceivableType NVARCHAR(100),
@JobStepInstanceId BIGINT,
@DiscountingEntityType NVarChar(10),
@AssessCapitalizedUpfrontTaxAtInception	BIT,
@TaxRemittancePreferenceValues_Cash NVARCHAR(10),
@CPIBaseRentalReceivableType		NVARCHAR(100)
)
AS
BEGIN
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CommencementDate],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT [ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedRealAsset],[IsCapitalizedSalesTaxAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CommencementDate],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased] FROM
(
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.GLTemplateId
,RD.LegalEntityId
,SRT.TaxTypeId
,RD.ReceivableDueDate
,RD.AssetId
,SNL.LocationId
,RD.AssetLocationId
,RD.ExtendedPrice
,0 AS FairMarketValue
,0 AS AssetCost
,RD.Currency
,SNL.UpfrontTaxMode
,SNL.StateShortName
,PL.StateShortName PreviousStateShortName
,0 AS IsUpFrontApplicable
,SCU.ClassCode
,SNL.JurisdictionId
,TaxBasisType = CASE WHEN ((SNL.TaxBasisType = @UCTaxBasisTypeName AND SRT.TaxReceivableName  = @LeaseInterimInterestReceivableType)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName AND SRT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
AND SRT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
OR
(SRT.IsRental = 0)
OR RD.IsRenewal = 1)
THEN @STTaxBasisTypeName
ELSE SNL.TaxBasisType
END
,CASE WHEN SNA.StateTaxTypeId IS NULL THEN SRT.TaxTypeId ELSE SNA.StateTaxTypeId END AS StateTaxTypeId
,CASE WHEN SNA.CountyTaxTypeId IS NULL THEN SRT.TaxTypeId ELSE SNA.CountyTaxTypeId END AS CountyTaxTypeId
,CASE WHEN SNA.CityTaxTypeId	 IS NULL THEN SRT.TaxTypeId ELSE SNA.CityTaxTypeId END AS CityTaxTypeId
,RD.IsExemptAtSundry
,SA.IsExemptAtAsset
,IsPrepaidUpfrontTax = CASE WHEN ((SNL.TaxBasisType = @STTaxBasisTypeName)
OR
(SRT.IsRental = 0)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SRT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
AND SRT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND (SRT.TaxReceivableName = @LeaseInterimInterestReceivableType
OR SRT.TaxReceivableName = @CPIBaseRentalReceivableType))
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SNL.TaxBasisType <> SA.OriginalTaxBasisType)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SNL.TaxBasisType <> SA.OriginalTaxBasisType)
) THEN
CAST(0 AS BIT)
ELSE
SA.IsPrepaidUpfrontTax
END
,IsCapitalizedRealAsset = CASE WHEN ((SNL.TaxBasisType = @STTaxBasisTypeName)
OR
(SRT.IsRental = 0)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SRT.TaxReceivableName <> @CapitalLeaseRentalReceivableType
AND SRT.TaxReceivableName <> @OperatingLeaseRentalReceivableType)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND (SRT.TaxReceivableName = @LeaseInterimInterestReceivableType
OR SRT.TaxReceivableName = @CPIBaseRentalReceivableType))
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SNL.TaxBasisType <> SA.OriginalTaxBasisType)
OR
(SNL.TaxBasisType = @URTaxBasisTypeName
AND SNL.TaxBasisType <> SA.OriginalTaxBasisType)
) THEN
CAST(0 AS BIT)
ELSE
SLD.IsContractCapitalizeUpfront
END
,SA.IsCapitalizedSalesTaxAsset
,SRT.IsExemptAtReceivableCode
,@JobStepInstanceId JobStepInstanceId
,0 IsCapitalizedFirstRealAsset
,SLD.CommencementDate
,SNL.CountryShortName
,CASE WHEN SNA.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND SNA.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN SNA.PreviousSalesTaxRemittanceResponsibility ELSE  SNA.SalesTaxRemittanceResponsibility END AS SalesTaxRemittanceResponsibility
,CASE WHEN SLD.SalesTaxRemittanceMethod = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END AS IsCashBased
,ROW_NUMBER() OVER(PARTITION BY RD.ReceivableDetailId,RD.AssetId ORDER BY RD.ReceivableDetailId,RD.AssetId) RowNumber
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract SCU ON RD.CustomerId = SCU.CustomerId AND SCU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLeaseDetailExtract SLD ON RD.ContractId = SLD.ContractId AND SLD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN SalesTaxAssetDetailExtract SA ON RD.AssetId = SA.AssetId AND RD.ContractId = SA.ContractId AND SA.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexAssetDetailExtract SNA ON RD.AssetId = SNA.AssetId AND RD.ContractId = SNA.ContractId AND SNA.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract SNL ON  RD.LocationId = SNL.LocationId AND SNL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract SRT ON RD.ReceivableCodeId = SRT.ReceivableCodeId AND SNL.StateId = SRT.StateId AND SRT.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN SalesTaxLocationDetailExtract PL ON RD.PreviousLocationId = PL.LocationId AND PL.JobStepInstanceId = RD.JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL AND RD. JobStepInstanceId = @JobStepInstanceId) AS NonVertexReceivableDetails
WHERE NonVertexReceivableDetails.RowNumber = 1;

UPDATE RD
SET FairMarketValue = URD.FairMarketValue,   IsUpFrontApplicable = 1,
IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN
CAST(1 AS BIT)
ELSE
CAST(0 AS BIT)
END,
ReceivableDueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.ReceivableDueDate END
FROM NonVertexReceivableDetailExtract RD
INNER JOIN NonVertexUpfrontRentalDetailExtract URD ON RD.ReceivableDetailId = URD.ReceivableDetailId
AND RD.AssetId = URD.AssetId AND URD.JobStepInstanceId = RD.JobStepInstanceId AND RD.JobStepInstanceId = @JobStepInstanceId;
UPDATE RD
SET AssetCost = UCD.AssetCost, IsUpFrontApplicable = 1,
IsCapitalizedFirstRealAsset = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN
CAST(1 AS BIT)
ELSE
CAST(0 AS BIT)
END,
ReceivableDueDate = CASE WHEN RD.IsCapitalizedRealAsset = 1 THEN RD.CommencementDate ELSE RD.ReceivableDueDate END
FROM NonVertexReceivableDetailExtract RD INNER JOIN NonVertexUpfrontCostDetailExtract UCD ON RD.ReceivableDetailId =UCD.ReceivableDetailId
AND RD.AssetId = UCD.AssetId AND UCD.JobStepInstanceId = RD.JobStepInstanceId AND RD.JobStepInstanceId =  @JobStepInstanceId;
IF(@AssessCapitalizedUpfrontTaxAtInception = 1)
BEGIN
DELETE FROM NonVertexReceivableDetailExtract WHERE IsUpFrontApplicable = 0
END
ELSE
BEGIN
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedSalesTaxAsset],[IsCapitalizedRealAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT
ReceivableId = RD.ReceivableId,
ReceivableDetailId = RD.ReceivableDetailId,
RD.GLTemplateId,
RD.LegalEntityId,
RC.TaxTypeId,
RD.ReceivableDueDate,
RD.AssetId,
L.LocationId,
RD.AssetLocationId,
RD.ExtendedPrice,
FairMarketValue = CAST(0.00 AS DECIMAL(16,2)),
AssetCost = CAST(0.00 AS DECIMAL(16,2)),
RD.Currency,
L.UpFrontTaxMode,
L.StateShortName,
NULL,
CAST(0 AS BIT) IsUpFrontApplicable,
CU.ClassCode,
L.JurisdictionId AS JurisdictionId,
TaxBasisType = @STTaxBasisTypeName,
RC.TaxTypeId AS StateTaxTypeId,
RC.TaxTypeId AS CountyTaxTypeId,
RC.TaxTypeId AS CityTaxTypeId,
RD.IsExemptAtSundry,
CAST(0 AS BIT) AS IsExemptAtAsset,
CAST(0 AS BIT) AS IsPrepaidUpfrontTax,
CAST(0 AS BIT) AS IsCapitalizedSalesTaxAsset,
CAST(0 AS BIT) AS IsCapitalizedRealAsset,
RC.IsExemptAtReceivableCode,
@JobStepInstanceId ,
0,
L.CountryShortName,
'_',
CASE WHEN LD.SalesTaxRemittanceMethod = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract CU ON RD.CustomerId = CU.CustomerId AND CU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLeaseDetailExtract LD ON RD.ContractId = LD.ContractId AND LD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract L ON RD.LocationId = L.LocationId AND L.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract RC ON RD.ReceivableCodeId = RC.ReceivableCodeId AND L.StateId = RC.StateId AND RC.JobStepInstanceId = @JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL AND RD.AssetId IS NULL AND LD.IsLease = 1 AND RD.JobStepInstanceId = @JobStepInstanceId
;
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedSalesTaxAsset],[IsCapitalizedRealAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.GLTemplateId
,RD.LegalEntityId
,SRT.TaxTypeId
,RD.ReceivableDueDate
,RD.AssetId
,SNL.LocationId
,RD.AssetLocationId
,RD.ExtendedPrice
,0 AS FairMarketValue
,0 AS AssetCost
,RD.Currency
,SNL.UpfrontTaxMode
,SNL.StateShortName
,NULL
,0 AS  IsUpFrontApplicable
,SCU.ClassCode
,SNL.JurisdictionId
,@STTaxBasisTypeName
,SRT.TaxTypeId AS StateTaxTypeId
,SRT.TaxTypeId AS CountyTaxTypeId
,SRT.TaxTypeId AS CityTaxTypeId
,RD.IsExemptAtSundry
,0 AS IsExemptAtAsset
,0 AS IsPrepaidUpfrontTax
,0 AS IsCapitalizedSalesTaxAsset
,0 AS IsCapitalizedRealAsset
,SRT.IsExemptAtReceivableCode
,@JobStepInstanceId
,0
,SNL.CountryShortName
,'_'
,CASE WHEN RD.LegalEntityTaxRemittancePreference = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract SCU ON RD.CustomerId = SCU.CustomerId AND SCU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract SNL ON RD.LocationId = SNL.LocationId AND SNL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract SRT ON RD.ReceivableCodeId = SRT.ReceivableCodeId  AND SNL.StateId = SRT.StateId AND SRT.JobStepInstanceId = @JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL  AND RD.ContractId IS NULL
AND RD.EntityType = @CustomerEntityType AND RD.JobStepInstanceId = @JobStepInstanceId
AND RD.AssetId IS NULL;
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedSalesTaxAsset],[IsCapitalizedRealAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.GLTemplateId
,RD.LegalEntityId
,SRT.TaxTypeId
,RD.ReceivableDueDate
,RD.AssetId
,SNL.LocationId
,RD.AssetLocationId
,RD.ExtendedPrice
,0 AS FairMarketValue
,0 AS AssetCost
,RD.Currency
,SNL.UpfrontTaxMode
,SNL.StateShortName
,NULL
,0 AS  IsUpFrontApplicable
,SCU.ClassCode
,SNL.JurisdictionId
,@STTaxBasisTypeName
,SRT.TaxTypeId AS StateTaxTypeId
,SRT.TaxTypeId AS CountyTaxTypeId
,SRT.TaxTypeId AS CityTaxTypeId
,RD.IsExemptAtSundry
,0 AS IsExemptAtAsset
,0 AS IsPrepaidUpfrontTax
,0 AS IsCapitalizedSalesTaxAsset
,0 AS IsCapitalizedRealAsset
,SRT.IsExemptAtReceivableCode
,@JobStepInstanceId
,0
,SNL.CountryShortName
,'_'
,CASE WHEN RD.LegalEntityTaxRemittancePreference = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract SCU ON RD.CustomerId = SCU.CustomerId AND SCU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract SNL ON RD.LocationId = SNL.LocationId AND SNL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract SRT ON RD.ReceivableCodeId = SRT.ReceivableCodeId  AND SNL.StateId = SRT.StateId AND SRT.JobStepInstanceId = @JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL  AND RD.ContractId IS NULL
AND RD.EntityType = @DiscountingEntityType AND RD.DiscountingId IS NOT NULL AND RD.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedSalesTaxAsset],[IsCapitalizedRealAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.GLTemplateId
,RD.LegalEntityId
,SRT.TaxTypeId
,RD.ReceivableDueDate
,RD.AssetId
,SNL.LocationId
,RD.AssetLocationId
,RD.ExtendedPrice
,0 AS FairMarketValue
,0 AS AssetCost
,RD.Currency
,SNL.UpfrontTaxMode
,SNL.StateShortName
,PL.StateShortName
,0 AS IsUpFrontApplicable
,SCU.ClassCode
,SNL.JurisdictionId AS JurisdictionId
,SNL.TaxBasisType AS  TaxBasisType
,CASE WHEN SNA.StateTaxTypeId IS NULL THEN SRT.TaxTypeId ELSE SNA.StateTaxTypeId END
,CASE WHEN SNA.CountyTaxTypeId IS NULL THEN SRT.TaxTypeId ELSE SNA.CountyTaxTypeId END
,CASE WHEN SNA.CityTaxTypeId	 IS NULL THEN SRT.TaxTypeId ELSE SNA.CityTaxTypeId END
,RD.IsExemptAtSundry
,SA.IsExemptAtAsset
,SA.IsPrepaidUpfrontTax
,SA.IsCapitalizedSalesTaxAsset
,0 AS IsCapitalizedRealAsset
,SRT.IsExemptAtReceivableCode
,@JobStepInstanceId
,0
,SNL.CountryShortName
,CASE WHEN SNA.PreviousSalesTaxRemittanceResponsibility IS NOT NULL AND SNA.PreviousSalesTaxRemittanceResponsibilityEffectiveTillDate >= RD.ReceivableDueDate THEN SNA.PreviousSalesTaxRemittanceResponsibility ELSE  SNA.SalesTaxRemittanceResponsibility END
,CASE WHEN RD.LegalEntityTaxRemittancePreference = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract SCU ON RD.CustomerId = SCU.CustomerId AND SCU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN SalesTaxAssetDetailExtract SA ON RD.AssetId = SA.AssetId  AND RD.EntityType = @CustomerEntityType AND SA.JobStepInstanceId = @JobStepInstanceId AND SA.ContractId Is NULL
INNER JOIN NonVertexAssetDetailExtract SNA ON RD.AssetId = SNA.AssetId AND RD.EntityType = @CustomerEntityType AND SNA.JobStepInstanceId = @JobStepInstanceId AND SNA.ContractId Is NULL
INNER JOIN NonVertexLocationDetailExtract SNL ON RD.LocationId = SNL.LocationId AND SNL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract SRT ON RD.ReceivableCodeId = SRT.ReceivableCodeId  AND SNL.StateId = SRT.StateId AND SRT.JobStepInstanceId = @JobStepInstanceId
LEFT JOIN SalesTaxLocationDetailExtract PL ON RD.PreviousLocationId = PL.LocationId AND PL.JobStepInstanceId = RD.JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL AND RD.JobStepInstanceId = @JobStepInstanceId;
INSERT INTO NonVertexReceivableDetailExtract([ReceivableId],[ReceivableDetailId],[GLTemplateId],[LegalEntityId],[TaxTypeId],[ReceivableDueDate],[AssetId],[LocationId],
[AssetLocationId],[ExtendedPrice],[FairMarketValue],[AssetCost],[Currency],[UpFrontTaxMode],[StateShortName],[PreviousStateShortName],[IsUpFrontApplicable],[ClassCode],[JurisdictionId],[TaxBasisType],[StateTaxTypeId],[CountyTaxTypeId],
[CityTaxTypeId],[IsExemptAtSundry],[IsExemptAtAsset],[IsPrepaidUpfrontTax],[IsCapitalizedSalesTaxAsset],[IsCapitalizedRealAsset],
[IsExemptAtReceivableCode],[JobStepInstanceId],[IsCapitalizedFirstRealAsset],[CountryShortName],[SalesTaxRemittanceResponsibility],[IsCashBased])
SELECT
RD.ReceivableId
,RD.ReceivableDetailId
,RD.GLTemplateId
,RD.LegalEntityId
,SRT.TaxTypeId
,RD.ReceivableDueDate
,RD.AssetId
,SNL.LocationId
,RD.AssetLocationId
,RD.ExtendedPrice
,0 AS FairMarketValue
,0 AS AssetCost
,RD.Currency
,SNL.UpfrontTaxMode
,SNL.StateShortName
,NULL
,0 AS IsUpFrontApplicable
,SCU.ClassCode
,SNL.JurisdictionId
,@STTaxBasisTypeName
,SRT.TaxTypeId AS StateTaxTypeId
,SRT.TaxTypeId AS CountyTaxTypeId
,SRT.TaxTypeId AS CityTaxTypeId
,RD.IsExemptAtSundry
,0 AS  IsExemptAtAsset
,0 AS IsPrepaidUpfrontTax
,0 AS IsCapitalizedSalesTaxAsset
,0 AS IsCapitalizedRealAsset
,SRT.IsExemptAtReceivableCode
,@JobStepInstanceId
,0
,SNL.CountryShortName
,'_'
,CASE WHEN SLD.SalesTaxRemittanceMethod = @TaxRemittancePreferenceValues_Cash THEN 1 ELSE 0 END
FROM SalesTaxReceivableDetailExtract RD
INNER JOIN NonVertexCustomerDetailExtract SCU ON RD.CustomerId = SCU.CustomerId AND SCU.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLeaseDetailExtract SLD ON RD.ContractId = SLD.ContractId AND SLD.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexLocationDetailExtract SNL ON RD.LocationId = SNL.LocationId AND SNL.JobStepInstanceId = @JobStepInstanceId
INNER JOIN NonVertexReceivableCodeDetailExtract SRT ON RD.ReceivableCodeId = SRT.ReceivableCodeId  AND SNL.StateId = SRT.StateId AND SRT.JobStepInstanceId = @JobStepInstanceId
WHERE RD.IsVertexSupported = 0 AND RD.InvalidErrorCode IS NULL AND SLD.IsLease =0 AND RD.JobStepInstanceId = @JobStepInstanceId
END
END

GO

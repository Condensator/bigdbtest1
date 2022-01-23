SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROC [dbo].[GetReceivableDetailsForAssetSale]
(
@DueDate DATETIMEOFFSET,
@ReceivableId BIGINT,
@GLConfigurationId BIGINT,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN

DECLARE @TaxSourceTypeVertex NVARCHAR(10);
SET @TaxSourceTypeVertex = 'Vertex';

WITH CTE_AllTaxAreaIdForLocation AS
(
SELECT
ROW_NUMBER() OVER (PARTITION BY p.LocationId ORDER BY CASE WHEN DATEDIFF(DAY,@DueDate, p.TaxAreaEffectiveDate) = 0 THEN 0 ELSE 1 END,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END DESC,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END ASC) Row_Num,
P.TaxAreaEffectiveDate,
P.TaxAreaId,
P.LocationId,
LienCredit_Amount = 0.0,
LienCredit_Currency = R.TotalAmount_Currency,
ReciprocityAmount_Amount = 0.0,
ReciprocityAmount_Currency = R.TotalAmount_Currency,
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) < 0 THEN TaxAreaEffectiveDate END AS [negative],
CASE WHEN DATEDIFF(DAY, @DueDate, p.TaxAreaEffectiveDate) > 0 THEN TaxAreaEffectiveDate END AS [positive]
FROM LocationTaxAreaHistories P
INNER JOIN Receivables R ON R.LocationId = P.LocationId
INNER JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id
WHERE R.Id = @ReceivableId
),
CTE_TaxAreaId AS
(
SELECT *
FROM CTE_AllTaxAreaIdForLocation
WHERE Row_Num = 1
)
,CTE_FromTaxAreaId AS
(
SELECT *
FROM CTE_AllTaxAreaIdForLocation
WHERE Row_Num = 2
),
CTE_AssetSerialNumberDetails AS(
SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
FROM AssetSerialNumbers ASN 
INNER JOIN ReceivableDetails RD on RD.AssetId =  ASN.AssetId
INNER JOIN Receivables R ON RD.ReceivableId = R.Id
WHERE ASN.IsActive = 1  AND R.Id= @ReceivableId AND RD.IsActive = 1 AND RD.IsTaxAssessed = 0
GROUP BY ASN.AssetId
)
SELECT

	RD.Id 'ReceivableDetailId'
	,RD.ReceivableId 'ReceivableId'
	,R.DueDate 'DueDate'
	,RT.IsRental 'IsRental'
	,CASE WHEN (RT.IsRental = 1) THEN ACC.ClassCode ELSE RT.Name END AS Product
	,RD.Amount_Amount AS 'FairMarketValue'
	,0.00 AS 'Cost'
	,0.00 AS 'AmountBilledToDate'
	,RD.Amount_Amount 'ExtendedPrice'
	,RD.Amount_Currency 'Currency'

	,CONVERT(BIT,1) 'IsAssetBased'
	,CONVERT(BIT,0) AS'IsLeaseBased'
	,CASE WHEN country.TaxSourceType=@TaxSourceTypeVertex AND TAID.TaxAreaId IS NOT NULL THEN CASE WHEN CONVERT(BIT,1) IN (A.IsTaxExempt) THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END ELSE CONVERT(BIT,0) END AS 'IsExemptAtAsset'
	,CASE WHEN country.TaxSourceType=@TaxSourceTypeVertex AND TAID.TaxAreaId IS NOT NULL THEN CASE WHEN (CC.Class = 'Exempt') THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END ELSE CONVERT(BIT,0) END AS 'IsExemptAtBuyer'
	,CASE WHEN country.TaxSourceType=@TaxSourceTypeVertex AND TAID.TaxAreaId IS NOT NULL THEN CASE WHEN CONVERT(BIT,1) IN (RC.IsTaxExempt) THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END ELSE CONVERT(BIT,0) END AS 'IsExemptAtReceivableCode'
	,CASE WHEN AssetRule.IsCountryTaxExempt=1 THEN 'AssetTaxExemptRule' ELSE CASE WHEN LocationRule.IsCountryTaxExempt=1 THEN 'LocationTaxExemptRule' ELSE CASE WHEN ISNULL(ReceivableCodeRule.IsCountryTaxExempt,0) = 1 THEN 'ReceivableCodeTaxExemptRule' ELSE '' END END END CountryTaxExemptRule
	,CASE WHEN AssetRule.IsStateTaxExempt=1 THEN 'AssetTaxExemptRule' ELSE CASE WHEN LocationRule.IsStateTaxExempt=1 THEN 'LocationTaxExemptRule' ELSE CASE WHEN ISNULL(ReceivableCodeRule.IsStateTaxExempt,0) = 1 THEN 'ReceivableCodeTaxExemptRule' ELSE '' END END END StateTaxExemptRule
	,CASE WHEN AssetRule.IsCityTaxExempt=1 THEN 'AssetTaxExemptRule' ELSE CASE WHEN LocationRule.IsCityTaxExempt=1 THEN 'LocationTaxExemptRule' ELSE CASE WHEN ISNULL(ReceivableCodeRule.IsCityTaxExempt,0) = 1 THEN 'ReceivableCodeTaxExemptRule' ELSE '' END END END  CityTaxExemptRule
	,CASE WHEN AssetRule.IsCountyTaxExempt=1 THEN 'AssetTaxExemptRule' ELSE CASE WHEN LocationRule.IsCountyTaxExempt=1 THEN 'LocationTaxExemptRule' ELSE CASE WHEN ISNULL(ReceivableCodeRule.IsCountyTaxExempt,0) = 1 THEN 'ReceivableCodeTaxExemptRule' ELSE '' END END END  CountyTaxExemptRule


	,CASE WHEN (RT.Name = 'BuyOut' OR RT.Name = 'AssetSale') THEN 'SALE' ELSE 'LEASE' END AS 'TransactionType'
	,LE.TaxPayer AS 'Company'
	,P.PartyNumber AS 'CustomerCode'
	,C.Id  AS 'CustomerId'
	,CC.Class  'ClassCode'

	,R.LocationId 'LocationId'
	,ST.ShortName 'MainDivision'
	,country.ShortName 'Country'
	,L.City 'City'
	,L.ApprovalStatus 'LocationStatus'
	,L.IsActive 'IsLocationActive'
	,TAID.TaxAreaId 'TaxAreaId'
	,TAID.TaxAreaEffectiveDate 'TaxAreaEffectiveDate'

	,R.EntityId 'ContractId'
	,NULL 'RentAccrualStartDate'

	,0.0 AS 'CustomerCost'
	--,CASE WHEN (LF.IsSalesTaxExempt = 1) THEN CONVERT(BIT,1) ELSE CONVERT(BIT,0) END AS 'IsExemptAtLease'
	,0.0 AS 'LessorRisk'
	,NULL AS 'AssetLocationId'
	,CONVERT(BIT,0) 'IsExemptAtSundry'
	,NULL AS ReceivableTaxId
	,RC.Id ReceivableCodeId

	--flex fields
	,CASE WHEN RT.IsRental = 1 THEN 'FMV' ELSE '' END 'ContractType' -- Future update : FMV or CSC
	,NULL  'LeaseUniqueId'
	,CASE WHEN (RT.IsRental = 1) THEN '' ELSE RC.Name END 'SundryReceivableCode'
	,ACC.ClassCode 'AssetType'
	--,CONVERT(BIT,0) 'IsPurchaseLeaseBack'
	,NULL 'LeaseType'
	,0.00 'LeaseTerm'
	--,NULL AS 'InstallDate'
	,TTC.TransferCode AS 'TitleTransferCode'
	,L.TaxAreaVerifiedTillDate AS 'LocationEffectiveDate'
	,RT.Name 'ReceivableType'
	,LE.Id 'LegalEntityId'
	,CAST(CASE WHEN country.TaxSourceType = @TaxSourceTypeVertex THEN 1 ELSE 0 END AS BIT) 'IsVertexSupportedLocation'
	,L.JurisdictionId TaxJurisdictionId
	,RC.ReceivableTypeId

	 --User Defined Flex Fields
	,ToState.ShortName ToState
	,FromState.ShortName FromState
	,CASE WHEN (TAID.LienCredit_Amount Is NULL) THEN 0.00 ELSE TAID.LienCredit_Amount END 'LienCredit_Amount'
	,CASE WHEN (TAID.LienCredit_Currency Is NULL) THEN RD.Amount_Currency ELSE TAID.LienCredit_Currency END 'LienCredit_Currency'
	,CASE WHEN (TAID.ReciprocityAmount_Amount Is NULL ) THEN 0.00 ELSE TAID.ReciprocityAmount_Amount END 'ReciprocityAmount_Amount'
	,CASE WHEN (TAID.ReciprocityAmount_Currency Is NULL) THEN RD.Amount_Currency ELSE TAID.ReciprocityAmount_Currency END 'ReciprocityAmount_Currency'
	,RD.AssetId 'AssetId'
	,CAST(0.00 as DECIMAL(16,2)) AS HorsePower
	,AC.CollateralCode AS AssetCatalogNumber
	,CAST(NULL AS NVARCHAR) AS EngineType
	,STEL.Name SalesTaxExemptionLevel
	,DTTFRT.TaxTypeId
	,ST.Id StateId
	,CASE WHEN AssetRule.IsCountryTaxExempt=1 THEN AssetRule.IsCountryTaxExempt ELSE CASE WHEN LocationRule.IsCountryTaxExempt=1 THEN LocationRule.IsCountryTaxExempt ELSE IsNULL(ReceivableCodeRule.IsCountryTaxExempt,0)END END  CountryTaxExempt
	,CASE WHEN AssetRule.IsStateTaxExempt=1 THEN AssetRule.IsStateTaxExempt ELSE CASE WHEN LocationRule.IsStateTaxExempt=1 THEN LocationRule.IsStateTaxExempt ELSE IsNULL(ReceivableCodeRule.IsStateTaxExempt,0) END END  StateTaxExempt
	,CASE WHEN AssetRule.IsCityTaxExempt=1 THEN AssetRule.IsCityTaxExempt ELSE CASE WHEN LocationRule.IsCityTaxExempt=1 THEN LocationRule.IsCityTaxExempt ELSE IsNULL(ReceivableCodeRule.IsCityTaxExempt,0) END END  CityTaxExempt
	,CASE WHEN AssetRule.IsCountyTaxExempt=1 THEN AssetRule.IsCountyTaxExempt ELSE CASE WHEN LocationRule.IsCountyTaxExempt=1 THEN LocationRule.IsCountyTaxExempt ELSE ISNULL (ReceivableCodeRule.IsCountyTaxExempt,0) END END CountyTaxExempt
	,ISNULL(P.VATRegistrationNumber, NULL) AS TaxRegistrationNumber
	,ISNULL(IncorporationCountry.ShortName, NULL) AS ISOCountryCode
	,'ST' AS TaxBasisType
	,'_' AS SalesTaxRemittanceResponsibility
	,'INV' AS TransactionCode
	, glTemplate.Id AS GlTemplateId
	,LA.AcquisitionLocationId
	,ASN.SerialNumber AS AssetSerialOrVIN
	,ISNULL(A.UsageCondition,'_') AS AssetUsageCondition
	,L.Code AS LocationCode
	,A.GrossVehicleWeight
INTO #AssetSaleReceivableDetails
FROM

	Receivables R
	--INNER JOIN @ReceivableIds RId ON R.Id = RId.ReceivableId
	INNER JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id
	INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
	INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id
	INNER JOIN LegalEntities LE ON R.LegalEntityId = LE.Id
	INNER JOIN Locations L ON R.LocationId = L.Id
	INNER JOIN States ST ON L.StateId = ST.Id
	INNER JOIN Countries country ON ST.CountryId = country.Id
	INNER JOIN Customers C ON R.CustomerId = C.Id
	INNER JOIN Parties P ON C.Id = P.Id
	LEFT JOIN
	(SELECT TOP(1) glTemplate.Id, glTemplate.GLConfigurationId
	FROM GLTransactionTypes glType
	INNER JOIN GLTemplates glTemplate ON glTemplate.GLConfigurationId=@GLConfigurationId AND glTemplate.IsActive = 1 AND glTemplate.GLTransactionTypeId = glType.Id
	WHERE glType.Name = 'SalesTax') AS glTemplate ON LE.GLConfigurationId = glTemplate.GLConfigurationId
	LEFT JOIN States StateOfIncorporation ON P.StateOfIncorporationId = StateOfIncorporation.Id
	LEFT JOIN Countries IncorporationCountry ON StateOfIncorporation.CountryId = IncorporationCountry.Id
	LEFT JOIN dbo.DefaultTaxTypeForReceivableTypes DTTFRT ON RT.Id = DTTFRT.ReceivableTypeId AND country.Id = DTTFRT.CountryId
	LEFT JOIN CustomerClasses CC ON C.CustomerClassId = CC.Id
	LEFT JOIN Assets A ON RD.AssetId = A.Id
	LEFT JOIN AssetTypes AT ON AT.Id = A.TypeId
	LEFT JOIN AssetCatalogs AC ON A.AssetCatalogId = AC.Id
	LEFT JOIN AssetClassCodes ACC ON AT.AssetClassCodeId = ACC.Id
	LEFT JOIN TitleTransferCodes TTC ON A.TitleTransferCodeId = TTC.Id
	LEFT JOIN CTE_TaxAreaId TAID ON R.LocationId = TAID.LocationId
	LEFT JOIN Locations ToLocation ON TAID.LocationId = ToLocation.Id
	LEFT JOIN States ToState ON ToLocation.StateId = ToState.Id
	LEFT JOIN SalesTaxExemptionLevelConfigs STEL ON A.SalesTaxExemptionLevelId = STEL.Id
	LEFT JOIN CTE_FromTaxAreaId FromTAID ON R.LocationId = FromTAID.LocationId
	LEFT JOIN Locations FromLocation ON FromTAID.LocationId = FromLocation.Id
	LEFT JOIN States FromState ON FromLocation.StateId = FromState.Id
	LEFT JOIN TaxExemptRules AssetRule ON a.TaxExemptRuleId = AssetRule.Id
	LEFT JOIN TaxExemptRules BuyerRule ON C.TaxExemptRuleId = BuyerRule.Id
	LEFT JOIN TaxExemptRules LocationRule ON L.TaxExemptRuleId = LocationRule.Id
	LEFT JOIN ReceivableCodeTaxExemptRules rct ON RC.Id = rct.ReceivableCodeId AND ST.Id = rct.StateId AND rct.IsActive=1
    LEFT JOIN TaxExemptRules ReceivableCodeRule ON rct.TaxExemptRuleId = ReceivableCodeRule.Id
	LEFT JOIN Contracts Co ON R.EntityId = Co.Id AND R.EntityType = 'CT'
	LEFT JOIN LeaseFinances LF ON LF.ContractId = co.Id AND LF.IsCurrent = 1
	LEFT JOIN LeaseFinanceDetails LFD ON LFD.Id = LF.Id
	LEFT JOIN LoanFinances Loan ON Loan.ContractId = Co.Id AND Loan.IsCurrent = 1
	LEFT JOIN LeaseAssets LA ON LA.AssetId = A.Id AND LA.LeaseFinanceId = LF.Id AND (LA.IsActive = 1 OR (LA.IsActive = 0 AND LA.TerminationDate IS NOT NULL))
	LEFT JOIN TaxExemptRules ContractRule ON LF.TaxExemptRuleId = ContractRule.Id
	LEFT JOIN CTE_AssetSerialNumberDetails ASN ON A.Id =  ASN.AssetId 
WHERE RD.IsActive = 1 AND RD.IsTaxAssessed = 0 AND R.Id = @ReceivableId
;WITH CTE_AcquisitionLocationDetails
AS
(
SELECT DISTINCT L.Id AS AcquisitionLocationId,
L.TaxAreaId AS AcquisitionLocationTaxAreaId,
L.City AS AcquisitionLocationCity,
S.ShortName AS AcquisitionLocationMainDivision,
C.ShortName AS AcquisitionLocationCountry,
RD.ReceivableDetailId AS ReceivableDetailId
FROM #AssetSaleReceivableDetails RD
JOIN Locations L ON RD.AcquisitionLocationId = L.Id
JOIN States S ON L.StateId = S.Id
JOIN Countries C ON C.Id = S.CountryId
WHERE L.TaxAreaId IS NOT NULL AND L.JurisdictionId IS NULL
)
SELECT	RD.*,
AD.AcquisitionLocationTaxAreaId,
AD.AcquisitionLocationCity,
AD.AcquisitionLocationMainDivision,
AD.AcquisitionLocationCountry,
ROW_NUMBER() OVER (ORDER BY RD.ReceivableDetailId) as LineItemNumber
FROM  #AssetSaleReceivableDetails RD
LEFT JOIN CTE_AcquisitionLocationDetails AD ON RD.AcquisitionLocationId = AD.AcquisitionLocationId AND AD.ReceivableDetailId = RD.ReceivableDetailId
DROP TABLE #AssetSaleReceivableDetails
END

GO

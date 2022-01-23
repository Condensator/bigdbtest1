SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VP_GetAssetDetails]
(
@CurrentVendorId BIGINT,
@IsProgramVendor BIT,
@IsFromLocationChange BIT = 0,
@ContractAlias NVARCHAR(100) = NULL,
@ExternalReferenceNumber NVARCHAR(100) = NULL,
@CapitalizedSalesTaxAssetTypeValue NVARCHAR(200),
@SerialNumber NVARCHAR(200)=NULL,
@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
CREATE TABLE #InvoiceDetails
(
ContractId BIGINT,
TotalAssetAmount DECIMAL(16,2)
)
;WITH CTE_TotalAssetAmount AS
(
SELECT
Contracts.Id AS InvoiceId
,(PayableInvoiceAssets.AcquisitionCost_Amount+PayableInvoiceAssets.OtherCost_Amount) AS TotalAssetAmount
,PayableInvoiceAssets.Id
FROM Contracts
JOIN PayableInvoices  on PayableInvoices.ContractId = Contracts.Id
JOIN LeaseFinances  on Contracts.Id = LeaseFinances.ContractId	 AND LeaseFinances.IsCurrent = 1
join LeaseFundings  on PayableInvoices.Id = LeaseFundings.FundingId and LeaseFinances.Id = LeaseFundings.LeaseFinanceId
JOIN LeaseAssets  ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
JOIN PayableInvoiceAssets  on PayableInvoiceAssets.AssetId = LeaseAssets.AssetId AND PayableInvoiceAssets.IsActive = 1 and PayableInvoices.Id = PayableInvoiceAssets.PayableInvoiceId
WHERE PayableInvoices.Status != 'Inactive'
GROUP BY
Contracts.Id
,(PayableInvoiceAssets.AcquisitionCost_Amount+PayableInvoiceAssets.OtherCost_Amount)
,PayableInvoiceAssets.Id
)
INSERT INTO #InvoiceDetails
SELECT
InvoiceId
,SUM(TotalAssetAmount) AS TotalAssetAmount
FROM CTE_TotalAssetAmount
GROUP BY
InvoiceId
;
CREATE TABLE #ContractDetails
(
LeaseFinanceId BIGINT,
PaymentAmount DECIMAL(16,2)
)
INSERT INTO #ContractDetails
SELECT
LeaseFinances.Id As LeaseFinanceId,
CASE WHEN LeaseFinances.IsFutureFunding = 0 THEN
SUM(LeaseAssets.Rent_Amount)
ELSE
(SELECT TOP(1) Amount_Amount FROM LeasePaymentSchedules WHERE LeaseFinanceDetailId = LeaseFinances.Id AND IsActive = 1 AND PaymentType = 'FixedTerm' ORDER BY DueDate)
END AS PaymentAmount
FROM Contracts
JOIN LeaseFinances  ON Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
JOIN LeaseAssets  ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
GROUP BY LeaseFinances.Id,LeaseFinances.IsFutureFunding
;
SELECT
LeaseAssets.AssetId,
SUM(PayableInvoiceOtherCosts.Amount_Amount) AS PayableInvoiceOtherCostAmount
INTO #LeasePayableInvoiceOtherCosts
FROM Contracts
JOIN LeaseFinances  on Contracts.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
JOIN LeaseAssets  ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
JOIN PayableInvoices  on PayableInvoices.ContractId = Contracts.Id
JOIN PayableInvoiceAssets  ON PayableInvoices.Id = PayableInvoiceAssets.PayableInvoiceId AND LeaseAssets.AssetId = PayableInvoiceAssets.AssetId
JOIN PayableInvoiceOtherCostDetails  ON PayableInvoiceAssets.Id = PayableInvoiceOtherCostDetails.PayableInvoiceAssetId
JOIN PayableInvoiceOtherCosts  ON PayableInvoiceOtherCosts.Id = PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId
AND PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id AND PayableInvoiceOtherCosts.IsActive = 1
WHERE (PayableInvoiceOtherCosts.AllocationMethod IN ('AssetCost','AssetCount','Specific','SpecificCostAdjustment'))
GROUP BY
LeaseAssets.AssetId
;
SELECT
LeaseAssets.AssetId,
SUM(LeaseAssets.NBV_Amount) CapitalizedAmount
INTO #LeaseCapitalizedTaxAssets
FROM Contracts
JOIN LeaseFinances  on Contracts.Id = LeaseFinances.ContractId  AND LeaseFinances.IsCurrent = 1
JOIN LeaseAssets  ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
JOIN Assets  ON LeaseAssets.AssetId = Assets.Id
JOIN AssetTypes  ON Assets.TypeId = AssetTypes.Id
AND AssetTypes.Name = @CapitalizedSalesTaxAssetTypeValue
GROUP BY
LeaseAssets.AssetId
;
CREATE TABLE #LeaseAssetDetails
(
AssetId BIGINT,
AssetAlias NVARCHAR(50),
ParentAssetId BIGINT,
PartNumber NVARCHAR(100),
SerialNumber NVARCHAR(100),
Quantity Int  NOT NULL,
UsageCondition NVARCHAR(4),
Description NVARCHAR(500),
Status NVARCHAR(100),
Manufacturer NVARCHAR(100),
AssetType NVARCHAR(100),
LocationCode NVARCHAR(MAX),
LocationCity NVARCHAR(40),
LocationState NVARCHAR(40),
Address NVARCHAR(250),
AssetAmount DECIMAL(16,2),
AssetCurrency NVARCHAR(3),
TotalCost_Amount DECIMAL(16,2),
TotalCost_Currency NVARCHAR(3),
LeasePaymentAmount DECIMAL(16,2),
LeasePaymentCurrency NVARCHAR(3),
AssetPaymentAmount DECIMAL(16,2),
AssetPaymentCurrency NVARCHAR(3),
InvoiceNumber NVARCHAR(40),
CustomerName NVARCHAR(Max),
CustomerNumber NVARCHAR(Max),
ProgramVendor NVARCHAR(100),
VendorId BIGINT,
ContractSequenceNumber NVARCHAR(MAX),
ContractId BIGINT,
ContractType NVARCHAR(MAX),
CustomerPurchaseOrderNumber NVARCHAR(MAX),
ModelYear DECIMAL(4,0),
EffectiveFromDate DATE,
PayableInvoiceVendor NVARCHAR(100),
CreditApplicatioNumber NVARCHAR(MAX),
UDF1Value NVARCHAR(100),
UDF2Value NVARCHAR(100),
UDF3Value NVARCHAR(100),
UDF4Value NVARCHAR(100),
UDF5Value NVARCHAR(100),
UDF1Label NVARCHAR(100),
UDF2Label NVARCHAR(100),
UDF3Label NVARCHAR(100),
UDF4Label NVARCHAR(100),
UDF5Label NVARCHAR(100),
DoingBusinessAs	NVARCHAR(200),
AssetCostAdjustmentAmount DECIMAL(16,2),
AddressLine1 NVARCHAR(100),
AddressLine2 NVARCHAR(100),
City NVARCHAR(50),
PostalCode NVARCHAR(100),
StateShortName NVARCHAR(100),
BookedResidual_Amount DECIMAL(16,2),
BookedResidual_Currency NVARCHAR(50),
Term DECIMAL(10,6),
ExternalReferenceNumber NVARCHAR(100),
ContractAlias NVARCHAR(100)
)
INSERT INTO #LeaseAssetDetails
SELECT DISTINCT
Assets.Id AS AssetId,
Assets.Alias AS AssetAlias,
Assets.ParentAssetId AS ParentAssetId,
Assets.PartNumber AS PartNumber,
null AS SerialNumber,
Assets.Quantity as Quantity,
Assets.UsageCondition AS UsageCondition,
Assets.Description AS Description,
Assets.Status AS Status,
Manufacturers.Name AS Manufacturer,
AssetTypes.Name AS AssetType,
Locations.Code AS LocationCode,
Locations.City AS LocationCity,
States.ShortName AS LocationState,
Locations.AddressLine1 + ','+Locations.AddressLine2+ ','+ Locations.City+ ','+States.ShortName+ ','+Countries.LongName AS Address,
PayableInvoiceAssets.AcquisitionCost_Amount AS AssetAmount,
PayableInvoiceAssets.AcquisitionCost_Currency AS AssetCurrency,
invoiceDetail.TotalAssetAmount AS TotalCost_Amount,
PayableInvoiceAssets.AcquisitionCost_Currency AS TotalCost_Currency,
contractDetails.PaymentAmount AS LeasePaymentAmount,
LeaseAssets.Rent_Currency AS LeasePaymentCurrency,
LeaseAssets.Rent_Amount AS AssetPaymentAmount,
LeaseAssets.Rent_Currency AS AssetPaymentCurrency,
payableInvoice.InvoiceNumber AS InvoiceNumber,
Parties.PartyName AS CustomerName,
Parties.PartyNumber  AS CustomerNumber,
(CASE WHEN @IsProgramVendor = 1 THEN NULL ELSE originParty.PartyName END) AS ProgramVendor,
PayableInvoices.VendorId,
contract.SequenceNumber AS ContractSequenceNumber,
contract.Id AS ContractId,
contract.ContractType AS ContractType,
Assets.CustomerPurchaseOrderNumber AS CustomerPurchaseOrderNumber,
Assets.ModelYear AS ModelYear,
AssetLocations.EffectiveFromDate AS EffectiveFromDate,
pivendor.PartyName As PayableInvoiceVendor,
Opp.Number AS CreditApplicatioNumber,
UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Parties.DoingBusinessAs
,ISNULL((ISNULL(PIOC.PayableInvoiceOtherCostAmount,0.00) + ISNULL(CTA.CapitalizedAmount,0.00)),0.00) AssetCostAdjustmentAmount
,Locations.AddressLine1
,Locations.AddressLine2
,Locations.City
,Locations.PostalCode
,States.ShortName
,LeaseAssets.BookedResidual_Amount
,LeaseAssets.BookedResidual_Currency
, LeaseFinanceDetails.TermInMonths
,contract.ExternalReferenceNumber
,contract.Alias
FROM Contracts  contract
JOIN LeaseFinances on contract.Id = LeaseFinances.ContractId AND LeaseFinances.IsCurrent = 1
JOIN LeaseFinanceDetails on LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
JOIN PayableInvoices on PayableInvoices.ContractId = contract.Id
JOIN PayableInvoiceAssets on LeaseAssets.AssetId = PayableInvoiceAssets.AssetId AND PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id
JOIN #InvoiceDetails invoiceDetail  on invoiceDetail.ContractId = contract.Id
JOIN Assets on PayableInvoiceAssets.AssetId = Assets.Id
JOIN PayableInvoiceAssets payableInvoiceAsset on LeaseAssets.AssetId = payableInvoiceAsset.AssetId
JOIN PayableInvoices payableInvoice ON PayableInvoiceAssets.PayableInvoiceId = payableInvoice.Id
JOIN AssetTypes on Assets.TypeId = AssetTypes.Id
JOIN Customers ON LeaseFinances.CustomerId = Customers.Id
JOIN Parties ON Parties.Id = Customers.Id
join ContractOriginations on LeaseFinances.ContractOriginationId = ContractOriginations.Id
join OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
JOIN #ContractDetails contractDetails on contractDetails.LeaseFinanceId = LeaseFinances.Id
JOIN Parties originParty ON ContractOriginations.OriginationSourceId = originParty.Id
join Parties pivendor on PayableInvoices.VendorId = pivendor.Id
LEFT JOIN CreditApprovedStructures CPS ON contract.CreditApprovedStructureId = CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
LEFT JOIN CreditApplications CApp ON Opp.Id = CApp.Id
LEFT JOIN Manufacturers ON Assets.ManufacturerId = Manufacturers.Id
LEFT JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
LEFT JOIN Locations ON AssetLocations.LocationId = Locations.Id
LEFT JOIN States ON Locations.StateId = States.Id
LEFT JOIN Countries  ON States.CountryId = Countries.Id
LEFT JOIN UDFs ON Assets.Id = UDFs.AssetId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = 'Vendor'
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = 'Asset'
LEFT JOIN #LeasePayableInvoiceOtherCosts PIOC ON PIOC.AssetId = LeaseAssets.AssetId
LEFT JOIN #LeaseCapitalizedTaxAssets CTA ON CTA.AssetId = LeaseAssets.AssetId
WHERE PayableInvoices.Status != 'Inactive'
AND PayableInvoiceAssets.IsActive = 1 AND LeaseAssets.AssetId=Assets.Id AND LeaseFinances.IsCurrent = 1
AND (
(@IsProgramVendor=1 AND ContractOriginations.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId))
OR
(ContractOriginations.OriginationSourceId = @CurrentVendorId)
)
AND (AssetLocations.IsCurrent = CASE WHEN AssetLocations.id is not null THEN 1 END
OR AssetLocations.IsCurrent IS NULL)
AND OriginationSourceTypes.Name = 'Vendor'
INSERT INTO #LeaseAssetDetails
SELECT DISTINCT
Assets.Id AS AssetId,
Assets.Alias AS AssetAlias,
Assets.ParentAssetId AS ParentAssetId,
Assets.PartNumber AS PartNumber,
null AS SerialNumber,
Assets.Quantity AS Quantity,
Assets.UsageCondition AS UsageCondition,
Assets.Description AS Description,
Assets.Status AS Status,
Manufacturers.Name AS Manufacturer,
AssetTypes.Name AS AssetType,
Locations.Code AS LocationCode,
Locations.City AS LocationCity,
States.ShortName AS LocationState,
Locations.AddressLine1 + ','+Locations.AddressLine2+ ','+ Locations.City+ ','+States.ShortName+ ','+Countries.LongName AS Address,
PayableInvoiceAssets.AcquisitionCost_Amount AS AssetAmount,
PayableInvoiceAssets.AcquisitionCost_Currency AS AssetCurrency,
InvD.TotalAssetAmount AS TotalCost_Amount,
PayableInvoiceAssets.AcquisitionCost_Currency AS TotalCost_Currency,
CD.PaymentAmount AS LeasePaymentAmount,
LeaseAssets.Rent_Currency AS LeasePaymentCurrency,
LeaseAssets.Rent_Amount AS AssetPaymentAmount,
LeaseAssets.Rent_Currency AS AssetPaymentCurrency,
PInv.InvoiceNumber AS InvoiceNumber,
Parties.PartyName AS CustomerName,
Parties.PartyNumber  AS CustomerNumber,
(CASE WHEN @IsProgramVendor = 1 THEN NULL ELSE originParty.PartyName END) AS ProgramVendor,
PayableInvoices.VendorId,
Contracts.SequenceNumber AS ContractSequenceNumber,
Contracts.Id AS ContractId,
Contracts.ContractType AS ContractType,
Assets.CustomerPurchaseOrderNumber AS CustomerPurchaseOrderNumber,
Assets.ModelYear AS ModelYear,
AssetLocations.EffectiveFromDate AS EffectiveFromDate,
pivendor.PartyName as PayableInvoiceVendor,
Opp.Number AS CreditApplicatioNumber,
UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Parties.DoingBusinessAs
,ISNULL((ISNULL(PIOC.PayableInvoiceOtherCostAmount,0.00) + ISNULL(CTA.CapitalizedAmount,0.00)),0.00) AssetCostAdjustmentAmount
,Locations.AddressLine1
,Locations.AddressLine2
,Locations.City
,Locations.PostalCode
,States.ShortName
,LeaseAssets.BookedResidual_Amount
,LeaseAssets.BookedResidual_Currency
, LeaseFinanceDetails.TermInMonths
,Contracts.ExternalReferenceNumber
,Contracts.Alias
FROM Contracts
JOIN LeaseFinances on Contracts.Id = LeaseFinances.ContractId
JOIN LeaseFinanceDetails on LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId = LeaseFinances.Id AND LeaseAssets.IsActive = 1
JOIN PayableInvoices  on PayableInvoices.ContractId = Contracts.Id
JOIN PayableInvoiceAssets  on LeaseAssets.AssetId = PayableInvoiceAssets.AssetId
JOIN PayableInvoiceAssets payableInvoiceAsset on LeaseAssets.AssetId = payableInvoiceAsset.AssetId
JOIN PayableInvoices PInv ON payableInvoiceAsset.PayableInvoiceId = PInv.Id
JOIN #InvoiceDetails InvD on InvD.ContractId = Contracts.Id
JOIN Assets on PayableInvoiceAssets.AssetId = Assets.Id
JOIN AssetTypes on Assets.TypeId = AssetTypes.Id
JOIN Customers  ON LeaseFinances.CustomerId = Customers.Id
JOIN Parties  ON Parties.Id = Customers.Id
JOIN #ContractDetails CD on CD.LeaseFinanceId = LeaseFinances.Id
join ContractOriginations on LeaseFinances.ContractOriginationId = ContractOriginations.Id
join OriginationSourceTypes ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
JOIN Parties originParty ON ContractOriginations.OriginationSourceId = originParty.Id
join Parties pivendor on PayableInvoices.VendorId = pivendor.Id
LEFT JOIN CreditApprovedStructures CPS ON contracts.CreditApprovedStructureId = CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
LEFT JOIN CreditApplications CApp ON Opp.Id = CApp.Id
LEFT JOIN Manufacturers  ON Assets.ManufacturerId = Manufacturers.Id
LEFT JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
LEFT JOIN Locations ON AssetLocations.LocationId = Locations.Id
LEFT JOIN States ON Locations.StateId = States.Id
LEFT JOIN Countries ON States.CountryId = Countries.Id
LEFT JOIN UDFs ON Assets.Id = UDFs.AssetId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = 'Vendor'
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = 'Asset'
LEFT JOIN #LeasePayableInvoiceOtherCosts PIOC ON PIOC.AssetId = LeaseAssets.AssetId
LEFT JOIN #LeaseCapitalizedTaxAssets CTA ON CTA.AssetId = LeaseAssets.AssetId
WHERE PayableInvoices.Status != 'Inactive'
AND PayableInvoiceAssets.IsActive = 1 AND LeaseAssets.AssetId=Assets.Id AND LeaseFinances.IsCurrent = 1
AND (
(@IsProgramVendor=1 AND ContractOriginations.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId))
OR
(ContractOriginations.OriginationSourceId = @CurrentVendorId)
)
AND (AssetLocations.IsCurrent = CASE WHEN AssetLocations.id is not null THEN 1 END
OR AssetLocations.IsCurrent IS NULL)
AND Assets.Id NOT IN (SELECT AssetId FROM #LeaseAssetDetails)
AND OriginationSourceTypes.Name = 'Vendor'
;
CREATE TABLE #CollateralAssetDetails
(
LoanFinanceId BIGINT,
TotalAssetAmount DECIMAL(16,2)
)
INSERT INTO #CollateralAssetDetails
SELECT
CA.LoanFinanceId,
SUM(CA.AcquisitionCost_Amount) AS TotalAssetAmount
FROM CollateralAssets CA
WHERE CA.IsActive = 1
GROUP BY CA.LoanFinanceId
SELECT
CollateralAssets.AssetId,
SUM(PayableInvoiceOtherCosts.Amount_Amount) PayableInvoiceOtherCostAmount
INTO #LoanPayableInvoiceOtherCosts
FROM Contracts
JOIN LoanFinances  on Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
JOIN #CollateralAssetDetails CAD ON CAD.LoanFinanceId = LoanFinances.Id
JOIN CollateralAssets on CollateralAssets.LoanFinanceId = LoanFinances.Id AND CollateralAssets.IsActive = 1
JOIN PayableInvoices on PayableInvoices.ContractId = Contracts.Id
JOIN PayableInvoiceAssets ON PayableInvoices.Id = PayableInvoiceAssets.PayableInvoiceId
JOIN PayableInvoiceOtherCostDetails ON PayableInvoiceAssets.Id = PayableInvoiceOtherCostDetails.PayableInvoiceAssetId
JOIN PayableInvoiceOtherCosts ON PayableInvoiceOtherCosts.Id = PayableInvoiceOtherCostDetails.PayableInvoiceOtherCostId
AND PayableInvoiceOtherCosts.PayableInvoiceId = PayableInvoices.Id AND PayableInvoiceOtherCosts.IsActive = 1
WHERE (PayableInvoiceOtherCosts.AllocationMethod IN ('AssetCost','AssetCount','Specific','SpecificCostAdjustment'))
GROUP BY
CollateralAssets.AssetId
;
SELECT
Assets.Id AssetId,
SUM(CollateralAssets.AcquisitionCost_Amount) CapitalizedAmount
INTO #LoanCapitalizedTaxAssets
FROM Contracts
JOIN LoanFinances on Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
JOIN #CollateralAssetDetails CAD ON CAD.LoanFinanceId = LoanFinances.Id
JOIN CollateralAssets on CollateralAssets.LoanFinanceId = LoanFinances.Id AND CollateralAssets.IsActive = 1
JOIN Assets on CollateralAssets.AssetId = Assets.Id
JOIN AssetTypes on Assets.TypeId = AssetTypes.Id
AND AssetTypes.Name = @CapitalizedSalesTaxAssetTypeValue
GROUP BY Assets.Id
;
CREATE TABLE #LoanPaymentDetails
(
LeaseFinanceId BIGINT,
PaymentAmount DECIMAL(16,2)
)
INSERT INTO #LoanPaymentDetails
SELECT
LP.LoanFinanceId AS LeaseFinanceId,
MIN(LP.Amount_Amount) AS PaymentAmount
FROM LoanPaymentSchedules LP
WHERE IsFromReceiptPosting = 0 AND IsActive = 1
GROUP BY LP.LoanFinanceId
CREATE TABLE #LoanAssetDetails
(
AssetId BIGINT,
AssetAlias NVARCHAR(50),
ParentAssetId BIGINT,
PartNumber NVARCHAR(100),
SerialNumber NVARCHAR(100),
Quantity Int  NOT NULL,
UsageCondition NVARCHAR(4),
Description NVARCHAR(500),
Status NVARCHAR(100),
Manufacturer NVARCHAR(100),
AssetType NVARCHAR(100),
LocationCode NVARCHAR(MAX),
LocationCity NVARCHAR(40),
LocationState NVARCHAR(40),
Address NVARCHAR(250),
AssetAmount DECIMAL(16,2),
AssetCurrency NVARCHAR(3),
TotalCost_Amount DECIMAL(16,2),
TotalCost_Currency NVARCHAR(3),
LeasePaymentAmount DECIMAL(16,2),
LeasePaymentCurrency NVARCHAR(3),
AssetPaymentAmount DECIMAL(16,2),
AssetPaymentCurrency NVARCHAR(3),
InvoiceNumber NVARCHAR(40),
CustomerName NVARCHAR(Max),
CustomerNumber NVARCHAR(Max),
ProgramVendor NVARCHAR(100),
VendorId BIGINT,
ContractSequenceNumber NVARCHAR(MAX),
ContractId BIGINT,
ContractType NVARCHAR(MAX),
CustomerPurchaseOrderNumber NVARCHAR(MAX),
ModelYear DECIMAL(4,0),
EffectiveFromDate DATE,
PayableInvoiceVendor NVARCHAR(100),
CreditApplicatioNumber NVARCHAR(MAX),
UDF1Value NVARCHAR(100),
UDF2Value NVARCHAR(100),
UDF3Value NVARCHAR(100),
UDF4Value NVARCHAR(100),
UDF5Value NVARCHAR(100)	,
UDF1Label NVARCHAR(100),
UDF2Label NVARCHAR(100),
UDF3Label NVARCHAR(100),
UDF4Label NVARCHAR(100),
UDF5Label NVARCHAR(100),
DoingBusinessAs	NVARCHAR(200),
AssetCostAdjustmentAmount DECIMAL(16,2) ,
AddressLine1 NVARCHAR(100),
AddressLine2 NVARCHAR(100),
City NVARCHAR(50),
PostalCode NVARCHAR(100),
StateShortName NVARCHAR(100),
BookedResidual_Amount DECIMAL(16,2),
BookedResidual_Currency NVARCHAR(50),
Term DECIMAL(10,6),
ExternalReferenceNumber NVARCHAR(100) ,
ContractAlias NVARCHAR(100)
)
;
WITH CTE_ActivePayableInvoice AS
(
SELECT DISTINCT
Assets.Id AS AssetId,
Assets.Alias AS AssetAlias,
Assets.ParentAssetId AS ParentAssetId,
Assets.PartNumber AS PartNumber,
null AS SerialNumber,
Assets.Quantity AS Quantity,
Assets.UsageCondition AS UsageCondition,
Assets.Description AS Description,
Assets.Status AS Status,
Manufacturers.Name AS Manufacturer,
AssetTypes.Name AS AssetType,
Locations.Code AS LocationCode,
Locations.City AS LocationCity,
States.ShortName AS LocationState,
Locations.AddressLine1 + ','+Locations.AddressLine2+ ','+ Locations.City+ ','+States.ShortName+ ','+Countries.LongName AS Address,
CollateralAssets.AcquisitionCost_Amount AS AssetAmount,
CollateralAssets.AcquisitionCost_Currency AS AssetCurrency,
CAD.TotalAssetAmount AS TotalCost_Amount,
CollateralAssets.AcquisitionCost_Currency AS TotalCost_Currency,
(CASE WHEN Contracts.ContractType = 'ProgressLoan' THEN 0.00 ELSE LPD.PaymentAmount END) AS LeasePaymentAmount,
CollateralAssets.AcquisitionCost_Currency AS LeasePaymentCurrency,
0.00 AS AssetPaymentAmount,
CollateralAssets.AcquisitionCost_Currency AS AssetPaymentCurrency,
(CASE WHEN Contracts.ContractType = 'ProgressLoan' THEN PayableInvoices.InvoiceNumber ELSE NULL END) AS InvoiceNumber,
Parties.PartyName AS CustomerName,
Parties.PartyNumber  AS CustomerNumber,
(CASE WHEN @IsProgramVendor = 1 THEN NULL ELSE originVendor.PartyName END) AS ProgramVendor,
PayableInvoices.VendorId,
Contracts.SequenceNumber AS ContractSequenceNumber,
Contracts.Id AS ContractId,
Contracts.ContractType AS ContractType,
Assets.CustomerPurchaseOrderNumber AS CustomerPurchaseOrderNumber,
Assets.ModelYear AS ModelYear,
AssetLocations.EffectiveFromDate AS EffectiveFromDate,
pivendor.PartyName AS PayableInvoiceVendor,
Opp.Number AS CreditApplicatioNumber,
UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Parties.DoingBusinessAs
,ISNULL((ISNULL(PIOC.PayableInvoiceOtherCostAmount,0.00) + ISNULL(CTA.CapitalizedAmount,0.00)),0.00) AssetCostAdjustmentAmount
,Locations.AddressLine1
,Locations.AddressLine2
,Locations.City
,Locations.PostalCode
,States.ShortName
,BookedResidual_Amount = 0.00
,CurrencyCodes.ISO as BookedResidual_Currency
, LoanFinances.Term
,Contracts.ExternalReferenceNumber
,Contracts.Alias
FROM Contracts
JOIN LoanFinances  on Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
JOIN #CollateralAssetDetails CAD ON CAD.LoanFinanceId = LoanFinances.Id
JOIN CollateralAssets  on CollateralAssets.LoanFinanceId = LoanFinances.Id AND CollateralAssets.IsActive = 1
JOIN Assets on CollateralAssets.AssetId = Assets.Id
JOIN AssetTypes  on Assets.TypeId = AssetTypes.Id
JOIN Customers  ON LoanFinances.CustomerId = Customers.Id
JOIN Parties  ON Parties.Id = Customers.Id
JOIN PayableInvoices  on PayableInvoices.ContractId = Contracts.Id
JOIN PayableInvoiceAssets on PayableInvoiceAssets.PayableInvoiceId = PayableInvoices.Id AND PayableInvoiceAssets.IsActive = 1 and Assets.id = PayableInvoiceAssets.AssetId
JOIN Currencies on Contracts.CurrencyId = Currencies.Id
JOIN CurrencyCodes on Currencies.CurrencyCodeId = CurrencyCodes.Id
join ContractOriginations  on LoanFinances.ContractOriginationId = ContractOriginations.Id
join OriginationSourceTypes  ON ContractOriginations.OriginationSourceTypeId = OriginationSourceTypes.Id
JOIN Parties originVendor on ContractOriginations.OriginationSourceId = originVendor.id
join Parties pivendor on PayableInvoices.vendorId = pivendor.Id
LEFT JOIN CreditApprovedStructures CPS ON contracts.CreditApprovedStructureId = CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
LEFT JOIN CreditApplications CApp ON Opp.Id = CApp.Id
LEFT JOIN #LoanPaymentDetails LPD on LPD.LeaseFinanceId = LoanFinances.Id
LEFT JOIN Manufacturers  ON Assets.ManufacturerId = Manufacturers.Id
LEFT JOIN AssetLocations ON Assets.Id = AssetLocations.AssetId
LEFT JOIN Locations  ON AssetLocations.LocationId = Locations.Id
LEFT JOIN States ON Locations.StateId = States.Id
LEFT JOIN Countries  ON States.CountryId = Countries.Id
LEFT JOIN UDFs ON Assets.Id = UDFs.AssetId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = 'Vendor'
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = 'Asset'
LEFT JOIN #LoanPayableInvoiceOtherCosts PIOC ON PIOC.AssetId = CollateralAssets.AssetId
LEFT JOIN #LoanCapitalizedTaxAssets CTA ON CTA.AssetId = CollateralAssets.AssetId
WHERE  (PayableInvoices.id IS NULL OR (PayableInvoices.id IS NOT NULL AND PayableInvoices.Status <> 'Inactive' AND PayableInvoices.Status <> 'Pending' AND (PayableInvoiceAssets.Id IS NULL OR (PayableInvoiceAssets.Id IS NOT NULL AND PayableInvoiceAssets.IsActive = 1))))
AND LoanFinances.IsCurrent = 1
AND (
(@IsProgramVendor=1 AND ContractOriginations.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId))
OR
(ContractOriginations.OriginationSourceId = @CurrentVendorId)
)
AND (AssetLocations.IsCurrent = CASE WHEN AssetLocations.id is not null THEN 1 END
OR AssetLocations.IsCurrent IS NULL)
AND OriginationSourceTypes.Name = 'Vendor'
),
CTE_AllPayableInvoice AS
(
SELECT DISTINCT
Assets.Id AS AssetId,
Assets.Alias AS AssetAlias,
Assets.ParentAssetId AS ParentAssetId,
Assets.PartNumber AS PartNumber,
null AS SerialNumber,
Assets.Quantity AS Quantity,
Assets.UsageCondition AS UsageCondition,
Assets.Description AS Description,
Assets.Status AS Status,
m.Name AS Manufacturer,
AssetTypes.Name AS AssetType,
l.Code AS LocationCode,
l.City AS LocationCity,
s.ShortName AS LocationState,
l.AddressLine1 + ','+l.AddressLine2+ ','+ l.City+ ','+s.ShortName+ ','+cn.LongName AS Address,
CollateralAssets.AcquisitionCost_Amount AS AssetAmount,
CollateralAssets.AcquisitionCost_Currency AS AssetCurrency,
CAD.TotalAssetAmount AS TotalCost_Amount,
CollateralAssets.AcquisitionCost_Currency AS TotalCost_Currency,
(CASE WHEN Contracts.ContractType = 'ProgressLoan' THEN 0.00 ELSE LPD.PaymentAmount END) AS LeasePaymentAmount,
CollateralAssets.AcquisitionCost_Currency AS LeasePaymentCurrency,
0.00 AS AssetPaymentAmount,
CollateralAssets.AcquisitionCost_Currency AS AssetPaymentCurrency,
(CASE WHEN Contracts.ContractType = 'ProgressLoan' THEN pi.InvoiceNumber ELSE NULL END) AS InvoiceNumber,
Parties.PartyName AS CustomerName,
Parties.PartyNumber  AS CustomerNumber,
(CASE WHEN @IsProgramVendor = 1 THEN null ELSE originParty.PartyName END) AS ProgramVendor,
pi.VendorId,
Contracts.SequenceNumber AS ContractSequenceNumber,
Contracts.Id AS ContractId,
Contracts.ContractType AS ContractType,
Assets.CustomerPurchaseOrderNumber AS CustomerPurchaseOrderNumber,
Assets.ModelYear AS ModelYear,
al.EffectiveFromDate AS EffectiveFromDate,
pivendor.PartyName AS PayableInvoiceVendor,
Opp.Number AS CreditApplicatioNumber
,UDFs.UDF1Value
,UDFs.UDF2Value
,UDFs.UDF3Value
,UDFs.UDF4Value
,UDFs.UDF5Value
,UDFLabel.UDF1Label
,UDFLabel.UDF2Label
,UDFLabel.UDF3Label
,UDFLabel.UDF4Label
,UDFLabel.UDF5Label
,Parties.DoingBusinessAs
,ISNULL((ISNULL(PIOC.PayableInvoiceOtherCostAmount,0.00) + ISNULL(CTA.CapitalizedAmount,0.00)),0.00) AssetCostAdjustmentAmount
,l.AddressLine1
,l.AddressLine2
,l.City
,l.PostalCode
,s.ShortName
,0.00 BookedResidual_Amount
,CC.ISO as BookedResidual_Currency
, LoanFinances.Term
,Contracts.ExternalReferenceNumber
,Contracts.Alias
FROM Contracts
JOIN LoanFinances on Contracts.Id = LoanFinances.ContractId AND LoanFinances.IsCurrent = 1
JOIN #CollateralAssetDetails CAD ON CAD.LoanFinanceId = LoanFinances.Id
JOIN CollateralAssets  on CollateralAssets.LoanFinanceId = LoanFinances.Id AND CollateralAssets.IsActive = 1
JOIN Assets on CollateralAssets.AssetId = Assets.Id
JOIN AssetTypes on Assets.TypeId = AssetTypes.Id
JOIN Customers  ON LoanFinances.CustomerId = Customers.Id
JOIN Parties ON Parties.Id = Customers.Id
JOIN Currencies CU on Contracts.CurrencyId = CU.Id
JOIN CurrencyCodes CC on CU.CurrencyCodeId = CC.Id
join ContractOriginations co on LoanFinances.ContractOriginationId = co.Id
join OriginationSourceTypes ost ON co.OriginationSourceTypeId = ost.Id
JOIN Parties originParty ON co.OriginationSourceId = originParty.Id
LEFT JOIN CreditApprovedStructures CPS ON contracts.CreditApprovedStructureId = CPS.Id
LEFT JOIN CreditProfiles CP ON CPS.CreditProfileId = CP.Id
LEFT JOIN Opportunities Opp ON CP.OpportunityId = Opp.Id
LEFT JOIN CreditApplications CApp ON Opp.Id = CApp.Id
LEFT JOIN PayableInvoices pi on pi.ContractId = Contracts.Id
LEFT  JOIN Parties pivendor on pivendor.Id = pi.VendorId
LEFT JOIN PayableInvoiceAssets pa on pa.PayableInvoiceId = pi.Id AND pa.IsActive = 1 and Assets.id = pa.AssetId
LEFT JOIN #LoanPaymentDetails LPD on LPD.LeaseFinanceId = LoanFinances.Id
LEFT JOIN Manufacturers m ON Assets.ManufacturerId = m.Id
LEFT JOIN AssetLocations al ON Assets.Id = al.AssetId
LEFT JOIN Locations l ON al.LocationId = l.Id
LEFT JOIN States s ON l.StateId = s.Id
LEFT JOIN Countries cn ON s.CountryId = cn.Id
LEFT JOIN UDFs ON Assets.Id = UDFs.AssetId AND UDFs.IsActive = 1
LEFT JOIN UDFLabelForParties UL ON UL.EntityId = @CurrentVendorId AND  UL.EntityType = 'Vendor'
LEFT JOIN UDFLabelForPartyDetails UDFLabel ON UL.Id = UDFLabel.UDFLabelForPartyId AND UDFLabel.EntityType = 'Asset'
LEFT JOIN #LoanPayableInvoiceOtherCosts PIOC ON PIOC.AssetId = CollateralAssets.AssetId
LEFT JOIN #LoanCapitalizedTaxAssets CTA ON CTA.AssetId = CollateralAssets.AssetId
WHERE (pi.id IS NULL OR (pi.id IS NOT NULL AND pi.Status <> 'Inactive' AND pi.Status <> 'Pending' AND (pa.Id IS NULL OR (pa.Id IS NOT NULL AND pa.IsActive = 1))))
AND LoanFinances.IsCurrent = 1
AND (
(@IsProgramVendor=1 AND co.OriginationSourceId IN (SELECT VendorId FROM ProgramsAssignedToAllVendors WHERE IsAssigned = 1 AND ProgramVendorId =  @CurrentVendorId))
OR
(co.OriginationSourceId = @CurrentVendorId)
)
AND (al.IsCurrent = CASE WHEN al.id is not null THEN 1 END
OR al.IsCurrent IS NULL)
AND Assets.Id NOT IN (SELECT  AssetId FROM CTE_ActivePayableInvoice)
AND ost.Name = 'Vendor'
)
INSERT INTO #LoanAssetDetails
SELECT  * FROM CTE_AllPayableInvoice
UNION
SELECT  * FROM CTE_ActivePayableInvoice
;
;WITH CTE_SerialNumberFilteredAssets as (
	SELECT DISTINCT(A.ID) AS AssetId FROM Assets A 
	LEFT JOIN AssetSerialNumbers ASN ON ASN.AssetId = A.Id AND ASN.IsActive=1 
	WHERE @SerialNumber IS  NULL OR ASN.SerialNumber LIKE REPLACE(@SerialNumber ,'*','%')
),CTE_AssetDetails AS
(
SELECT DISTINCT	AD.AssetId AS Id, * FROM #LeaseAssetDetails AD
UNION
SELECT DISTINCT LD.AssetId AS Id, * FROM #LoanAssetDetails LD
) 

SELECT Result.* INTO #AssetDetails FROM CTE_AssetDetails Result
JOIN CTE_SerialNumberFilteredAssets A ON Result.AssetId = A.AssetId
 WHERE Result.VendorId IS NOT NULL ORDER BY Result.AssetId

UPDATE AD
	SET AD.SerialNumber=ASN.SerialNumber  
FROM #AssetDetails AD
JOIN (SELECT 
		ASN.AssetId,
		SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
		FROM #AssetDetails A 
		JOIN AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
		GROUP BY ASN.AssetId ) ASN 
ON ASN.AssetId = AD.AssetId

IF(@IsFromLocationChange = 1)
BEGIN
SELECT * FROM #AssetDetails WHERE ContractId NOT IN (SELECT ContractId FROM Assumptions WHERE Status = 'Approved')
AND (@ContractAlias IS NULL OR ContractAlias LIKE REPLACE(@ContractAlias ,'*','%'))
AND (@ExternalReferenceNumber IS NULL OR ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber ,'*','%'))
END
SELECT * FROM #AssetDetails
WHERE (@ContractAlias IS NULL OR ContractAlias LIKE REPLACE(@ContractAlias ,'*','%'))
AND (@ExternalReferenceNumber IS NULL OR ExternalReferenceNumber LIKE REPLACE(@ExternalReferenceNumber ,'*','%'))
;
END

GO

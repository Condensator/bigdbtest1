SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[FetchContractInfoForPreQuote]
(
@IsLease INT,
@SyndicationTypeFullSale NVARCHAR(16) = NULL,
@SyndicationTypeUnknown NVARCHAR(16) = NULL,
@SyndicationTypeNone NVARCHAR(16) = NULL,
@HoldingStatusHFS NVARCHAR(13) = NULL,
@HoldingStatusHFI NVARCHAR(13) = NULL,
@HoldingStatusUnknown NVARCHAR(13) = NULL,
@LoanApprovalStatusPending NVARCHAR(25) = NULL,
@LoanApprovalStatusRejected NVARCHAR(25) = NULL,
@LoanBookingStatusCommenced NVARCHAR(12) = NULL,
@RFTApprovalStatusApproved NVARCHAR(25) = NULL,
@LeaseApprovalStatusPending NVARCHAR(25) = NULL,
@LeaseBookingStatusCommenced NVARCHAR(16) = NULL,
@LeaseBookingStatusInstallingAsset NVARCHAR(16) = NULL,
@InterimAssessmentMethodUnknown NVARCHAR(8) = NULL,
@CustomerId BIGINT = NULL,
@SequenceNumber NVARCHAR(40) = NULL,
@ContractType NVARCHAR(14) = NULL,
@DealType NVARCHAR(20) = NULL,
@DealProductType NVARCHAR(32) = NULL,
@Modality NVARCHAR(20) = NULL,
@DescriptionOne NVARCHAR(20) = NULL,
@DescriptionTwo NVARCHAR(20) = NULL,
@AccessibleLegalEntities NVARCHAR(MAX)
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
CREATE TABLE #LeaseInfo(LeaseFinanceId BIGINT NOT NULL, MaxNBV DECIMAL(16,2))
CREATE TABLE #LoanInfo(LoanFinanceId BIGINT NOT NULL, MaxAcquisitionCost DECIMAL(16,2))
CREATE TABLE #MaxAmountAssetInfo(FinanceId BIGINT NOT NULL, AssetId BIGINT NOT NULL, IsLase BIT)
CREATE TABLE #ServicedSyndicatedDeals(LeaseFinanceId BIGINT NULL)
CREATE TABLE #SyndicatedContracts(ContractId BIGINT NULL)
CREATE TABLE #AssetInfo(FinanceId BIGINT, AssetId BIGINT, Modality NVARCHAR(40), DescriptionOne NVARCHAR(40), DescriptionTwo NVARCHAR(40), AssetDescription NVARCHAR(500), AssetState NVARCHAR(50), AssetCity NVARCHAR(40), IsLease BIT)
CREATE TABLE #PreQuoteContractInformation(ContractId BIGINT,IsLease BIT,FinanceId BIGINT,AssetId BIGINT,Modality NVARCHAR(40),
DescriptionOne NVARCHAR(40),DescriptionTwo NVARCHAR(40),AssetDescription NVARCHAR(500),AssetCity NVARCHAR(40),AssetState NVARCHAR(50),LineOfBusinessName NVARCHAR(40),
LegalEntityName NVARCHAR(100),MaturityDate DATETIME,DealTypeName NVARCHAR(40),DealProductName NVARCHAR(32))
SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',')
INSERT INTO #LeaseInfo(LeaseFinanceId, MaxNBV)
SELECT lf.Id, MAX(NBV_Amount)
From LeaseAssets la
JOIN LeaseFinances lf ON la.LeaseFinanceId = lf.Id
WHERE la.IsActive = 1 AND lf.IsCurrent = 1
GROUP BY lf.Id
INSERT INTO #LoanInfo(LoanFinanceId, MaxAcquisitionCost)
SELECT lf.Id, MAX(ca.AcquisitionCost_Amount)
FROM CollateralAssets ca
JOIN LoanFinances lf ON ca.LoanFinanceId = lf.Id
WHERE ca.IsActive = 1 AND lf.IsCurrent = 1
GROUP BY lf.Id
INSERT INTO #MaxAmountAssetInfo(FinanceId,AssetId, IsLase)
SELECT li.LeaseFinanceId, MAX(leaseAsset.AssetId), 1 FROM LeaseAssets la
JOIN #LeaseInfo li ON la.LeaseFinanceId = li.LeaseFinanceId AND la.NBV_Amount = li.MaxNBV
JOIN LeaseAssets leaseAsset on leaseAsset.LeaseFinanceId = li.LeaseFinanceId and ( leaseAsset.AssetId = la.AssetId or la.CapitalizedForId = leaseAsset.Id )
GROUP BY li.LeaseFinanceId
INSERT INTO #MaxAmountAssetInfo(FinanceId,AssetId,IsLase)
SELECT li.LoanFinanceId, MAX(ca.AssetId), 0 FROM CollateralAssets ca
JOIN #LoanInfo li ON ca.LoanFinanceId = li.LoanFinanceId AND ca.AcquisitionCost_Amount = li.MaxAcquisitionCost
GROUP BY li.LoanFinanceId
INSERT INTO #AssetInfo (FinanceId, AssetId, Modality, DescriptionOne, DescriptionTwo, AssetDescription, AssetState, AssetCity, IsLease)
SELECT
tempTable.FinanceId
, tempTable.AssetId
, Modality = CASE WHEN category.Id IS NOT NULL THEN category.Name ELSE NULL END
, DescriptionOne = CASE WHEN p.Id IS NOT NULL THEN p.Name ELSE NULL END
, DescriptionTwo = CASE WHEN pst.Id IS NOT NULL THEN pst.Name ELSE NULL END
, AssetDescription = a.Description
, AssetState = CASE WHEN s.Id IS NOT NULL THEN s.LongName ELSE NULL END
, AssetCity = CASE WHEN l.Id IS NOT NULL THEN l.City ELSE NULL END
, tempTable.IsLase
FROM
#MaxAmountAssetInfo tempTable
JOIN Assets a ON tempTable.AssetId = a.Id
LEFT JOIN AssetLocations al ON a.Id = al.AssetId AND al.IsActive =1 AND al.IsCurrent = 1
LEFT JOIN Locations l ON al.LocationId = l.Id AND l.IsActive = 1
LEFT JOIN States s ON l.StateId = s.Id AND s.IsActive = 1
LEFT JOIN AssetCatalogs ac ON a.AssetCatalogId = ac.Id AND ac.IsActive = 1
LEFT JOIN Products p ON ac.ProductId = p.Id AND p.IsActive = 1
LEFT JOIN AssetCategories category ON ac.AssetCategoryId = category.Id AND category.IsActive = 1
LEFT JOIN ProductSubTypes pst ON ac.ProductSubTypeId = pst.Id AND pst.IsActive = 1
INSERT INTO #ServicedSyndicatedDeals(LeaseFinanceId)
SELECT DISTINCT lf.Id FROM LeaseFinances lf
JOIN ReceivableForTransfers rft ON lf.ContractId = rft.ContractId
JOIN ReceivableForTransferServicings rfts ON rft.Id = rfts.ReceivableForTransferId
WHERE rft.ApprovalStatus = @RFTApprovalStatusApproved
AND rfts.IsActive = 1 AND rfts.IsServiced = 1 AND lf.IsCurrent = 1
INSERT INTO #SyndicatedContracts(ContractId)
SELECT rft.ContractId FROM ReceivableForTransfers rft
WHERE rft.ApprovalStatus = @RFTApprovalStatusApproved
IF @IsLease = 1 OR @IsLease = 3
BEGIN
INSERT INTO #PreQuoteContractInformation
(ContractId,
IsLease,
FinanceId,
AssetId,
Modality,
DescriptionOne,
DescriptionTwo,
AssetDescription,
AssetCity,
AssetState,
LineOfBusinessName,
LegalEntityName,
MaturityDate,
DealTypeName,
DealProductName)
SELECT DISTINCT
c.Id,
ai.IsLease,
lf.Id,
ai.AssetId,
ai.Modality,
ai.DescriptionOne,
ai.DescriptionTwo,
ai.AssetDescription,
ai.AssetCity,
ai.AssetState,
lob.Name,
le.Name,
lfd.MaturityDate,
dt.ProductType,
dpt.Name
FROM Contracts c
JOIN DealTypes dt ON c.DealTypeId = dt.Id
JOIN LeaseFinances lf ON c.Id = lf.ContractId AND lf.IsCurrent = 1
JOIN #AccessibleLegalEntityIds ale ON lf.LegalEntityId = ale.Id
JOIN #AssetInfo ai ON lf.Id = ai.FinanceId AND ai.IsLease = 1
JOIN LeaseFinanceDetails lfd on lf.Id = lfd.Id
JOIN LineofBusinesses lob ON lf.LineofBusinessId = lob.Id AND lob.IsActive = 1
JOIN LegalEntities le ON lf.LegalEntityId = le.Id
JOIN Parties p ON lf.CustomerId = p.Id
JOIN DealProductTypes dpt ON c.DealProductTypeId = dpt.Id AND dpt.IsActive = 1
LEFT JOIN #ServicedSyndicatedDeals ssd ON lf.Id = ssd.LeaseFinanceId
LEFT JOIN #SyndicatedContracts sc ON c.Id = sc.ContractId
WHERE lf.IsCurrent = 1 AND lf.ApprovalStatus != @LeaseApprovalStatusPending
AND (lf.BookingStatus = @LeaseBookingStatusCommenced OR (lf.BookingStatus = @LeaseBookingStatusInstallingAsset AND lfd.InterimAssessmentMethod != @InterimAssessmentMethodUnknown))
AND (@CustomerId IS NULL OR p.Id = @CustomerId)
AND dt.IsActive = 1
AND (((lf.HoldingStatus = @HoldingStatusHFI OR lf.HoldingStatus = @HoldingStatusUnknown) AND
((c.SyndicationType = @SyndicationTypeNone OR c.SyndicationType = @SyndicationTypeUnknown) OR (sc.ContractId IS NOT NULL AND (c.SyndicationType != @SyndicationTypeFullSale OR ssd.LeaseFinanceId IS NOT NULL))))
OR (lf.HoldingStatus = @HoldingStatusHFS AND ( sc.ContractId IS NOT NULL AND c.SyndicationType = @SyndicationTypeFullSale AND ssd.LeaseFinanceId IS NOT NULL)))
AND (@SequenceNumber IS NULL OR c.SequenceNumber LIKE REPLACE(@SequenceNumber,'*','%'))
AND (@ContractType IS NULL OR c.ContractType LIKE REPLACE(@ContractType,'*','%'))
AND (@DealType IS NULL OR dt.ProductType LIKE REPLACE(@DealType,'*','%'))
AND (@DealProductType IS NULL OR dpt.Name LIKE REPLACE(@DealProductType,'*','%'))
AND (@Modality IS NULL OR (ai.Modality IS NOT NULL AND ai.Modality LIKE REPLACE(@Modality,'*','%')))
AND (@DescriptionOne IS NULL OR (ai.DescriptionOne IS NOT NULL AND ai.DescriptionOne LIKE REPLACE(@DescriptionOne,'*','%')))
AND (@DescriptionTwo IS NULL OR (ai.DescriptionTwo IS NOT NULL AND ai.DescriptionTwo LIKE REPLACE(@DescriptionTwo,'*','%')))
END
IF @IsLease = 2 OR @IsLease = 3
BEGIN
INSERT INTO #PreQuoteContractInformation
(ContractId,
IsLease,
FinanceId,
AssetId,
Modality,
DescriptionOne,
DescriptionTwo,
AssetDescription,
AssetCity,
AssetState,
LineOfBusinessName,
LegalEntityName,
MaturityDate,
DealTypeName,
DealProductName)
SELECT DISTINCT
c.Id,
ai.IsLease,
lf.Id,
ai.AssetId,
ai.Modality,
ai.DescriptionOne,
ai.DescriptionTwo,
ai.AssetDescription,
ai.AssetCity,
ai.AssetState,
lob.Name,
le.Name,
lf.MaturityDate,
dt.ProductType,
dpt.Name
FROM Contracts c
JOIN DealTypes dt ON c.DealTypeId = dt.Id
JOIN LoanFinances lf ON c.Id = lf.ContractId AND lf.IsCurrent = 1
JOIN #AccessibleLegalEntityIds ale ON lf.LegalEntityId = ale.Id
JOIN #AssetInfo ai ON lf.Id = ai.FinanceId AND ai.IsLease = 0
JOIN LineofBusinesses lob ON lf.LineofBusinessId = lob.Id
JOIN LegalEntities le ON lf.LegalEntityId = le.Id
JOIN Parties p ON lf.CustomerId = p.Id
JOIN DealProductTypes dpt ON c.DealProductTypeId = dpt.Id AND dpt.IsActive = 1
LEFT JOIN ReceivableForTransfers rft ON c.Id = rft.ContractId AND rft.ApprovalStatus = @RFTApprovalStatusApproved
LEFT JOIN ReceivableForTransferServicings rfts ON rft.Id = rfts.ReceivableForTransferId AND rfts.IsActive = 1
WHERE lf.IsCurrent = 1
AND lf.Status = @LoanBookingStatusCommenced	AND lf.ApprovalStatus != @LoanApprovalStatusPending	AND lf.ApprovalStatus != @LoanApprovalStatusRejected
AND (@CustomerId IS NULL OR p.Id = @CustomerId)
AND dt.IsActive = 1
AND (c.SyndicationType = @SyndicationTypeFullSale OR lf.HoldingStatus != @HoldingStatusHFS)
AND ((c.SyndicationType = @SyndicationTypeFullSale AND (rfts.Id != 0 AND (rfts.IsServiced = 1 OR rfts.IsCollected = 1))) OR c.SyndicationType != @SyndicationTypeFullSale)
AND (@SequenceNumber IS NULL OR c.SequenceNumber LIKE REPLACE(@SequenceNumber,'*','%'))
AND (@ContractType IS NULL OR c.ContractType LIKE REPLACE(@ContractType,'*','%'))
AND (@DealType IS NULL OR dt.ProductType LIKE REPLACE(@DealType,'*','%'))
AND (@DealProductType IS NULL OR dpt.Name LIKE REPLACE(@DealProductType,'*','%'))
AND (@Modality IS NULL OR (ai.Modality IS NOT NULL AND ai.Modality LIKE REPLACE(@Modality,'*','%')))
AND (@DescriptionOne IS NULL OR (ai.DescriptionOne IS NOT NULL AND ai.DescriptionOne LIKE REPLACE(@DescriptionOne,'*','%')))
AND (@DescriptionTwo IS NULL OR (ai.DescriptionTwo IS NOT NULL AND ai.DescriptionTwo LIKE REPLACE(@DescriptionTwo,'*','%')))
END
SELECT * FROM #PreQuoteContractInformation
DROP TABLE #LeaseInfo
DROP TABLE #LoanInfo
DROP TABLE #MaxAmountAssetInfo
DROP TABLE #AssetInfo
DROP TABLE #ServicedSyndicatedDeals
DROP TABLE #SyndicatedContracts
DROP TABLE #PreQuoteContractInformation
END

GO

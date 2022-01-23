SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetAssetSaleAssetInfo]
(
	@Assets AssetSaleAssetInfoParamType READONLY,
	@AssetSaleId BIGINT,
	@Activated NVARCHAR(10),
	@Active NVARCHAR(10),
	@LeaseContractType NVARCHAR(10),
	@Completed NVARCHAR(10),
	@Inactive NVARCHAR(10),
	@AssetStatusInvestor NVARCHAR(10),
	@AssetStatusInvestorLeased NVARCHAR(20),
	@SyndicationApprovalStatusApproved NVARCHAR(20),
	@AssetMultipleSerialNumberType NVARCHAR(10)
)
AS
BEGIN
SET NOCOUNT ON;
--DECLARE @Assets TABLE (AssetId BIGINT, AssetStatus NVARCHAR(20)) INSERT INTO @Assets Select 8,'Inventory'
--DECLARE @AssetSaleId BIGINT = 1
--DECLARE @Activated NVARCHAR(10) = 'Activated'
--DECLARE @Active NVARCHAR(10) = 'Active'
--DECLARE @LeaseContractType NVARCHAR(10) = 'DirectFinance'
--DECLARE @Completed NVARCHAR(10) = 'Completed'
--DECLARE @Inactive NVARCHAR(10) = 'Inactive'
--DECLARE @AssetStatusInvestor NVARCHAR(10) = 'Investor'
--DECLARE @AssetStatusInvestorLeased NVARCHAR(10) = 'InvestorLeased'
--DECLARE @SyndicationApprovalStatusApproved NVARCHAR(10) = 'Approved'
SELECT * INTO #Assets FROM @Assets
CREATE UNIQUE INDEX AssetId ON #Assets(AssetId)

SELECT
PA.AssetValuation_Amount OriginalOffLeaseNBV_Amount,
PA.AssetValuation_Currency OriginalOffLeaseNBV_Currency,
PA.IsPartiallyOwned,
LA.AssetId,
ROW_NUMBER() OVER (PARTITION BY LA.AssetId ORDER BY P.PayoffEffectiveDate DESC, P.Id DESC) AS RowNumber,
LF.InstrumentTypeId,
LF.LineofBusinessId,
LF.CostCenterId,
LF.BranchId,
LFD.LeaseContractType
INTO #PayoffAssets
FROM Assets A
JOIN #Assets Ast ON A.Id = Ast.AssetId
Join LeaseAssets LA ON A.Id = LA.AssetId
Join PayoffAssets PA ON LA.Id = PA.LeaseAssetId And PA.IsActive = 1
Join Payoffs P ON PA.PayoffId = P.Id AND P.Status = @Activated
Join LeaseFinances LF ON P.LeaseFinanceId=LF.Id
Join LeaseFinanceDetails LFD ON LF.Id=LFD.Id
Order by P.Id Desc

SELECT * 
INTO #PaidoffAssets 
FROM #PayoffAssets WHERE RowNumber = 1

SELECT 
	ASN.AssetId,
	SerialNumber = CASE WHEN count(ASN.Id) > 1 THEN @AssetMultipleSerialNumberType ELSE MAX(ASN.SerialNumber) END  
INTO #AssetSerialNumberDetails
FROM #Assets A
join AssetSerialNumbers ASN on A.AssetId = ASN.AssetId AND ASN.IsActive=1
GROUP BY ASN.AssetId

INSERT INTO 
#PaidoffAssets(OriginalOffLeaseNBV_Amount,OriginalOffLeaseNBV_Currency,IsPartiallyOwned,AssetId,RowNumber)
SELECT 0,AssetCost_Currency, 0, LA.AssetId, 0
FROM Assets A
JOIN #Assets Ast ON A.Id = Ast.AssetId
Join LoanPaydownAssetDetails LA ON A.Id = LA.AssetId And LA.IsActive = 1
Join LoanPaydowns PD ON LA.LoanPaydownId = PD.Id AND PD.Status = @Active

SELECT
Ast.AssetId, TransactionNumber 
INTO #TransactionNumbers
FROM AssetSales ASS
JOIN AssetSaleDetails ASD ON ASS.Id = ASD.AssetSaleId
AND ASD.IsActive = 1 AND ASS.Status Not IN (@Completed, @Inactive)
JOIN #Assets Ast ON ASD.AssetId = Ast.AssetId
WHERE ASS.Id <> @AssetSaleId

SELECT AssetId, STUFF((SELECT ',' + TransactionNumber FROM #TransactionNumbers T WHERE TN.AssetId = T.AssetId ORDER BY AssetId for xml path('')),1,1,'') AS ActiveAssetSaleTransactions
INTO #AssetSaleTransactionNumbers 
FROM #TransactionNumbers TN GROUP BY AssetId
SELECT A.Id AssetId, CA.Id ChildAssetId INTO #ChildAssets FROM Assets A
JOIN Assets CA With (ForceSeek) ON A.Id = CA.ParentAssetId AND CA.ParentAssetId > 0
JOIN #Assets Ast ON A.Id = Ast.AssetId

SELECT AssetId, STUFF((SELECT ',' + CAST(ChildAssetId AS NVARCHAR(100)) FROM #ChildAssets C WHERE CA.AssetId = C.AssetId ORDER BY AssetId for xml path('')),1,1,'') AS ChildAssets
INTO #AssetSaleChildAssets 
FROM #ChildAssets CA GROUP BY AssetId

SELECT A.Id  
INTO #AVHIds
FROM AssetValueHistories A  
JOIN #Assets Ast ON A.AssetId = Ast.AssetId  
WHERE IsSchedule = 1 AND  
(IsLessorOwned = CASE WHEN Ast.AssetStatus IN (@AssetStatusInvestor, @AssetStatusInvestorLeased) THEN 0 ELSE 1 END)  

SELECT A.AssetId, A.EndBookValue_Amount EndBookValue, ROW_NUMBER() OVER (PARTITION BY A.AssetId,A.IsLeaseComponent ORDER BY A.Id DESC) AS RowNumber   
INTO #AVHistory  
FROM AssetValueHistories A  
JOIN #AVHIds Ast ON A.Id = Ast.Id  

SELECT avh.AssetId, SUM(avh.EndBookValue) EndBookValue
INTO #AssetValueHistory 
FROM #AVHistory avh 
WHERE RowNumber = 1
GROUP BY avh.AssetId


SELECT
A.Id AssetId, AIS.EndNetBookValue_Amount EndBookValue, ROW_NUMBER() OVER (PARTITION BY A.Id ORDER BY LIS.IncomeDate DESC) AS RowNumber 
INTO #AssetIncome
FROM Assets A
JOIN #Assets Ast ON A.Id = Ast.AssetId
JOIN LeaseAssets LA ON A.Id = LA.AssetId
JOIN LeaseFinanceDetails LFD ON LA.LeaseFinanceId = LFD.Id AND LFD.LeaseContractType = @LeaseContractType
JOIN AssetIncomeSchedules AIS ON A.Id = AIS.AssetId AND AIS.IsActive = 1
JOIN LeaseIncomeSchedules LIS ON AIS.LeaseIncomeScheduleId = LIS.Id
WHERE  IsSchedule = 1 AND
(IsLessorOwned = CASE WHEN Ast.AssetStatus IN (@AssetStatusInvestor, @AssetStatusInvestorLeased) THEN 0 ELSE 1 END)


SELECT * 
INTO #AssetLevelIncomes FROM #AssetIncome WHERE RowNumber = 1


;WITH CTE_SyndicationInfo
AS
(
SELECT ROW_NUMBER() OVER (PARTITION BY LA.AssetId ORDER BY RFT.Id DESC, RFTS.EffectiveDate DESC) AS RowNumber
,LA.AssetId,
RFTS.EffectiveDate,
RFTS.IsCollected,
RFTS.IsPerfectPay,
RFT.RetainedPercentage/100 AS RetainedPercentage
FROM ReceivableForTransfers AS RFT
INNER JOIN ReceivableForTransferServicings RFTS ON RFT.id = RFTS.ReceivableForTransferId AND RFTS.IsActive = 1
INNER JOIN Contracts AS C ON RFT.ContractId = C.Id
INNER JOIN LeaseFinances AS LF ON C.Id = LF.ContractId AND LF.Id = RFT.LeaseFinanceId
INNER JOIN LeaseAssets AS LA ON LF.Id = LA.LeaseFinanceId AND LA.IsActive = 1
INNER JOIN #Assets Ast ON LA.AssetId = Ast.AssetId
WHERE RFT.ApprovalStatus = @SyndicationApprovalStatusApproved
)


SELECT *
INTO #SyndicatedAssetServicingInfo
FROM CTE_SyndicationInfo 
WHERE RowNumber = 1;
SELECT LA.AssetId,
LF.ContractId
INTO #AssetsOnCurrentLease
FROM LeaseAssets LA
INNER JOIN #Assets Ast ON LA.AssetId = Ast.AssetId AND LA.IsActive = 1
INNER JOIN LeaseFinances LF ON LA.LeaseFinanceId = LF.Id AND LF.IsCurrent = 1


SELECT
A.Id AssetId,
A.Alias,
A.PartNumber,
A.Status,
ASN.SerialNumber,
A.Quantity,
A.AcquisitionDate,
L.Code LocationCode,
L.Name LocationName,
AL.EffectiveFromDate,
ISNULL(AL.TaxBasisType,'_') TaxBasisType,
ISNULL(AL.UpfrontTaxMode,'_') UpfrontTaxMode,
ATS.Name AssetTypeName,
P.Name ProductName,
AC.Name CategoryName,
M.Name ManufacturerName,
ISNULL(A.FinancialType,'_') FinancialType,
A.UsageCondition,
CASE WHEN AVH.EndBookValue IS NOT NULL THEN AVH.EndBookValue
WHEN ALI.EndBookValue IS NOT NULL THEN ALI.EndBookValue
ELSE 0 END NetBookValue_Amount,
A.CurrencyCode NetBookValue_Currency,
A.Description,
A.ModelYear,
A.LegalEntityId,
LE.GLConfigurationId,
A.CurrencyCode CurrencyISO,
A.ParentAssetId,
ASTN.ActiveAssetSaleTransactions AssetSaleTransactionNumber,
A.PreviousSequenceNumber,
CASE WHEN PA.AssetId IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END IsTransferAsset,
ISNULL( PA.IsPartiallyOwned,CAST(0 AS BIT)) IsPartiallyOwned,
PA.OriginalOffLeaseNBV_Amount,
PA.OriginalOffLeaseNBV_Currency,
CA.ChildAssets ChildAssetIds,
AG.InstrumentTypeId,
AG.LineofBusinessId,
AG.CostCenterId,
AG.BranchId,
ISNULL(ACL.ContractId,C.Id) ContractId,
C.Id PreviousContractId,
PayoffInstrumentTypeId=PA.InstrumentTypeId,
PayoffLineofBusinessId=PA.LineofBusinessId,
PayoffCostCenterId=PA.CostCenterId,
PayoffBranchId=PA.BranchId,
ClassificationContractType=PA.LeaseContractType,
CASE WHEN ASSI.AssetId IS NULL THEN CAST(0 AS BIT) ELSE CAST(1 AS BIT) END IsSyndicated,
ISNULL( ASSI.IsCollected,CAST(1 AS BIT)) IsCollected,
ISNULL( ASSI.IsPerfectPay,CAST(0 AS BIT)) IsPerfectPay,
ISNULL( ASSI.RetainedPercentage, 1) RetainedPercentage
FROM Assets A
JOIN #Assets Ast ON A.Id = Ast.AssetId
LEFT JOIN #AssetSerialNumberDetails ASN ON A.Id = ASN.AssetId
JOIN AssetGLDetails AG ON A.Id = AG.Id
JOIN LegalEntities LE ON A.LegalEntityId = LE.Id
JOIN AssetTypes ATS ON A.TypeId = ATS.Id
LEFT JOIN Products P ON A.ProductId = P.Id
LEFT JOIN AssetCategories AC ON A.AssetCategoryId = AC.Id
LEFT JOIN Manufacturers M ON A.ManufacturerId = M.Id
LEFT JOIN AssetLocations AL ON A.Id = AL.AssetId AND AL.IsCurrent = 1
LEFT JOIN Locations L ON AL.LocationId = L.Id
LEFT JOIN #AssetLevelIncomes ALI ON A.Id = ALI.AssetId
LEFT JOIN #AssetSaleChildAssets CA ON A.Id = CA.AssetId
LEFT JOIN #PaidoffAssets PA ON A.Id = PA.AssetId
LEFT JOIN #AssetSaleTransactionNumbers ASTN ON A.Id = ASTN.AssetId
LEFT JOIN Contracts C ON A.PreviousSequenceNumber = C.SequenceNumber
LEFT JOIN #AssetValueHistory AVH ON A.Id = AVH.AssetId
LEFT JOIN #SyndicatedAssetServicingInfo ASSI ON ASSI.AssetId = A.Id
LEFT JOIN #AssetsOnCurrentLease ACL ON ACL.AssetId = A.Id
--DROP TABLE #Assets
--DROP TABLE #AssetLevelIncomes
--DROP TABLE #AssetSaleChildAssets
--DROP TABLE #PaidoffAssets
--DROP TABLE #AssetSaleTransactionNumbers
--DROP TABLE #AssetValueHistory
--DROP TABLE #AssetIncome
--DROP TABLE #ChildAssets
--DROP TABLE #TransactionNumbers
--DROP TABLE #PayoffAssets
--DROP TABLE #AVHistory
--DROP TABLE #SyndicatedAssetServicingInfo
--DROP TABLE #AssetsOnCurrentLease
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetInvoicesForWilliamsLeaEDIInterface] @CustomerID NVARCHAR(MAX)
AS
--DECLARE @CustomerId Nvarchar(max)
--SET @CustomerId='4974,8942'
BEGIN
SET NOCOUNT ON;
CREATE TABLE #WilliamsCustomers (CustomerId Bigint);
DECLARE @TEXT NVARCHAR(max) = @CustomerId
DECLARE @InsertStatement NVARCHAR(max) = 'insert into #WilliamsCustomers(CustomerId)
values ('''+REPLACE(@TEXT,',','''),(''')+''');';
EXEC (@InsertStatement);
CREATE TABLE #AssetSerialNumbers
	(
		AssetId BIGINT,
		SerialNumber nvarchar(100)
	)

	INSERT INTO #AssetSerialNumbers
		SELECT AssetId, MAX (ASN.SerialNumber) as SerialNumber  from AssetSerialNumbers ASN inner join Assets 
		Asset on ASN.AssetId = Asset.Id where ASN.IsActive = 1  group by AssetId
		having COUNT(ASN.SerialNumber) = 1;


SELECT
ContractId,
ClassCode,
Cost
INTO #LoanContractAssetClassCode
FROM
(
SELECT
Rank=ROW_NUMBER () OVER ( PARTITION BY ContractId ORDER BY Cost desc),*
FROM
(
SELECT
ContractId,
ClassCode,
Cost=Sum(Cost)
FROM
(
SELECT
ContractId=Contracts.Id,
ClassCode=AssetClassCodes.ClassCode,
Cost=AssetValueHistories.NetValue_Amount
FROM Assets
INNER JOIN CollateralAssets ON Assets.Id =CollateralAssets.AssetId  and CollateralAssets.IsActive=1
INNER JOIN LoanFinances ON CollateralAssets.LoanFinanceId=LoanFinances.Id and LoanFinances.IsCurrent=1
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId=Assets.Id  and AssetValueHistories.IsLessorOwned = 1
INNER JOIN Contracts ON Contracts.Id=LoanFinances.ContractId
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GROUP BY
Contracts.Id,
AssetClassCodes.ClassCode,
AssetValueHistories.NetValue_Amount
)As AssetDetails
GROUP BY
ContractId,
ClassCode
)
AssetDetail
)
LoanAssetDetails WHERE Rank=1
SELECT
ContractId=LoanFinances.ContractId,
AssetId=Assets.Id,
ClassCode=AssetClassCodes.ClassCode,
Cost=AssetValueHistories.NetValue_Amount,
Description=AssetClassCodes.Description
INTO #LoanContractAssets
FROM
LoanFinances
INNER JOIN CollateralAssets ON CollateralAssets.LoanFinanceId=LoanFinances.Id and LoanFinances.IsCurrent=1
INNER JOIN Assets ON Assets.Id =CollateralAssets.AssetId  and CollateralAssets.IsActive=1
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId=Assets.Id  and AssetValueHistories.IsLessorOwned = 1
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GROUP BY
LoanFinances.ContractId,
Assets.Id,
AssetClassCodes.ClassCode,
AssetValueHistories.NetValue_Amount,
AssetClassCodes.Description
SELECT
ContractId,
AssetId,
ClassCode,
AssetCost=Cost,
Description=Description
INTO #LoanAssetClassCodeDetails
FROM
(
SELECT
ROW_NUMBER() over(PARTITION BY ContractId ORDER BY Cost desc)as RANK,*
FROM
#LoanContractAssets LCA
WHERE LCA.ClassCode IN
(SELECT
ClassCode
FROM #LoanContractAssetClassCode
WHERE ClassCode=LCA.ClassCode and ContractId=LCA.ContractId
)
) AS LoanFinancesAssets  WHERE RANK=1
SELECT
ContractId,
ClassCode,
Cost
INTO #LeaseContractAssetClassCode
FROM
(
SELECT
Rank=ROW_NUMBER () OVER ( PARTITION BY ContractId ORDER BY Cost desc),*
FROM
(
SELECT
ContractId,
ClassCode,
Cost=Sum(Cost)
FROM
(
SELECT
ContractId=Contracts.Id,
ClassCode=AssetClassCodes.ClassCode,
Cost=AssetValueHistories.NetValue_Amount
FROM Assets
INNER JOIN LeaseAssets ON Assets.Id =LeaseAssets.AssetId  and LeaseAssets.IsActive=1
INNER JOIN LeaseFinances ON LeaseAssets.LeaseFinanceId=LeaseFinances.Id and LeaseFinances.IsCurrent=1
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId=Assets.Id and AssetValueHistories.IsLessorOwned = 1
INNER JOIN Contracts ON Contracts.Id=LeaseFinances.ContractId
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GROUP BY
Contracts.Id,
AssetClassCodes.ClassCode,
AssetValueHistories.NetValue_Amount
)As AssetDetails
GROUP BY
ContractId,
ClassCode
)
AssetDetail
)
LeaseAssetDetails WHERE Rank=1
SELECT
ContractId=LeaseFinances.ContractId,
AssetId=Assets.Id,
ClassCode=AssetClassCodes.ClassCode,
Cost=AssetValueHistories.NetValue_Amount,
Description=AssetClassCodes.Description
INTO #LeaseContractAssets
FROM
LeaseFinances
INNER JOIN LeaseAssets ON LeaseAssets.LeaseFinanceId=LeaseFinances.Id and LeaseFinances.IsCurrent=1
INNER JOIN Assets ON Assets.Id =LeaseAssets.AssetId  and LeaseAssets.IsActive=1
INNER JOIN AssetValueHistories ON AssetValueHistories.AssetId=Assets.Id and AssetValueHistories.IsLessorOwned = 1
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId and AssetTypes.IsActive=1
INNER JOIN AssetClassCodes ON AssetClassCodes.Id=AssetTypes.AssetClassCodeId and AssetClassCodes.IsActive=1
GROUP BY
LeaseFinances.ContractId,
Assets.Id,
AssetClassCodes.ClassCode,
AssetValueHistories.NetValue_Amount,
AssetClassCodes.Description
SELECT
ContractId,
AssetId,
ClassCode,
AssetCost=Cost,
Description=Description
INTO #LeaseAssetClassCodeDetails
FROM
(
SELECT
ROW_NUMBER() over(PARTITION BY ContractId ORDER BY Cost desc)as RANK,*
FROM
#LeaseContractAssets LCA
WHERE LCA.ClassCode IN
(SELECT
ClassCode
FROM #LeaseContractAssetClassCode
WHERE ClassCode=LCA.ClassCode and ContractId=LCA.ContractId
)
) AS LeaseFinancesAssets  WHERE RANK=1
SELECT
ContractId
,AssetId
,ClassCode
,AssetCost
,Description
INTO #EquipmentDescription
FROM
(
SELECT ContractId,AssetId,ClassCode,AssetCost,Description FROM #LeaseAssetClassCodeDetails
UNION ALL
SELECT ContractId,AssetId,ClassCode,AssetCost,Description FROM #LoanAssetClassCodeDetails
) AS Temp_ContractEquipmentDescriptionDetails
SELECT
ContractId
,AssetId
,IsNULL(Description,'')As AssetDescription
,AssetClassCode=ClassCode
INTO #ContractEquipmentDescription
FROM
(
SELECT ContractId,AssetId,ClassCode,AssetCost,Description=#EquipmentDescription.Description
FROM #EquipmentDescription
INNER JOIN Assets ON #EquipmentDescription.AssetId=Assets.Id
INNER JOIN AssetTypes ON AssetTypes.Id=Assets.TypeId AND AssetTypes.IsActive=1
)
As ContractAssets
;WITH CTE_ReceivableInvoiceDetails AS
(
SELECT
ContractId
,AssessmentAmount
,AssessmentDescription
,InvoiceNumber
,AssessmentDate
,DueDate
,CustomerId
FROM
(
SELECT
ROW_Number() OVER(PARTITION BY ReceivableInvoice.Number ORDER BY ReceivableInvoice.Number)AS RowNumber
,ContractId=Contract.Id
,AssessmentAmount=ReceivableInvoice.InvoiceAmount_Amount+ReceivableInvoice.InvoiceTaxAmount_Amount
,AssessmentBalance=ReceivableInvoice.Balance_Amount+ReceivableInvoice.TaxBalance_Amount
,AssessmentDescription=ReceivableType.Name
,InvoiceNumber=ReceivableInvoice.Number
,AssessmentDate=convert(nvarchar(20),ReceivableInvoice.InvoiceRunDate,101)
,DueDate=convert(nvarchar(10),ReceivableInvoice.DueDate,101)
,CustomerId=ReceivableInvoice.CustomerId
FROM ReceivableInvoices ReceivableInvoice
INNER JOIN ReceivableInvoiceDetails ReceivableInvoiceDetail ON ReceivableInvoiceDetail.ReceivableInvoiceId=ReceivableInvoice.Id
AND ReceivableInvoice.IsActive=1
INNER JOIN ReceivableDetails ReceivableDetail ON ReceivableInvoiceDetail.ReceivableDetailId=ReceivableDetail.Id
AND ReceivableDetail.IsActive=1
INNER JOIN Receivables Receivable ON Receivable.Id=ReceivableDetail.ReceivableId
AND ReceivableInvoiceDetail.EntityId=Receivable.EntityId
AND Receivable.IsActive=1
AND Receivable.CustomerId=ReceivableInvoice.CustomerId
INNER JOIN ReceivableCodes ReceivableCode ON Receivable.ReceivableCodeId=ReceivableCode.Id
AND ReceivableCode.IsActive=1
INNER JOIN ReceivableTypes ReceivableType ON ReceivableCode.ReceivableTypeId=ReceivableType.Id
AND ReceivableType.IsActive=1
INNER JOIN Contracts Contract ON Contract.id=ReceivableInvoiceDetail.EntityId
AND Contract.Status='Commenced'
) AS Temp_receivable_Details WHERE RowNumber=1 AND (AssessmentAmount>0 OR AssessmentBalance>0)
),
CTE_ContractLevelDetails AS
(
SELECT
PurchaseOrderNumber=LoanFinance.ContractPurchaseOrderNumber
,LeaseNumber=Contracts.SequenceNumber
,CustomerId=LoanFinance.CustomerId
,ContractId=LoanFinance.ContractId
,CustomerInvoiceComment=Customers.InvoiceComment
FROM
Contracts
INNER JOIN LoanFinances LoanFinance ON LoanFinance.ContractId=Contracts.Id
AND LoanFinance.IsCurrent=1
AND LoanFinance.Status='Commenced'
AND Contracts.Status='Commenced'
INNER JOIN Customers On Customers.Id=LoanFinance.CustomerId
UNION ALL
SELECT
PurchaseOrderNumber=LeaseFinances.PurchaseOrderNumber
,LeaseNumber=Contracts.SequenceNumber
,CustomerId=LeaseFinances.CustomerId
,ContractId=LeaseFinances.ContractId
,CustomerInvoiceComment=Customers.InvoiceComment
FROM
Contracts
INNER JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND LeaseFinances.IsCurrent=1
AND LeaseFinances.BookingStatus='Commenced'
AND Contracts.Status='Commenced'
INNER JOIN Customers On Customers.Id=LeaseFinances.CustomerId
),
CTE_ContractWithAssetSerialNumber AS
(
SELECT
ContractId
,AssetId
,SerialNumber=ASN.SerialNumber
FROM #ContractEquipmentDescription
INNER JOIN Assets On #ContractEquipmentDescription.AssetId=Assets.Id
LEFT JOIN #AssetSerialNumbers ASN ON Assets.Id = ASN.AssetId 
),
WilliamsCustomerDetails AS
(
SELECT
AssessmentAmount
,AssessmentDescription=CONVERT(NVARCHAR(40),CASE
WHEN CTE_ReceivableInvoiceDetails.AssessmentDescription IN ('CapitalLeaseRental','OperatingLeaseRental','OperatingLeaseRental','InterimRental','OverTermRental','CPIBaseRental') THEN 'Rental Payment'
WHEN CTE_ReceivableInvoiceDetails.AssessmentDescription IN ('LeaseInterimInterest','LoanInterest') THEN 'Interest Payment'
WHEN CTE_ReceivableInvoiceDetails.AssessmentDescription ='LoanPrincipal' THEN  'Principal Payment'
ELSE CTE_ContractLevelDetails.CustomerInvoiceComment
END)
,InvoiceNumber
,AssessmentDate
,DueDate
,CustomerId=CTE_ReceivableInvoiceDetails.CustomerId
,PurchaseOrderNumber
,LeaseNumber
,SerialNumber
FROM
CTE_ReceivableInvoiceDetails
INNER JOIN CTE_ContractLevelDetails ON CTE_ReceivableInvoiceDetails.ContractId=CTE_ContractLevelDetails.ContractId
AND CTE_ReceivableInvoiceDetails.CustomerId=CTE_ContractLevelDetails.CustomerId
LEFT JOIN CTE_ContractWithAssetSerialNumber ON CTE_ContractWithAssetSerialNumber.ContractId=CTE_ReceivableInvoiceDetails.ContractId
)
SELECT
AssessmentAmount
,AssessmentDescription
,InvoiceNumber
,AssessmentDate
,DueDate
,CustomerId
,PurchaseOrderNumber
,LeaseNumber
,SerialNumber
FROM
WilliamsCustomerDetails
WHERE CustomerId IN (SELECT CustomerId FROM #WilliamsCustomers)
DROP TABLE #ContractEquipmentDescription
DROP TABLE #EquipmentDescription
DROP TABLE #LeaseAssetClassCodeDetails
DROP TABLE #LeaseContractAssetClassCode
DROP TABLE #LeaseContractAssets
DROP TABLE #LoanContractAssets
DROP TABLE #LoanAssetClassCodeDetails
DROP TABLE #LoanContractAssetClassCode
DROP TABLE #WilliamsCustomers
DROP TABLE #AssetSerialNumbers
END

GO

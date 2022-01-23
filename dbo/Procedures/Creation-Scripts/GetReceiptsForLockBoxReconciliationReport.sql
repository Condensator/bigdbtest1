SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[GetReceiptsForLockBoxReconciliationReport]
(
@FromDate DATETIME
,@ToDate DATETIME
,@JobId NVARCHAR(MAX)=NULL
,@CommaSeparatedLegalEntityIds NVARCHAR(MAX)
,@IsShowReceiptApplicationDetails NVARCHAR(2)
,@IsFullyPostedToInvoices NVARCHAR(2)
,@IsFullyPostedToUnAllocatedCash NVARCHAR(2)
,@IsPostedToInvoiceAndUnAllocatedCash NVARCHAR(2)
)
AS
--DECLARE @FromDate NVARCHAR(10)
--DECLARE @ToDate NVARCHAR(10)
--DECLARE @JobId NVARCHAR(max)
--DECLARE @IsFullyPostedToInvoices NVARCHAR(2)
--DECLARE @IsFullyPostedToUnAllocatedCash NVARCHAR(2)
--DECLARE @IsPostedToInvoiceAndUnAllocatedCash NVARCHAR(2)
--DECLARE @CommaSeparatedLegalEntityIds NVARCHAR(max)
--SET @JobId=null
--SET @FromDate='2016-01-01'
--SET @ToDate='2016-12-31'
--SET @IsFullyPostedToInvoices='1'
--SET @IsFullyPostedToUnAllocatedCash='1'
--SET @IsPostedToInvoiceAndUnAllocatedCash='1'
--SET @CommaSeparatedLegalEntityIds=null
BEGIN
SET NOCOUNT ON;
CREATE TABLE #LegalEntityIdsForLockBox (LegalEntityId Bigint);
DECLARE @TEXT NVARCHAR(max) = @CommaSeparatedLegalEntityIds
DECLARE @InsertStatement NVARCHAR(max) = 'insert into #LegalEntityIdsForLockBox(LegalEntityId) values ('''+REPLACE(@TEXT,',','''),(''')+''');';
--DECLARE @InsertStatement NVARCHAR(max) = 'insert into #LegalEntityIdsForLockBox(LegalEntityId) select Id from LegalEntities';
EXEC (@InsertStatement);
DECLARE @SQL NVARCHAR(Max)
SET @SQL=N'
;WITH CTE_CustomerInfo AS
(
SELECT
CustomerId=Parties.Id
,CustomerName=Parties.PartyName
FROM
Parties
INNER JOIN Customers On Customers.Id=Parties.Id
),
CTE_ContractWithCustomerInfo AS
(
SELECT
CustomerId=CASE WHEN Contracts.ContractType=''Lease'' THEN LeaseFinances.CustomerId
WHEN Contracts.ContractType IN (''Loan'',''ProgressLoan'') THEN LoanFinances.CustomerId
ELSE LeveragedLeases.CustomerId END
,ContractId=Contracts.Id
FROM
Contracts
LEFT JOIN LeaseFinances ON LeaseFinances.ContractId=Contracts.Id
AND LeaseFinances.IsCurrent=1
LEFT JOIN LoanFinances ON LoanFinances.ContractId=Contracts.Id
AND LoanFinances.IsCurrent=1
LEFT JOIn LeveragedLeases ON LeveragedLeases.ContractId=Contracts.Id
AND LeveragedLeases.IsCurrent=1
),
CTE_ReceiptsWithCustomerDetails AS
(
SELECT
ReceiptId=Receipts.Id
,CustomerName=CTE_CustomerInfo.CustomerName
FROM
Receipts
INNER JOIN CTE_ContractWithCustomerInfo ON Receipts.ContractId=CTE_ContractWithCustomerInfo.ContractId
AND Receipts.EntityType IN (''Lease'',''Loan'',''LeveragedLease'')
LEFT JOIN CTE_CustomerInfo ON CTE_CustomerInfo.CustomerId=CTE_ContractWithCustomerInfo.CustomerId
UNION ALL
SELECT
ReceiptId=Receipts.Id
,CustomerName=CTE_CustomerInfo.CustomerName
FROM
Receipts
INNER JOIN CTE_CustomerInfo ON CTE_CustomerInfo.CustomerId=Receipts.CustomerId
AND Receipts.EntityType IN (''Customer'')
),
CTE_ReceiptChargesAndTaxes AS
(
SELECT
ReceiptId=Receipts.Id
,Charges=SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount)
,Taxes=SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount)
,Total=SUM(ReceiptApplicationReceivableDetails.AmountApplied_Amount+ReceiptApplicationReceivableDetails.TaxApplied_Amount)
FROM
Receipts
INNER JOIN ReceiptApplications ON ReceiptApplications.ReceiptId=Receipts.Id
INNER JOIN ReceiptApplicationReceivableDetails ON ReceiptApplicationReceivableDetails.ReceiptApplicationId=ReceiptApplications.Id
AND ReceiptApplicationReceivableDetails.IsActive=1
GROUP BY Receipts.Id
)
SELECT
AccountNumber=''****'' + BankAccounts.LastFourDigitAccountNumber   --Encryption Change
,CustomerName=CTE_ReceiptsWithCustomerDetails.CustomerName
,ReceivedDate=CONVERT(NVARCHAR(10),Receipts.ReceivedDate)
,CheckNumber=Receipts.CheckNumber
,ReceiptAmount=Receipts.ReceiptAmount_Amount
,ReceiptId=Receipts.Number
,Status=Receipts.Status
,Charges=ISNULL(CTE_ReceiptChargesAndTaxes.Charges,0.0)
,Taxes=ISNULL(CTE_ReceiptChargesAndTaxes.Taxes,0.0)
,UnAllocatedCash=CASE WHEN @IsFullyPostedToUnAllocatedCash=''1'' THEN Receipts.Balance_Amount
ELSE 0.0 END
FROM Receipts
INNER JOIN ReceiptTypes ON ReceiptTypes.Id=Receipts.TypeId
AND ReceiptTypes.ReceiptTypeName=''LockBox''
INNER JOIN #LegalEntityIdsForLockBox ON #LegalEntityIdsForLockBox.LegalEntityId = Receipts.LegalEntityId
LEFT JOIN CTE_ReceiptsWithCustomerDetails ON Receipts.Id=CTE_ReceiptsWithCustomerDetails.ReceiptId
LEFT JOIN CTE_ReceiptChargesAndTaxes ON CTE_ReceiptChargesAndTaxes.ReceiptId=Receipts.Id
LEFT JOIN BankAccounts ON Receipts.BankAccountId=BankAccounts.Id
WHERE 1=1
'
IF @JobId Is NOT NULL
SET @SQL = @SQL+ N' AND Receipts.JobId = CONVERT(BIGINT,@JId) AND (@ReceiptFromDate IS NULL OR Receipts.ReceivedDate >= @ReceiptFromDate) AND (@ReceiptToDate IS NULL OR Receipts.ReceivedDate <= @ReceiptToDate)';
ELSE
SET @SQL = @SQL+ N' AND (@ReceiptFromDate IS NULL OR Receipts.ReceivedDate >= @ReceiptFromDate) AND (@ReceiptToDate IS NULL OR Receipts.ReceivedDate <= @ReceiptToDate)';
IF @JobId Is NULL
EXEC sp_executesql @SQL,N'@ReceiptFromDate DATETIMEOFFSET,@ReceiptToDate DATETIMEOFFSET,@IsFullyPostedToUnAllocatedCash NVARCHAR(2)',@ReceiptFromDate=@FromDate,@ReceiptToDate=@ToDate,@IsFullyPostedToUnAllocatedCash=@IsFullyPostedToUnAllocatedCash
ELSE
EXEC sp_executesql @SQL,N'@JId BIGINT, @ReceiptFromDate DATETIMEOFFSET,@ReceiptToDate DATETIMEOFFSET,@IsFullyPostedToUnAllocatedCash NVARCHAR(2)',@JId=@JobId,@ReceiptFromDate=@FromDate,@ReceiptToDate=@ToDate,@IsFullyPostedToUnAllocatedCash=@IsFullyPostedToUnAllocatedCash
DROP Table #LegalEntityIdsForLockBox
END

GO

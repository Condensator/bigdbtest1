SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetContractsWithoutUnallocatedCash]
(
@InputContractIds ContractIdsForAutoPayoff READONLY,
@ParameterDetailId BIGINT NULL
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @ReceiptLeaseEntityType NVARCHAR(5)
DECLARE @ReceiptPostedStatus NVARCHAR(6)
DECLARE @ReceiptCustomerEntityType NVARCHAR(10)
SET @ReceiptLeaseEntityType = (SELECT [Value] FROM #AutopayoffEnums WHERE [Name] = 'ReceiptLeaseEntityType')
SET @ReceiptPostedStatus = (SELECT [Value] FROM #AutopayoffEnums WHERE [Name] = 'ReceiptPostedStatus')
SET @ReceiptCustomerEntityType = (SELECT [Value] FROM #AutopayoffEnums WHERE [Name] = 'ReceiptCustomerEntityType')
SELECT * INTO #FilteredContracts FROM (
SELECT DISTINCT
ContractId = R.ContractId
FROM
Receipts R
JOIN @InputContractIds IC  ON R.ContractId = IC.Id
WHERE R.EntityType = @ReceiptLeaseEntityType
AND R.[Status] = @ReceiptPostedStatus
AND R.Balance_Amount <> 0
UNION
SELECT DISTINCT
ContractId = R.ContractId
FROM
Receipts R
JOIN ReceiptAllocations RA ON R.Id = RA.ReceiptId
JOIN @InputContractIds IC  ON RA.ContractId = IC.Id
WHERE      RA.EntityType = @ReceiptLeaseEntityType
AND R.[Status] = @ReceiptPostedStatus
AND RA.IsActive = 1
AND (RA.AllocationAmount_Amount - RA.AmountApplied_Amount) <> 0) AS #FilteredContracts
SELECT
Id
FROM
@InputContractIds
WHERE
Id NOT IN (SELECT ContractId FROM #FilteredContracts)
SET NOCOUNT OFF;
END

GO

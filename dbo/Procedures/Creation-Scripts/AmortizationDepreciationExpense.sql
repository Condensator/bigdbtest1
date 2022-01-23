SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AmortizationDepreciationExpense]
(
@CustomerName NVARCHAR(MAX) = NULL,
@LegalEntity NVARCHAR(MAX) = NULL,
@ContractSequenceNumber NVARCHAR(MAX) = NULL,
@AsOfDate DATETIME = NULL
)
AS
BEGIN
SET NOCOUNT ON;
IF OBJECT_ID('#AmortizationDepreciationExpences') IS NOT NuLL
drop table #AmortizationDepreciationExpences
SELECT
RANK() OVER(PARTITION BY contracts.SequenceNumber,DATEPART(YYYY,assetvaluehistory.IncomeDate) ORDER BY (DATEPART(M,assetvaluehistory.IncomeDate))) AS 'QRANK',
legalentity.LegalEntityNumber 'LegalEntityNumber',
parties.PartyName 'PartyName',
contracts.SequenceNumber 'SequenceNumber',
assetvaluehistory.Cost_Currency 'Currency',
leasefinancedetails.LeaseContractType 'Lease Type',
DATEPART(M,assetvaluehistory.IncomeDate)  'Month',
DATENAME(M,assetvaluehistory.IncomeDate)  'Month Name',
DATEPART(YYYY,assetvaluehistory.IncomeDate) 'YEAR',
SUM(assetvaluehistory.Value_Amount)*-1  'MTDDepreciationExpenses',
SUM(assetvaluehistory.Value_Amount)*-1  'QTDDepreciationExpenses',
SUM(assetvaluehistory.Value_Amount)*-1  'YTDDepreciationExpenses',
SUM(assetvaluehistory.Value_Amount)*-1  'LTDDepreciationExpenses'
Into #AmortizationDepreciationExpences
FROM LeaseFinances leasefinances
INNER JOIN Parties parties ON leasefinances.CustomerId = parties.Id
INNER JOIN Contracts contracts ON leasefinances.ContractId = contracts.Id
INNER JOIN LegalEntities legalentity ON legalentity.Id = leasefinances.LegalEntityId
INNER JOIN LeaseAssets leaseAssets ON leasefinances.Id = leaseAssets.LeaseFinanceId AND leaseAssets.IsActive = 1
--INNER JOIN Assets assets ON assets.LegalEntityId = legalentity.Id
INNER JOIN LeaseFinanceDetails leasefinancedetails ON leasefinancedetails.Id = leasefinances.Id
INNER JOIN AssetValueHistories assetvaluehistory on assetvaluehistory.AssetId = leaseAssets.AssetId
WHERE parties.CurrentRole = 'Customer' AND contracts.ContractType = 'Lease'
AND (@CustomerName IS NULL OR parties.PartyName = @CustomerName)
AND (@LegalEntity IS NULL OR legalentity.LegalEntityNumber in (select value from String_split(@LegalEntity,',')))
AND (@ContractSequenceNumber IS NULL OR contracts.SequenceNumber = @ContractSequenceNumber)
AND (assetvaluehistory.SourceModule IN ('FixedTermDepreciation','OTPDepreciation') AND assetvaluehistory.IsSchedule = 1 AND assetvaluehistory.IsLessorOwned =1)
AND (@AsOfDate IS NULL OR assetvaluehistory.IncomeDate <= @AsOfDate )
AND assetvaluehistory.FromDate != assetvaluehistory.ToDate
GROUP BY legalentity.LegalEntityNumber,parties.PartyName,contracts.SequenceNumber,assetvaluehistory.Cost_Currency,
leasefinancedetails.LeaseContractType,DATEPART(MM,assetvaluehistory.IncomeDate),
DATENAME(MM,assetvaluehistory.IncomeDate),DATEPART(YYYY,assetvaluehistory.IncomeDate)
DECLARE @QRunningTotal decimal(18,2);
DECLARE @QBalance decimal(18,2);
UPDATE #AmortizationDepreciationExpences SET @QBalance =(CASE  WHEN QRANK % 3 = 1 THEN  MTDDepreciationExpenses ELSE  @QRunningTotal + MTDDepreciationExpenses END) ,
QTDDepreciationExpenses = @QBalance,
@QRunningTotal = CASE  WHEN QRANK % 3 = 0 THEN  0 WHEN  QRANK % 3 = 1 THEN  MTDDepreciationExpenses ELSE  @QRunningTotal + MTDDepreciationExpenses END
DECLARE @YRunningTotal decimal(18,2);
DECLARE @YBalance decimal(18,2);
UPDATE #AmortizationDepreciationExpences SET @YBalance =(CASE  WHEN (QRANK = 1) THEN  MTDDepreciationExpenses ELSE  @YRunningTotal + MTDDepreciationExpenses END) ,
YTDDepreciationExpenses = @YBalance,
@YRunningTotal = CASE  WHEN QRANK = 1 THEN  MTDDepreciationExpenses  ELSE  @YRunningTotal + MTDDepreciationExpenses END
DECLARE @LRunningTotal decimal(18,2) = 0;
DECLARE @LBalance decimal(18,2) = 0;
DECLARE @PreviousSequenceNumber NVARCHAR(80) = '';
UPDATE #AmortizationDepreciationExpences SET @LBalance = CASE WHEN @PreviousSequenceNumber = '' OR @PreviousSequenceNumber != SequenceNumber THEN MTDDepreciationExpenses ELSE @LRunningTotal + MTDDepreciationExpenses END,
LTDDepreciationExpenses = @LBalance,
@LRunningTotal = CASE WHEN @PreviousSequenceNumber = '' OR @PreviousSequenceNumber != SequenceNumber THEN MTDDepreciationExpenses ELSE @LRunningTotal + MTDDepreciationExpenses END,
@PreviousSequenceNumber = SequenceNumber
SELECT * FROM #AmortizationDepreciationExpences
END

GO

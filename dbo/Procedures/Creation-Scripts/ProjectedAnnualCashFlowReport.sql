SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProjectedAnnualCashFlowReport]
(
@AsOfDate DATETIME = NULL
,@CustomerId AS NVARCHAR(40) = NULL
,@SequenceNumber AS NVARCHAR(40) = NULL
,@LeaseContractType NVARCHAR(40) = NULL
,@CommaSeparatedLegalEntityIds NVARCHAR(MAX) = NULL
)
AS
BEGIN
SET NOCOUNT ON;
SELECT ID AS LegalEntityId INTO #InputLegalEntities FROM ConvertCSVToBigIntTable(@CommaSeparatedLegalEntityIds,',')
SELECT	Contracts.Id,
Contracts.SequenceNumber AS SequenceNumber,
LegalEntities.Name AS LegalEntity,
LeaseFinanceDetails.LeaseContractType AS LeaseContractType
INTO #ContractDetails
FROM Contracts
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN LegalEntities ON LeaseFinances.LegalEntityId = LegalEntities.Id
WHERE LeaseFinances.IsCurrent = 1
AND (@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId)
AND (@LeaseContractType IS NULL OR LeaseFinanceDetails.LeaseContractType = @LeaseContractType)
AND (@CommaSeparatedLegalEntityIds IS NULL OR LegalEntities.Id IN (SELECT LegalEntityId FROM #InputLegalEntities))
DECLARE @CurrentFiscalMonth Date
SET @CurrentFiscalMonth = (SELECT CONVERT(DATE,DATEADD(MONTH, DATEDIFF(MONTH, 0, @AsOfDate), 0)))
SELECT  LegalEntities.Name AS LegalEnitityName,
LegalEntities.Id AS LegalEntityId,
CONVERT(DATE,LegalEntities.FiscalYearBeginMonthNo +  '01' + ' '+(SELECT CAST(DATEPART(YY,@AsOfDate) as nvarchar))) as FiscalYearStartingDate
INTO #StartDate
FROM LegalEntities
WHERE (@CommaSeparatedLegalEntityIds IS NULL OR LegalEntities.Id IN (SELECT LegalEntityId FROM #InputLegalEntities))
SELECT  LegalEnitityName,
LegalEntityId,
@CurrentFiscalMonth as CurrentFiscalMonthStart,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +1, 0))) as CurrentFiscalYearEnd,
DATEADD(YY, 1, #StartDate.FiscalYearStartingDate) AS FiscalYear2StartingDate,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +2, 0))) as FiscalYear2EndingDate,
DATEADD(YY, 2, #StartDate.FiscalYearStartingDate) AS FiscalYear3StartingDate,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +3, 0))) as FiscalYear3EndingDate,
DATEADD(YY, 3, #StartDate.FiscalYearStartingDate) AS FiscalYear4StartingDate,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +4, 0))) as FiscalYear4EndingDate,
DATEADD(YY, 4, #StartDate.FiscalYearStartingDate) AS FiscalYear5StartingDate,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +5, 0))) as FiscalYear5EndingDate,
DATEADD(YY, 5, #StartDate.FiscalYearStartingDate) AS FiscalYear6StartingDate,
CONVERT(DATE,DATEADD (DAY, -1, DATEADD(YEAR, DATEDIFF(YEAR, 0, #StartDate.FiscalYearStartingDate) +6, 0))) as FiscalYear6EndingDate
INTO #FiscalYearDates
FROM #StartDate

CREATE TABLE #YearDivision(
	Amount DECIMAL(16,2),
	CanBookedResidualAddedToCalc BIT,
	Id BIGINT,
	SequenceNumber NVARCHAR(50),
	Amount_Currency NVARCHAR(3),
	Year INT,
	DueDate DATE
);

INSERT INTO #YearDivision
SELECT
ReceivableDetails.LeaseComponentAmount_Amount,
CASE
WHEN LeaseFinanceDetails.LeaseContractType IN  ('SalesType','Operating','DirectFinance','ConditionalSales','Financing','IFRSFinanceLease')
THEN
1
ELSE
0
END AS CanBookedResidualAddedToCalc,
Contracts.Id,
Contracts.SequenceNumber AS SequenceNumber,
ReceivableDetails.Amount_Currency,
CASE
WHEN #FiscalYearDates.CurrentFiscalMonthStart <= DueDate
AND DueDate <= #FiscalYearDates.CurrentFiscalYearEnd
THEN
1
WHEN #FiscalYearDates.FiscalYear2StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear2EndingDate
THEN
2
WHEN #FiscalYearDates.FiscalYear3StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear3EndingDate
THEN
3
WHEN #FiscalYearDates.FiscalYear4StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear4EndingDate
THEN
4
WHEN #FiscalYearDates.FiscalYear5StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear5EndingDate
THEN
5
WHEN #FiscalYearDates.FiscalYear6StartingDate <= DueDate
THEN
6
END AS Year,
DueDate
FROM Receivables JOIN #FiscalYearDates ON Receivables.LegalEntityId = #FiscalYearDates.LegalEntityId
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Contracts ON Receivables.EntityId = Contracts.Id
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Assets ON ReceivableDetails.AssetId = Assets.Id
WHERE	(@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId)
AND LeaseFinances.IsCurrent = 1
AND ReceivableDetails.IsActive = 1
AND ReceivableTypes.Name IN ('CapitalLeaseRental', 'OperatingLeaseRental', 'LeaseFloatRateAdj')
AND Receivables.EntityType = 'CT'
AND Receivables.IsActive = 1
AND Assets.IsSKU=1

INSERT INTO #YearDivision
SELECT 
ReceivableDetails.Amount_Amount,
CASE
WHEN LeaseFinanceDetails.LeaseContractType IN  ('SalesType','Operating','DirectFinance','ConditionalSales','Financing','IFRSFinanceLease')
THEN
1
ELSE
0
END AS CanBookedResidualAddedToCalc,
Contracts.Id,
Contracts.SequenceNumber AS SequenceNumber,
ReceivableDetails.Amount_Currency,
CASE
WHEN #FiscalYearDates.CurrentFiscalMonthStart <= DueDate
AND DueDate <= #FiscalYearDates.CurrentFiscalYearEnd
THEN
1
WHEN #FiscalYearDates.FiscalYear2StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear2EndingDate
THEN
2
WHEN #FiscalYearDates.FiscalYear3StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear3EndingDate
THEN
3
WHEN #FiscalYearDates.FiscalYear4StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear4EndingDate
THEN
4
WHEN #FiscalYearDates.FiscalYear5StartingDate <= DueDate
AND DueDate <= #FiscalYearDates.FiscalYear5EndingDate
THEN
5
WHEN #FiscalYearDates.FiscalYear6StartingDate <= DueDate
THEN
6
END AS Year,
DueDate
FROM Receivables JOIN #FiscalYearDates ON Receivables.LegalEntityId = #FiscalYearDates.LegalEntityId
JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId
JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
JOIN Contracts ON Receivables.EntityId = Contracts.Id
JOIN LeaseFinances ON LeaseFinances.ContractId = Contracts.Id
JOIN LeaseFinanceDetails ON LeaseFinances.Id = LeaseFinanceDetails.Id
JOIN Assets ON ReceivableDetails.AssetId = Assets.Id
WHERE	(@SequenceNumber IS NULL OR Contracts.SequenceNumber = @SequenceNumber)
AND (@CustomerId IS NULL OR LeaseFinances.CustomerId = @CustomerId)
AND LeaseFinances.IsCurrent = 1
AND ReceivableDetails.IsActive = 1
AND ReceivableTypes.Name IN ('CapitalLeaseRental', 'OperatingLeaseRental', 'LeaseFloatRateAdj')
AND Receivables.EntityType = 'CT'
AND Receivables.IsActive = 1
AND ReceivableDetails.AssetComponentType  IN ('Lease', '_') 
AND Assets.IsSKU=0

SELECT	DISTINCT t1.Id,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)= (select distinct YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 1) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 1)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 1)
END,0) AS Year1,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)=(select distinct YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 2) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 2)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 2)
END,0) AS Year2,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)=(select distinct YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 3) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 3)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 3)
END,0) AS Year3,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)=(select distinct YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 4) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 4)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 4)
END,0) AS Year4,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)=(select distinct YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 5) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 5)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 5)
END,0) AS Year5,
ISNULL(CASE WHEN t1.CanBookedResidualAddedToCalc=1 AND YEAR(lfd.MaturityDate)<=(select distinct TOP 1 YEAR(DueDate) from #YearDivision where Id=t1.Id AND Year = 6) THEN
(select SUM(Amount)+lfd.BookedResidual_Amount AS Year1 from #YearDivision where Id=t1.Id AND Year = 6)
ELSE
(select SUM(Amount) AS Year1 from #YearDivision where Id=t1.Id AND Year = 6)
END,0) AS Year6AndAbove,
Amount_Currency
INTO #ProjectedAnnualCashFlow
FROM #YearDivision t1
JOIN LeaseFinances ON t1.Id=LeaseFinances.ContractId
JOIN LeaseFinanceDetails lfd ON LeaseFinances.Id = lfd.Id

SELECT  DISTINCT #ContractDetails.Id,
#ContractDetails.SequenceNumber,
#ContractDetails.LegalEntity,
#ContractDetails.LeaseContractType,
#ProjectedAnnualCashFlow.Year1,
#ProjectedAnnualCashFlow.Year2,
#ProjectedAnnualCashFlow.Year3,
#ProjectedAnnualCashFlow.Year4,
#ProjectedAnnualCashFlow.Year5,
#ProjectedAnnualCashFlow.Year6AndAbove,
Amount_Currency
FROM #ProjectedAnnualCashFlow JOIN #ContractDetails ON #ProjectedAnnualCashFlow.Id = #ContractDetails.Id
ORDER BY #ContractDetails.Id
DROP TABLE #StartDate
DROP TABLE #FiscalYearDates
DROP TABLE #InputLegalEntities
DROP TABLE #YearDivision
DROP TABLE #ContractDetails
DROP TABLE #ProjectedAnnualCashFlow
END

GO

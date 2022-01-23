SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[PreQuoteContractDelinquencySummary]
(
@ProcessThroughDate Datetime
,@CustomerId BigInt
,@ContractsCSV NVARCHAR(MAX)
,@IsCustomerLevel TINYINT
)
AS
BEGIN
SET NOCOUNT ON
--DECLARE	@ProcessThroughDate Datetime = GETDATE()
--DECLARE @CustomerId BigInt = 1
--DECLARE @ContractsCSV PreQuoteContractDelinquency READONLY
--CREATE TABLE #ContractsCSV (CustomerId BIGINT,ContractId BIGINT)
--INSERT INTO #ContractsCSV VALUES(1,164004)
--INSERT INTO #ContractsCSV VALUES(1,163978)
--INSERT INTO #ContractsCSV VALUES(1,194416)
--INSERT INTO #ContractsCSV VALUES(1,163952)
Create Table #Contracts(ContractId BigInt);
Create Table #InvoiceDetails(ContractId BigInt,InvoiceId BigInt,DueDate DateTime,ThresholdDays Int);
Create Table #AgeInDays(ContractId BigInt,InvoiceId BigInt,AgeInDays Int);
Create Table #TLCResult(ContractId BigInt,FivePlusDaysLate Int,ThirtyPlusDaysLate Int,SixtyPlusDaysLate Int,NinetyPlusDaysLate Int);
Create Table #TLCFinalResult(ContractId BigInt,FivePlusDaysLate Int,ThirtyPlusDaysLate Int,SixtyPlusDaysLate Int,NinetyPlusDaysLate Int);
SELECT @CustomerId CustomerId,Id AS ContractId INTO #ContractsCSV FROM ConvertCSVToBigIntTable(@ContractsCSV,',')
IF @IsCustomerLevel = 0
BEGIN
Insert Into #Contracts
Select Distinct Contracts.Id From Contracts
Join LoanFinances On Contracts.Id = LoanFinances.ContractId And LoanFinances.IsCurrent = 1
And Contracts.Status Not In('Cancelled','Terminated','Inactive')
JOIN #ContractsCSV ON Contracts.Id = #ContractsCSV.ContractId --AND LoanFinances.CustomerId = #ContractsCSV.CustomerId
Union All
Select Distinct Contracts.Id From Contracts
Join LeaseFinances On Contracts.Id = LeaseFinances.ContractId And LeaseFinances.IsCurrent = 1
And Contracts.Status Not In('Cancelled','Terminated','Inactive')
JOIN #ContractsCSV ON Contracts.Id = #ContractsCSV.ContractId --AND LeaseFinances.CustomerId = #ContractsCSV.CustomerId
Union All
Select Distinct Contracts.Id From Contracts
Join LeveragedLeases On Contracts.Id = LeveragedLeases.ContractId And Contracts.Status Not In('Cancelled','Terminated','Inactive')
JOIN #ContractsCSV ON Contracts.Id = #ContractsCSV.ContractId --AND LeveragedLeases.CustomerId = #ContractsCSV.CustomerId
END
ELSE
BEGIN
Insert Into #Contracts
Select Distinct Contracts.Id From Contracts
Join LoanFinances On Contracts.Id = LoanFinances.ContractId And LoanFinances.IsCurrent = 1
And Contracts.Status Not In('Cancelled','Terminated','Inactive')
WHERE Contracts.Id NOT IN (SELECT ContractId FROM #ContractsCSV) --AND LoanFinances.CustomerId = @CustomerId
Union All
Select Distinct Contracts.Id From Contracts
Join LeaseFinances On Contracts.Id = LeaseFinances.ContractId And LeaseFinances.IsCurrent = 1
And Contracts.Status Not In('Cancelled','Terminated','Inactive')
WHERE Contracts.Id NOT IN (SELECT ContractId FROM #ContractsCSV) --AND LeaseFinances.CustomerId = @CustomerId
Union All
Select Distinct Contracts.Id From Contracts
Join LeveragedLeases On Contracts.Id = LeveragedLeases.ContractId And Contracts.Status Not In('Cancelled','Terminated','Inactive')
WHERE Contracts.Id NOT IN (SELECT ContractId FROM #ContractsCSV) --AND LeveragedLeases.CustomerId = @CustomerId
END
Insert Into #InvoiceDetails
Select Distinct #Contracts.ContractId, ReceivableInvoices.Id,ReceivableInvoices.DueDate, LegalEntities.ThresholdDays
From ReceivableInvoiceDetails With(NoLock)
Join ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id And ReceivableInvoices.IsActive = 1 --Only Active Invoices
join LegalEntities on ReceivableInvoices.LegalEntityId = LegalEntities.Id
Join ReceivableDetails With(NoLock) On ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id
Join Receivables With(NoLock) On ReceivableDetails.ReceivableId = Receivables.Id and ReceivableInvoiceDetails.EntityId = Receivables.EntityId
Join ReceivableCodes On ReceivableCodes.Id = Receivables.ReceivableCodeId
Join ReceivableTypes On ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
Join #Contracts On #Contracts.ContractId = Receivables.EntityId
JOIN #ContractsCSV ON #ContractsCSV.CustomerId = ReceivableInvoices.CustomerId
Where ReceivableInvoiceDetails.EntityType = 'CT' And Receivables.IsActive = 1
And ReceivableTypes.Name In('InterimRental','CapitalLeaseRental','OperatingLeaseRental','LeveragedLeaseRental','OverTermRental'
,'Supplemental','LoanInterest','LoanPrincipal','LeaseInterimInterest','LeaseFloatRateAdj')
And ReceivableInvoiceDetails.Balance_Amount != 0 And ReceivableInvoices.DueDate <= @ProcessThroughDate;
Insert Into #AgeInDays
Select ContractId,InvoiceId,DATEDIFF(DD,DueDate + ThresholdDays,GetDate()) AgeInDays
From #InvoiceDetails
Insert Into #TLCResult
Select ContractId,0,0,0,0
From #AgeInDays
;With FivePlusDays As
(
Select ContractId,Count(InvoiceId) FivePlusDaysCount From #AgeInDays
Where AgeInDays > 15
And AgeInDays <= 30
Group By #AgeInDays.ContractId
)
Update #TLCResult Set FivePlusDaysLate = FivePlusDaysCount
From FivePlusDays
Join #TLCResult On #TLCResult.ContractId = FivePlusDays.ContractId
;With ThirtyPlusDays As
(
Select ContractId,Count(InvoiceId) ThirtyPlusDaysCount From #AgeInDays
Where AgeInDays > 30
And AgeInDays <= 60
Group By #AgeInDays.ContractId
)
Update #TLCResult Set ThirtyPlusDaysLate = ThirtyPlusDaysCount
From ThirtyPlusDays
Join #TLCResult On #TLCResult.ContractId = ThirtyPlusDays.ContractId
;With SixtyPlusDays As
(
Select ContractId,Count(InvoiceId) SixtyPlusDaysCount From #AgeInDays
Where AgeInDays > 60
And AgeInDays <= 90
Group By #AgeInDays.ContractId
)
Update #TLCResult Set SixtyPlusDaysLate = SixtyPlusDaysCount
From SixtyPlusDays
Join #TLCResult On #TLCResult.ContractId = SixtyPlusDays.ContractId
;With NinetyPlusDays As
(
Select ContractId,Count(InvoiceId) NinetyPlusDaysCount From #AgeInDays
Where AgeInDays > 90
--And AgeInDays <= 120
Group By #AgeInDays.ContractId
)
Update #TLCResult Set NinetyPlusDaysLate = NinetyPlusDaysCount
From NinetyPlusDays
Join #TLCResult On #TLCResult.ContractId = NinetyPlusDays.ContractId
Insert Into #TLCFinalResult
Select Distinct
ContractId ,FivePlusDaysLate
,ThirtyPlusDaysLate ,SixtyPlusDaysLate
,NinetyPlusDaysLate
From #TLCResult
SELECT
SequenceNumber
,Contracts.Id ContractId
,@CustomerId CustomerId
,ContractType
,ISNULL(#TLCFinalResult.FivePlusDaysLate,0) Fifteendayslate
,ISNULL(#TLCFinalResult.ThirtyPlusDaysLate,0) Thirtydayslate
,ISNULL(#TLCFinalResult.SixtyPlusDaysLate,0) Sixtydayslate
,ISNULL(#TLCFinalResult.NinetyPlusDaysLate,0) Nintydayslate
INTO #Final
From Contracts
JOIN #Contracts ON Contracts.Id = #Contracts.ContractId
LEFT Join #TLCFinalResult On #TLCFinalResult.ContractId = Contracts.Id
IF @IsCustomerLevel = 0
BEGIN
SELECT * FROM #Final
END
ELSE
BEGIN
SELECT
'' AS SequenceNumber,
0 AS ContractId,
CustomerId,
'_' AS ContractType,
SUM(Fifteendayslate) Fifteendayslate,
SUM(Thirtydayslate) Thirtydayslate,
SUM(Sixtydayslate) Sixtydayslate,
SUM(Nintydayslate) Nintydayslate
FROM #Final
GROUP BY CustomerId
END
Drop Table #Contracts;
Drop Table #InvoiceDetails;
Drop Table #AgeInDays;
Drop Table #TLCResult;
Drop Table #TLCFinalResult;
Drop Table #Final;
END

GO

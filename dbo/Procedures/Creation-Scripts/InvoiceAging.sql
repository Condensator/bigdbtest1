SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[InvoiceAging]
(
@CustomerNumber NVARCHAR(40) = NULL,
@CustomerName NVARCHAR(MAX) = NULL,
@ContractSequenceNumber NVARCHAR(MAX) = NULL,
@LineOfBusiness NVARCHAR(MAX) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@ReceivableType NVARCHAR(MAX) = NULL,
@Currency NVARCHAR(10) = NULL,
@AsOfDate DATETIME = NULL,
@Culture NVARCHAR(10)
)
AS
--DECLARE @CustomerNumber BIGINT = NULL
--DECLARE @CustomerName NVARCHAR(MAX) = null--'1179917'
--DECLARE @ContractSequenceNumber NVARCHAR(MAX) = '142-187'--'196213000'
--DECLARE @LineOfBusiness NVARCHAR(MAX) = NULL
--DECLARE @LegalEntityNumber NVARCHAR(MAX) = NULL
--DECLARE @ReceivableType NVARCHAR(MAX) = '5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29'
--DECLARE @Currency NVARCHAR(10) = NULL
--DECLARE @AsOfDate DATETIME = '2017-03-20'
--DECLARE @Culture NVARCHAR(5) = 'en-US'
SET NOCOUNT ON
SELECT ID into #TypeTemp from dbo.ConvertCSVToBigIntTable(@ReceivableType,',')
SELECT p.PartyNumber AS 'Customer #',
p.PartyName AS 'Customer Name',
c.SequenceNumber AS 'Sequence #',
c.Id 'ContractId',
le.LegalEntityNumber AS 'Legal Entity #',
lb.Id AS 'CT LineofBusinessId',
p.Id AS 'CustomerId',
rt.Name AS 'ReceivableType',
rid.InvoiceAmount_Currency AS 'Currency',
rid.EntityType,
rid.EntityId,
r.Id,
ri.BillToId,
DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) days,
rid.Balance_Amount+rid.TaxBalance_Amount 'Total',
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) >= 0 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [Current],
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) < 0 AND DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) >= -30 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [0-30],
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) < -30 AND DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) >= -60 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [30-60],
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) < -60 AND DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) >= -90 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [60-90],
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) < -90 AND DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) >= -120 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [90-120],
CASE
WHEN DATEDIFF(dd,@AsOfDate,DATEADD(Day,le.ThresholdDays,ri.DueDate)) < -120 THEN rid.Balance_Amount+rid.TaxBalance_Amount
ELSE 0
END [>120]
INTO #test
FROM dbo.ReceivableInvoices ri
INNER JOIN dbo.ReceivableInvoiceDetails rid ON rid.ReceivableInvoiceId = ri.Id AND ri.IsActive = 1 AND ri.IsDummy = 0
INNER JOIN dbo.ReceivableDetails rd ON rid.ReceivableDetailId = rd.Id
INNER JOIN dbo.Receivables r ON rd.ReceivableId = r.Id
INNER JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
INNER JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
INNER JOIN dbo.#TypeTemp tt ON rt.Id = tt.ID
INNER JOIN dbo.LegalEntities le ON ri.LegalEntityId = le.Id
INNER JOIN dbo.Parties p ON ri.CustomerId = p.Id
LEFT JOIN dbo.Contracts c ON rid.EntityId = c.Id AND rid.EntityType = 'CT'
LEFT JOIN dbo.LineofBusinesses lb ON c.LineofBusinessId = lb.Id
WHERE rid.Balance_Amount+rid.TaxBalance_Amount != 0
AND r.IsActive = 1
AND rid.Isactive = 1
AND rd.IsActive = 1
AND (@CustomerNumber IS NULL OR p.PartyNumber = @CustomerNumber)
AND (@CustomerName IS NULL OR p.PartyName = @CustomerName)
AND (@ContractSequenceNumber IS NULL OR c.SequenceNumber = @ContractSequenceNumber)
AND (@LegalEntityNumber IS NULL OR le.LegalEntityNumber in (select value from String_split(@LegalEntityNumber,',')))
AND (@Currency IS NULL OR rid.InvoiceAmount_Currency = @Currency)
SELECT Distinct r.Id AS 'ReceivableId',IsNUll(s.LineofBusinessId,ISNULL(sd.LineofBusinessId,sr.LineofBusinessId)) AS 'CU LineOfBusinessId' INTO #test1
FROM #test r
LEFT JOIN dbo.Sundries s ON s.ReceivableId = r.Id
LEFT JOIN dbo.SecurityDeposits sd ON sd.ReceivableId = r.Id
LEFT JOIN dbo.SundryRecurringPaymentSchedules srps ON srps.ReceivableId = r.Id
LEFT JOIN dbo.SundryRecurrings sr ON srps.SundryRecurringId = sr.Id
SELECT t.CustomerId,t.ContractId,t.[Customer #],t.[Customer Name],t.[Sequence #],t.[Legal Entity #],t.BillToId,
ISNULL(lb.Name,lb2.Name) AS 'Line of Business',t.ReceivableType,t.Currency,
t.days,t.Total,t.[Current], t.[0-30], t.[30-60], t.[60-90], t.[90-120], t.[>120]
INTO #test2
from dbo.#test t
INNER JOIN dbo.#test1 t2 ON t.Id = t2.ReceivableId
LEFT JOIN dbo.LineofBusinesses lb ON t.[CT LineofBusinessId] = lb.Id
LEFT JOIN dbo.LineofBusinesses lb2 ON t2.[CU LineOfBusinessId] = lb2.Id
WHERE (@LineOfBusiness IS NULL OR lb.Name = @LineOfBusiness OR lb2.Name = @LineOfBusiness)
;WITH CTE_PartyBalanceDetails(CustomerId,ContractId,CustomerNo,CustomerName,Currency,Total,[Current],[0-30],[30-60],[60-90],[90-120],[>120],[Sequence #],[Legal Entity #],[Line of Business],[BillToId])
AS
(
SELECT t.CustomerId,t.ContractId, t.[Customer #], t.[Customer Name], t.Currency,
SUM(t.Total),SUm(t.[Current]),Sum(t.[0-30]),Sum(t.[30-60]),SUM(t.[60-90]),SUM(t.[90-120]),Sum(t.[>120]),
t.[Sequence #],t.[Legal Entity #],t.[Line of Business],t.[BillToId] FROM dbo.#test2 t
GROUP BY t.CustomerId,t.ContractId,t.[Customer #], t.[Customer Name], t.Currency,t.[Sequence #],t.[Legal Entity #],t.[Line of Business],t.[BillToId]
)
,CTE_PartyContactDetails(BillToId,ContactPersonName,Address) AS
(
select
DISTINCT basedetails.[BillToId],pc.FullName,
Isnull(pa.AddressLine1,pa.HomeAddressLine1)+', '+Isnull(pa.City,pa.HomeCity)+', '+Isnull(er.[Value],ISnull(s.LongName,hs.LongName))+', '+Isnull(pa.PostalCode,pa.HomePostalCode) AS 'Contact Address'
from  CTE_PartyBalanceDetails  basedetails
INNER JOIN BillToes bt on basedetails.BillToId = bt.Id
INNER JOIN dbo.Parties p ON bt.CustomerId = p.Id
LEFT JOIN dbo.PartyAddresses pa ON bt.BillingAddressId = pa.Id
LEFT JOIN dbo.States s ON pa.StateId = s.Id
LEFT JOIN dbo.States hs ON pa.HomeStateId = hs.Id
LEFT JOIN dbo.EntityResources er ON er.EntityId = isnull(s.Id,hs.Id) AND er.EntityType = 'State' AND er.Name = 'LongName' AND er.Culture = @Culture
LEFT JOIN dbo.PartyContacts pc ON bt.BillingContactPersonId = pc.Id AND pc.IsActive = 1
LEFT JOIN dbo.PartyContactTypes pct ON pct.PartyContactId = pc.Id  AND pct.IsActive = 1
)
SELECT cpbd.CustomerNo AS 'Customer #', cpbd.CustomerName,cpcd.ContactPersonName, cpcd.Address,cpbd.[Sequence #],cpbd.[Legal Entity #],cpbd.[Line of Business],cpbd.Currency,
SUM(cpbd.Total) - SUM(cpbd.[Current]) AS 'Total', SUM(cpbd.[Current]) AS 'Current', SUM(cpbd.[0-30]) [0-30], SUM(cpbd.[30-60]) [30-60],SUM(cpbd.[60-90]) [60-90], SUM(cpbd.[90-120]) [90-120], SUM(cpbd.[>120])  [>120]from
CTE_PartyBalanceDetails cpbd
INNER JOIN CTE_PartyContactDetails cpcd ON cpbd.[BillToId] = cpcd.[BillToId]
GROUP BY  cpbd.CustomerNo, cpbd.CustomerName,cpcd.ContactPersonName, cpcd.Address,cpbd.[Sequence #],cpbd.[Legal Entity #],cpbd.[Line of Business],cpbd.Currency
ORDER BY cpbd.[Legal Entity #]
DROp TABLE #test
DROp TABLE #test1
DROp TABLE #test2
DROP TABLE #TypeTemp

GO

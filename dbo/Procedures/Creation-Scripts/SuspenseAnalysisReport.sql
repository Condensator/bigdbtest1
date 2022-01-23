SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SuspenseAnalysisReport]
(
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET,
@EntityType NVARCHAR(MAX) = NULL,
@EntityTypeLabel NVARCHAR(MAX) = NULL,
@EntityId NVARCHAR(MAX) = NULL,
@Entity NVARCHAR(MAX) = NULL
)
AS
--declare
--	@FromDate DATETIMEOFFSET = '01/01/2000',
--	@ToDate DATETIMEOFFSET = '12/31/2020',
--	@EntityType NVARCHAR(MAX) = 'LegalEntity',
--	@EntityTypeLabel NVARCHAR(MAX) = null,
--	@EntityId NVARCHAR(MAX) = '1,2,3,20028',
--	@Entity NVARCHAR(MAX) = NULL
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
IF(@EntityType = 'Lease' or @EntityType = 'Loan' or @EntityType = 'LeveragedLease' or @EntityType = 'Contract')
BEGIN
SET @EntityType = 'Contract'
END
CREATE TABLE #GLBalanceSummary
(Currency nvarchar(10),
GLAccountNumber nvarchar(150),
GLAccountName nvarchar(150),
BeginBalance  Decimal(16,2),
DebitAmount  Decimal(16,2),
CreditAmount  Decimal(16,2),
EndBalance  Decimal(16,2),
LegalEntityNumber nvarchar(250),
PartyName NVarChar(250),
ReceiptTypeName NVarChar(50),
ReceiptBatchName NVarChar(50),
PostDate datetime,
ReceivedDate datetime,
CheckNumber NVarChar(50),
Description NVarChar(500),
ReceiptID bigint,GLJournalId bigint)
CREATE TABLE #GLJournals
(Id BIGINT)
INSERT INTO #GLJournals SELECT Id from GLJournals where CAST(GLJournals.PostDate AS DATE) < CAST(@FromDate AS DATE)
CREATE TABLE #GLJournalsTemp
(Id BIGINT,
LegalEntityId BIGINT,
PostDate datetime
)
INSERT INTO #GLJournalsTemp SELECT Id,LegalEntityId,PostDate from GLJournals where (CAST(GLJournals.PostDate AS DATE) >= CAST(@FromDate AS DATE)
AND CAST(GLJournals.PostDate AS DATE) <= CAST(@ToDate AS DATE))
CREATE TABLE #GLJournalDetailsTemp
(
Id BIGINT,
GLJournalId BIGINT,
EntityId BIGINT,
GLAccountId BIGINT,
GLTemplateDetailId BIGINT,
EntityType nvarchar(150),
Description nvarchar(400),
IsDebit bit,
Amount_Amount Decimal(16,2),
GLAccountNumber nvarchar(150),
Amount_Currency nvarchar(150)
)
CREATE TABLE #DisbursementRequest
(Id BIGINT,
DisbursementRequestId BIGINT,
GLJournalId BIGINT,
EntityId BIGINT,
GLAccountId BIGINT,
GLTemplateDetailId BIGINT,
EntityType nvarchar(150),
Description nvarchar(400),
IsDebit bit,
Amount_Amount Decimal(16,2),
GLAccountNumber nvarchar(150),
Amount_Currency nvarchar(150)
)
IF(@EntityType is NULL)
BEGIN
insert into #GLJournalDetailsTemp select GLJournalDetails.Id,GLJournalDetails.GLJournalId,GLJournalDetails.EntityId,GLJournalDetails.GLAccountId,
GLJournalDetails.GLTemplateDetailId,GLJournalDetails.EntityType,GLJournalDetails.Description,GLJournalDetails.IsDebit,GLJournalDetails.Amount_Amount,
GLJournalDetails.GLAccountNumber,GLJournalDetails.Amount_Currency from GLJournalDetails
END
IF(@EntityType = 'Customer')
BEGIN
insert into #GLJournalDetailsTemp select GLJournalDetails.Id,GLJournalDetails.GLJournalId,GLJournalDetails.EntityId,GLJournalDetails.GLAccountId,
GLJournalDetails.GLTemplateDetailId,GLJournalDetails.EntityType,GLJournalDetails.Description,GLJournalDetails.IsDebit,GLJournalDetails.Amount_Amount,
GLJournalDetails.GLAccountNumber,GLJournalDetails.Amount_Currency
from GLJournalDetails JOIN Parties ON GLJournalDetails.EntityId = Parties.Id
AND GLJournalDetails.EntityType = 'Customer'
where (@EntityId IS NULL OR Parties.Id = @EntityId) AND GLJournalDetails.EntityType != 'DisbursementRequest'
END
IF(@EntityType = 'LegalEntity')
BEGIN
insert into #GLJournalDetailsTemp select GLJournalDetails.Id,GLJournalDetails.GLJournalId,GLJournalDetails.EntityId,GLJournalDetails.GLAccountId,
GLJournalDetails.GLTemplateDetailId,GLJournalDetails.EntityType,GLJournalDetails.Description,GLJournalDetails.IsDebit,GLJournalDetails.Amount_Amount,
GLJournalDetails.GLAccountNumber,GLJournalDetails.Amount_Currency from GLJournalDetails  JOIN LegalEntities AS GLLegalEntities ON GLJournalDetails.EntityId = GLLegalEntities.Id
AND GLJournalDetails.EntityType = 'LegalEntity'
where (@EntityId IS NULL OR GLLegalEntities.Id in (select value from String_split(@EntityId,','))) AND GLJournalDetails.EntityType != 'DisbursementRequest'
END
IF(@EntityType = 'Lease' or @EntityType = 'Loan' or @EntityType = 'LeveragedLease' or @EntityType = 'Contract')
BEGIN
insert into #GLJournalDetailsTemp select GLJournalDetails.Id,GLJournalDetails.GLJournalId,GLJournalDetails.EntityId,GLJournalDetails.GLAccountId,
GLJournalDetails.GLTemplateDetailId,GLJournalDetails.EntityType,GLJournalDetails.Description,GLJournalDetails.IsDebit,GLJournalDetails.Amount_Amount,
GLJournalDetails.GLAccountNumber,GLJournalDetails.Amount_Currency from GLJournalDetails JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id
AND GLJournalDetails.EntityType = 'Contract'
where (@EntityId IS NULL OR Contracts.Id = @EntityId) AND (@EntityTypeLabel is null OR Contracts.ContractType = @EntityTypeLabel) AND GLJournalDetails.EntityType != 'DisbursementRequest'
END
IF(@EntityType = 'DisbursementRequest' OR @EntityType is NULL)
BEGIN
INSERT INTO #DisbursementRequest SELECT GLJournalDetails.Id,DisbursementRequests.Id,GLJournalDetails.GLJournalId,GLJournalDetails.EntityId,GLJournalDetails.GLAccountId,
GLJournalDetails.GLTemplateDetailId,GLJournalDetails.EntityType,GLJournalDetails.Description,GLJournalDetails.IsDebit,GLJournalDetails.Amount_Amount,
GLJournalDetails.GLAccountNumber,GLJournalDetails.Amount_Currency from DisbursementRequests
JOIN GLJournalDetails ON GLJournalDetails.EntityId = DisbursementRequests.Id
AND GLJournalDetails.EntityType = 'DisbursementRequest'
WHERE ((@EntityId IS NULL )OR (@EntityId IS NOT NULL AND DisbursementRequests.Id =@EntityId))
END
CREATE TABLE #GLForBeginBalance
(DebitAmount Decimal(16,2),
CreditAmount Decimal(16,2),
ReceiptId BIGINT
)
CREATE TABLE #GLBeginBalance
(BeginBalance Decimal(16,2),
ReceiptId BIGINT
)
CREATE TABLE #GLBalance
(
GLAccountNumber nvarchar(150),
GLAccountName nvarchar(150),
DebitAmount Decimal(16,2),
CreditAmount Decimal(16,2),
GLJournalId BIGINT,
LegalEntityId BIGINT,
CurrencyCode nvarchar(10),
Description nvarchar(400),
PartyName nvarchar(150),
ReceiptID BIGINT,
PostDate datetime,
ReceivedDate datetime,
CheckNumber nvarchar(150),
ReceiptBatchName nvarchar(150),
ReceiptTypeName nvarchar(150)
)
CREATE TABLE #GLBalanceSummaryGroup
(
GLAccountNumber nvarchar(150),
GLAccountName nvarchar(150),
DebitAmount Decimal(16,2),
CreditAmount Decimal(16,2),
GLJournalId BIGINT,
LegalEntityId BIGINT,
CurrencyCode nvarchar(10),
Description nvarchar(400),
PartyName nvarchar(150),
ReceiptID BIGINT,
PostDate datetime,
ReceivedDate datetime,
CheckNumber nvarchar(150),
ReceiptBatchName nvarchar(150),
ReceiptTypeName nvarchar(150)
)
INSERT INTO  #GLForBeginBalance
SELECT
CASE WHEN #GLJournalDetailsTemp.IsDebit = 1 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 0 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS CreditAmount,
ReceiptGLJournals.ReceiptId AS 'ReceiptId'
FROM
#GLJournals
JOIN #GLJournalDetailsTemp ON #GLJournals.Id = #GLJournalDetailsTemp.GLJournalId
JOIN ReceiptGLJournals ON ReceiptGLJournals.GLJournalId =#GLJournals.Id
JOIN GLTemplateDetails on #GLJournalDetailsTemp.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
UNION
SELECT
CASE WHEN #GLJournalDetailsTemp.IsDebit = 1 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 0 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END CreditAmount,
ReceiptApplications.ReceiptId AS 'ReceiptId'
FROM
#GLJournals
JOIN #GLJournalDetailsTemp ON #GLJournals.Id = #GLJournalDetailsTemp.GLJournalId
JOIN ReceiptApplicationGLJournals ON ReceiptApplicationGLJournals.GLJournalId =#GLJournals.Id
JOIN ReceiptApplications ON ReceiptApplicationGLJournals.ReceiptApplicationId=ReceiptApplications.Id
JOIN GLTemplateDetails ON #GLJournalDetailsTemp.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
UNION
SELECT
CASE WHEN #DisbursementRequest.IsDebit = 1 THEN Payables.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #DisbursementRequest.IsDebit = 0 THEN Payables.Amount_Amount ELSE 0 END AS CreditAmount,
Receipts.Id AS 'ReceiptID'
FROM
Payables
JOIN DisbursementRequestPayables ON DisbursementRequestPayables.PayableId = Payables.Id
JOIN #DisbursementRequest ON #DisbursementRequest.DisbursementRequestId = DisbursementRequestPayables.DisbursementRequestId
JOIN #GLJournals ON #GLJournals.Id = #DisbursementRequest.GLJournalId
JOIN GLTemplateDetails on #DisbursementRequest.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
JOIN receipts ON receipts.Id = Payables.SourceId and Payables.SourceTable = 'Receipt'
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
INSERT INTO #GLBeginBalance
SELECT
SUM(CreditAmount)-SUM(DebitAmount)  AS BeginBalance,
ReceiptId
FROM
#GLForBeginBalance
GROUP BY
ReceiptId
INSERT INTO #GLBalance
SELECT
#GLJournalDetailsTemp.GLAccountNumber,
GLAccounts.Name AS GLAccountName,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 1 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 0 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS CreditAmount,
#GLJournalsTemp.Id as 'GLJournalId',
#GLJournalsTemp.LegalEntityId,
#GLJournalDetailsTemp.Amount_Currency AS CurrencyCode,
#GLJournalDetailsTemp.Description,
Customer.PartyName,
Receipts.ID AS 'ReceiptID',
#GLJournalsTemp.PostDate,
Receipts.ReceivedDate,
Receipts.CheckNumber,
ReceiptBatches.Name AS 'ReceiptBatchName',
ReceiptTypes.ReceiptTypeName
FROM #GLJournalsTemp
JOIN #GLJournalDetailsTemp ON #GLJournalsTemp.Id = #GLJournalDetailsTemp.GLJournalId
JOIN ReceiptGLJournals ON ReceiptGLJournals.GLJournalId =#GLJournalsTemp.Id
JOIN Receipts ON ReceiptGLJournals.ReceiptId=Receipts.Id
JOIN ReceiptTypes ON Receipts.TypeId=ReceiptTypes.Id
JOIN GLAccounts ON #GLJournalDetailsTemp.GLAccountId = GLAccounts.Id
JOIN GLTemplateDetails on #GLJournalDetailsTemp.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
LEFT JOIN Parties Customer ON Receipts.CustomerId=Customer.Id
LEFT JOIN  ReceiptBatches ON Receipts.ReceiptBatchId=ReceiptBatches.Id
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
UNION
SELECT
#GLJournalDetailsTemp.GLAccountNumber,
GLAccounts.Name AS GLAccountName,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 1 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #GLJournalDetailsTemp.IsDebit = 0 THEN #GLJournalDetailsTemp.Amount_Amount ELSE 0 END AS CreditAmount,
#GLJournalsTemp.Id as 'GLJournalId',
#GLJournalsTemp.LegalEntityId,
#GLJournalDetailsTemp.Amount_Currency AS CurrencyCode,
#GLJournalDetailsTemp.Description,
Customer.PartyName,
Receipts.ID AS 'ReceiptID',
#GLJournalsTemp.PostDate,
Receipts.ReceivedDate,
Receipts.CheckNumber,
ReceiptBatches.Name AS 'ReceiptBatchName',
ReceiptTypes.ReceiptTypeName
FROM #GLJournalsTemp
JOIN #GLJournalDetailsTemp ON #GLJournalsTemp.Id = #GLJournalDetailsTemp.GLJournalId
JOIN ReceiptApplicationGLJournals ON ReceiptApplicationGLJournals.GLJournalId =#GLJournalsTemp.Id
JOIN ReceiptApplications ON ReceiptApplicationGLJournals.ReceiptApplicationId=ReceiptApplications.Id
JOIN Receipts ON ReceiptApplications.ReceiptId=Receipts.Id
JOIN ReceiptTypes ON Receipts.TypeId=ReceiptTypes.Id
JOIN GLAccounts ON #GLJournalDetailsTemp.GLAccountId = GLAccounts.Id
JOIN GLTemplateDetails on #GLJournalDetailsTemp.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id
LEFT JOIN Parties Customer ON Receipts.CustomerId=Customer.Id
LEFT JOIN  ReceiptBatches ON Receipts.ReceiptBatchId=ReceiptBatches.Id
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
UNION
SELECT
#DisbursementRequest.GLAccountNumber,
GLAccounts.Name AS GLAccountName,
CASE WHEN #DisbursementRequest.IsDebit = 1 THEN Payables.Amount_Amount ELSE 0 END AS DebitAmount,
CASE WHEN #DisbursementRequest.IsDebit = 0 THEN Payables.Amount_Amount ELSE 0 END AS CreditAmount,
#GLJournalsTemp.Id as 'GLJournalId',
#GLJournalsTemp.LegalEntityId,
#DisbursementRequest.Amount_Currency AS CurrencyCode,
#DisbursementRequest.Description,
Customer.PartyName,
Receipts.ID AS 'ReceiptID',
#GLJournalsTemp.PostDate,
Receipts.ReceivedDate,
Receipts.CheckNumber,
ReceiptBatches.Name AS 'ReceiptBatchName',
ReceiptTypes.ReceiptTypeName
FROM
Payables
JOIN DisbursementRequestPayables ON DisbursementRequestPayables.PayableId = Payables.Id
JOIN #DisbursementRequest ON #DisbursementRequest.DisbursementRequestId = DisbursementRequestPayables.DisbursementRequestId
JOIN GLAccounts ON GLAccounts.Id = #DisbursementRequest.GLAccountId
JOIN #GLJournalsTemp ON #GLJournalsTemp.Id = #DisbursementRequest.GLJournalId
JOIN GLTemplateDetails on #DisbursementRequest.GLTemplateDetailId=GLTemplateDetails.Id
JOIN GLEntryItems ON GLTemplateDetails.EntryItemId= GLEntryItems.id
JOIN receipts ON receipts.Id = Payables.SourceId and Payables.SourceTable = 'Receipt'
LEFT JOIN  ReceiptBatches ON receipts.ReceiptBatchId = ReceiptBatches.Id
LEFT JOIN  ReceiptTypes ON Receipts.TypeId=ReceiptTypes.Id
LEFT JOIN Parties Customer ON Receipts.CustomerId=Customer.Id
WHERE
GLEntryItems.Name = 'UnappliedAR' AND GLEntryItems.IsActive=1
INSERT INTO #GLBalanceSummaryGroup
SELECT
GLAccountNumber,
GLAccountName,
SUM(DebitAmount) AS DebitAmount,
SUM(CreditAmount) AS CreditAmount,
GLJournalId ,
LegalEntityId,
MIN(CurrencyCode) As CurrencyCode,
Description,
PartyName,
ReceiptID,
PostDate ,
ReceivedDate,
CheckNumber,
ReceiptBatchName,
ReceiptTypeName
FROM
#GLBalance
GROUP BY
GLAccountNumber,GLAccountName,LegalEntityId,PartyName,ReceiptBatchName,ReceiptTypeName,PostDate,ReceivedDate
,CheckNumber,Description,ReceiptID,GLJournalId
INSERT INTO #GLBalanceSummary
SELECT
#GLBalanceSummaryGroup.CurrencyCode AS Currency,
#GLBalanceSummaryGroup.GLAccountNumber AS GLAccountNumber,
#GLBalanceSummaryGroup.GLAccountName AS GLAccountName,
ISNULL(#GLBeginBalance.BeginBalance,0.0)
AS BeginBalance,
ISNULL(#GLBalanceSummaryGroup.DebitAmount,0.0) AS DebitAmount,
ISNULL(#GLBalanceSummaryGroup.CreditAmount,0.0) AS CreditAmount,
ISNULL(#GLBeginBalance.BeginBalance,0.0)
-ISNULL(#GLBalanceSummaryGroup.DebitAmount,0.0)+ISNULL(#GLBalanceSummaryGroup.CreditAmount,0.0) AS 'EndBalance',
LegalEntities.LegalEntityNumber AS LegalEntityNumber,
#GLBalanceSummaryGroup.PartyName AS PartyName,
#GLBalanceSummaryGroup.ReceiptTypeName AS ReceiptTypeName,
#GLBalanceSummaryGroup.ReceiptBatchName AS ReceiptBatchName,
#GLBalanceSummaryGroup.PostDate AS PostDate,
#GLBalanceSummaryGroup.ReceivedDate AS ReceivedDate,
#GLBalanceSummaryGroup.CheckNumber AS CheckNumber,
#GLBalanceSummaryGroup.Description AS Description,
#GLBalanceSummaryGroup.ReceiptId,
#GLBalanceSummaryGroup.GLJournalId
FROM #GLBalanceSummaryGroup
LEFT JOIN  #GLBeginBalance ON #GLBeginBalance.ReceiptId = #GLBalanceSummaryGroup.ReceiptID
LEFT JOIN LegalEntities ON #GLBalanceSummaryGroup.LegalEntityId = LegalEntities.Id
ORDER BY
LEN(#GLBalanceSummaryGroup.GLAccountNumber),
#GLBalanceSummaryGroup.GLAccountNumber
SELECT
SUM(GLBalanceSummary2.EndBalance) as BeginBalance,
GLBalanceSummary.ReceiptId,
GLBalanceSummary.GLJournalId
INTO #GLBalanceDetail
FROM
#GLBalanceSummary GLBalanceSummary
INNER JOIN #GLBalanceSummary GLBalanceSummary2 ON GLBalanceSummary2.ReceiptId = GLBalanceSummary.ReceiptId
AND GLBalanceSummary2.GLJournalId < GLBalanceSummary.GLJournalId
GROUP BY
GLBalanceSummary.ReceiptId,
GLBalanceSummary.GLJournalId
SELECT
#GLBalanceSummary.Currency,
#GLBalanceSummary.GLAccountNumber AS GLAccountNumber,
#GLBalanceSummary.GLAccountName AS GLAccountName,
isnull(#GLBalanceDetail.BeginBalance,#GLBalanceSummary.BeginBalance) as BeginBalance,
#GLBalanceSummary.DebitAmount,
#GLBalanceSummary.CreditAmount,
isnull(#GLBalanceDetail.BeginBalance,#GLBalanceSummary.BeginBalance)-#GLBalanceSummary.DebitAmount+#GLBalanceSummary.CreditAmount AS EndBalance,
#GLBalanceSummary.LegalEntityNumber AS LegalEntityNumber,
#GLBalanceSummary.PartyName AS PartyName,
#GLBalanceSummary.ReceiptTypeName AS ReceiptTypeName,
#GLBalanceSummary.ReceiptBatchName AS ReceiptBatchName,
#GLBalanceSummary.PostDate AS PostDate,
#GLBalanceSummary.ReceivedDate AS ReceivedDate,
#GLBalanceSummary.CheckNumber AS CheckNumber,
#GLBalanceSummary.Description AS Description,
#GLBalanceSummary.gljournalid,
#GLBalanceSummary.ReceiptID
FROM
#GLBalanceSummary
LEFT JOIN #GLBalanceDetail ON #GLBalanceDetail.ReceiptId=#GLBalanceSummary.ReceiptId
AND #GLBalanceSummary.GLJournalId=#GLBalanceDetail.GLJournalId
ORDER BY
#GLBalanceSummary.GLJournalId,
LEN(#GLBalanceSummary.GLAccountNumber),
#GLBalanceSummary.GLAccountNumber
DROP TABLE #GLJournals
DROP TABLE #GLJournalsTemp
DROP TABLE #GLBalanceSummary
DROP TABLE #GLBalanceDetail
DROP TABLE #GLJournalDetailsTemp
DROP TABLE #GLBalance
DROP TABLE #GLBalanceSummaryGroup
DROP TABLE #GLBeginBalance
DROP TABLE #GLForBeginBalance
DROP TABLE #DisbursementRequest
END

GO

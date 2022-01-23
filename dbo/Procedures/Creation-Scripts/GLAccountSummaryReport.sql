SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GLAccountSummaryReport]
(
@FromDate DATETIMEOFFSET = NULL,
@ToDate DATETIMEOFFSET = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityId NVARCHAR(MAX) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@GLAccountId NVARCHAR(40) = NULL,
@GLEntryItemId NVARCHAR(40) = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LineofBusinessName NVARCHAR(80) = NULL,
@Culture NVARCHAR(10)
)
AS
--DECLARE @FromDate DATETIMEOFFSET = NULL
--DECLARE @ToDate DATETIMEOFFSET = NULL
--DECLARE @GLTransactionType NVARCHAR(50) = NULL
--DECLARE @EntityType NVARCHAR(25) = NULL
--DECLARE @EntityId NVARCHAR(40) = NULL
--DECLARE @GLAccountType NVARCHAR(50) = NULL
--DECLARE @GLAccountId NVARCHAR(40) = NULL
--DECLARE @GLEntryItemId NVARCHAR(40) = NULL
--DECLARE @LegalEntityNumber NVARCHAR(MAX) = NULL
--DECLARE @LineofBusinessName NVARCHAR(80) = NULL
--DECLARE @Culture NVARCHAR(10)
--SET @FromDate = '09-01-2017'
--SET @ToDate = '09-20-2017'
--SET @EntityType = 'Lease'
--SET @EntityId = '588621'
--SET @Culture = 'en-US'
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
DECLARE @SQL NVARCHAR(MAX)
DECLARE @ConditionalJoin NVARCHAR(MAX) = ''
DECLARE @WhereCondition NVARCHAR(MAX) = ''
CREATE TABLE #GLAccountSummary
(
GLAccountNumber NVARCHAR(300),
AccountType NVARCHAR(200),
Debit DECIMAL(16,2),
Credit DECIMAL(16,2),
Currency NVARCHAR(3),
LegalEntityNumber NVARCHAR(40),
LineofBusiness NVARCHAR(80),
UserBookName NVARCHAR(80),
);
CREATE TABLE #GLJournalDetailIds
(
GLJournalId BIGINT
,GLJournalDetailId BIGINT
)
SET @SQL = '
INSERT INTO #GLJournalDetailIds
SELECT
GLJournals.Id
,GLJournalDetails.Id
FROM GLJournals
INNER JOIN LegalEntities ON GLJournals.LegalEntityId = LegalEntities.Id
INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalId
INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id
INNER JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id
JOIN LineofBusinesses ON GLJournalDetails.LineofBusinessId = LineofBusinesses.Id
WHERE	( @ToDate IS NULL OR CAST(GLJournals.PostDate AS DATE) <= CAST(@ToDate AS DATE))
AND ( @FromDate IS NULL OR CAST(GLJournals.PostDate AS DATE) >= CAST(@FromDate AS DATE))
AND ( @LegalEntityNumber IS NULL OR LegalEntities.LegalEntityNumber in (SELECT value
FROM STRING_SPLIT(@LegalEntityNumber,'','')))
AND ( @LineofBusinessName IS NULL OR LineofBusinesses.Name = @LineofBusinessName)
AND ( @GLAccountType IS NULL OR GLAccountTypes.AccountType = @GLAccountType)
AND ( @GLAccountId IS NULL OR GLAccounts.Id = @GLAccountId)
INSERT INTO #GLAccountSummary
SELECT
GLJournalDetails.GLAccountNumber
,ISNULL(EntityResources.Value,GLAccountTypes.AccountType) AS AccountType
,(CASE WHEN GLJournalDetails.IsDebit=1 THEN GLJournalDetails.Amount_Amount ELSE 0 END) As Debit
,(CASE WHEN GLJournalDetails.IsDebit=0 THEN GLJournalDetails.Amount_Amount ELSE 0 END) As Credit
,GLJournalDetails.Amount_Currency
,LegalEntities.LegalEntityNumber
,LineofBusinesses.Name AS LineofBusiness
,UserBookName = GLUserBooks.Name
FROM #GLJournalDetailIds
JOIN GLJournals ON #GLJournalDetailIds.GLJournalId = GlJournals.Id
JOIN GLJournalDetails ON #GLJournalDetailIds.GLJournalDetailId = GLJournalDetails.Id
AND #GLJournalDetailIds.GLJournalId = GLJournalDetails.GLJournalId
JOIN LegalEntities ON GLJournals.LegalEntityId = LegalEntities.Id
JOIN LineofBusinesses ON GLJournalDetails.LineofBusinessId = LineofBusinesses.Id
JOIN GLAccounts	ON GLJournalDetails.GLAccountId = GLAccounts.Id
JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id
LEFT JOIN GLTemplateDetails	ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id
LEFT JOIN GLUserBooks ON GLTemplateDetails.UserBookId = GLUserBooks.Id
LEFT JOIN GLTemplates ON GLTemplateDetails.GLTemplateId = GLTemplates.Id
LEFT JOIN EntityResources
ON GLAccountTypes.Id = EntityResources.EntityId
AND EntityResources.EntityType = ''GLAccountType''
AND EntityResources.Name = ''AccountType''
AND EntityResources.Culture = @Culture
'
IF(@GLTransactionType IS NOT NULL)
BEGIN
SET @ConditionalJoin = @ConditionalJoin + '
INNER JOIN GLTransactionTypes
ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name = @GLTransactionType '
IF(@GLEntryItemId IS NOT NULL)
BEGIN
SET @ConditionalJoin = @ConditionalJoin + 'INNER JOIN GLEntryItems
ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Id = @GLEntryItemId '
END
END
ELSE
IF(@GLEntryItemId IS NOT NULL)
BEGIN
SET @ConditionalJoin = @ConditionalJoin + '
INNER JOIN GLEntryItems
ON GLTemplateDetails.EntryItemId = GLEntryItems.Id AND GLEntryItems.Id = @GLEntryItemId '
END
IF( @EntityType IS NOT NULL )
BEGIN
	IF(@EntityType = 'Lease')
	BEGIN
		SET @ConditionalJoin = @ConditionalJoin + 'INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType = ''Lease''
		AND GLJournalDetails.EntityType = ''Contract'' AND Contracts.BackgroundProcessingPending = 0 '
		IF(@EntityId IS NOT NULL)
		BEGIN
			SET @ConditionalJoin = @ConditionalJoin + ' AND Contracts.Id = @EntityId'
		END
	END
	IF(@EntityType = 'Loan')
	BEGIN
		SET @ConditionalJoin = @ConditionalJoin + 'INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType IN(''Loan'',''ProgressLoan'')
		AND GLJournalDetails.EntityType = ''Contract'' '
		IF(@EntityId IS NOT NULL)
		BEGIN
			SET @ConditionalJoin = @ConditionalJoin + ' AND Contracts.Id = @EntityId'
		END
	END
	IF(@EntityType = 'LeveragedLease')
	BEGIN
		SET @ConditionalJoin = @ConditionalJoin + 'INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType = ''LeveragedLease''
		AND GLJournalDetails.EntityType = ''Contract'' '
		IF(@EntityId IS NOT NULL)
		BEGIN
		SET @ConditionalJoin = @ConditionalJoin + ' AND Contracts.Id = @EntityId'
		END
	END

IF(@EntityType = 'DisbursementRequest')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''DisbursementRequest'' '
IF(@EntityType = 'Customer')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''Customer'' '
IF(@EntityType = 'LegalEntity')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''LegalEntity'' '
IF(@EntityType = 'SecurityDeposit')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''SecurityDeposit'' '
IF(@EntityType = 'AccountsPayablePayment')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''AccountsPayablePayment'' '
IF(@EntityType = 'BookDepreciation')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''BookDepreciation'' '
IF(@EntityType = 'RT')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''RT'' '
IF(@EntityType = 'ReceiptRefund')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''ReceiptRefund'' '
IF(@EntityType = 'Asset')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''Asset'' '
IF(@EntityType = 'AssetSale')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''AssetSale'' '
IF(@EntityType = 'AssetValueAdjustment')
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityType = ''AssetValueAdjustment'' '
IF(@EntityId IS NOT NULL AND @EntityType NOT IN ('Lease','Loan','LeveragedLease'))
SET @WhereCondition = @WhereCondition + ' AND GLJournalDetails.EntityId = @EntityId'
END
ELSE
BEGIN
	----Offline Processing: If EntityType is not selected/Unknown, then exclusion of Contract GL Records for Pending Contracts should occur--
	SET @ConditionalJoin = @ConditionalJoin + 'LEFT JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType = ''Lease''
		AND GLJournalDetails.EntityType = ''Contract'' '

	SET @WhereCondition = @WhereCondition + ' AND (Contracts.Id IS NULL OR Contracts.BackgroundProcessingPending = 0)'
END
SET @SQL = @SQL + @ConditionalJoin + '
WHERE ( @GLAccountId IS NULL OR GLAccounts.Id = @GLAccountId)
'
SET @SQL = @SQL + @WhereCondition +' ORDER BY GLJournals.PostDate, GLJournals.Id'
EXEC SP_EXECUTESQL @SQL ,N'@FromDate DATETIMEOFFSET=NULL,
@ToDate DATETIMEOFFSET=NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LineofBusinessName NVARCHAR(80) = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@GLAccountId NVARCHAR(40) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityId NVARCHAR(40) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@GLEntryItemId NVARCHAR(40) = NULL,
@Culture NVARCHAR(10) = NULL'
,
@FromDate,
@ToDate,
@LegalEntityNumber,
@LineofBusinessName,
@GLTransactionType,
@GLAccountId,
@EntityType,
@EntityId,
@GLAccountType,
@GLEntryItemId,
@Culture
SELECT
GLAccountNumber,
AccountType,
SUM(Debit) as Debit,
SUM(Credit) as Credit,
SUM(Debit) - SUM(Credit) AS 'Net Investment',
Currency,
LegalEntityNumber,
LineofBusiness,
UserBookName,
ROW_NUMBER() OVER (PARTITION BY GLAccountNumber,Currency,LegalEntityNumber,LineofBusiness ORDER BY GLAccountNumber) AS OrderNumber
FROM #GLAccountSummary
GROUP BY GLAccountNumber,AccountType,Currency,LegalEntityNumber,LineofBusiness,UserBookName
DROP TABLE #GLAccountSummary
DROP TABLE #GLJournalDetailIds
END

GO

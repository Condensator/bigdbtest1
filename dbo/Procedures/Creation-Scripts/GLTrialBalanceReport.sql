SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GLTrialBalanceReport]
(
@FromDate DATETIMEOFFSET,
@ToDate DATETIMEOFFSET,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@GLTransactionTypeLabel NVARCHAR(50) = NULL,
@GLAccount NVARCHAR(40) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityTypeLabel NVARCHAR(25) = NULL,
@EntityId NVARCHAR(40) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@Culture NVARCHAR(10)
)
AS
BEGIN
--DECLARE @FromDate DATETIMEOFFSET = '01-01-2000'
--DECLARE @ToDate DATETIMEOFFSET = '01-11-2018'
--DECLARE @LegalEntityNumber NVARCHAR(MAX) = NULL
--DECLARE @GLTransactionType NVARCHAR(50) = NULL
--DECLARE @GLTransactionTypeLabel NVARCHAR(50) = NULL
--DECLARE @GLAccount NVARCHAR(40) = NULL
--DECLARE @EntityType NVARCHAR(25) = 'Lease'
--DECLARE @EntityTypeLabel NVARCHAR(25) = NULL
--DECLARE @EntityId NVARCHAR(40) = NULL
--DECLARE @GLAccountType NVARCHAR(50) = NULL
--DECLARE @Culture NVARCHAR(10)

SET @FromDate = CAST(@FromDate AS DATE);
SET @ToDate = CAST(@ToDate AS DATE);

DECLARE @Sql NVARCHAR(MAX) = '';
DECLARE @EntityTypeFilter NVARCHAR(MAX) = '';
DECLARE @LegalEntityFilter NVARCHAR(MAX) = '';
DECLARE @GLAccountFilter NVARCHAR(MAX) = '';
DECLARE @GLAccountTypeFilter NVARCHAR(MAX) = '';
DECLARE @GLTransactionTypeFilter NVARCHAR(MAX) = '';
DECLARE @FilterBackgroundProcessingPendingContracts NVARCHAR(MAX) = '';

IF (@EntityType IS NOT NULL)
BEGIN
	SET @EntityTypeFilter  = ' AND GLJournalDetails.EntityType = @EntityType '

	IF(@EntityId IS NOT NULL)
	BEGIN
		SET @EntityTypeFilter += ' AND GLJournalDetails.EntityId = @EntityId '
	END
	IF(@EntityType = 'Lease')
	BEGIN
		SET @EntityTypeFilter += 
		' INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType = ''Lease'' '
		SET @FilterBackgroundProcessingPendingContracts = ' AND Contracts.BackgroundProcessingPending = 0 '
	END
	IF(@EntityType = 'Loan')
	BEGIN
		SET @EntityTypeFilter += 
		' INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType IN(''Loan'',''ProgressLoan'') '
	END
	IF(@EntityType = 'LeveragedLease')
	BEGIN
		SET @EntityTypeFilter += 
		' INNER JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND Contracts.ContractType = ''LeveragedLease'' '
	END
END
ELSE
BEGIN
	SET @EntityTypeFilter += 
		' LEFT JOIN Contracts ON GLJournalDetails.EntityId = Contracts.Id AND GLJournalDetails.EntityType = ''Contract'' '
		SET @FilterBackgroundProcessingPendingContracts = ' AND (Contracts.Id IS NULL OR Contracts.BackgroundProcessingPending = 0) '
END

IF (@GLAccount IS NOT NULL)
BEGIN
	SET @GLAccountFilter = 
	' INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id AND GLAccounts.Name = @GLAccount '
END

IF (@GLAccountType IS NOT NULL)
BEGIN
	IF (@GLAccount IS NULL)
	BEGIN
	SET @GLAccountTypeFilter = 
	' INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id 
	  INNER JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id AND GLAccountTypes.AccountType = @GLAccountType '
	END
	ELSE
	BEGIN
	SET @GLAccountTypeFilter = 
	' INNER JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id AND GLAccountTypes.AccountType = @GLAccountType '
	END
END

IF (@GLTransactionType IS NOT NULL)
BEGIN
	SET @GLTransactionTypeFilter = 
	' INNER JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id
	  INNER JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id
	  INNER JOIN GLTransactionTypes ON GLEntryItems.GLTransactionTypeId = GLTransactionTypes.Id AND GLTransactionTypes.Name = @GLTransactionType '
END

SET @Sql = N'
SELECT Id INTO #LegalEntities
FROM LegalEntities
WHERE LegalEntityNumber IN (SELECT value FROM STRING_SPLIT(@LegalEntityNumber,'',''))

;WITH CTE_BasicFilterAppliedCollection
AS
(
SELECT
	GLJournalDetails.GLAccountNumber
	,CASE WHEN GLJournalDetails.IsDebit = 1 THEN GLJournalDetails.Amount_Amount ELSE 0 END AS DebitAmount
	,CASE WHEN GLJournalDetails.IsDebit = 0 THEN GLJournalDetails.Amount_Amount ELSE 0 END CreditAmount
	,GLJournalDetails.Amount_Currency AS Currency
	,GLJournals.LegalEntityId AS LegalEntityId
	,GLJournalDetails.GLAccountId AS GLAccountId
	,CASE WHEN GLJournals.PostDate >= @FromDate THEN 1 ELSE 0 END AS IsGreaterThanFromDate
FROM GLJournals
INNER JOIN #LegalEntities ON GLJournals.LegalEntityId = #LegalEntities.Id
INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalId '
SET @Sql += @EntityTypeFilter
SET @Sql += @LegalEntityFilter
SET @Sql += @GLAccountFilter
SET @Sql += @GLAccountTypeFilter
SET @Sql += @GLTransactionTypeFilter +'
WHERE PostDate <= @ToDate'
+ @FilterBackgroundProcessingPendingContracts +'
)
SELECT
	GLAccountNumber,	
	Currency,
	SUM(DebitAmount) DebitAmount,
	SUM(CreditAmount) CreditAmount,
	LegalEntityId,
	GLAccountId,
	IsGreaterThanFromDate
INTO #GLTrialBalanceBasicInfo
FROM CTE_BasicFilterAppliedCollection
GROUP BY
	GLAccountNumber,
	Currency,
	LegalEntityId,
	GLAccountId,
	IsGreaterThanFromDate

SELECT 
	GLAccountNumber, 
	GLAccountName, 
	AccountType, 
	Currency, 
	LegalEntityNumber, 
	UserBookName, 
	IsGreaterThanFromDate, 
	SUM(DebitAmount) DebitAmount, 
	SUM(CreditAmount) CreditAmount,
	CASE WHEN AccountType IN (''Asset Account'',''Expense Account'',''Contra Asset Account'') THEN SUM(DebitAmount) - SUM(CreditAmount)
		 WHEN AccountType IN (''Liability Account'',''Revenue Account'',''Contra Liability Account'') THEN SUM(CreditAmount) - SUM(DebitAmount) 
	ELSE 0 END AmountPosted
INTO #GLTrialBalanceDetailInfo
FROM 
(
	SELECT 
		#GLTrialBalanceBasicInfo.GLAccountNumber,
		GLAccounts.Name as GLAccountName,
		COALESCE(EntityResources.Value, GLAccountTypes.AccountType) AS AccountType,
		#GLTrialBalanceBasicInfo.Currency,
		LegalEntities.LegalEntityNumber,
		#GLTrialBalanceBasicInfo.DebitAmount,
		#GLTrialBalanceBasicInfo.CreditAmount,
		GLUserBooks.Name as UserBookName,
		#GLTrialBalanceBasicInfo.IsGreaterThanFromDate	
	FROM #GLTrialBalanceBasicInfo
	JOIN GLAccounts on #GLTrialBalanceBasicInfo.GLAccountId = GLAccounts.Id
	JOIN GLAccountTypes on GLAccounts.GLAccountTypeId = GLAccountTypes.Id
	JOIN LegalEntities on #GLTrialBalanceBasicInfo.LegalEntityId = LegalEntities.Id
	JOIN GLUserBooks on GLAccounts.GLUserBookId = GLUserBooks.Id
	LEFT JOIN EntityResources
		ON GLAccountTypes.Id = EntityResources.EntityId
		AND EntityResources.EntityType = ''GLAccountType''
		AND EntityResources.Name = ''AccountType''
		AND EntityResources.Culture = @Culture
) DetailInfo
GROUP BY GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, UserBookName, IsGreaterThanFromDate

SELECT 
 GreaterThanRec.Currency,
 GreaterThanRec.GLAccountNumber,
 GreaterThanRec.GLAccountName,
 ISNULL(LessThanRec.BeginBalance,0.0) AS BeginBalance,
 GreaterThanRec.DebitAmount,
 GreaterThanRec.CreditAmount,
 ISNULL(LessThanRec.BeginBalance,0.0) + GreaterThanRec.AmountPosted AS EndBalance,
 GreaterThanRec.LegalEntityNumber,
 GreaterThanRec.AccountType AS ''Account Type'',
 GreaterThanRec.UserBookName
FROM 
(
	SELECT GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, UserBookName, SUM(DebitAmount) DebitAmount, SUM(CreditAmount) CreditAmount, 
	SUM(AmountPosted) AmountPosted
	FROM 
	(
		SELECT 
			GLAccountNumber, GLAccountName,	AccountType, Currency, LegalEntityNumber, DebitAmount, CreditAmount, UserBookName, AmountPosted	
		FROM #GLTrialBalanceDetailInfo
		WHERE IsGreaterThanFromDate = 1
	) s1
	GROUP BY GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, UserBookName
) GreaterThanRec
LEFT JOIN
(
	SELECT GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, UserBookName, SUM(AmountPosted) BeginBalance
	FROM 
	(
		SELECT 
			GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, DebitAmount, CreditAmount, UserBookName, AmountPosted	
		FROM #GLTrialBalanceDetailInfo
		WHERE IsGreaterThanFromDate = 0
	) s2
	GROUP BY GLAccountNumber, GLAccountName, AccountType, Currency, LegalEntityNumber, UserBookName
) LessThanRec 
	ON GreaterThanRec.GLAccountNumber = LessThanRec.GLAccountNumber
   AND GreaterThanRec.GLAccountName = LessThanRec.GLAccountName
   AND GreaterThanRec.LegalEntityNumber = LessThanRec.LegalEntityNumber
   AND GreaterThanRec.AccountType = LessThanRec.AccountType
   AND GreaterThanRec.UserBookName = LessThanRec.UserBookName
   AND GreaterThanRec.Currency = LessThanRec.Currency
ORDER BY LEN(GreaterThanRec.GLAccountNumber), GreaterThanRec.GLAccountNumber
'

--print CAST(@sql as NTEXT);

--EXEC Print1 @sql;

EXEC SP_EXECUTESQL @SQL ,N'@FromDate DATETIMEOFFSET = NULL,
@ToDate DATETIMEOFFSET = NULL,
@LegalEntityNumber NVARCHAR(Max) = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@GLAccount NVARCHAR(40) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityId NVARCHAR(40) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@EntityTypeLabel NVARCHAR(25) = NULL,
@Culture NVARCHAR(10) = NULL',
@FromDate,
@ToDate,
@LegalEntityNumber,
@GLTransactionType,
@GLAccount,
@EntityType,
@EntityId,
@GLAccountType,
@EntityTypeLabel,
@Culture
END

GO

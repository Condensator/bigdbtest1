SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GLJournalDetailSummaryReport]
(
@FromDate DATETIMEOFFSET = NULL,
@ToDate DATETIMEOFFSET = NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LineofBusinessName NVARCHAR(80) = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@GLAccountId NVARCHAR(40) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityId NVARCHAR(40) = NULL,
@GLEntryItemId NVARCHAR(40) = NULL,
@GLAccountNumber NVARCHAR(129) = NULL
)
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--DECLARE @FromDate DATETIMEOFFSET = '2007-06-28'
--DECLARE @ToDate DATETIMEOFFSET = '2049-12-01'
--DECLARE @LegalEntityNumber NVARCHAR(MAX) = NULL
--DECLARE @LineofBusinessName NVARCHAR(80) = NULL
--DECLARE @GLTransactionType NVARCHAR(50) = 'AssetBookValueAdjustment'
--DECLARE @GLAccountId NVARCHAR(40) = NULL
--DECLARE @GLAccountType NVARCHAR(50) = NULL
--DECLARE @EntityType NVARCHAR(25) = NULL
--DECLARE @EntityId NVARCHAR(40) = NULL
--DECLARE @GLEntryItemId NVARCHAR(40) = NULL
--DECLARE @GLAccountNumber NVARCHAR(129) = NULL
DECLARE @SQL NVARCHAR(MAX)
DECLARE @GLJournalEntityType NVARCHAR(25)
DECLARE @GLTransactionTypeId BIGINT
CREATE TABLE #GLJournalDetailIds
(
GLJournalId BIGINT
,PostDate DATE
,GLAccountNumber NVARCHAR(258)
,IsDebit BIT
,EntityType NVARCHAR(46)
,Amount_Amount DECIMAL(18,2)
,Amount_Currency NVARCHAR(3)
,Description NVARCHAR(400)
,IsManualEntry BIT
,EntityId BIGINT
,CreatedById BIGINT
,GLAccountName NVARCHAR(80)
,LegalEntityNumber NVARCHAR(40)
,LineofBusiness NVARCHAR(80)
,SortOrder BIT
,GLTemplate NVARCHAR(40)
,GLEntryItemName NVARCHAR(100)
,GLTransactionType NVARCHAR(30)
,UserBookName NVARCHAR(80)
)
Declare @GLFromDate DATE = CAST(@FromDate AS DATE)
Declare @GLToDate DATE = CAST(@ToDate AS DATE)
Select @GLTransactionTypeId = Id from GLTransactionTypes where Name = @GLTransactionType

SET @GLJournalEntityType = @EntityType;
IF(@EntityType = 'Lease' OR @EntityType = 'Loan' OR @EntityType = 'LeveragedLease')
BEGIN
SET @GLJournalEntityType = 'Contract'
END

SET @SQL = '
INSERT INTO #GLJournalDetailIds
SELECT
GLJournals.Id
,GLJournals.PostDate
,GLJournalDetails.GLAccountNumber
,GLJournalDetails.IsDebit
,GLJournalDetails.EntityType
,GLJournalDetails.Amount_Amount
,GLJournalDetails.Amount_Currency
,GLJournalDetails.Description
,GLJournals.IsManualEntry
,GLJournalDetails.EntityId
,GLJournals.CreatedById
,GLAccounts.Name AS GLAccountName
,LegalEntities.LegalEntityNumber
,LineofBusinesses.Name AS LineofBusiness
,GLEntryItems.SortOrder
,GLTemplates.Name AS GLTemplate
,GLEntryItems.Name AS GLEntryItemName
,GLTransactionTypes.Name AS GLTransactionType
,GLUserBooks.Name AS UserBookName
FROM GLJournals
INNER JOIN LegalEntities ON GLJournals.LegalEntityId = LegalEntities.Id AND GLJournals.IsManualEntry = 0 '
IF (@GLFromDate IS NOT NULL AND @GLToDate IS NOT NULL)
BEGIN
	SET @SQL = @SQL + ' AND GLJournals.PostDate BETWEEN @GLFromDate AND @GLToDate '
END
IF (@GLFromDate IS NOT NULL AND @GLToDate IS NULL)
BEGIN
	SET @SQL = @SQL + ' AND GLJournals.PostDate >= @GLFromDate'
END

IF (@GLToDate IS NOT NULL AND @GLFromDate IS NULL)
BEGIN
	SET @SQL = @SQL + ' AND GLJournals.PostDate <= @GLToDate'
END

SET @SQL = @SQL + ' INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalId '

IF(@EntityType IS NOT NULL)
BEGIN
	SET @SQL = @SQL + ' AND GLJournalDetails.EntityType = @GLJournalEntityType '
	IF(@EntityId IS NOT NULL)
	BEGIN
		SET @SQL = @SQL + ' AND GLJournalDetails.EntityId = @EntityId '
	END
END

IF @GLAccountId IS NOT NULL
BEGIN
	SET @SQL = @SQL + ' AND GLJournalDetails.GLAccountId = @GLAccountId '
END

SET @SQL = @SQL + ' INNER JOIN GLTemplateDetails ON GLJournalDetails.GLTemplateDetailId = GLTemplateDetails.Id ' +
CASE WHEN @GLEntryItemId IS NOT NULL THEN ' AND GLTemplateDetails.EntryItemId = @GLEntryItemId ' ELSE '' END
+ ' INNER JOIN GLTemplates ON GLTemplateDetails.GLTemplateId = GLTemplates.Id ' +
CASE WHEN @GLTransactionType IS NOT NULL THEN ' AND GLTemplates.GLTransactionTypeId = @GLTransactionTypeId ' ELSE '' END
+ ' INNER JOIN GLTransactionTypes ON GLTemplates.GLTransactionTypeId = GLTransactionTypes.Id 
 INNER JOIN GLUserBooks ON GLTemplateDetails.UserBookID = GLUserBooks.ID
 INNER JOIN GLEntryItems ON GLTemplateDetails.EntryItemId = GLEntryItems.Id 
 INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id 
 INNER JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id ' +
CASE WHEN @GLAccountType IS NOT NULL THEN ' AND GLAccountTypes.AccountType = @GLAccountType ' ELSE '' END
+ ' INNER JOIN LineofBusinesses ON GLJournalDetails.LineofBusinessId = LineofBusinesses.Id ' +
CASE WHEN @LineofBusinessName IS NOT NULL THEN ' AND LineofBusinesses.Name = @LineofBusinessName ' ELSE '' END

DECLARE @WhereStatement Nvarchar(1000) = NULL;

IF @LegalEntityNumber IS NOT NULL
BEGIN
	IF @WhereStatement IS NULL SET @WhereStatement = 'WHERE ' ELSE SET @WhereStatement = @WhereStatement + ' AND'
	SET @WhereStatement = @WhereStatement + ' LegalEntities.LegalEntityNumber in (SELECT value
FROM STRING_SPLIT(@LegalEntityNumber,'',''))'
END

IF @GLAccountNumber IS NOT NULL
BEGIN
	IF @WhereStatement IS NULL SET @WhereStatement = 'WHERE ' ELSE SET @WhereStatement = @WhereStatement + ' AND'
	SET @WhereStatement = @WhereStatement + ' GLJournalDetails.GLAccountNumber LIKE @GLAccountNumber'
END

IF @WhereStatement IS NOT NULL
BEGIN
	SET @SQL = @SQL + @WhereStatement
END

IF(@GLTransactionType IS NULL AND @GLEntryItemId IS NULL)
BEGIN
	SET @SQL = @SQL + ' 
	INSERT INTO #GLJournalDetailIds
	SELECT
	GLJournals.Id
	,GLJournals.PostDate
	,GLJournalDetails.GLAccountNumber
	,GLJournalDetails.IsDebit
	,GLJournalDetails.EntityType
	,GLJournalDetails.Amount_Amount
	,GLJournalDetails.Amount_Currency
	,GLJournalDetails.Description
	,GLJournals.IsManualEntry
	,GLJournalDetails.EntityId
	,GLJournals.CreatedById
	,GLAccounts.Name AS GLAccountName
	,LegalEntities.LegalEntityNumber
	,LineofBusinesses.Name AS LineofBusiness
	,NULL AS SortOrder
	,NULL AS GLTemplate
	,NULL AS GLEntryItemName
	,NULL AS GLTransactionType
	,NULL AS UserBookName
	FROM GLJournals
	INNER JOIN LegalEntities ON GLJournals.LegalEntityId = LegalEntities.Id AND GLJournals.IsManualEntry = 1 '
	IF (@GLFromDate IS NOT NULL AND @GLToDate IS NOT NULL)
	BEGIN
		SET @SQL = @SQL + ' AND GLJournals.PostDate BETWEEN @GLFromDate AND @GLToDate '
	END
	IF (@GLFromDate IS NOT NULL AND @GLToDate IS NULL)
	BEGIN
		SET @SQL = @SQL + ' AND GLJournals.PostDate >= @GLFromDate'
	END

	IF (@GLToDate IS NOT NULL AND @GLFromDate IS NULL)
	BEGIN
		SET @SQL = @SQL + ' AND GLJournals.PostDate <= @GLToDate'
	END

	SET @SQL = @SQL + ' INNER JOIN GLJournalDetails ON GLJournals.Id = GLJournalDetails.GLJournalId '

	IF(@EntityType IS NOT NULL)
	BEGIN
		SET @SQL = @SQL + ' AND GLJournalDetails.EntityType = @GLJournalEntityType '
		IF(@EntityId IS NOT NULL)
		BEGIN
			SET @SQL = @SQL + ' AND GLJournalDetails.EntityId = @EntityId '
		END
	END

	IF @GLAccountId IS NOT NULL
	BEGIN
		SET @SQL = @SQL + ' AND GLJournalDetails.GLAccountId = @GLAccountId '
	END

	SET @SQL = @SQL + ' INNER JOIN GLAccounts ON GLJournalDetails.GLAccountId = GLAccounts.Id 
	 INNER JOIN GLAccountTypes ON GLAccounts.GLAccountTypeId = GLAccountTypes.Id ' +
	CASE WHEN @GLAccountType IS NOT NULL THEN ' AND GLAccountTypes.AccountType = @GLAccountType ' ELSE '' END
	+ ' INNER JOIN LineofBusinesses ON GLJournalDetails.LineofBusinessId = LineofBusinesses.Id ' +
	CASE WHEN @LineofBusinessName IS NOT NULL THEN ' AND LineofBusinesses.Name = @LineofBusinessName ' ELSE '' END

	IF @WhereStatement IS NOT NULL
	BEGIN
		SET @SQL = @SQL + @WhereStatement
	END

END

SET @SQL = @SQL + ' 
SELECT
GLJournal.GLJournalId AS GLJournalId
,GLJournal.PostDate as PostDate
,GLJournal.GLTemplate
,GLJournal.GLEntryItemName
,GLJournal.GLAccountNumber
,GLJournal.GLAccountName
,(CASE WHEN GLJournal.IsDebit=1 THEN GLJournal.Amount_Amount ELSE 0 END) As Debit
,(CASE WHEN GLJournal.IsDebit=0 THEN GLJournal.Amount_Amount ELSE 0 END) As Credit
,(CASE WHEN (@EntityType IS NOT NULL AND (@EntityType = ''Lease'' OR @EntityType = ''Loan'')) THEN @EntityType ELSE GLJournal.EntityType END) As EntityType
,''ENTITYUNIQUEIDENTIFIER'' AS EntityId
,GLJournal.LineofBusiness
,GLJournal.Amount_Currency
,GLJournal.[Description] AS Description
,GLJournal.LegalEntityNumber
,GLJournal.GLTransactionType
,GLJournal.IsManualEntry
,Users.FullName AS UserName
,GLJournal.UserBookName
FROM #GLJournalDetailIds GLJournal
JOIN Users ON GLJournal.CreatedById = Users.Id
'

IF(@EntityType IS NULL)
BEGIN
	DECLARE @EntityCondition AS NVARCHAR(MAX) = ''
	SET @EntityCondition = '
	CASE
	WHEN GLJournal.EntityType =''Customer'' THEN CAST(Parties.PartyNumber AS NVARCHAR)
	WHEN GLJournal.EntityType = ''Contract'' THEN CAST(Contracts.SequenceNumber AS NVARCHAR)
	WHEN GLJournal.EntityType = ''LegalEntity'' THEN CAST(GLLegalEntities.LegalEntityNumber AS NVARCHAR)
	WHEN GLJournal.EntityType = ''AssetSale'' THEN CAST(AssetSales.TransactionNumber AS NVARCHAR)
	WHEN GLJournal.EntityType = ''Discounting'' THEN CAST(Discountings.SequenceNumber AS NVARCHAR)
	ELSE CAST(GLJournal.EntityId AS NVARCHAR)
	END '
	SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''',@EntityCondition)
	SET @SQL +='
	LEFT JOIN Parties ON GLJournal.EntityId = Parties.Id AND GLJournal.EntityType = ''Customer''
	LEFT JOIN Contracts ON GLJournal.EntityId = Contracts.Id AND GLJournal.EntityType = ''Contract'' 
	LEFT JOIN LegalEntities AS GLLegalEntities ON GLJournal.EntityId = GLLegalEntities.Id AND GLJournal.EntityType = ''LegalEntity''
	LEFT JOIN AssetSales ON GLJournal.EntityId = AssetSales.Id AND GLJournal.EntityType = ''AssetSales''
	LEFT JOIN Discountings ON GLJournal.EntityId = Discountings.Id AND GLJournal.EntityType = ''Discounting''
	WHERE Contracts.Id IS NULL OR Contracts.BackgroundProcessingPending = 0
	'
END
IF(@EntityType = 'DisbursementRequest')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'Customer')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Parties.PartyNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN Parties ON GLJournal.EntityId = Parties.Id AND GLJournal.EntityType = ''Customer'' '
END
IF(@EntityType = 'LegalEntity')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLLegalEntities.LegalEntityNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN LegalEntities AS GLLegalEntities ON GLJournal.EntityId = GLLegalEntities.Id AND GLJournal.EntityType = ''LegalEntity'' '
END
IF(@EntityType = 'Lease')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN Contracts ON GLJournal.EntityId = Contracts.Id AND Contracts.ContractType = ''Lease'' AND GLJournal.EntityType = ''Contract'' 
					AND Contracts.BackgroundProcessingPending = 0 '
END
IF(@EntityType = 'Loan')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN Contracts ON GLJournal.EntityId = Contracts.Id AND Contracts.ContractType IN(''Loan'',''ProgressLoan'')
AND GLJournal.EntityType = ''Contract'' '
END
IF(@EntityType = 'LeveragedLease')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Contracts.SequenceNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN Contracts ON GLJournal.EntityId = Contracts.Id AND Contracts.ContractType = ''LeveragedLease''
AND GLJournal.EntityType = ''Contract'' '
END
IF(@EntityType = 'SecurityDeposit')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'AccountsPayablePayment')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'BookDepreciation')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'RT')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'ReceiptRefund')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'Asset')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'AssetSale')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(AssetSales.TransactionNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN AssetSales ON GLJournal.EntityId = AssetSales.Id AND GLJournal.EntityType = ''AssetSale'' '
END
IF(@EntityType = 'AssetValueAdjustment')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(GLJournal.EntityId AS NVARCHAR)')
END
IF(@EntityType = 'Discounting')
BEGIN
SET @SQL = REPLACE(@SQL,'''ENTITYUNIQUEIDENTIFIER''','CAST(Discountings.SequenceNumber AS NVARCHAR)')
SET @SQL = @SQL + 'INNER JOIN Discountings ON GLJournal.EntityId = Discountings.Id AND GLJournal.EntityType = ''Discounting'' '
END
SET @SQL = @SQL + ' 
ORDER BY PostDate, GLJournal.GLJournalId, GLJournal.SortOrder
'

EXEC SP_EXECUTESQL @SQL ,N'@GLFromDate DATETIMEOFFSET=NULL,
@GLToDate DATETIMEOFFSET=NULL,
@LegalEntityNumber NVARCHAR(MAX) = NULL,
@LineofBusinessName NVARCHAR(80) = NULL,
@GLTransactionType NVARCHAR(50) = NULL,
@GLAccountId NVARCHAR(40) = NULL,
@EntityType NVARCHAR(25) = NULL,
@EntityId NVARCHAR(40) = NULL,
@GLAccountType NVARCHAR(50) = NULL,
@GLEntryItemId NVARCHAR(40) = NULL,
@GLAccountNumber NVARCHAR(129) = NULL,
@GLJournalEntityType NVARCHAR(25) = NULL,
@GLTransactionTypeId BIGINT = NULL
',
@GLFromDate,
@GLToDate,
@LegalEntityNumber,
@LineofBusinessName,
@GLTransactionType,
@GLAccountId,
@EntityType,
@EntityId,
@GLAccountType,
@GLEntryItemId,
@GLAccountNumber,
@GLJournalEntityType,
@GLTransactionTypeId

DROP TABLE #GLJournalDetailIds
END

GO

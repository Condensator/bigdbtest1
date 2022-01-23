SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ImportInvoicesForReceiptApplication] (
	@InvoiceNumber NVARCHAR(40),
	@LegalEntityId BIGINT,
	@AllowTransfer BIT,
	@CustomerName NVARCHAR(500),
	@CustomerNumber NVARCHAR(40),
	@LeaseSequenceNumber NVARCHAR(40),
	@DueDate DATETIME,
	@ContractType NVARCHAR(14),
	@InvoiceType NVARCHAR(56),
	@InvoiceIds InvoiceIdCollection READONLY,
	@StatementInvoiceIds InvoiceIdCollection READONLY,
	@ReceiptCustomerId BIGINT,
	@ReceiptContractId BIGINT,
	@CurrentUserId BIGINT,
	@CurrencyISO NVARCHAR(6),
	@StartingRowNumber INT,
	@EndingRowNumber INT,
	@ExistingReceivableCount INT,
	@OrderBy NVARCHAR(6) = NULL,
	@OrderColumn NVARCHAR(MAX) = NULL,
	@ADVWHERECLAUSE NVARCHAR(2000) = '',
	@IsForSelectAll BIT = 0,
	@InvoiceIdsToSelect InvoiceIdCollection READONLY,
	@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY,
	@IsNonCashReceipt BIT =0,
	@DiscountingId BIGINT = NULL,
	@GLConfigurationId	BIGINT,
	@DueByDate DATETIME = NULL,
	@MinDaysPastDue INT = NULL,
	@CurrentBusinessDate DATETIME,
	@MinOutstandingBalance DECIMAL(18,2) = NULL,
	@ImportedTaxType NVARCHAR(30)
)
AS
BEGIN

DECLARE @MinDaysPastDueDate DATETIME;

IF(@MinDaysPastDue IS NOT NULL)
BEGIN
	SET @MinDaysPastDue = CASE WHEN @MinDaysPastDue > 9999 THEN 9999 WHEN @MinDaysPastDue < 0 THEN 0 ELSE @MinDaysPastDue END
	SET @MinDaysPastDueDate = DATEADD(DD,@MinDaysPastDue*-1,@CurrentBusinessDate)

	IF(@DueByDate IS NULL OR @MinDaysPastDueDate <= @DueByDate) 
		SET @DueByDate = @MinDaysPastDueDate 
END

DECLARE
@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )

DECLARE @WHERECLAUSE NVARCHAR(MAX);
DECLARE @SELECTQUERY NVARCHAR(MAX);

	SET NOCOUNT ON; 

	CREATE TABLE #TempInvoiceId (InvoiceId bigint)  
	CREATE TABLE #TempStatementInvoiceId (StatementInvoiceId bigint)  
	CREATE TABLE #TempAccessibleLegalEntityIds (LegalEntityId bigint)
	CREATE TABLE #AccessibleLegalEntity (LegalEntityId bigint,LegalEntityNumber NVARCHAR(40))

	INSERT INTO #TempInvoiceId(InvoiceId)   
	SELECT InvoiceId FROM @InvoiceIds    
	CREATE NONCLUSTERED INDEX IX_TempInvoiceId_InvoiceId ON #TempInvoiceId(InvoiceId);

	INSERT INTO #TempStatementInvoiceId(StatementInvoiceId)   
	SELECT InvoiceId FROM @StatementInvoiceIds 
      
	INSERT INTO #TempAccessibleLegalEntityIds(LegalEntityId)
	SELECT LegalEntityId FROM @AccessibleLegalEntityIds 
    
	INSERT INTO #AccessibleLegalEntity(LegalEntityId,LegalEntityNumber)  
	SELECT	LegalEntities.Id AS LegalEntityId ,
			LegalEntities.LegalEntityNumber AS LegalEntityNumber   
	FROM LegalEntities JOIN #TempAccessibleLegalEntityIds AS TLEId ON LegalEntities.Id = TLEId.LegalEntityId  
	WHERE (@AllowTransfer = 1 or @LegalEntityId = LegalEntities.Id)
	AND GLConfigurationId = @GLConfigurationId
	Group By LegalEntities.Id  ,LegalEntities.LegalEntityNumber
			
	SET @WHERECLAUSE = REPLACE(@ADVWHERECLAUSE,'"','')

	CREATE TABLE #ValidDetailsForSelectALL
	(
		ReceivableInvoiceId BIGINT,
		InvoicetypeId BIGINT,
		ReceivableInvoiceDetailId BIGINT,
		TaxType NVARCHAR(30)
	)

DECLARE @ValidDetailInsertQuery NVARCHAR(MAX) =
	'INSERT INTO #ValidDetailsForSelectALL
	SELECT 
		ReceivableInvoiceDetails.ReceivableInvoiceId,
		InvoiceTypes.Id InvoicetypeId,
		ReceivableInvoiceDetails.Id ReceivableInvoiceDetailId,
		Receivables.ReceivableTaxType AS TaxType	
	FROM
		ReceivableInvoiceDetails
	JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1   
								AND ReceivableInvoices.Balance_Currency = @CurrencyISO  
								AND ReceivableInvoices.IsDummy = 0   
								AND ReceivableInvoiceDetails.IsActive = 1  
	JOIN #AccessibleLegalEntity AS AccessibleLegalEntity ON AccessibleLegalEntity.LegalEntityId = ReceivableInvoices.LegalEntityId
	JOIN ReceivableCategories ON ReceivableCategories.Id = ReceivableInvoiceDetails.ReceivableCategoryId
	JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id
						AND Receivables.IsDummy = 0   
						AND Receivables.IsCollected = 1 	  
	LEFT JOIN #TempInvoiceId AS TempInvoiceId ON TempInvoiceId.InvoiceId = ReceivableInvoices.Id
	LEFT JOIN InvoiceTypes ON InvoiceTypes.Id = ReceivableCategories.InvoiceTypeId
	LEFT JOIN Contracts ON Contracts.Id = ReceivableInvoiceDetails.EntityId AND ReceivableInvoiceDetails.EntityType = ''CT''
	LEFT JOIN Discountings ON Discountings.Id = Receivables.EntityId  AND ReceivableInvoiceDetails.EntityType = ''DT'''

DECLARE @WHERESTATEMENT NVARCHAR(2000) = 
'WHERE TempInvoiceId.InvoiceId IS NULL
	AND ((Contracts.Id IS NULL OR Contracts.ContractType != ''Loan'' OR Contracts.IsNonAccrual = 0)
		OR (Receivables.IncomeType IN (''InterimInterest'',''TakeDownInterest''))
		OR (ReceivableInvoiceDetails.ReceivableTypeId != @LoanInterestReceivableTypeId AND ReceivableInvoiceDetails.ReceivableTypeId != @LoanPrincipalReceivableTypeId))
	AND (ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) <> 0
	AND ((ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) > 0
		OR ((ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) < 0 AND (@IsNonCashReceipt = 0 OR Receivables.LegalEntityId = @LegalEntityId)))
		AND (@ImportedTaxType IS NULL OR @ImportedTaxType = ''''OR Receivables.ReceivableTaxType = @ImportedTaxType)' +
CASE WHEN @InvoiceNumber IS NOT NULL THEN 'AND ReceivableInvoices.Number like @InvoiceNumber' + ' ' ELSE '' END +
CASE WHEN @ReceiptCustomerId IS NOT NULL THEN 'AND ReceivableInvoices.CustomerId = @ReceiptCustomerId' + ' ' ELSE '' END +
CASE WHEN @ReceiptContractId IS NOT NULL THEN 'AND Contracts.Id = @ReceiptContractId' + ' ' ELSE '' END +
CASE WHEN @CustomerName IS NOT NULL THEN 'AND ReceivableInvoices.CustomerName LIKE @CustomerName' + ' ' ELSE '' END +
CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND ReceivableInvoices.CustomerNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
CASE WHEN @ContractType IS NOT NULL THEN 'AND Contracts.ContractType = @ContractType' + ' ' ELSE '' END +
CASE WHEN @InvoiceType IS NOT NULL THEN 'AND InvoiceTypes.Name = @InvoiceType' + ' ' ELSE '' END +
CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND Contracts.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
CASE WHEN @DueDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate = @DueDate' + ' ' ELSE '' END +
CASE WHEN @DueByDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate <= @DueByDate' + ' ' ELSE '' END +
CASE WHEN @DiscountingId IS NOT NULL THEN 'AND Discountings.Id = @DiscountingId' + ' ' ELSE '' END 

DECLARE @ValidInvoicesQuery NVARCHAR(MAX) = @ValidDetailInsertQuery + @WHERESTATEMENT

EXEC sp_executesql @ValidInvoicesQuery , 
N'@CurrencyISO NVARCHAR(3)
,@InvoiceNumber NVARCHAR(40)
,@ReceiptCustomerId BIGINT
,@ReceiptContractId BIGINT
,@CustomerName NVARCHAR(500)
,@CustomerNumber NVARCHAR(40)
,@ContractType NVARCHAR(14)
,@InvoiceType NVARCHAR(56)
,@LeaseSequenceNumber NVARCHAR(40)
,@DueDate DATETIME
,@DueByDate DATETIME
,@DiscountingId BIGINT
,@LoanInterestReceivableTypeId BIGINT
,@LoanPrincipalReceivableTypeId BIGINT
,@IsNonCashReceipt BIT 
,@LegalEntityId BIGINT
,@ImportedTaxType NVARCHAR(30)'
,@CurrencyISO
,@InvoiceNumber
,@ReceiptCustomerId 
,@ReceiptContractId
,@CustomerName
,@CustomerNumber
,@ContractType
,@InvoiceType
,@LeaseSequenceNumber
,@DueDate 
,@DueByDate 
,@DiscountingId
,@LoanInterestReceivableTypeId
,@LoanPrincipalReceivableTypeId
,@IsNonCashReceipt
,@LegalEntityId
,@ImportedTaxType

CREATE TABLE #ValidStatementDetailsForSelectALL
(
ReceivableInvoiceId BIGINT,
TaxType NVARCHAR(30)
)

DECLARE @ValidStatementDetailInsertQuery NVARCHAR(MAX) =				
'INSERT INTO #ValidStatementDetailsForSelectALL
SELECT DISTINCT ReceivableInvoices.Id AS ReceivableInvoiceId,Receivables.ReceivableTaxType AS TaxType
	FROM 
	ReceivableInvoices 
	JOIN ReceivableInvoiceStatementAssociations RISA ON RISA.StatementInvoiceId = ReceivableInvoices.Id 
		AND ReceivableInvoices.IsDummy = 0 AND ReceivableInvoices.IsActive = 1 AND ReceivableInvoices.IsStatementInvoice = 1  
	JOIN ReceivableInvoiceDetails ON RISA.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId
	JOIN #AccessibleLegalEntity AS AccessibleLegalEntity ON AccessibleLegalEntity.LegalEntityId = ReceivableInvoices.LegalEntityId
	JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id
						AND Receivables.IsDummy = 0   
						AND Receivables.IsCollected = 1 
	LEFT JOIN #TempStatementInvoiceId AS TempStatementInvoiceId ON TempStatementInvoiceId.StatementInvoiceId = ReceivableInvoices.Id
	LEFT JOIN Contracts ON Contracts.Id = ReceivableInvoiceDetails.EntityId AND ReceivableInvoiceDetails.EntityType = ''CT''
	LEFT JOIN Discountings ON Discountings.Id = Receivables.EntityId  AND ReceivableInvoiceDetails.EntityType = ''DT'''

DECLARE @StatementInvoice_WHERESTATEMENT NVARCHAR(2000) = 
'WHERE TempStatementInvoiceId.StatementInvoiceId IS NULL
	AND (ReceivableInvoices.EffectiveBalance_Amount + ReceivableInvoices.EffectiveTaxBalance_Amount) <> 0' +
CASE WHEN @InvoiceNumber IS NOT NULL THEN 'AND ReceivableInvoices.Number like @InvoiceNumber' + ' ' ELSE '' END +
CASE WHEN @ReceiptCustomerId IS NOT NULL THEN 'AND ReceivableInvoices.CustomerId = @ReceiptCustomerId' + ' ' ELSE '' END +
CASE WHEN @CustomerName IS NOT NULL THEN 'AND ReceivableInvoices.CustomerName LIKE @CustomerName' + ' ' ELSE '' END +
CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND ReceivableInvoices.CustomerNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
CASE WHEN @ReceiptContractId IS NOT NULL THEN 'AND Contracts.Id = @ReceiptContractId' + ' ' ELSE '' END +
CASE WHEN @ContractType IS NOT NULL THEN 'AND Contracts.ContractType = @ContractType' + ' ' ELSE '' END +
CASE WHEN @InvoiceType IS NOT NULL THEN 'AND ''Statement'' = @InvoiceType' + ' ' ELSE '' END +
CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND Contracts.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
CASE WHEN @DueDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate = @DueDate' + ' ' ELSE '' END +
CASE WHEN @DueByDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate <= @DueByDate' + ' ' ELSE '' END +
CASE WHEN @DiscountingId IS NOT NULL THEN 'AND Discountings.Id = @DiscountingId' + ' ' ELSE '' END +
CASE WHEN @MinOutstandingBalance IS NOT NULL THEN 'AND @MinOutstandingBalance <= (ReceivableInvoices.EffectiveBalance_Amount + ReceivableInvoices.EffectiveTaxBalance_Amount)' + ' ' ELSE '' END 

DECLARE @ValidStatementInvoicesQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + @ValidStatementDetailInsertQuery + @StatementInvoice_WHERESTATEMENT

EXEC sp_executesql @ValidStatementInvoicesQuery , 
N'@InvoiceNumber NVARCHAR(40)
,@ReceiptCustomerId BIGINT
,@ReceiptContractId BIGINT
,@CustomerName NVARCHAR(500)
,@CustomerNumber NVARCHAR(40)
,@ContractType NVARCHAR(14)
,@InvoiceType NVARCHAR(56)
,@LeaseSequenceNumber NVARCHAR(40)
,@DueDate DATETIME
,@DueByDate DATETIME
,@DiscountingId BIGINT
,@MinOutstandingBalance DECIMAL
,@ImportedTaxType NVARCHAR(30)'
,@InvoiceNumber 
,@ReceiptCustomerId 
,@ReceiptContractId 
,@CustomerName 
,@CustomerNumber 
,@ContractType 
,@InvoiceType
,@LeaseSequenceNumber
,@DueDate
,@DueByDate 
,@DiscountingId 
,@MinOutstandingBalance 
,@ImportedTaxType

CREATE TABLE #InvoiceSummary
(
	InvoiceId BIGINT,
	IsStatementInvoice BIT,
	InvoiceAmount DECIMAL(18,2),    
	EffectiveInvoiceBalance DECIMAL(18,2),           
	InvoiceTaxAmount DECIMAL(18,2),  
	EffectiveTaxBalance DECIMAL(18,2),
	Currency NVARCHAR(3),
	InvoiceNumber NVARCHAR(40),
	InvoiceType NVARCHAR(56),
	DueDate DATE,
	CustomerNumber NVARCHAR(40), 
	CustomerName NVARCHAR(500), 
	LegalEntityNumber NVARCHAR(20),
	TaxType NVARCHAR(30)
);

	SET @SELECTQUERY = N'
	;WITH CTE_InvoiceDetails
	AS
	(
	SELECT		ReceivableInvoices.Id AS ReceivableInvoiceId,
				ReceivableInvoices.IsStatementInvoice AS IsStatementInvoice,
				SUM(ReceivableInvoiceDetails.InvoiceAmount_Amount)    AS OriginalBalance_Amount,
				SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount)   AS EffectiveBalance_Amount,
				SUM(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount)  AS OriginalTaxBalance_Amount,
				SUM(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) AS EffectiveTaxBalance_Amount,
				ReceivableInvoices.Number AS InvoiceNumber,
				InvoiceTypes.Name AS InvoiceType,
				ReceivableInvoices.DueDate AS DueDate,
				ReceivableInvoices.CustomerNumber AS CustomerNumber, 
				ReceivableInvoices.CustomerName AS CustomerName,
				ReceivableInvoices.LegalEntityNumber AS LegalEntityNumber,
				ValidReceivableInvoiceDetails.TaxType
	FROM #ValidDetailsForSelectALL ValidReceivableInvoiceDetails
	JOIN ReceivableInvoices ON ValidReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
	JOIN InvoiceTypes ON InvoiceTypes.Id = ValidReceivableInvoiceDetails.InvoicetypeId
	JOIN ReceivableInvoiceDetails ON ValidReceivableInvoiceDetails.ReceivableInvoiceDetailId = ReceivableInvoiceDetails.Id 										  
	GROUP BY ReceivableInvoices.Id,  
				ReceivableInvoices.IsStatementInvoice,
				ReceivableInvoices.Number,
				InvoiceTypes.Name,
				ReceivableInvoices.DueDate,
				ReceivableInvoices.CustomerNumber, 
				ReceivableInvoices.CustomerName,
				ReceivableInvoices.LegalEntityNumber,
				ValidReceivableInvoiceDetails.TaxType				

	UNION ALL
	SELECT		ReceivableInvoices.Id AS ReceivableInvoiceId,
				ReceivableInvoices.IsStatementInvoice AS IsStatementInvoice,
				ReceivableInvoices.InvoiceAmount_Amount    AS OriginalBalance_Amount,
				ReceivableInvoices.EffectiveBalance_Amount   AS EffectiveBalance_Amount,
				ReceivableInvoices.InvoiceTaxAmount_Amount  AS OriginalTaxBalance_Amount,
				ReceivableInvoices.EffectiveTaxBalance_Amount AS EffectiveTaxBalance_Amount,
				ReceivableInvoices.Number AS InvoiceNumber,
				''Statement'' AS InvoiceType,
				ReceivableInvoices.DueDate AS DueDate,
				ReceivableInvoices.CustomerNumber AS CustomerNumber, 
				ReceivableInvoices.CustomerName AS CustomerName,
				ReceivableInvoices.LegalEntityNumber AS LegalEntityNumber,
				ValidReceivableInvoiceDetails.TaxType
	FROM #ValidStatementDetailsForSelectALL ValidReceivableInvoiceDetails
	JOIN ReceivableInvoices ON ValidReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id 
	)
	INSERT INTO #InvoiceSummary		
				SELECT 
				ReceivableInvoiceDetails.ReceivableInvoiceId AS InvoiceId,
				ReceivableInvoiceDetails.IsStatementInvoice AS IsStatementInvoice,
				ReceivableInvoiceDetails.OriginalBalance_Amount    AS InvoiceAmount,
				ReceivableInvoiceDetails.EffectiveBalance_Amount   AS EffectiveInvoiceBalance,
				ReceivableInvoiceDetails.OriginalTaxBalance_Amount  AS InvoiceTaxAmount,
				ReceivableInvoiceDetails.EffectiveTaxBalance_Amount AS EffectiveTaxBalance,
				@CurrencyISO AS Currency,
				ReceivableInvoiceDetails.InvoiceNumber AS InvoiceNumber,
				ReceivableInvoiceDetails.InvoiceType AS InvoiceType,
				ReceivableInvoiceDetails.DueDate AS DueDate,
				ReceivableInvoiceDetails.CustomerNumber AS CustomerNumber, 
				ReceivableInvoiceDetails.CustomerName AS CustomerName,
				ReceivableInvoiceDetails.LegalEntityNumber AS LegalEntityNumber,
				ReceivableInvoiceDetails.TaxType AS TaxType
	FROM CTE_InvoiceDetails ReceivableInvoiceDetails
	WHERE 1=1 AND ' + @WHERECLAUSE +' (@MinOutstandingBalance IS NULL OR @MinOutstandingBalance <= (ReceivableInvoiceDetails.EffectiveBalance_Amount + ReceivableInvoiceDetails.EffectiveTaxBalance_Amount))
	ORDER BY ReceivableInvoiceDetails.ReceivableInvoiceId'

	EXEC sp_executesql @SELECTQUERY , N'@CurrencyISO NVARCHAR(3), @MinOutstandingBalance DECIMAL(18,2)' ,@CurrencyISO, @MinOutstandingBalance	

	DECLARE @COUNT INT = 0; 
	SELECT @COUNT  = COUNT(*) 
	FROM 
	#InvoiceSummary;

	SELECT InvoiceId AS 'Id' 
	FROM 
	#InvoiceSummary;

	IF(dbo.IsStringNullOrEmpty(@OrderBy) = 1) SET @OrderBy = 'ASC'
	IF(dbo.IsStringNullOrEmpty(@OrderColumn) = 1) SET @OrderColumn = 'InvoiceNumber'

	;WITH CTE_InvoiceList AS (
	SELECT	
	ROW_NUMBER() OVER (ORDER BY      
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='InvoiceNumber' THEN InvoiceNumber END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='IsStatementInvoice' THEN IsStatementInvoice END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='LegalEntityNumber' THEN LegalEntityNumber END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='InvoiceType.Value' THEN InvoiceType END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='CustomerName' THEN CustomerName END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='CustomerNumber' THEN CustomerNumber END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='OriginalBalance.Amount' THEN InvoiceAmount END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='OriginalBalance.Currency' THEN InvoiceAmount END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='EffectiveBalance.Amount' THEN EffectiveInvoiceBalance END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='EffectiveBalance.Currency' THEN EffectiveInvoiceBalance END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='OriginalTaxBalance.Amount' THEN InvoiceTaxAmount END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='OriginalTaxBalance.Currency' THEN InvoiceTaxAmount END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='EffectiveTaxBalance.Amount' THEN EffectiveTaxBalance END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='EffectiveTaxBalance.Currency' THEN EffectiveTaxBalance END ASC,
			CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='DueDate' THEN DueDate END ASC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='InvoiceNumber' THEN InvoiceNumber END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='LegalEntityNumber' THEN LegalEntityNumber END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='InvoiceType.Value' THEN InvoiceType END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='CustomerName' THEN CustomerName END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='CustomerNumber' THEN CustomerNumber END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='OriginalBalance.Amount' THEN InvoiceAmount END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='OriginalBalance.Currency' THEN InvoiceAmount END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='EffectiveBalance.Amount' THEN EffectiveInvoiceBalance END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='EffectiveBalance.Currency' THEN EffectiveInvoiceBalance END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='OriginalTaxBalance.Amount' THEN InvoiceTaxAmount END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='OriginalTaxBalance.Currency' THEN InvoiceTaxAmount END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='EffectiveTaxBalance.Amount' THEN EffectiveTaxBalance END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='EffectiveTaxBalance.Currency' THEN EffectiveTaxBalance END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='DueDate' THEN DueDate END DESC,
			CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='TaxType.Value' THEN TaxType END DESC
) AS RowNumber,* 
	FROM #InvoiceSummary
	)
	SELECT InvoiceId AS 'Id',
			InvoiceNumber,
			IsStatementInvoice,
			LegalEntityNumber,
			CustomerNumber,
			CustomerName,
			InvoiceType,
			InvoiceAmount AS OriginalBalance_Amount,
			Currency AS OriginalBalance_Currency,
			EffectiveInvoiceBalance AS EffectiveBalance_Amount,
			Currency AS EffectiveBalance_Currency,
			InvoiceTaxAmount AS OriginalTaxBalance_Amount,
			Currency AS OriginalTaxBalance_Currency,
			EffectiveTaxBalance AS EffectiveTaxBalance_Amount,
			Currency AS EffectiveTaxBalance_Currency,
			DueDate,
			TaxType,
			@COUNT as TotalInvoices
	FROM CTE_InvoiceList 
	WHERE RowNumber BETWEEN @StartingRowNumber AND @EndingRowNumber
	ORDER BY RowNumber

DROP TABLE #InvoiceSummary;
DROP TABLE #ValidDetailsForSelectALL;
DROP TABLE #TempInvoiceId
DROP TABLE #AccessibleLegalEntity
DROP TABLE #TempAccessibleLegalEntityIds
DROP TABLE #ValidStatementDetailsForSelectALL
SET NOCOUNT OFF;
END

GO

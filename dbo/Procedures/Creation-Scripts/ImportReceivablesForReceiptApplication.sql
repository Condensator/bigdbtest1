SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ImportReceivablesForReceiptApplication] (
	@ReceivableId BIGINT,
	@LegalEntityId BIGINT,
	@AllowTransfer BIT,
	@FunderName NVARCHAR(500),
	@CustomerName NVARCHAR(500),
	@CustomerNumber NVARCHAR(40),
	@LeaseSequenceNumber NVARCHAR(40),
	@ReceivableType NVARCHAR(100),
	@DueDate DATETIME,
	@ContractType NVARCHAR(14),
	@ReceivableDetailIds ReceivableDetailIdCollection READONLY,
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
	@ReceivableDetailIdsToSelect ReceivableDetailIdCollection READONLY,
	@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY,
	@IsNonCashReceipt BIT =0,
	@DiscountingId BigInt,
	@GLConfigurationId	BIGINT,
	@WithHoldingTaxAssessed BIT,
	@IsWithHoldingTaxApplicable BIT,
	@DueByDate DATETIME = NULL,
	@MinDaysPastDue INT = NULL,
	@CurrentBusinessDate DATETIME,
	@MinOutstandingBalance DECIMAL(18,2) = NULL,
	@ReceivableCodeId BIGINT,
	@ReceivableCodeName NVARCHAR(400),
	@ImportedTaxType NVARCHAR(30)
) 
AS
BEGIN

SET NOCOUNT ON;

DECLARE @MinDaysPastDueDate DATETIME;

IF(@MinDaysPastDue IS NOT NULL)
BEGIN
	SET @MinDaysPastDue = CASE WHEN @MinDaysPastDue > 9999 THEN 9999 WHEN @MinDaysPastDue < 0 THEN 0 ELSE @MinDaysPastDue END
	SET @MinDaysPastDueDate = DATEADD(DD,@MinDaysPastDue*-1,@CurrentBusinessDate)

	IF(@DueByDate IS NOT NULL AND @MinDaysPastDueDate <= @DueByDate) 
		SET @DueByDate = @MinDaysPastDueDate
END

DECLARE
@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )

SET @ADVWHERECLAUSE = REPLACE(@ADVWHERECLAUSE,'"','')

DECLARE @HasTempReceivableDetailIds bit = (SELECT TOP 1 ReceivableDetailId FROM @ReceivableDetailIds)
IF(@HasTempReceivableDetailIds = 1)
BEGIN
SELECT ReceivableDetailId INTO #TempReceivableDetailId FROM @ReceivableDetailIds
CREATE NONCLUSTERED INDEX IX_ValidReceivables ON #TempReceivableDetailId(ReceivableDetailId);
END

SELECT LegalEntities.Id AS LegalEntityId, LegalEntities.LegalEntityNumber AS LegalEntityNumber
INTO #AccesibleLegalEntity
FROM LegalEntities
JOIN @AccessibleLegalEntityIds AS TLEId ON LegalEntities.Id = TLEId.LegalEntityId
WHERE (TLEId.LegalEntityId IS NOT NULL OR LegalEntities.Id = @LegalEntityId)
	AND (@AllowTransfer = 1 or @LegalEntityId = LegalEntities.Id)
	AND GLConfigurationId = @GLConfigurationId

CREATE TABLE #ReceivableDetailSummary
(   
	RowNumber							BIGINT,
	ReceivableId                        BIGINT NOT NULL,
	LegalEntityNumber                   NVARCHAR(20),
	FunderName                          NVARCHAR(250),
	CustomerName                        NVARCHAR(250),
	CustomerNumber                      NVARCHAR(40),
	SequenceNumber                      NVARCHAR(40),
	ContractType                        NVARCHAR(14),
	ReceivableType                      NVARCHAR(30),
	DueDate                             DATETIME,
	ReceivableDetailId                  BIGINT NOT NULL,
	ReceivableAmount_Amount             DECIMAL(18, 2) NOT NULL,
	ReceivableAmount_Currency           NVARCHAR(3),
	EffectiveReceivableBalance_Amount   DECIMAL(18, 2) NOT NULL,
	EffectiveReceivableBalance_Currency NVARCHAR(3),
	EffectiveTaxBalance_Amount          DECIMAL(18, 2) NOT NULL,
	EffectiveTaxBalance_Currency        NVARCHAR(3),
	TaxAmount_Amount                    DECIMAL(18, 2) NOT NULL,
	TaxAmount_Currency                  NVARCHAR(3),
	ReceivableCodeName					NVARCHAR(400),
	TaxType								NVARCHAR(30)
);

DECLARE @ReceivableDetailsSelectStatement Nvarchar(1000) =
	'SELECT 
	r.Id as [ReceivableId],
	le.LegalEntityNumber [LegalEntityNumber],
	fp.PartyNumber AS [FunderName],
	p.PartyName AS [CustomerName],
	p.PartyNumber AS [CustomerNumber],
	CASE WHEN c.Id IS NOT NULL THEN c.SequenceNumber WHEN d.Id IS NOT NULL THEN d.SequenceNumber END AS [SequenceNumber],
	c.ContractType AS [ContractType],
	rt.Name AS [ReceivableType],
	r.DueDate AS [DueDate],
	rd.Id AS [ReceivableDetailId],
	rd.Amount_Amount AS [ReceivableAmount_Amount],	
	rd.EffectiveBalance_Amount AS [EffectiveReceivableBalance_Amount],
	rd.Balance_Currency AS [Currency],
	rc.Name AS [ReceivableCodeName],
	r.ReceivableTaxType AS [TaxType]'

DECLARE @ReceivableTaxDetailsSelectStatement Nvarchar(1000) =
	'SELECT 
	rtd.ReceivableDetailId AS [TaxReceivableDetailId], 
	SUM(rtd.Amount_Amount) AS [TaxAmount_Amount], 
	SUM(rtd.EffectiveBalance_Amount) AS [EffectiveTaxBalance_Amount]'

DECLARE @ReceivableDetailsJoinStatement Nvarchar(1000) =  
	' FROM #AccesibleLegalEntity le 
	JOIN dbo.Receivables r ON r.LegalEntityId = le.LegalEntityId AND r.IsActive = 1	AND r.IsDummy = 0 AND r.IsCollected = 1 
	JOIN dbo.ReceivableDetails rd ON r.Id = rd.ReceivableId AND rd.IsActive = 1
	JOIN dbo.Parties p ON r.CustomerId = p.Id
	JOIN dbo.ReceivableCodes rc ON r.ReceivableCodeId = rc.Id
	JOIN dbo.ReceivableTypes rt ON rc.ReceivableTypeId = rt.Id
	LEFT JOIN Contracts c ON r.EntityId = c.Id AND r.EntityType = ''CT''
	LEFT JOIN Parties fp ON fp.Id = r.FunderId
	LEFT JOIN Discountings d ON d.Id = r.EntityId AND r.EntityType = ''DT'''+
		
	CASE WHEN @WithHoldingTaxAssessed IS NOT NULL AND @WithHoldingTaxAssessed = 1 
		 THEN 'JOIN ReceivableWithHoldingTaxDetails ON r.Id = ReceivableWithHoldingTaxDetails.ReceivableId AND ReceivableWithHoldingTaxDetails.IsActive = 1' + ' ' ELSE '' END +
	CASE WHEN @WithHoldingTaxAssessed IS NOT NULL AND @WithHoldingTaxAssessed = 0 
		 THEN 'LEFT JOIN ReceivableWithHoldingTaxDetails ON r.Id = ReceivableWithHoldingTaxDetails.ReceivableId AND ReceivableWithHoldingTaxDetails.IsActive = 1' + ' ' ELSE '' END +
	CASE WHEN @HasTempReceivableDetailIds = 1
		 THEN 'LEFT JOIN #TempReceivableDetailId ON rd.Id = #TempReceivableDetailId.ReceivableDetailId' + ' ' ELSE '' END 

DECLARE @ReceivableTaxDetailsJoinStatement Nvarchar(1000) =
	' JOIN dbo.ReceivableTaxes tax ON r.Id = tax.ReceivableId AND tax.IsActive=1
	JOIN dbo.ReceivableTaxDetails rtd ON rd.Id = rtd.ReceivableDetailId AND rtd.IsActive = 1'

DECLARE @TaxLeftJoin Nvarchar(100) = 'LEFT JOIN dbo.ReceivableTaxes tax ON r.Id = tax.ReceivableId AND tax.IsActive=1' 

DECLARE @WhereStatement Nvarchar(1000) =  
	' WHERE ((r.TotalEffectiveBalance_Amount + ISNULL(tax.EffectiveBalance_Amount,0.00)) > 0 
		OR ((r.TotalEffectiveBalance_Amount + ISNULL(tax.EffectiveBalance_Amount,0.00)) < 0 AND (@IsNonCashReceipt = 0 OR r.LegalEntityId = @LegalEntityId)))
	AND ((c.Id IS NULL OR c.ContractType != ''Loan'' OR c.IsNonAccrual = 0)
		OR (rt.Id != @LoanInterestReceivableTypeId AND rt.Id != @LoanPrincipalReceivableTypeId)
		OR (r.IncomeType IN (''InterimInterest'',''TakeDownInterest'')))
		AND (@ImportedTaxType IS NULL OR r.ReceivableTaxType = @ImportedTaxType) ' +
	CASE WHEN @ReceiptContractId IS NOT NULL  THEN 'AND c.Id = @ReceiptContractId' + ' ' ELSE '' END +
	CASE WHEN @ReceiptCustomerId IS NOT NULL  THEN 'AND p.Id = @ReceiptCustomerId' + ' ' ELSE '' END +
	CASE WHEN @IsWithHoldingTaxApplicable = 1 AND @WithHoldingTaxAssessed = 1 THEN 'AND ReceivableWithHoldingTaxDetails.Id IS NOT NULL' + ' ' ELSE '' END +
	CASE WHEN @IsWithHoldingTaxApplicable = 1 AND @WithHoldingTaxAssessed = 0 THEN 'AND ReceivableWithHoldingTaxDetails.Id IS NULL' + ' ' ELSE '' END +
	CASE WHEN @HasTempReceivableDetailIds = 1THEN 'AND #TempReceivableDetailId.ReceivableDetailId IS NULL' + ' ' ELSE '' END +
	CASE WHEN @DiscountingId IS NOT NULL  THEN 'AND d.Id = @DiscountingId' + ' ' ELSE '' END +
	CASE WHEN @FunderName IS NOT NULL THEN 'AND fp.PartyName = @FunderName' + ' ' ELSE '' END +	
	CASE WHEN @ReceivableId IS NOT NULL THEN 'AND r.Id = @ReceivableId' + ' ' ELSE '' END +
	CASE WHEN @ContractType IS NOT NULL THEN 'AND c.ContractType = @ContractType' + ' ' ELSE '' END +
	CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND c.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
	CASE WHEN @CurrencyISO IS NOT NULL THEN 'AND rd.Amount_Currency = @CurrencyISO' + ' ' ELSE '' END +
	CASE WHEN @ReceivableType IS NOT NULL THEN 'AND rt.Name = @ReceivableType' + ' ' ELSE '' END +
	CASE WHEN @DueDate IS NOT NULL THEN 'AND r.DueDate = @DueDate' + ' ' ELSE '' END +
	CASE WHEN @DueByDate IS NOT NULL THEN 'AND r.DueDate <= @DueByDate' + ' ' ELSE '' END +
	CASE WHEN @CustomerName IS NOT NULL THEN 'AND p.PartyName LIKE @CustomerName' + ' ' ELSE '' END +
	CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND p.PartyNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
	CASE WHEN @ReceivableCodeId IS NOT NULL THEN 'AND (rc.Id = @ReceivableCodeId AND rc.IsActive = 1)' + ' ' ELSE '' END +
	CASE WHEN @ReceivableCodeName IS NOT NULL THEN 'AND (rc.Name = @ReceivableCodeName AND rc.IsActive = 1)' + ' ' ELSE '' END
	

IF(dbo.IsStringNullOrEmpty(@OrderBy) = 1) SET @OrderBy = 'ASC'
IF(dbo.IsStringNullOrEmpty(@OrderColumn) = 1) SET @OrderColumn = 'ReceivableId'
DECLARE @OrderStatement Nvarchar(500) =  
	CASE 
	WHEN @OrderColumn='ContractType.Value' THEN 'ContractType' + ' ' + @OrderBy
	WHEN @OrderColumn='ReceivableType.Value' THEN 'ReceivableType'  + ' ' + @OrderBy
	WHEN @OrderColumn='ReceivableAmount.Amount' THEN 'ReceivableAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='ReceivableAmount.Currency' THEN 'ReceivableAmount_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='EffectiveReceivableBalance.Amount' THEN 'EffectiveReceivableBalance_Amount'  + ' ' + @OrderBy
	WHEN @OrderColumn='EffectiveReceivableBalance.Currency' THEN 'EffectiveReceivableBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='TaxAmount.Amount' THEN 'TaxAmount_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='TaxAmount.Currency' THEN 'TaxAmount_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='EffectiveTaxBalance.Amount' THEN 'EffectiveTaxBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='EffectiveTaxBalance.Currency' THEN 'EffectiveTaxBalance_Amount' + ' ' + @OrderBy
	WHEN @OrderColumn='TaxType.Value' THEN 'TaxType' 
	ELSE @OrderColumn + ' ' + @OrderBy END


DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '
;With ReceivableDetailsInfo AS ( ' 
	+ @ReceivableDetailsSelectStatement 
	+ @ReceivableDetailsJoinStatement 
	+ @TaxLeftJoin
	+ @WhereStatement 
+ '), ReceivableTaxDetailsInfo AS ( ' 
	+ @ReceivableTaxDetailsSelectStatement 
	+ @ReceivableDetailsJoinStatement 
	+ @ReceivableTaxDetailsJoinStatement 
	+ @WhereStatement
+ ' GROUP BY rtd.ReceivableDetailId ) 

INSERT INTO #ReceivableDetailSummary
SELECT 
	ROW_NUMBER() OVER (ORDER BY ' + @OrderStatement + ') RowNumber,
	ReceivableId,
	LegalEntityNumber,
	FunderName,
	CustomerName,
	CustomerNumber,
	SequenceNumber,
	ContractType,
	ReceivableType,
	DueDate,
	rd.ReceivableDetailId,
	ReceivableAmount_Amount,
	Currency AS ReceivableAmount_Currency,
	EffectiveReceivableBalance_Amount,
	Currency AS EffectiveReceivableBalance_Currency,
	ISNULL(EffectiveTaxBalance_Amount, 0.00) AS EffectiveTaxBalance_Amount,
	Currency AS EffectiveTaxBalance_Currency,
	ISNULL(TaxAmount_Amount, 0.00) AS TaxAmount_Amount,
	Currency AS TaxAmount_Currency,
	ReceivableCodeName,
	TaxType

FROM ReceivableDetailsInfo rd
LEFT JOIN ReceivableTaxDetailsInfo rtd on rd.ReceivableDetailId = rtd.TaxReceivableDetailId
WHERE ' + @ADVWHERECLAUSE +'(EffectiveReceivableBalance_Amount + ISNULL(EffectiveTaxBalance_Amount,0.00)) != 0.00 
AND (@MinOutstandingBalance IS NULL OR @MinOutstandingBalance <= (EffectiveReceivableBalance_Amount + ISNULL(EffectiveTaxBalance_Amount,0.00)))'

EXEC sp_executesql @SelectQuery,
	N'@ExistingReceivableCount BIGINT
	,@ReceiptContractId BIGINT
	,@ReceivableId BIGINT
	,@ContractType Nvarchar(14)
	,@LeaseSequenceNumber NVARCHAR(40)
	,@ReceivableType NVARCHAR(100)
	,@DueDate DATETIME
	,@DueByDate DATETIME
	,@MinOutstandingBalance DECIMAL(18,2)
	,@DiscountingId BigInt
	,@FunderName NVARCHAR(500)
	,@CustomerName NVARCHAR(500)
	,@CustomerNumber NVARCHAR(40)
	,@ReceiptCustomerId BIGINT 
	,@IsNonCashReceipt BIT
	,@LegalEntityId BIGINT 
	,@LoanInterestReceivableTypeId BIGINT
	,@LoanPrincipalReceivableTypeId BIGINT
	,@ReceivableCodeId BIGINT
	,@ReceivableCodeName NVARCHAR(400)
	,@CurrencyISO NVARCHAR(6)
	,@ImportedTaxType NVARCHAR(30)'
	,@ExistingReceivableCount
	,@ReceiptContractId
	,@ReceivableId
	,@ContractType
	,@LeaseSequenceNumber
	,@ReceivableType
	,@DueDate
	,@DueByDate
	,@MinOutstandingBalance
	,@DiscountingId
	,@FunderName
	,@CustomerName
	,@CustomerNumber 
	,@ReceiptCustomerId
	,@IsNonCashReceipt
	,@LegalEntityId
	,@LoanInterestReceivableTypeId
	,@LoanPrincipalReceivableTypeId
	,@ReceivableCodeId
	,@ReceivableCodeName
	,@CurrencyISO
	,@ImportedTaxType;


SELECT ReceivableDetailId AS Id FROM #ReceivableDetailSummary

DECLARE @COUNT INT = (SELECT COUNT(*) FROM #ReceivableDetailSummary)

SELECT 
ReceivableDetailId AS [Id], 
ReceivableDetailId, 
ReceivableId, 
LegalEntityNumber, 
FunderName, 
CustomerName, 
CustomerNumber, 
SequenceNumber,
ContractType,
ReceivableType,
DueDate,
ReceivableAmount_Amount,
ReceivableAmount_Currency,
EffectiveReceivableBalance_Amount,
EffectiveReceivableBalance_Currency,
TaxAmount_Amount,
TaxAmount_Currency,
EffectiveTaxBalance_Amount,
EffectiveTaxBalance_Currency,
ReceivableCodeName,
TaxType,
@COUNT AS [TotalReceivables], RowNumber

FROM #ReceivableDetailSummary WHERE RowNumber BETWEEN @StartingRowNumber AND @EndingRowNumber

IF(@HasTempReceivableDetailIds = 1)
DROP TABLE #TempReceivableDetailId
DROP TABLE #AccesibleLegalEntity
DROP TABLE #ReceivableDetailSummary

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ImportReceivablesForReApplication]
(
    @ReceiptId				BIGINT,
    @ReceivableId			BIGINT,
    @FunderName				NVARCHAR(500),
    @CustomerName			NVARCHAR(500),
    @CustomerNumber			NVARCHAR(40),
    @LeaseSequenceNumber	NVARCHAR(40),
    @ReceivableType			NVARCHAR(100),
    @DueDate				DATETIME,
    @ContractType			NVARCHAR(14),
    @ReceivableDetailIds	ReceivableDetailIdCollection READONLY,
    @ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX),
    @StartingRowNumber		INT,
    @EndingRowNumber		INT,
    @ExistingReceivableCount INT,
    @OrderBy				NVARCHAR(6) = NULL,
    @OrderColumn			NVARCHAR(MAX) = NULL,
    @ADVWHERECLAUSE			NVARCHAR(2000) = '',
    @IsForSelectAll			BIT = 0,
    @ReceivableDetailIdsToSelect ReceivableDetailIdCollection READONLY,
	@DueByDate				DATETIME = NULL,
	@MinDaysPastDue			INT = NULL,
	@CurrentBusinessDate	DATETIME,
	@MinOutstandingBalance	DECIMAL(18,2) = NULL,
	@ReceivableCodeId		BIGINT,
	@ReceivableCodeName		NVARCHAR(400),
	@ImportedTaxType		NVARCHAR(30) = NULL,
	@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY
)
AS
BEGIN

SET NOCOUNT ON;

DECLARE @MinDaysPastDueDate DATETIME;

IF(@MinDaysPastDue IS NOT NULL)
BEGIN
	SET @MinDaysPastDue = CASE WHEN @MinDaysPastDue > 9999 THEN 9999 WHEN @MinDaysPastDue < 0 THEN 0 ELSE @MinDaysPastDue END
	SET @MinDaysPastDueDate = DATEADD(DD,@MinDaysPastDue*-1,@CurrentBusinessDate)

	IF(@DueByDate IS NULL OR @MinDaysPastDueDate <= @DueByDate) 
		SET @DueByDate = @MinDaysPastDueDate 
END

SET @ADVWHERECLAUSE = REPLACE(@ADVWHERECLAUSE,'"','')
SET @ADVWHERECLAUSE = CASE WHEN @ADVWHERECLAUSE LIKE '%ReceivableDetailId%' THEN REPLACE(@ADVWHERECLAUSE,'ReceivableDetailId','ReceivableDetailsInfo.ReceivableDetailId') ELSE @ADVWHERECLAUSE END

SELECT ReceivableDetailId INTO #TempReceivableDetailId FROM @ReceivableDetailIds

DECLARE
@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )


SELECT LegalEntityId INTO #AccesibleLegalEntity
FROM @AccessibleLegalEntityIds

CREATE TABLE #ReceivableDetailSummary
(
	RowNumber						BIGINT,
	ReceivableDetailId				BIGINT,
	ReceivableId					BIGINT,
	LegalEntityNumber				NVARCHAR(20),
	FunderName						NVARCHAR(500),
	CustomerName					NVARCHAR(500),
	CustomerNumber					NVARCHAR(40),
	SequenceNumber					NVARCHAR(40),
	ContractType					NVARCHAR(14),
	ReceivableType					NVARCHAR(100),
	DueDate							DATETIME,
	Currency						NVARCHAR(3),
	ReceivableAmount_Amount			DECIMAL(18,2),
	EffectiveReceivableBalance_Amount DECIMAL(18,2),
	TaxAmount_Amount				DECIMAL(18,2),
	TaxCurrency						NVARCHAR(3),
	EffectiveTaxBalance_Amount		DECIMAL(18,2),
	WithHoldingTaxEffectiveBalance_Amount	DECIMAL(18,2),	
	ReceivableCodeName				NVARCHAR(400),
	TaxType							NVARCHAR(30)
);

CREATE TABLE #AppliedReceivableDetails(ReceivableDetailId BIGINT, AmountApplied DECIMAL(18, 2), TaxApplied DECIMAL(18, 2));
CREATE NONCLUSTERED INDEX IX_AppliedReceivableDetails ON #AppliedReceivableDetails(ReceivableDetailId);

INSERT INTO #AppliedReceivableDetails
SELECT 
	ReceiptApplicationReceivableDetails.ReceivableDetailId AS ReceivableDetailId,
	SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) AS AmountApplied,
	SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied	
FROM ReceiptApplicationReceivableDetails
JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
LEFT JOIN #TempReceivableDetailId ON #TempReceivableDetailId.ReceivableDetailId = ReceiptApplicationReceivableDetails.ReceivableDetailId
WHERE ReceiptApplications.ReceiptId = @ReceiptId
	AND ReceiptApplicationReceivableDetails.IsActive = 1
	AND #TempReceivableDetailId.ReceivableDetailId IS NULL
GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId
HAVING SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) +	SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) > 0 

DECLARE @ReceivableDetailsSelectStatement Nvarchar(2000) =
	'SELECT 
		ValidAppliedReceivables.ReceivableDetailId,
		Receivables.Id AS ReceivableId,
		FunderParties.PartyName AS FunderName,
		Parties.PartyName AS CustomerName,
		Parties.PartyNumber AS CustomerNumber,
		Contracts.SequenceNumber AS SequenceNumber,
		Contracts.ContractType AS ContractType,
		ReceivableTypes.Name AS  ReceivableType,
		Receivables.DueDate AS DueDate,
		ReceivableDetails.Amount_Amount AS ReceivableAmount_Amount,
		ReceivableDetails.EffectiveBalance_Amount AS EffectiveReceivableBalance_Amount,
		ReceivableDetails.Amount_Currency AS Currency,
		LegalEntities.LegalEntityNumber AS LegalEntityNumber,
		ISNULL(RDWTD.EffectiveBalance_Amount, 0.00) AS WithHoldingTaxEffectiveBalance_Amount,
		ReceivableCodes.Name AS ReceivableCodeName,
		Receivables.ReceivableTaxType AS TaxType
	FROM #AppliedReceivableDetails ValidAppliedReceivables
		JOIN ReceivableDetails ON ValidAppliedReceivables.ReceivableDetailId = ReceivableDetails.Id
		JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive = 1
		JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
		JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
		JOIN Parties ON Parties.Id = Receivables.CustomerId
		JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
		JOIN #AccesibleLegalEntity ON LegalEntities.Id = #AccesibleLegalEntity.LegalEntityId
		LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON ReceivableDetails.Id = RDWTD.ReceivableDetailId
		LEFT JOIN Contracts ON Contracts.Id = Receivables.EntityId AND Receivables.EntityType = ''CT''
		LEFT JOIN Funders ON Funders.Id = Receivables.FunderId
		LEFT JOIN Parties FunderParties ON FunderParties.Id = Funders.Id'

DECLARE @WhereStatement Nvarchar(2000) =  '
  WHERE 
    ((Contracts.Id IS NULL OR Contracts.ContractType != ''Loan'' OR Contracts.IsNonAccrual = 0)
   OR (ReceivableTypes.Id != @LoanInterestReceivableTypeId AND ReceivableTypes.Id != @LoanPrincipalReceivableTypeId)
   OR (Receivables.IncomeType IN (''InterimInterest'',''TakeDownInterest''))) 
   AND (@ImportedTaxType IS NULL OR Receivables.ReceivableTaxType = @ImportedTaxType) ' +
   
	CASE WHEN @ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt IS NOT NULL  
		 THEN 'AND ReceivableDetails.Id NOT IN (SELECT ID FROM ConvertCSVToBigIntTable   (@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt, '',''))' + ' ' ELSE '' END +
	CASE WHEN @FunderName IS NOT NULL THEN 'AND FunderParties.PartyName = @FunderName' + ' ' ELSE '' END +	
	CASE WHEN @CustomerName IS NOT NULL THEN 'AND Parties.PartyName LIKE @CustomerName' + ' ' ELSE '' END +
	CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND Parties.PartyNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
	CASE WHEN @ContractType IS NOT NULL THEN 'AND Contracts.ContractType = @ContractType' + ' ' ELSE '' END +
	CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND Contracts.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
	CASE WHEN @ReceivableType IS NOT NULL THEN 'AND ReceivableTypes.Name = @ReceivableType' + ' ' ELSE '' END +
	CASE WHEN @DueDate IS NOT NULL THEN 'AND Receivables.DueDate = @DueDate' + ' ' ELSE '' END +
	CASE WHEN @DueByDate IS NOT NULL THEN 'AND Receivables.DueDate <= @DueByDate' + ' ' ELSE '' END +
	CASE WHEN @ReceivableCodeId IS NOT NULL THEN 'AND (ReceivableCodes.Id = @ReceivableCodeId AND ReceivableCodes.IsActive = 1)' + ' ' ELSE '' END +
	CASE WHEN @ReceivableCodeName IS NOT NULL THEN 'AND (ReceivableCodes.Name = @ReceivableCodeName AND ReceivableCodes.IsActive = 1)' + ' ' ELSE '' END

DECLARE @ReceivableTaxDetailsSelectStatement Nvarchar(2000) =
	'SELECT  
		ReceivableTaxDetails.ReceivableDetailId,
		SUM(ReceivableTaxDetails.Amount_Amount) AS TaxAmount_Amount,
		SUM(ReceivableTaxDetails.EffectiveBalance_Amount) AS EffectiveTaxBalance_Amount
	FROM #AppliedReceivableDetails ValidAppliedReceivables
	JOIN ReceivableDetails ON ValidAppliedReceivables.ReceivableDetailId = ReceivableDetails.Id
	JOIN Receivables ON ReceivableDetails.ReceivableId = Receivables.Id AND Receivables.IsActive = 1
	JOIN ReceivableTaxDetails ON ReceivableTaxDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableTaxDetails.IsActive = 1
	JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id AND ReceivableTaxes.IsActive = 1
	JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	JOIN Parties ON Parties.Id = Receivables.CustomerId
	JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
	LEFT JOIN Contracts ON Contracts.Id = Receivables.EntityId AND Receivables.EntityType = ''CT''
	LEFT JOIN Funders ON Funders.Id = Receivables.FunderId
	LEFT JOIN Parties FunderParties ON FunderParties.Id = Funders.Id'

IF(dbo.IsStringNullOrEmpty(@OrderBy) = 1) SET @OrderBy = 'ASC'
IF(dbo.IsStringNullOrEmpty(@OrderColumn) = 1) SET @OrderColumn = 'ReceivableId'
DECLARE @OrderStatement Nvarchar(1000) =  
     CASE 
     WHEN @OrderColumn='ContractType.Value' THEN 'ContractType' + ' ' + @OrderBy
     WHEN @OrderColumn='ReceivableType.Value' THEN 'ReceivableType' + ' ' + @OrderBy
     WHEN @OrderColumn='ReceivableAmount.Amount' THEN 'ReceivableAmount_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='ReceivableAmount.Currency' THEN 'ReceivableAmount_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='EffectiveReceivableBalance.Amount' THEN 'EffectiveReceivableBalance_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='EffectiveReceivableBalance.Currency' THEN 'EffectiveReceivableBalance_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='TaxAmount.Amount' THEN 'TaxAmount_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='TaxAmount.Currency' THEN 'TaxAmount_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='EffectiveTaxBalance.Amount' THEN 'EffectiveTaxBalance_Amount' + ' ' + @OrderBy
     WHEN @OrderColumn='EffectiveTaxBalance.Currency' THEN 'EffectiveTaxBalance_Amount' + ' ' + @OrderBy
	 WHEN @OrderColumn='ReceivableDetailId' THEN 'ReceivableDetailsInfo.ReceivableDetailId' + ' ' + @OrderBy
     ELSE @OrderColumn + ' ' + @OrderBy END


DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '
;With ReceivableDetailsInfo AS ( ' 
	+ @ReceivableDetailsSelectStatement
	+ @WhereStatement 

+ '), ReceivableTaxDetailsInfo AS ( ' 
	+ @ReceivableTaxDetailsSelectStatement 
	+ @WhereStatement

+ ' GROUP BY ReceivableTaxDetails.ReceivableDetailId
)
INSERT INTO #ReceivableDetailSummary
SELECT 
	ROW_NUMBER() OVER (ORDER BY ' + @OrderStatement + '),
    ReceivableDetailsInfo.ReceivableDetailId,
    ReceivableDetailsInfo.ReceivableId,
    ReceivableDetailsInfo.LegalEntityNumber,
    ReceivableDetailsInfo.FunderName,
    ReceivableDetailsInfo.CustomerName,
    ReceivableDetailsInfo.CustomerNumber,
    ReceivableDetailsInfo.SequenceNumber,
    ReceivableDetailsInfo.ContractType,
    ReceivableDetailsInfo.ReceivableType,
    ReceivableDetailsInfo.DueDate,
    ReceivableDetailsInfo.Currency,
    ReceivableDetailsInfo.ReceivableAmount_Amount AS ReceivableAmount_Amount,
    ReceivableDetailsInfo.EffectiveReceivableBalance_Amount AS EffectiveReceivableBalance_Amount,
    ISNULL(ReceivableTaxDetailsInfo.TaxAmount_Amount, 0.0) AS TaxAmount_Amount,
    ReceivableDetailsInfo.Currency AS TaxCurrency,
    ISNULL(ReceivableTaxDetailsInfo.EffectiveTaxBalance_Amount, 0.0) AS EffectiveTaxBalance_Amount,
	ReceivableDetailsInfo.WithHoldingTaxEffectiveBalance_Amount,
	ReceivableDetailsInfo.ReceivableCodeName,
	ReceivableDetailsInfo.TaxType
FROM ReceivableDetailsInfo
LEFT JOIN ReceivableTaxDetailsInfo ON ReceivableDetailsInfo.ReceivableDetailId = ReceivableTaxDetailsInfo.ReceivableDetailId
WHERE ' + @ADVWHERECLAUSE +' (@MinOutstandingBalance IS NULL OR @MinOutstandingBalance >= ReceivableDetailsInfo.EffectiveReceivableBalance_Amount + ISNULL(ReceivableTaxDetailsInfo.EffectiveTaxBalance_Amount, 0.0))
ORDER BY ReceivableDetailsInfo.ReceivableDetailId'

EXEC sp_executesql @SelectQuery,
N'@ReceiptId BIGINT,
@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX),
@ReceivableId BIGINT,
@FunderName NVARCHAR(500),
@CustomerName NVARCHAR(500),
@CustomerNumber NVARCHAR(40),
@ContractType NVARCHAR(14),
@LeaseSequenceNumber NVARCHAR(40),
@ReceivableType NVARCHAR(100),
@DueDate DATETIME,
@StartingRowNumber INT,
@EndingRowNumber INT,
@LoanInterestReceivableTypeId BIGINT,
@LoanPrincipalReceivableTypeId BIGINT,
@DueByDate DATETIME,
@MinOutstandingBalance DECIMAL(18,2),
@ReceivableCodeId BIGINT,
@ReceivableCodeName NVARCHAR(400),
@ImportedTaxType	NVARCHAR(30)',
@ReceiptId,
@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt,
@ReceivableId,
@FunderName,
@CustomerName,
@CustomerNumber,
@ContractType,
@LeaseSequenceNumber,
@ReceivableType,
@DueDate,
@StartingRowNumber,
@EndingRowNumber,
@LoanInterestReceivableTypeId,
@LoanPrincipalReceivableTypeId,
@DueByDate,
@MinOutstandingBalance,
@ReceivableCodeId,
@ReceivableCodeName,
@ImportedTaxType;


SELECT Id = ReceivableDetailId FROM #ReceivableDetailSummary

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
Currency AS ReceivableAmount_Currency, 
EffectiveReceivableBalance_Amount,
Currency AS EffectiveReceivableBalance_Currency, 
TaxAmount_Amount,
TaxCurrency AS TaxAmount_Currency, 
EffectiveTaxBalance_Amount, 
TaxCurrency AS EffectiveTaxBalance_Currency, 
WithHoldingTaxEffectiveBalance_Amount AS WithHoldingTaxEffectiveBalance_Amount, 
Currency AS WithHoldingTaxEffectiveBalance_Currency,
ReceivableCodeName,
TaxType,
@COUNT AS TotalReceivables
		
FROM #ReceivableDetailSummary WHERE RowNumber BETWEEN @StartingRowNumber AND @EndingRowNumber

DROP TABLE #TempReceivableDetailId
DROP TABLE #AppliedReceivableDetails
DROP TABLE #ReceivableDetailSummary
DROP TABLE #AccesibleLegalEntity
END

GO

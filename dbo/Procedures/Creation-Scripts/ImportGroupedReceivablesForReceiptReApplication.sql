SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ImportGroupedReceivablesForReceiptReApplication]
(
	@ReceiptId				BIGINT,
	@LeaseSequenceNumber	NVARCHAR(40),
	@ReceivableType			NVARCHAR(100),
	@FunderName				NVARCHAR(500),
	@DueDate				DATETIME,
	@CustomerName			NVARCHAR(500),
	@CustomerNumber			NVARCHAR(40),
	@ContractType			NVARCHAR(14),		
	@ReceivableIds			ReceiptReceivableIdCollection READONLY,
	@ReceivableIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX),
	@StartingRowNumber		INT,
	@EndingRowNumber		INT,
	@ExistingReceivableCount INT,
	@OrderBy				NVARCHAR(6) = NULL,
	@OrderColumn			NVARCHAR(MAX) = NULL,
	@ADVWHERECLAUSE			NVARCHAR(2000) = '',
	@DueByDate				DATETIME = NULL,
	@MinDaysPastDue			INT = NULL,
	@CurrentBusinessDate	DATETIME,
	@MinOutstandingBalance	DECIMAL(18,2) = NULL,
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

	CREATE TABLE #TempReceivableId
	(
		ReceivableId BIGINT NULL
	)

	DECLARE @HasTempReceivableIds bit = (SELECT TOP 1 ReceivableId FROM @ReceivableIds)
	IF(@HasTempReceivableIds = 1)
	BEGIN
		INSERT INTO #TempReceivableId SELECT ReceivableId FROM @ReceivableIds
	END

	DECLARE
	@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
	@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )

SELECT LegalEntityId INTO #AccesibleLegalEntity
FROM @AccessibleLegalEntityIds

CREATE TABLE #ReceivableGroupSummary
(
	RowNumber								BIGINT,
	ReceivableId							BIGINT NOT NULL,
	LegalEntityNumber						NVARCHAR(20),
	FunderName								NVARCHAR(250),
	CustomerName							NVARCHAR(250),
	CustomerNumber							NVARCHAR(40),
	SequenceNumber							NVARCHAR(40),
	ContractType							NVARCHAR(14),
	ReceivableType							NVARCHAR(30),
	DueDate									DATETIME,
	Currency								NVARCHAR(3),
	ReceivableAmount_Amount					DECIMAL(18, 2) NOT NULL,
	EffectiveReceivableBalance_Amount		DECIMAL(18, 2) NOT NULL,
	TaxAmount_Amount						DECIMAL(18, 2) NOT NULL,
	TaxCurrency								NVARCHAR(3),
	EffectiveTaxBalance_Amount				DECIMAL(18, 2) NOT NULL,
	WithHoldingTaxEffectiveBalance_Amount   DECIMAL(18, 2) NOT NULL,
	TaxType									NVARCHAR(30)
);

	CREATE TABLE #AppliedReceivables(ReceivableId BIGINT, AmountApplied DECIMAL(18, 2), TaxApplied DECIMAL(18, 2));
	CREATE NONCLUSTERED INDEX IX_AppliedReceivables ON #AppliedReceivables(ReceivableId);

	INSERT INTO #AppliedReceivables
	SELECT 
	ReceivableDetails.ReceivableId AS ReceivableId,
	SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) AS AmountApplied,
	SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) AS TaxApplied
	FROM ReceiptApplicationReceivableDetails
	JOIN ReceiptApplications ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
	JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	LEFT JOIN #TempReceivableId ON #TempReceivableId.ReceivableId = ReceivableDetails.ReceivableId
	WHERE ReceiptApplications.ReceiptId = @ReceiptId
		AND ReceiptApplicationReceivableDetails.IsActive = 1
		AND #TempReceivableId.ReceivableId IS NULL
	GROUP BY ReceivableDetails.ReceivableId
	HAVING SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount) + SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount) > 0

	DECLARE @ReceivablesSelectStatement Nvarchar(2000) =
		'SELECT  
		Receivables.Id AS ReceivableId,
		FunderParties.PartyName AS FunderName,
		Parties.PartyName AS CustomerName,
		Parties.PartyNumber AS CustomerNumber,
		Contracts.SequenceNumber AS SequenceNumber,
		Contracts.ContractType AS ContractType,
		ReceivableTypes.Name AS  ReceivableType,
		Receivables.DueDate AS DueDate,
		Receivables.TotalAmount_Amount AS ReceivableAmount_Amount,
		Receivables.TotalEffectiveBalance_Amount AS EffectiveReceivableBalance_Amount,
		Receivables.TotalAmount_Currency AS Currency,
		LegalEntities.LegalEntitynumber AS LegalEntityNumber,
		ISNULL(RDWTD.EffectiveBalance_Amount, 0.00) AS WithHoldingTaxEffectiveBalance_Amount,
		ISNULL(tax.Amount_Amount, 0.00)  AS TaxAmount_Amount,
		ISNULL(tax.EffectiveBalance_Amount, 0.00) AS EffectiveTaxBalance_Amount,
		Receivables.ReceivableTaxType AS TaxType
	FROM #AppliedReceivables ValidAppliedReceivables
	JOIN Receivables ON ValidAppliedReceivables.ReceivableId = Receivables.Id AND Receivables.IsActive = 1
	JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	JOIN Parties ON Parties.Id = Receivables.CustomerId
	JOIN LegalEntities ON Receivables.LegalEntityId = LegalEntities.Id
	JOIN #AccesibleLegalEntity ON LegalEntities.Id = #AccesibleLegalEntity.LegalEntityId
	LEFT JOIN dbo.ReceivableTaxes tax ON Receivables.Id = tax.ReceivableId AND tax.IsActive=1
	LEFT JOIN ReceivableWithholdingTaxDetails RDWTD ON Receivables.Id = RDWTD.ReceivableId
	LEFT JOIN Contracts ON Contracts.Id = Receivables.EntityId AND Receivables.EntityType = ''CT''
	LEFT JOIN Funders ON Funders.Id = Receivables.FunderId
	LEFT JOIN Parties FunderParties ON FunderParties.Id = Funders.Id'

	DECLARE @WhereStatement Nvarchar(2000) =  '
  WHERE 
    ((Contracts.Id IS NULL OR Contracts.ContractType != ''Loan'' OR Contracts.IsNonAccrual = 0)
   OR (ReceivableTypes.Id != @LoanInterestReceivableTypeId AND ReceivableTypes.Id != @LoanPrincipalReceivableTypeId)
   OR (Receivables.IncomeType IN (''InterimInterest'',''TakeDownInterest'')))
   AND (@ImportedTaxType IS NULL OR Receivables.ReceivableTaxType = @ImportedTaxType)' +
   
	CASE WHEN @ReceivableIdsInWaivedFromReceivableAdjustmentReceipt IS NOT NULL  
		 THEN 'AND Receivables.Id NOT IN (SELECT ID FROM ConvertCSVToBigIntTable   (@ReceivableIdsInWaivedFromReceivableAdjustmentReceipt, '',''))' + ' ' ELSE '' END +
	CASE WHEN @FunderName IS NOT NULL THEN 'AND FunderParties.PartyName = @FunderName' + ' ' ELSE '' END +	
	CASE WHEN @CustomerName IS NOT NULL THEN 'AND Parties.PartyName LIKE @CustomerName' + ' ' ELSE '' END +
	CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND Parties.PartyNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
	CASE WHEN @ContractType IS NOT NULL THEN 'AND Contracts.ContractType = @ContractType' + ' ' ELSE '' END +
	CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND Contracts.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
	CASE WHEN @ReceivableType IS NOT NULL THEN 'AND ReceivableTypes.Name = @ReceivableType' + ' ' ELSE '' END +
	CASE WHEN @DueDate IS NOT NULL THEN 'AND Receivables.DueDate = @DueDate' + ' ' ELSE '' END +
	CASE WHEN @DueByDate IS NOT NULL THEN 'AND Receivables.DueDate <= @DueByDate' + ' ' ELSE '' END 

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
     ELSE @OrderColumn + ' ' + @OrderBy END


DECLARE @SelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + '
;With ReceivablesInfo AS ( ' 
	+ @ReceivablesSelectStatement
	+ @WhereStatement 
+ ')

INSERT INTO #ReceivableGroupSummary
SELECT 
	ROW_NUMBER() OVER (ORDER BY ' + @OrderStatement + '),
    ReceivableId,
    LegalEntityNumber,
    FunderName,
    CustomerName,
    CustomerNumber,
    SequenceNumber,
    ContractType,
    ReceivableType,
    DueDate,
    Currency,
    ReceivableAmount_Amount AS ReceivableAmount_Amount,
    EffectiveReceivableBalance_Amount AS EffectiveReceivableBalance_Amount,
    ISNULL(TaxAmount_Amount, 0.0) AS TaxAmount_Amount,
    Currency AS TaxCurrency,
    ISNULL(EffectiveTaxBalance_Amount, 0.0) AS EffectiveTaxBalance_Amount,
	WithHoldingTaxEffectiveBalance_Amount,
	TaxType

FROM ReceivablesInfo
WHERE ' + @ADVWHERECLAUSE +' (@MinOutstandingBalance IS NULL OR @MinOutstandingBalance >= EffectiveReceivableBalance_Amount + ISNULL(EffectiveTaxBalance_Amount, 0.0))'

EXEC sp_executesql @SelectQuery,
N'@ReceiptId BIGINT,
@ReceivableIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX),
@ReceivableIds ReceiptReceivableIdCollection READONLY,
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
@ImportedTaxType	 NVARCHAR(30)',
@ReceiptId,
@ReceivableIdsInWaivedFromReceivableAdjustmentReceipt,
@ReceivableIds,
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
@ImportedTaxType


SELECT Id = ReceivableId FROM #ReceivableGroupSummary

DECLARE @COUNT INT = (SELECT COUNT(*) FROM #ReceivableGroupSummary)

SELECT 
ReceivableId AS [Id], 
ReceivableId, 
LegalEntityNumber, 
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
TaxType,
@COUNT AS TotalReceivables
		
FROM #ReceivableGroupSummary WHERE RowNumber BETWEEN @StartingRowNumber AND @EndingRowNumber

DROP TABLE #TempReceivableId
DROP TABLE #AppliedReceivables
DROP TABLE #ReceivableGroupSummary
DROP TABLE #AccesibleLegalEntity
END

GO

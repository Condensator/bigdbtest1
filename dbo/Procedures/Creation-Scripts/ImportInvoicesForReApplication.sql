SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ImportInvoicesForReApplication]
	@ReceiptId			BIGINT,
	@InvoiceNumber		NVARCHAR(80),
	@CustomerName		NVARCHAR(500),
	@CustomerNumber		NVARCHAR(40),
	@LeaseSequenceNumber NVARCHAR(40),
	@InvoiceType		NVARCHAR(100),
	@DueDate			DATETIME,
	@ContractType		NVARCHAR(14),
	@InvoiceIds			InvoiceIdCollection READONLY,
	@StatementInvoiceIds InvoiceIdCollection READONLY,
	@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX),
	@StartingRowNumber	INT,
	@EndingRowNumber	INT,
	@ExistingReceivableCount INT,
	@OrderBy			NVARCHAR(6) = NULL,
	@OrderColumn		NVARCHAR(MAX) = NULL,
	@ADVWHERECLAUSE		NVARCHAR(2000) = '',
	@IsForSelectALL		BIT = 0,
	@InvoiceIdsToSelect InvoiceIdCollection READONLY,
	@DueByDate			DATETIME = NULL,
	@MinDaysPastDue		INT = NULL,
	@CurrentBusinessDate DATETIME,
	@MinOutstandingBalance DECIMAL(18,2) = NULL,
	@ImportedTaxType	   NVARCHAR(30) = NULL,
	@AccessibleLegalEntityIds AccessibleLegalEntityIdCollection READONLY
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

	DECLARE @WHERECLAUSE NVARCHAR(MAX);
	DECLARE @SELECTQUERY NVARCHAR(MAX);

	SET NOCOUNT ON;

	SELECT InvoiceId INTO #TempInvoiceId FROM @InvoiceIds

	SELECT InvoiceId AS StatementInvoiceId INTO #TempStatementInvoiceId FROM @StatementInvoiceIds

	SET @WHERECLAUSE = REPLACE(@ADVWHERECLAUSE,'"','')

	CREATE TABLE #ReceiptApplicationDetails(ReceivableInvoiceId BIGINT,ReceivableDetailId BIGINT);
	CREATE TABLE #ReceiptApplicationStatementDetails(ReceivableInvoiceId BIGINT);

	CREATE NONCLUSTERED INDEX IX_ReceiptApplicationDetails ON #ReceiptApplicationDetails(ReceivableInvoiceId,ReceivableDetailId);
	CREATE NONCLUSTERED INDEX IX_ReceiptApplicationStatementDetails ON #ReceiptApplicationStatementDetails(ReceivableInvoiceId);
	
	SELECT DISTINCT RA.Id, RAI.ReceivableInvoiceId 
	INTO #ReceiptApplicationIds
	FROM ReceiptApplications RA
	JOIN ReceiptApplicationInvoices RAI ON RA.ReceiptId = @ReceiptId AND RA.Id = RAI.ReceiptApplicationId AND RAI.IsActive=1

	;WITH CTE_AppliedReceivableDetails AS
	(
		SELECT RA.ReceivableInvoiceId AS ReceivableInvoiceId,
			RARD.ReceivableDetailId AS ReceivableDetailId,
			SUM(RARD.ReceivedAmount_Amount) AS AmountApplied,
			SUM(RARD.TaxApplied_Amount) AS TaxApplied
		FROM #ReceiptApplicationIds RA
		JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId 
			AND RA.ReceivableInvoiceId = RARD.ReceivableInvoiceId AND RARD.IsActive = 1
		LEFT JOIN #TempInvoiceId ON #TempInvoiceId.InvoiceId = RA.ReceivableInvoiceId
		WHERE #TempInvoiceId.InvoiceId IS NULL
		GROUP BY RA.ReceivableInvoiceId,RARD.ReceivableDetailId
	)
	INSERT INTO #ReceiptApplicationDetails
	SELECT ReceivableInvoiceId,ReceivableDetailId FROM CTE_AppliedReceivableDetails WHERE AmountApplied <> 0 OR TaxApplied <> 0

	INSERT INTO #ReceiptApplicationStatementDetails
	SELECT ReceiptApplicationStatementInvoices.StatementInvoiceId AS ReceivableInvoiceId
	FROM ReceiptApplications
	JOIN ReceiptApplicationStatementInvoices ON ReceiptApplications.Id = ReceiptApplicationStatementInvoices.ReceiptApplicationId AND ReceiptApplicationStatementInvoices.IsActive = 1
	JOIN ReceivableInvoiceStatementAssociations ON ReceiptApplicationStatementInvoices.StatementInvoiceId = ReceivableInvoiceStatementAssociations.StatementInvoiceId
	JOIN #ReceiptApplicationDetails ON #ReceiptApplicationDetails.ReceivableInvoiceId = ReceivableInvoiceStatementAssociations.ReceivableInvoiceId
	LEFT JOIN #TempStatementInvoiceId ON #TempStatementInvoiceId.StatementInvoiceId = ReceiptApplicationStatementInvoices.StatementInvoiceId
	WHERE ReceiptApplications.ReceiptId = @ReceiptId
	AND #TempStatementInvoiceId.StatementInvoiceId IS NULL
	GROUP BY ReceiptApplicationStatementInvoices.StatementInvoiceId

DECLARE
	@LoanInterestReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanInterest' ),
	@LoanPrincipalReceivableTypeId bigint = (SELECT TOP 1 Id FROM dbo.ReceivableTypes rt WHERE rt.Name = 'LoanPrincipal' )

CREATE TABLE #ValidDetailsToSelect
(
	ReceivableInvoiceId			BIGINT,
	InvoiceTypeId				BIGINT,
	ReceivableInvoiceDetailId	BIGINT,
	TaxType						NVARCHAR(30)
)


SELECT LegalEntityId INTO #AccesibleLegalEntity
FROM @AccessibleLegalEntityIds

DECLARE @ValidDetailsToSelectStatement NVARCHAr(2000) ='
	INSERT INTO #ValidDetailsToSelect
	SELECT 
		ReceivableInvoiceDetails.ReceivableInvoiceId,
		InvoiceTypes.Id AS InvoiceTypeId,
		ReceivableInvoiceDetails.Id AS ReceivableInvoiceDetailId,
		Receivables.ReceivableTaxType AS TaxType
	FROM #ReceiptApplicationDetails
	JOIN ReceivableInvoiceDetails ON #ReceiptApplicationDetails.ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId AND #ReceiptApplicationDetails.ReceivableDetailId = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
	JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsActive = 1 AND ReceivableInvoices.IsStatementInvoice = 0
	JOIN #AccesibleLegalEntity ON ReceivableInvoices.LegalEntityId = #AccesibleLegalEntity.LegalEntityId
	JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id	  
	JOIN ReceivableCategories ON ReceivableCategories.Id = ReceivableInvoiceDetails.ReceivableCategoryId
	LEFT JOIN InvoiceTypes ON InvoiceTypes.Id = ReceivableCategories.InvoiceTypeId
	LEFT JOIN Contracts ON Contracts.Id = ReceivableInvoiceDetails.EntityId AND ReceivableInvoiceDetails.EntityType = ''CT'''

DECLARE @WhereStatement NVARCHAR(1000) = ' 
	WHERE ((ReceivableInvoiceDetails.InvoiceAmount_Amount + ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) > 0
			OR (ReceivableInvoiceDetails.Balance_Amount + ReceivableInvoiceDetails.TaxBalance_Amount) > 0)
		AND ((Contracts.Id IS NULL OR Contracts.ContractType != ''Loan'' OR Contracts.IsNonAccrual = 0)
			OR (ReceivableInvoiceDetails.ReceivableTypeId != @LoanInterestReceivableTypeId AND ReceivableInvoiceDetails.ReceivableTypeId != @LoanPrincipalReceivableTypeId)
			OR (Receivables.IncomeType IN (''InterimInterest'',''TakeDownInterest'')))
			AND (@ImportedTaxType IS NULL OR @ImportedTaxType = ''''OR Receivables.ReceivableTaxType = @ImportedTaxType)' +

	CASE WHEN @InvoiceNumber IS NOT NULL THEN 'AND ReceivableInvoices.Number LIKE @InvoiceNumber' + ' ' ELSE '' END +
	CASE WHEN @ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt IS NOT NULL 
		 THEN 'AND ReceivableInvoiceDetails.ReceivableDetailId NOT IN (SELECT ID FROM ConvertCSVToBigIntTable(@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt, '',''))' + ' ' ELSE '' END +
	CASE WHEN @CustomerName IS NOT NULL THEN 'AND ReceivableInvoices.CustomerName LIKE @CustomerName' + ' ' ELSE '' END +
	CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND ReceivableInvoices.CustomerNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
	CASE WHEN @ContractType IS NOT NULL THEN 'AND Contracts.ContractType = @ContractType' + ' ' ELSE '' END +
	CASE WHEN @LeaseSequenceNumber IS NOT NULL THEN 'AND Contracts.SequenceNumber LIKE @LeaseSequenceNumber' + ' ' ELSE '' END +
	CASE WHEN @InvoiceType IS NOT NULL THEN 'AND InvoiceTypes.Name = @InvoiceType' + ' ' ELSE '' END +
	CASE WHEN @DueDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate = @DueDate' + ' ' ELSE '' END +
	CASE WHEN @DueByDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate <= @DueByDate' + ' ' ELSE '' END 

DECLARE @ValidDetailsToSelectQuery NVARCHAR(Max) = CAST('' AS NVARCHAR(MAX)) + 
	@ValidDetailsToSelectStatement + @WhereStatement + '
	GROUP BY ReceivableInvoiceDetails.ReceivableInvoiceId,
			InvoiceTypes.Id,
			ReceivableInvoiceDetails.Id,
			Receivables.ReceivableTaxType'

EXEC sp_executesql @ValidDetailsToSelectQuery ,
	N'@LoanInterestReceivableTypeId BIGINT
	,@LoanPrincipalReceivableTypeId BIGINT
	,@InvoiceNumber NVARCHAR(80)
	,@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt NVARCHAR(MAX)
	,@CustomerName NVARCHAR(500)
	,@CustomerNumber NVARCHAR(40)
	,@ContractType NVARCHAR(14)
	,@LeaseSequenceNumber NVARCHAR(40)
	,@InvoiceType NVARCHAR(100)
	,@DueDate DATETIME
	,@DueByDate DATETIME
	,@ImportedTaxType NVARCHAR(30)'
	,@LoanInterestReceivableTypeId
	,@LoanPrincipalReceivableTypeId
	,@InvoiceNumber
	,@ReceivableDetailIdsInWaivedFromReceivableAdjustmentReceipt
	,@CustomerName
	,@CustomerNumber
	,@ContractType
	,@LeaseSequenceNumber
	,@InvoiceType
	,@DueDate
	,@DueByDate
	,@ImportedTaxType

CREATE TABLE #ValidStatementDetailsForSelectALL  
(
	ReceivableInvoiceId BIGINT,
	TaxType				NVARCHAR(30)
)

DECLARE @ValidStatementDetailsToSelectStatement NVARCHAr(2000) ='
	INSERT INTO #ValidStatementDetailsForSelectALL  
	SELECT 
		ReceivableInvoices.Id AS ReceivableInvoiceId,
		Receivables.ReceivableTaxType AS TaxType
	FROM #ReceiptApplicationStatementDetails
	JOIN ReceivableInvoices ON #ReceiptApplicationStatementDetails.ReceivableInvoiceId = ReceivableInvoices.Id AND ReceivableInvoices.IsDummy = 0  
		AND ReceivableInvoices.IsActive = 1 AND ReceivableInvoices.IsStatementInvoice = 1 
	JOIN ReceivableInvoiceDetails ON ReceivableInvoices.Id = ReceivableInvoiceDetails.ReceivableInvoiceId
	JOIN Receivables ON ReceivableInvoiceDetails.ReceivableId = Receivables.Id
	JOIN #AccesibleLegalEntity ON ReceivableInvoices.LegalEntityId = #AccesibleLegalEntity.LegalEntityId
	LEFT JOIN #TempStatementInvoiceId AS TempStatementInvoiceId ON TempStatementInvoiceId.StatementInvoiceId = ReceivableInvoices.Id'

DECLARE @StetementInvoiceWhereClause NVARCHAR(1000) = ' 
	WHERE TempStatementInvoiceId.StatementInvoiceId IS NULL
		AND (ReceivableInvoices.InvoiceAmount_Amount + ReceivableInvoices.InvoiceTaxAmount_Amount) <> 0
		AND (@ImportedTaxType IS NULL OR @ImportedTaxType = ''''OR Receivables.ReceivableTaxType = @ImportedTaxType)' + 

	CASE WHEN @InvoiceNumber IS NOT NULL THEN 'AND ReceivableInvoices.Number LIKE @InvoiceNumber' + ' ' ELSE '' END +
	CASE WHEN @CustomerName IS NOT NULL THEN 'AND ReceivableInvoices.CustomerName LIKE @CustomerName' + ' ' ELSE '' END +
	CASE WHEN @CustomerNumber IS NOT NULL THEN 'AND ReceivableInvoices.CustomerNumber LIKE @CustomerNumber' + ' ' ELSE '' END +
	CASE WHEN @InvoiceType IS NOT NULL THEN 'AND ''Statement'' = @InvoiceType' + ' ' ELSE '' END +
	CASE WHEN @DueDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate = @DueDate' + ' ' ELSE '' END +
	CASE WHEN @DueByDate IS NOT NULL THEN 'AND ReceivableInvoices.DueDate <= @DueByDate' + ' ' ELSE '' END 
	--Why only contract null check

DECLARE @ValidStatementDetailsQuery NVARCHAR(MAX) = @ValidStatementDetailsToSelectStatement + @StetementInvoiceWhereClause

EXEC sp_executesql @ValidStatementDetailsQuery,
	N'@InvoiceNumber NVARCHAR(80)
	,@CustomerName NVARCHAR(500)
	,@CustomerNumber NVARCHAR(40)
	,@InvoiceType NVARCHAR(100)
	,@DueDate DATETIME
	,@DueByDate DATETIME
	,@ImportedTaxType NVARCHAR(30)'
	,@InvoiceNumber
	,@CustomerName
	,@CustomerNumber
	,@InvoiceType
	,@DueDate
	,@DueByDate
	,@ImportedTaxType

	SELECT
		VSD.ReceivableInvoiceId,
		SUM(RDWTH.EffectiveBalance_Amount) WithHoldingTaxEffectiveBalance_Amount
	INTO #InvoiceWithholdingTaxDetails
	FROM #ValidDetailsToSelect VSD
	JOIN ReceivableInvoiceDetails RID ON VSD.ReceivableInvoiceDetailId = RID.Id
	JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RID.ReceivableDetailId = RDWTH.ReceivableDetailId
	GROUP BY
		VSD.ReceivableInvoiceId

	SELECT
		VSD.ReceivableInvoiceId,
		SUM(RDWTH.EffectiveBalance_Amount) WithHoldingTaxEffectiveBalance_Amount
	INTO #ValidStatementWithholdingTaxDetails
	FROM #ValidStatementDetailsForSelectALL VSD
	JOIN ReceivableInvoiceDetails RID ON VSD.ReceivableInvoiceId = RID.ReceivableInvoiceId
	JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RID.ReceivableDetailId = RDWTH.ReceivableDetailId
	GROUP BY
		VSD.ReceivableInvoiceId

	DECLARE @COUNT INT = 0; 

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
		WithHoldingTaxEffectiveBalance DECIMAL(18,2),	
		LegalEntityNumber NVARCHAR(20),
		TaxType			  NVARCHAR(20)	
	);


	SET @SELECTQUERY = N'
	WITH CTE_InvoiceDetails
	AS
	(
		SELECT  
			#ValidDetailsToSelect.ReceivableInvoiceId AS ReceivableInvoiceId,
			ReceivableInvoices.IsStatementInvoice AS IsStatementInvoice,
			SUM(ReceivableInvoiceDetails.InvoiceAmount_Amount) AS OriginalBalance_Amount,
			SUM(ReceivableInvoiceDetails.EffectiveBalance_Amount) AS EffectiveBalance_Amount,
			SUM(ReceivableInvoiceDetails.InvoiceTaxAmount_Amount) AS OriginalTaxBalance_Amount,
			SUM(ReceivableInvoiceDetails.EffectiveTaxBalance_Amount) AS EffectiveTaxBalance_Amount,
			ReceivableInvoiceDetails.InvoiceAmount_Currency AS OriginalAmount_Currency,
			ReceivableInvoices.Number AS InvoiceNumber,
			InvoiceTypes.Name AS InvoiceType,
			ReceivableInvoices.DueDate AS DueDate,
			ReceivableInvoices.CustomerNumber  AS CustomerNumber, 
			ReceivableInvoices.CustomerName  AS CustomerName,
			ISNULL(VSWTD.WithHoldingTaxEffectiveBalance_Amount, 0.00) AS WithHoldingTaxEffectiveBalance_Amount,
			ReceivableInvoices.LegalEntityNumber AS LegalEntityNumber,
			#ValidDetailsToSelect.TaxType
		FROM #ValidDetailsToSelect
		JOIN ReceivableInvoices ON ReceivableInvoices.Id = #ValidDetailsToSelect.ReceivableInvoiceId
		JOIN #AccesibleLegalEntity ON ReceivableInvoices.LegalEntityId = #AccesibleLegalEntity.LegalEntityId
		JOIN InvoiceTypes ON InvoiceTypes.Id = #ValidDetailsToSelect.InvoicetypeId
		JOIN ReceivableInvoiceDetails ON #ValidDetailsToSelect.ReceivableInvoiceDetailId = ReceivableInvoiceDetails.Id
		LEFT JOIN #InvoiceWithholdingTaxDetails VSWTD ON #ValidDetailsToSelect.ReceivableInvoiceId = VSWTD.ReceivableInvoiceId
		GROUP BY #ValidDetailsToSelect.ReceivableInvoiceId
			,ReceivableInvoices.IsStatementInvoice
			,ReceivableInvoiceDetails.InvoiceAmount_Currency
			,ReceivableInvoices.Number
			,InvoiceTypes.Name
			,ReceivableInvoices.DueDate
			,ReceivableInvoices.CustomerNumber
			,ReceivableInvoices.CustomerName
			,VSWTD.WithHoldingTaxEffectiveBalance_Amount
			,ReceivableInvoices.LegalEntityNumber
			,#ValidDetailsToSelect.TaxType
	UNION ALL			
		SELECT  
			ReceivableInvoices.Id AS ReceivableInvoiceId,
			ReceivableInvoices.IsStatementInvoice AS IsStatementInvoice,
			ReceivableInvoices.InvoiceAmount_Amount AS OriginalBalance_Amount,
			ReceivableInvoices.EffectiveBalance_Amount AS EffectiveBalance_Amount,
			ReceivableInvoices.InvoiceTaxAmount_Amount AS OriginalTaxBalance_Amount,
			ReceivableInvoices.EffectiveTaxBalance_Amount AS EffectiveTaxBalance_Amount,
			ReceivableInvoices.InvoiceAmount_Currency AS OriginalAmount_Currency,
			ReceivableInvoices.Number AS InvoiceNumber,
			''Statement'' AS InvoiceType,
			ReceivableInvoices.DueDate AS DueDate,
			ReceivableInvoices.CustomerNumber  AS CustomerNumber, 
			ReceivableInvoices.CustomerName  AS CustomerName,
			ISNULL(VSWTD.WithHoldingTaxEffectiveBalance_Amount, 0.00) AS WithHoldingTaxEffectiveBalance_Amount,
			ReceivableInvoices.LegalEntityNumber AS LegalEntityNumber,
			#ValidStatementDetailsForSelectALL.TaxType
		FROM #ValidStatementDetailsForSelectALL
		JOIN ReceivableInvoices ON ReceivableInvoices.Id = #ValidStatementDetailsForSelectALL.ReceivableInvoiceId
		JOIN #AccesibleLegalEntity ON ReceivableInvoices.LegalEntityId = #AccesibleLegalEntity.LegalEntityId
		LEFT JOIN #ValidStatementWithholdingTaxDetails VSWTD ON #ValidStatementDetailsForSelectALL.ReceivableInvoiceId = VSWTD.ReceivableInvoiceId
		)'


	SET @SELECTQUERY =@SELECTQUERY+ 'INSERT INTO #InvoiceSummary 
	SELECT 
		ReceivableInvoiceId AS InvoiceId,
		IsStatementInvoice AS IsStatementInvoice,
		SUM(OriginalBalance_Amount)    AS InvoiceAmount,
		SUM(EffectiveBalance_Amount)   AS EffectiveInvoiceBalance,
		SUM(OriginalTaxBalance_Amount)   AS InvoiceTaxAmount,
		SUM(EffectiveTaxBalance_Amount) AS EffectiveTaxBalance,
		OriginalAmount_Currency AS Currency,
		InvoiceNumber AS InvoiceNumber,
		InvoiceType AS InvoiceType,
		DueDate AS DueDate,
		CustomerNumber AS CustomerNumber, 
		CustomerName AS CustomerName, 
		SUM(WithHoldingTaxEffectiveBalance_Amount) AS WithHoldingTaxEffectiveBalance,
		LegalEntityNumber AS LegalEntityNumber,
		TaxType
	FROM CTE_InvoiceDetails 
	WHERE' + @WHERECLAUSE +' 1 = 1
	GROUP BY
		ReceivableInvoiceId,
		IsStatementInvoice, 
		OriginalAmount_Currency,
		InvoiceNumber,
		InvoiceType,
		DueDate,
		CustomerNumber,
		CustomerName,
		LegalEntityNumber,
		TaxType
	HAVING (@MinOutstandingBalance IS NULL OR @MinOutstandingBalance <= (SUM(EffectiveBalance_Amount) + SUM(EffectiveTaxBalance_Amount)))
	ORDER BY ReceivableInvoiceId'

	EXEC sp_executesql @SELECTQUERY , N'@MinOutstandingBalance DECIMAL(18,2)', @MinOutstandingBalance	

	SELECT @COUNT = COUNT(*)
	FROM #InvoiceSummary;

	SELECT InvoiceId AS 'Id'
	FROM #InvoiceSummary;

	IF(dbo.IsStringNullOrEmpty(@OrderBy) = 1) SET @OrderBy = 'ASC'
	IF(dbo.IsStringNullOrEmpty(@OrderColumn) = 1) SET @OrderColumn = 'InvoiceNumber'

	;WITH CTE_ReceivableList AS (
	SELECT	
		ROW_NUMBER() OVER (ORDER BY
		CASE WHEN @OrderBy = 'ASC' AND @OrderColumn='InvoiceNumber' THEN CAST(InvoiceNumber AS NVARCHAR) END ASC,
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
		CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='InvoiceNumber' THEN CAST(InvoiceNumber AS BIGINT) END DESC,
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
		CASE WHEN @OrderBy = 'DESC' AND @OrderColumn='DueDate' THEN DueDate END DESC
		) AS RowNumber,* 
	FROM #InvoiceSummary 	
	)
	SELECT	InvoiceId AS 'Id',
			InvoiceNumber,
			IsStatementInvoice,
			LegalEntityNumber,
			CustomerName,
			CustomerNumber,
			InvoiceType,
			DueDate,
			InvoiceAmount AS OriginalBalance_Amount,
			Currency AS OriginalBalance_Currency,
			EffectiveInvoiceBalance AS EffectiveBalance_Amount,
			Currency AS EffectiveBalance_Currency,
			InvoiceTaxAmount AS OriginalTaxBalance_Amount,
			Currency AS OriginalTaxBalance_Currency,
			EffectiveTaxBalance AS EffectiveTaxBalance_Amount,
			Currency AS EffectiveTaxBalance_Currency,
			WithHoldingTaxEffectiveBalance AS WithHoldingTaxEffectiveBalance_Amount,
			Currency AS WithHoldingTaxEffectiveBalance_Currency,
			TaxType,
			@COUNT AS TotalInvoices
	FROM CTE_ReceivableList 
	WHERE RowNumber BETWEEN @StartingRowNumber AND @EndingRowNumber
	ORDER BY RowNumber

	DROP TABLE #InvoiceSummary;
	DROP TABLE #ValidDetailsToSelect;
	DROP TABLE #TempInvoiceId;
	DROP TABLE #TempStatementInvoiceId
	DROP TABLE #ReceiptApplicationDetails
	DROP TABLE #ReceiptApplicationStatementDetails
	DROP TABLE #ValidStatementDetailsForSelectALL
	DROP TABLE #InvoiceWithholdingTaxDetails
	DROP TABLE #ValidStatementWithholdingTaxDetails
	DROP TABLE #ReceiptApplicationIds
	DROP TABLE #AccesibleLegalEntity	
	SET NOCOUNT OFF;
END

GO

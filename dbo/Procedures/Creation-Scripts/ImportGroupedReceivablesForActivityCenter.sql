SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ImportGroupedReceivablesForActivityCenter] 
	@ReceiptId   BIGINT,
	@CurrencyISO NVARCHAR(6),
	@FilterCustomerId BIGINT      = NULL,
	@FilterContractId BIGINT      = NULL
AS
BEGIN
	DECLARE @COUNT INT;
	DECLARE @WHERECLAUSE NVARCHAR(MAX);
	DECLARE @SELECTQUERY NVARCHAR(MAX);
	SET @COUNT = 0;
	SET NOCOUNT ON;
	CREATE TABLE #ValidReceivables
	(
		ReceivableId   BIGINT NOT NULL,
		FunderName     NVARCHAR(250),
		CustomerName   NVARCHAR(250),
		CustomerNumber NVARCHAR(40),
		SequenceNumber NVARCHAR(40),
		ContractType   NVARCHAR(14),
		ReceivableType NVARCHAR(30),
		DueDate        DATE,
		IsNonCash	   BIT
	);
	CREATE TABLE #ValidReceivableDetails
	(
		ReceivableDetailId       BIGINT NOT NULL,
		ReceivableId             BIGINT NOT NULL,
		InvoiceNumber            NVARCHAR(40) NULL,
		ReceivableAmount_Amount  DECIMAL(18, 2) NOT NULL,
		ReceivableBalance_Amount DECIMAL(18, 2) NOT NULL,
		EffectiveBalance_Amount  DECIMAL(18, 2) NOT NULL,
		WithholdingTaxBalance_Amount	DECIMAL(18, 2) NOT NULL,
		Currency                 NVARCHAR(3)
	);
	CREATE TABLE #ReceivableTaxAmount
	(
		ReceivableId        BIGINT NOT NULL,
		ReceivableDetailId  BIGINT NOT NULL,
		TotalTaxAmount      DECIMAL(18, 2) NOT NULL,
		TotalTaxBalance     DECIMAL(18, 2) NOT NULL,
		EffectiveTaxBalance DECIMAL(18, 2) NOT NULL,
		Currency            NVARCHAR(3)
	);
	CREATE TABLE #ReceivableDetailSummary
	(
		ReceivableId                        BIGINT NOT NULL,
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
		ReceivableBalance_Amount            DECIMAL(18, 2) NOT NULL,
		ReceivableBalance_Currency          NVARCHAR(3),
		EffectiveReceivableBalance_Amount   DECIMAL(18, 2) NOT NULL,
		EffectiveReceivableBalance_Currency NVARCHAR(3),
		EffectiveTaxBalance_Amount          DECIMAL(18, 2) NOT NULL,
		EffectiveTaxBalance_Currency        NVARCHAR(3),
		TaxAmount_Amount                    DECIMAL(18, 2) NOT NULL,
		TaxAmount_Currency                  NVARCHAR(3),
		TaxBalance_Amount                   DECIMAL(18, 2) NOT NULL,
		TaxBalance_Currency                 NVARCHAR(3),
		InvoiceNumber                       NVARCHAR(40),
		WithholdingTaxBalance_Amount		DECIMAL(18, 2) NOT NULL,
		WithholdingTaxBalance_Currency		NVARCHAR(3),
		IsNonCash							BIT
	);
	CREATE TABLE #ReceivableGroupSummary
	(
		SequenceNumber                      NVARCHAR(40),
		ContractType                        NVARCHAR(14),
		ReceivableType                      NVARCHAR(30),
		InvoiceNumber                       NVARCHAR(40),
		DueDate                             DATETIME,
		ReceivableAmount_Amount             DECIMAL(18, 2) NOT NULL,
		ReceivableAmount_Currency           NVARCHAR(3),
		EffectiveReceivableBalance_Amount   DECIMAL(18, 2) NOT NULL,
		EffectiveReceivableBalance_Currency NVARCHAR(3),
		ReceivableBalance_Amount            DECIMAL(18, 2) NOT NULL,
		ReceivableBalance_Currency          NVARCHAR(3),
		TaxAmount_Amount                    DECIMAL(18, 2) NOT NULL,
		TaxAmount_Currency                  NVARCHAR(3),
		EffectiveTaxBalance_Amount          DECIMAL(18, 2) NOT NULL,
		EffectiveTaxBalance_Currency        NVARCHAR(3),
		TaxBalance_Amount                   DECIMAL(18, 2) NOT NULL,
		TaxBalance_Currency                 NVARCHAR(3),
		CustomerName                        NVARCHAR(250),
		CustomerNumber                      NVARCHAR(40),
		AmountApplied_Amount                DECIMAL(18, 2) NOT NULL,
		AmountApplied_Currency              NVARCHAR(3),
		TaxApplied_Amount                   DECIMAL(18, 2) NOT NULL,
		TaxApplied_Currency                 NVARCHAR(3),
		AdjustedWithholdingTax_Amount		DECIMAL(18, 2) NOT NULL,
		AdjustedWithholdingTax_Currency		NVARCHAR(3),
		WithholdingTaxBalance_Amount		DECIMAL(18, 2) NOT NULL,
		WithholdingTaxBalance_Currency		NVARCHAR(3),
		IsNonCash							BIT
	);

	SELECT 
		Receivables.Id,
		CASE WHEN Receipts.ReceiptClassification = 'NonCash' OR Receipts.ReceiptClassification =  'NonAccrualNonDSLNonCash' THEN 1 ELSE 0  END IsNonCash
	INTO #ReceiptRelatedReceivableIds
	FROM Receivables
	INNER JOIN ReceivableDetails ON ReceivableId = Receivables.Id
	INNER JOIN ReceiptApplicationReceivableDetails ON ReceivableDetails.Id = ReceivableDetailId
	INNER JOIN ReceiptApplications ON ReceiptApplicationReceivableDetails.ReceiptApplicationId = ReceiptApplications.Id
	INNER JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
	WHERE ReceiptApplications.ReceiptId = @ReceiptId
	AND Receivables.IsActive = 1
	AND ReceivableDetails.IsActive = 1
	AND ReceiptApplicationReceivableDetails.IsActive = 1
	AND (@FilterCustomerId IS NULL
	OR Receivables.CustomerId = @FilterCustomerId)
	AND (@FilterContractId IS NULL
	OR (Receivables.EntityId = @FilterContractId AND Receivables.EntityType='CT'));

	INSERT INTO #ValidReceivables
	SELECT DISTINCT
		Receivables.Id AS ReceivableId,
		FunderParties.PartyName AS FunderName,
		Parties.PartyName AS CustomerName,
		Parties.PartyNumber AS CustomerNumber,
		Contracts.SequenceNumber AS SequenceNumber,
		Contracts.ContractType AS ContractType,
		ReceivableTypes.Name AS ReceivableType,
		Receivables.DueDate AS DueDate,
		#ReceiptRelatedReceivableIds.IsNonCash
	FROM Receivables
	INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id
	INNER JOIN Parties ON Parties.Id = Receivables.CustomerId
	INNER JOIN #ReceiptRelatedReceivableIds ON #ReceiptRelatedReceivableIds.Id = Receivables.Id
	LEFT JOIN Contracts ON Contracts.Id = Receivables.EntityId
	AND Receivables.EntityType = 'CT'
	LEFT JOIN Funders ON Funders.Id = Receivables.FunderId
	LEFT JOIN Parties FunderParties ON FunderParties.Id = Funders.Id
	WHERE Receivables.IsActive = 1
	;

	INSERT INTO #ValidReceivableDetails
	SELECT DISTINCT
		ReceivableDetails.Id AS ReceivableDetailId,
		ReceivableDetails.ReceivableId AS ReceivableId,
		ReceivableInvoices.Number AS InvoiceNumber,
		ISNULL(ReceivableDetails.Amount_Amount, 0.0) AS ReceivableAmount_Amount,
		ISNULL(ReceivableDetails.Balance_Amount, 0.0) AS ReceivableBalance_Amount,
		ISNULL(ReceivableDetails.EffectiveBalance_Amount, 0.0) AS EffectiveBalance_Amount,
		ISNULL(RWHT.EffectiveBalance_Amount, 0.0) WithholdingTaxBalance_Amount,
		ReceivableDetails.EffectiveBalance_Currency AS Currency
	FROM ReceiptApplicationReceivableDetails
	INNER JOIN ReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = ReceivableDetails.Id
	INNER JOIN #ValidReceivables ON ReceivableDetails.ReceivableId = #ValidReceivables.ReceivableId
	LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId
	AND ReceivableInvoiceDetails.IsActive = 1
	LEFT JOIN ReceivableInvoices ON ReceivableInvoiceDetails.ReceivableInvoiceId = ReceivableInvoices.Id
	AND ReceivableInvoices.IsActive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RWHT ON ReceivableDetails.Id = RWHT.ReceivableDetailId
	AND RWHT.IsActive = 1
	WHERE ReceivableDetails.IsActive = 1;

	INSERT INTO #ReceivableTaxAmount
	SELECT ReceivableTax.ReceivableId,
		ReceivableTaxDetail.ReceivableDetailId AS ReceivableDetailId,
		SUM(ReceivableTaxDetail.Amount_Amount) AS TaxAmount,
		SUM(ReceivableTaxDetail.Balance_Amount) AS TaxBalance,
		SUM(ReceivableTaxDetail.EffectiveBalance_Amount) AS EffectiveTaxBalance,
		ReceivableTaxDetail.Amount_Currency AS Currency
	FROM #ValidReceivables
	JOIN ReceivableTaxes AS ReceivableTax ON ReceivableTax.ReceivableId = #ValidReceivables.ReceivableId
	JOIN ReceivableTaxDetails AS ReceivableTaxDetail ON ReceivableTaxDetail.ReceivableTaxId = ReceivableTax.Id
	AND ReceivableTaxDetail.IsActive = 1
	WHERE ReceivableTaxDetail.Amount_Currency = @CurrencyISO
	GROUP BY ReceivableTaxDetail.ReceivableDetailId,
	ReceivableTax.ReceivableId,
	ReceivableTaxDetail.Amount_Currency;

	SELECT 
		ISNULL(#ValidReceivableDetails.ReceivableDetailId, #ReceivableTaxAmount.ReceivableDetailId) AS ReceivableDetailId,
		ISNULL(#ValidReceivableDetails.ReceivableId, #ReceivableTaxAmount.ReceivableId) AS ReceivableId,
		ISNULL(#ValidReceivableDetails.ReceivableAmount_Amount, 0.0) AS ReceivableAmount,
		ISNULL(#ValidReceivableDetails.EffectiveBalance_Amount, 0.0) AS EffectiveBalance,
		ISNULL(#ReceivableTaxAmount.EffectiveTaxBalance, 0.0) AS EffectiveTaxBalance,
		ISNULL(#ValidReceivableDetails.ReceivableBalance_Amount, 0.0) AS ReceivableBalance,
		ISNULL(#ValidReceivableDetails.Currency, #ReceivableTaxAmount.Currency) AS Currency,
		ISNULL(#ReceivableTaxAmount.TotalTaxAmount, 0.0) AS TaxAmount,
		ISNULL(#ReceivableTaxAmount.TotalTaxBalance, 0.0) AS TaxBalance,
		ISNULL(#ValidReceivableDetails.InvoiceNumber, 'Dummy') AS InvoiceNumber,
		ISNULL(#ValidReceivableDetails.WithholdingTaxBalance_Amount, 0.0) WithholdingTaxBalance_Amount
	INTO #ReceivableDetailAmountSummary
	FROM #ValidReceivableDetails
	FULL OUTER JOIN #ReceivableTaxAmount ON #ValidReceivableDetails.ReceivableDetailId = #ReceivableTaxAmount.ReceivableDetailId;

	INSERT INTO #ReceivableDetailSummary
	SELECT #ValidReceivables.ReceivableId AS ReceivableId,
		#ValidReceivables.FunderName AS FunderName,
		#ValidReceivables.CustomerName AS CustomerName,
		#ValidReceivables.CustomerNumber AS CustomerNumber,
		ISNULL(#ValidReceivables.SequenceNumber, 'Dummy') AS SequenceNumber,
		ISNULL(#ValidReceivables.ContractType, 'Dummy') AS ContractType,
		#ValidReceivables.ReceivableType AS ReceivableType,
		#ValidReceivables.DueDate AS DueDate,
		#ReceivableDetailAmountSummary.ReceivableDetailId AS ReceivableDetailId,
		#ReceivableDetailAmountSummary.ReceivableAmount AS ReceivableAmount_Amount,
		#ReceivableDetailAmountSummary.Currency AS ReceivableAmount_Currency,
		#ReceivableDetailAmountSummary.ReceivableBalance AS ReceivableBalance_Amount,
		#ReceivableDetailAmountSummary.Currency AS ReceivableBalance_Currency,
		#ReceivableDetailAmountSummary.EffectiveBalance AS EffectiveReceivableBalance_Amount,
		#ReceivableDetailAmountSummary.Currency AS EffectiveReceivableBalance_Currency,
		#ReceivableDetailAmountSummary.EffectiveTaxBalance AS EffectiveTaxBalance_Amount,
		#ReceivableDetailAmountSummary.Currency AS EffectiveTaxBalance_Currency,
		#ReceivableDetailAmountSummary.TaxAmount AS TaxAmount_Amount,
		#ReceivableDetailAmountSummary.Currency AS TaxAmount_Currency,
		#ReceivableDetailAmountSummary.TaxBalance AS TaxBalance_Amount,
		#ReceivableDetailAmountSummary.Currency AS TaxBalance_Currency,
		ISNULL(#ReceivableDetailAmountSummary.InvoiceNumber, 'Dummy') AS InvoiceNumber,
		#ReceivableDetailAmountSummary.WithholdingTaxBalance_Amount,
		#ReceivableDetailAmountSummary.Currency AS WithholdingTaxBalance_Currency,
		#ValidReceivables.IsNonCash
	FROM #ValidReceivables
	JOIN #ReceivableDetailAmountSummary ON #ValidReceivables.ReceivableId = #ReceivableDetailAmountSummary.ReceivableId
	;

	SELECT
		RDS.ReceivableDetailId,
		SUM(RARD.ReceivedAmount_Amount) AS AmountApplied_Amount,
		SUM(RARD.TaxApplied_Amount ) AS TaxApplied_Amount,
		SUM(RARD.AdjustedWithholdingTax_Amount) AS AdjustedWithholdingTax_Amount
	INTO #ReceiptApplicationDetail
	FROM #ReceivableDetailSummary RDS
	INNER JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceivableDetailId = RDS.ReceivableDetailId AND RARD.IsActive=1
	INNER JOIN ReceiptApplications RA ON RA.Id = RARD.ReceiptApplicationId
	WHERE RA.ReceiptId = @ReceiptId
	GROUP BY RDS.ReceivableDetailId;

	SELECT CASE
		WHEN SequenceNumber = 'Dummy'
		THEN NULL
		ELSE SequenceNumber
		END AS SequenceNumber,
		CASE
		WHEN ContractType = 'Dummy'
		THEN NULL
		ELSE ContractType
		END AS ContractType,
		ReceivableType,
		CASE
		WHEN InvoiceNumber = 'Dummy'
		THEN NULL
		ELSE InvoiceNumber
		END AS InvoiceNumber,
		DueDate,
		SUM(ReceivableAmount_Amount) AS ReceivableAmount_Amount,
		@CurrencyISO AS ReceivableAmount_Currency,
		SUM(EffectiveReceivableBalance_Amount) AS EffectiveReceivableBalance_Amount,
		@CurrencyISO AS EffectiveReceivableBalance_Currency,
		SUM(ReceivableBalance_Amount) AS ReceivableBalance_Amount,
		@CurrencyISO AS ReceivableBalance_Currency,
		SUM(TaxAmount_Amount) AS TaxAmount_Amount,
		@CurrencyISO AS TaxAmount_Currency,
		SUM(EffectiveTaxBalance_Amount) AS EffectiveTaxBalance_Amount,
		@CurrencyISO AS EffectiveTaxBalance_Currency,
		SUM(TaxBalance_Amount) AS TaxBalance_Amount,
		@CurrencyISO AS TaxBalance_Currency,
		RDS.CustomerName,
		RDS.CustomerNumber,
		SUM(AmountApplied_Amount) AS AmountApplied_Amount,
		@CurrencyISO AS AmountApplied_Currency,
		SUM(TaxApplied_Amount) AS TaxApplied_Amount,
		@CurrencyISO AS TaxApplied_Currency,
		SUM(AdjustedWithholdingTax_Amount) AdjustedWithholdingTax_Amount,
		@CurrencyISO AS AdjustedWithholdingTax_Currency,
		SUM(WithholdingTaxBalance_Amount) WithholdingTaxBalance_Amount, 
		@CurrencyISO AS WithholdingTaxBalance_Currency,
		IsNonCash
	INTO #GroupedReceivableSummary
	FROM #ReceivableDetailSummary RDS
	INNER JOIN #ReceiptApplicationDetail RARD ON RDS.ReceivableDetailId = RARD.ReceivableDetailId
	GROUP BY DueDate,
	ReceivableType,
	ContractType,
	SequenceNumber,
	InvoiceNumber,
	CustomerName,
	CustomerNumber,
	IsNonCash,
	SIGN(AmountApplied_Amount + TaxApplied_Amount);
	SET @SELECTQUERY = 'INSERT INTO #ReceivableGroupSummary
	SELECT * FROM #GroupedReceivableSummary';
	EXEC (@SELECTQUERY);

	WITH CTE_ReceivableList
	AS (
		SELECT * FROM #ReceivableGroupSummary
	)
	SELECT SequenceNumber,
		ContractType,
		ReceivableType,
		InvoiceNumber,
		DueDate,
		ReceivableAmount_Amount,
		ReceivableAmount_Currency,
		EffectiveReceivableBalance_Amount,
		EffectiveReceivableBalance_Currency,
		ReceivableBalance_Amount,
		ReceivableBalance_Currency,
		TaxAmount_Amount,
		TaxAmount_Currency,
		EffectiveTaxBalance_Amount,
		EffectiveTaxBalance_Currency,
		TaxBalance_Amount,
		TaxBalance_Currency,
		CustomerName,
		CustomerNumber,
		AmountApplied_Amount,
		AmountApplied_Currency,
		TaxApplied_Amount,
		TaxApplied_Currency,
		CASE WHEN IsNonCash = 1 THEN 
			 AmountApplied_Amount + TaxApplied_Amount
		ELSE 
			AmountApplied_Amount + TaxApplied_Amount + AdjustedWithholdingTax_Amount 
		END AS TotalAmountApplied_Amount,
		TaxApplied_Currency AS TotalAmountApplied_Currency,
		AdjustedWithholdingTax_Amount AS AdjustedWithHoldingTax_Amount,
		AdjustedWithholdingTax_Currency AS AdjustedWithHoldingTax_Currency,
		WithholdingTaxBalance_Amount,
		WithholdingTaxBalance_Currency
	FROM CTE_ReceivableList
	WHERE AmountApplied_Amount + TaxApplied_Amount <> 0;
	DROP TABLE #ValidReceivables;
	DROP TABLE #ValidReceivableDetails;
	DROP TABLE #ReceivableTaxAmount;
	DROP TABLE #ReceivableDetailAmountSummary;
	DROP TABLE #ReceivableDetailSummary;
	DROP TABLE #GroupedReceivableSummary;
	DROP TABLE #ReceivableGroupSummary;
	DROP TABLE #ReceiptRelatedReceivableIds;
END;

GO

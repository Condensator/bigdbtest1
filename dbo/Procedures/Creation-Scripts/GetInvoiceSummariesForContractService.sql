SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoiceSummariesForContractService]
(
	@ContractSequenceNumber NVARCHAR(80),
	@FilterCustomerId       BIGINT = NULL,
	@Error                  NVARCHAR(10),
	@AccessibleLegalEntities NVARCHAR(MAX),
	@CurrentBusinessDate DATETIME
)
AS

BEGIN

	--DECLARE
	--@ContractSequenceNumber NVARCHAR(80) = '7180-8',
	--@FilterCustomerId       BIGINT = NULL,
	--@Error                  NVARCHAR(10) = 'Error',
	--@AccessibleLegalEntities NVARCHAR(MAX) =N'1,2,5,7,11,13,19,20,22,48,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114',
	--@CurrentBusinessDate DATETIME = GetDate()

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET NOCOUNT ON

	SELECT * INTO #AccessibleLegalEntityIds FROM ConvertCSVToBigIntTable(@AccessibleLegalEntities, ',');

	DECLARE @ContractId BIGINT;
	SELECT @ContractId = Id  FROM Contracts  WHERE SequenceNumber = @ContractSequenceNumber;

	/* even inactive receivableInvoiceDetails ? */
	SELECT
		RD.ReceivableInvoiceId,
		IsBelongsToStatementInvoice = 1
	INTO #StatementDetails
	FROM
		ReceivableInvoiceDetails RD
	JOIN ReceivableInvoiceStatementAssociations SI ON
		RD.ReceivableInvoiceId = SI.ReceivableInvoiceId
	WHERE RD.EntityId = @ContractId AND RD.EntityType ='CT'
	AND RD.IsActive = 1 /* active */

	 SELECT
		RD.Id, R.CustomerId
	 INTO #RDetails
	 FROM ReceivableDetails RD
	 INNER JOIN Receivables R
	  ON RD.ReceivableId = R.Id
	  AND R.IsActive = 1
	  AND R.EntityId = @ContractID
	  AND R.EntityType = 'CT'
	  AND RD.IsActive=1
	 Where (@FilterCustomerId IS NULL OR R.CustomerId = @FilterCustomerId)
	 AND (R.CreationSourceTable IS NULL OR (R.CreationSourceTable IS NOT NULL AND R.CreationSourceTable <> 'ReceivableForTransfer'));

	SELECT
		RD.Id ReceivableDetailId,
		RD.Amount_Amount,
		RD.Balance_Amount,
		SUM(RTD.Amount_Amount) OriginalTaxAmount,
		SUM(RTD.Balance_Amount) OriginalTaxBalance
	Into #ReceivableTaxDetails
	FROM
		ReceivableDetails RD
	INNER JOIN #RDetails R
		ON RD.Id = R.Id
	INNER JOIN REceivableTaxDetails RTD
		ON Rd.Id = RTD.ReceivableDetailId
		AND RTD.IsActive=1
	GROUP BY RD.Id,
		RD.Amount_Amount,
		RD.Balance_Amount

	SELECT
		SUM(RT.Amount_Amount + ISNULL(RT.OriginalTaxAmount,0.00)) - SUM(RT.Balance_Amount + ISNULL(RT.OriginalTaxBalance,0.00)) AS AmountReceived,
		SUM(RID.InvoiceAmount_Amount) AS ChargeAmount,
		SUM(RID.InvoiceTaxAmount_Amount) AS TaxAmount,
		SUM(RT.Amount_Amount) AS OriginalAmount,
		ISNULL(SUM(RT.OriginalTaxAmount), 0.00) AS OriginalTaxAmount,
		SUM(RID.Balance_Amount + RID.TaxBalance_Amount) AS OutstandingBalance,
		CASE
		WHEN SUM(RID.Balance_Amount + RID.TaxBalance_Amount) = 0
		THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
		END AS IsPaid,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 30
		AND DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 0
		THEN SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ZeroToThirtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 60
		AND DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 30
		THEN SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ThirtyOneToSixtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 90
		AND DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 60
		THEN SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount)
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS SixtyOneToNinetyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <= 120
		AND DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 90
		THEN SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount)
		ELSE 0
		END AS NinetyOneToOneHundredTwentyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LI.ThresholdDays,RI.DueDate),@CurrentBusinessDate) > 120
		THEN SUM(RID.EffectiveBalance_Amount + RID.EffectiveTaxBalance_Amount)
		ELSE 0
		END AS OneHundredTwentyPlusDaysAndAbove,
		RI.Id AS ReceivableInvoiceId, RC.InvoiceTypeId
		into #CTE_ReceivableInvoices
		FROM
			ReceivableInvoices RI
		INNER JOIN #AccessibleLegalEntityIds ALE ON
			RI.LegalEntityId= ALE.Id
		INNER JOIN ReceivableInvoiceDetails RID
		ON RI.ID = RID.ReceivableInvoiceID
			AND RID.EntityType = 'CT' AND RID.EntityId = @ContractID
			AND RI.IsDummy = 0
			AND RI.IsActive=1
			AND RID.IsActive=1
			AND RI.CancellationDate IS NULL
		INNER JOIN #RDetails RD ON RD.ID = RID.ReceivableDetailId
		INNER JOIN ReceivableCategories AS RC
			ON RID.ReceivableCategoryId = RC.Id
			AND RC.Name != 'AssetSale'
		INNER JOIN LegalEntities LI ON
			ALE.ID= LI.Id
		LEFT JOIN #ReceivableTaxDetails RT ON
			RId.ReceivableDetailID = RT.ReceivableDetailId
		WHERE
			RI.IsStatementInvoice = 0
			AND (@FilterCustomerId IS NULL OR RI.CustomerId = @FilterCustomerId)
		GROUP BY RI.Id, RI.DueDate,LI.ThresholdDays,RC.InvoiceTypeId

		SELECT
		SUM(RARD.AmountApplied_Amount + RARD.TaxApplied_Amount) AS AmountWaived, RI.ReceivableInvoiceId ReceivableInvoiceId
		into #cte_receiptDetails
		FROM
			#CTE_ReceivableInvoices AS RI
		INNER JOIN ReceiptApplicationReceivableDetails AS RARD
			ON RARD.ReceivableInvoiceId = RI.ReceivableInvoiceId
		INNER JOIN #RDetails RD ON RD.ID = RARD.ReceivableDetailId
		INNER JOIN ReceiptApplications
		ON ReceiptApplications.Id = RARD.ReceiptApplicationId
		INNER JOIN Receipts
		ON Receipts.id = ReceiptApplications.ReceiptId
		INNER JOIN ReceiptTypes ON Receipts.TypeId = ReceiptTypes.Id
		WHERE
		RARD.IsActive = 1
		AND (Receipts.Status = 'Completed' AND Receipts.ReceiptClassification IN('NonCash', 'NonAccrualNonDSLNonCash')
		OR Receipts.Status = 'Posted'
		AND ReceiptTypes.ReceiptTypeName = 'WaivedFromReceivableAdjustment')
		GROUP BY RI.ReceivableInvoiceId

	SELECT
		DISTINCT RI.Number AS InvoiceNumber,
		IT.Name AS InvoiceType,
		RI.IsStatementInvoice,
		RI.IsActive AS Status,
		RI.InvoiceRunDate AS RunDate,
		RI.DueDate AS DueDate,
		RID.ChargeAmount,
		RID.TaxAmount,
		RI.InvoiceAmount_Amount + RI.InvoiceTaxAmount_Amount AS InvoiceAmount,
		CASE WHEN RI.IsActive = 0 THEN 0 ELSE RID.OutstandingBalance END OutstandingBalance,
		RID.IsPaid,
		RID.ZeroToThirtyDays,
		RID.ThirtyOneToSixtyDays,
		RID.SixtyOneToNinetyDays,
		RID.NinetyOneToOneHundredTwentyDays,
		RID.OneHundredTwentyPlusDaysAndAbove,
		RI.InvoiceFile_Source,
		RI.InvoiceFile_Type,
		RI.InvoiceFile_Content,
		BT.Name AS InvoiceGroup,
		PA.AddressLine1+ISNULL(','+Pa.AddressLine2, '')+IsNULL(','+PA.City, '')+ISNULL(','+S.LongName, '')+IsNull(','+PA.Division, '')+IsNull(','+PA.PostalCode, '') AS InvoiceGroupAddress,
		PC.FullName AS ContactPerson,
		RI.Id AS InvoiceId,
		currCode.ISO AS Currency,
		CASE
		WHEN R.AmountWaived IS NOT NULL AND R.AmountWaived > 0 AND RID.AmountReceived > 0
		THEN RID.AmountReceived - R.AmountWaived
		ELSE RID.AmountReceived
		END AS AmountReceived,
		CASE
		WHEN R.AmountWaived IS NOT NULL
		THEN R.AmountWaived
		ELSE 0
		END AS AmountWaived,
		CASE
		WHEN IT.Name = 'LateCharge'
		AND R.AmountWaived = RID.AmountReceived
		THEN 0
		ELSE RID.AmountReceived
		END AS TotalPaid,
		RID.OriginalAmount,
		RID.OriginalTaxAmount,
		Parties.PartyNumber AS CustomerNumber,
		CASE
		WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
		THEN NULL
		ELSE RI.InvoiceRunDate
		END AS GeneratedDate,
		RI.IsPdfGenerated AS IsGenerated,
		RI.DeliveryDate,
		CASE
		WHEN SI.IsBelongsToStatementInvoice = 1
		THEN 'SuppressGeneration'
		ELSE CASE
		WHEN RI.DeliveryMethod = '_'
		OR RI.DeliveryMethod IS NULL
		THEN CASE
		WHEN RI.StatementInvoicePreference = 'SuppressDelivery'
		THEN RI.StatementInvoicePreference
		ELSE CASE
		WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
		THEN RI.StatementInvoicePreference
		ELSE CASE
		WHEN RI.DeliveryJobStepInstanceId IS NULL
		THEN '_'
		ELSE CASE
		WHEN RI.DeliveryJobStepInstanceId IS NOT NULL
		AND RI.IsEmailSent = 0
		THEN @Error
		END
		END
		END
		END
		ELSE RI.DeliveryMethod
		END
		END AS DeliveryMethod,
		@ContractId ContractId,
		RI.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount,
		RI.WithHoldingTaxBalance_Amount AS WithHoldingTaxBalance
	INTO #Results
	FROM
	#CTE_ReceivableInvoices AS RID
	INNER JOIN ReceivableInvoices AS RI ON RID.ReceivableInvoiceId = RI.Id
	INNER JOIN Parties ON RI.CustomerId = Parties.Id
	INNER JOIN BillToes AS BT ON Ri.BillToId = BT.Id
	INNER JOIN InvoiceTypes AS IT ON RID.InvoiceTypeId = IT.Id
	INNER JOIN RemitToes AS RT ON RI.RemitToId = RT.Id
	INNER JOIN Currencies AS curr ON RI.CurrencyId = curr.Id
	INNER JOIN CurrencyCodes AS currCode ON curr.CurrencyCodeId = currCode.Id
	LEFT JOIN #StatementDetails SI ON SI.ReceivableInvoiceId = RI.Id
	LEFT JOIN #cte_receiptDetails AS R ON R.ReceivableInvoiceID = RID.ReceivableInvoiceId
	LEFT JOIN PartyAddresses AS PA ON BT.BillingAddressId = PA.Id
	LEFT JOIN States AS S ON Pa.StateId = S.Id
	LEFT JOIN PartyContacts AS PC ON BT.BillingContactPersonId = pc.Id
	WHERE RI.IsStatementInvoice = 0
	ORDER BY 1

	;WITH CTE_StatementInvoiceDetails
	AS
	(
		SELECT RI.Id FROM ReceivableInvoices RI
		INNER JOIN ReceivableInvoiceStatementAssociations SI ON RI.Id = SI.StatementInvoiceId AND RI.IsActive= 1
		INNER JOIN ReceivableInvoiceDetails RID ON SI.ReceivableInvoiceId = RID.ReceivableInvoiceId AND RID.IsActive= 1
		AND RID.EntityType = 'CT' AND RID.EntityId = @ContractID  AND (@FilterCustomerId IS NULL OR RI.CustomerId = @FilterCustomerId)
	)
	INSERT INTO #Results
	SELECT
		DISTINCT RI.Number AS InvoiceNumber,
		IT.Name AS InvoiceType,
		RI.IsStatementInvoice,
		RI.IsActive AS Status,
		RI.InvoiceRunDate AS RunDate,
		RI.DueDate AS DueDate,
		RI.InvoiceAmount_Amount,
		RI.InvoiceTaxAmount_Amount,
		RI.InvoiceAmount_Amount + RI.InvoiceTaxAmount_Amount AS InvoiceAmount,
		CASE WHEN RI.IsActive = 0 THEN 0 ELSE RI.Balance_Amount + RI.TaxBalance_Amount END OutstandingBalance,
		CASE
		WHEN RI.Balance_Amount + RI.TaxBalance_Amount= 0
		THEN CAST(1 AS BIT)
		ELSE CAST(0 AS BIT)
		END AS IsPaid,
		CASE
		WHEN DATEDIFF(DAY,DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 30
		AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 0
		THEN RI.Balance_Amount + RI.TaxBalance_Amount
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ZeroToThirtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 60
		AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 30
		THEN RI.Balance_Amount + RI.TaxBalance_Amount
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS ThirtyOneToSixtyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <  = 90
		AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 60
		THEN RI.Balance_Amount + RI.TaxBalance_Amount
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS SixtyOneToNinetyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) <= 120
		AND DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 90
		THEN RI.Balance_Amount + RI.TaxBalance_Amount
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS NinetyOneToOneHundredTwentyDays,
		CASE
		WHEN DATEDIFF(DAY, DATEADD(DD,LE.ThresholdDays,RI.DueDate), @CurrentBusinessDate) > 120
		THEN RI.Balance_Amount + RI.TaxBalance_Amount
		ELSE CAST(0 AS DECIMAL(16, 2))
		END AS OneHundredTwentyPlusDaysAndAbove,
		RI.InvoiceFile_Source,
		RI.InvoiceFile_Type,
		RI.InvoiceFile_Content,
		BT.Name AS InvoiceGroup,
		PA.AddressLine1+ISNULL(','+Pa.AddressLine2, '')+IsNULL(','+PA.City, '')+ISNULL(','+S.LongName, '')+IsNull(','+PA.Division, '')+IsNull(','+PA.PostalCode, '') AS InvoiceGroupAddress,
		PC.FullName AS ContactPerson,
		RI.Id AS ReceivableInvoiceID,
		currCode.ISO AS Currency,
		(RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount)[AmountReceived],
		CASE
		WHEN  (RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount) IS NOT NULL
		THEN  (RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount)
		ELSE 0
		END [AmountWaived],
		(RI.InvoiceTaxAmount_Amount + RI.InvoiceAmount_Amount) - (RI.Balance_Amount + RI.TaxBalance_Amount) [TotalPaid],
		RI.InvoiceAmount_Amount,
		RI.InvoiceTaxAmount_Amount,
		Parties.PartyNumber AS CustomerNumber,
		CASE
		WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
		THEN NULL
		ELSE RI.InvoiceRunDate
		END AS GeneratedDate,
		RI.IsPdfGenerated AS IsGenerated,
		RI.DeliveryDate,
		CASE
		WHEN RI.DeliveryMethod = '_'
		OR RI.DeliveryMethod IS NULL
		THEN CASE
		WHEN RI.StatementInvoicePreference = 'SuppressDelivery'
		THEN RI.StatementInvoicePreference
		ELSE CASE
		WHEN RI.StatementInvoicePreference = 'SuppressGeneration'
		THEN RI.StatementInvoicePreference
		ELSE CASE
		WHEN RI.DeliveryJobStepInstanceId IS NULL
		THEN '_'
		ELSE CASE
		WHEN RI.DeliveryJobStepInstanceId IS NOT NULL
		AND RI.IsEmailSent = 0
		THEN @Error
		END
		END
		END
		END
		ELSE RI.DeliveryMethod
		END AS DeliveryMethod,
		@ContractId ContractId,
		RI.WithHoldingTaxAmount_Amount AS WithHoldingTaxAmount,
		RI.WithHoldingTaxBalance_Amount AS WithHoldingTaxBalance
	FROM ReceivableInvoices AS RI
	INNER JOIN CTE_StatementInvoiceDetails SI ON RI.Id = SI.Id
	INNER JOIN LegalEntities LE
	ON RI.LegalEntityId = LE.Id
	INNER JOIN #AccessibleLegalEntityIds ON LE.Id = #AccessibleLegalEntityIds.Id
	INNER JOIN Parties ON RI.CustomerId = Parties.Id
	INNER JOIN ReceivableCategories AS RC ON RI.ReceivableCategoryId = RC.Id
	INNER JOIN BillToes AS BT ON Ri.BillToId = BT.Id
	INNER JOIN InvoiceTypes AS IT ON RC.InvoiceTypeId = IT.Id
	INNER JOIN RemitToes AS RT ON RI.RemitToId = RT.Id
	INNER JOIN Currencies AS curr ON RI.CurrencyId = curr.Id
	INNER JOIN CurrencyCodes AS currCode ON curr.CurrencyCodeId = currCode.Id
	LEFT JOIN PartyAddresses AS PA ON BT.BillingAddressId = PA.Id
	LEFT JOIN States AS S ON Pa.StateId = S.Id
	LEFT JOIN PartyContacts AS PC ON BT.BillingContactPersonId = pc.Id
	WHERE
		RC.Name != 'AssetSale' AND RI.IsStatementInvoice = 1 AND RI.IsActive=1 AND RI.CancellationDate IS NULL
		AND (@FilterCustomerId IS NULL OR RI.CustomerId = @FilterCustomerId)
		AND RI.IsDummy = 0
	ORDER BY 1

	SELECT * FROM #Results

	SELECT
		SUM(ChargeAmount) ChargeAmount,
		SUM(TaxAmount) TaxAmount,
		SUM(InvoiceAmount) InvoiceAmount,
		SUM(AmountReceived) AmountReceived,
		SUM(OutstandingBalance) OutstandingBalance,
		SUM(WithHoldingTaxAmount) WithHoldingTaxAmount,
		SUM(WithHoldingTaxBalance) WithHoldingTaxBalance,
		SUM(ZeroToThirtyDays) ZeroToThirtyDays ,
		SUM(ThirtyOneToSixtyDays) ThirtyOneToSixtyDays,
		SUM(SixtyOneToNinetyDays) SixtyOneToNinetyDays ,
		SUM(NinetyOneToOneHundredTwentyDays) NinetyOneToOneHundredTwentyDays,
		SUM(OneHundredTwentyPlusDaysAndAbove) OneHundredTwentyPlusDaysAndAbove ,
		SUM(AmountWaived) AmountWaived,
		SUM(TotalPaid) TotalPaid
	FROM #Results
	WHERE
		Status=1
		AND IsStatementInvoice = 0

	DROP TABLE IF EXISTS #Results
	DROP TABLE IF EXISTS #AccessibleLegalEntityIds
	DROP TABLE IF EXISTS #StatementDetails
	DROP TABLE IF EXISTS #CTE_ReceivableInvoices
	DROP TABLE IF EXISTS #cte_receiptDetails
	DROP TABLE IF EXISTS #RDetails
	DROP TABLE IF EXISTS #ReceivableTaxDetails
END

GO

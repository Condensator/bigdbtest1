SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetOpenReceivableSummariesForContractService]
(
@ContractSequenceNumber nvarchar(80),
@FilterCustomerId BIGINT = NULL
)
AS
BEGIN
SET NOCOUNT ON;
	DECLARE @ContractId AS BIGINT;
	SET @ContractId = (SELECT Id FROM Contracts WHERE SequenceNumber = @ContractSequenceNumber)

	Select Id,ReceivableCodeId Into #Receivables From Receivables
	Where EntityId = @ContractId
	AND EntityType = 'CT'
	AND IsActive = 1
	AND SourceTable NOT IN ('CPUSchedule')
	AND (CreationSourceTable IS NULL OR (CreationSourceTable IS NOT NULL AND CreationSourceTable <> 'ReceivableForTransfer'))
	AND (@FilterCustomerId IS NULL OR Receivables.CustomerId = @FilterCustomerId )

    SELECT 
        RD.Id ReceivableDetailId,
        rc.ReceivableTypeId,
        RD.Amount_Amount ReceivableAmount,
        RD.Balance_Amount ReceivableRemaining
    INTO #ReceivableDetails
    FROM ReceivableDetails RD
    INNER JOIN #Receivables R ON RD.ReceivableId = R.Id
    INNER JOIN ReceivableCodes rc ON R.ReceivableCodeId = rc.Id
    INNER JOIN ReceivableCategories AS RC1  ON RC.ReceivableCategoryId = RC1.Id
    WHERE RD.IsActive = 1
        AND RD.BilledStatus = 'Invoiced'
        AND RC1.Name != 'AssetSale'


    SELECT 
        RD.ReceivableDetailId,
        RD.ReceivableTypeId,
        RD.ReceivableAmount,
        RD. ReceivableRemaining, 
        RID.ReceivableInvoiceId ReceivableInvoiceId
    INTO #ReceivableInvoiceInfo  
    FROM #ReceivableDetails as RD
    INNER JOIN ReceivableInvoiceDetails as RID  on RID.ReceivableDetailId = RD.ReceivableDetailId
    WHERE RID.IsActive=1  
	OPTION(LOOP JOIN)

	CREATE INDEX IX_ReceivableId ON #ReceivableInvoiceInfo (ReceivableDetailId,ReceivableInvoiceId)

	SELECT
		RI.ReceivableInvoiceId
		,SUM(ISNULL(RWTD.Balance_Amount, 0)) AS RemainingAdjustedWithholdingtax
		,SUM(ISNULL(RARD.AdjustedWithholdingTax_Amount, 0)) AS AdjustedWithholdingTax
	INTO #ReceivableWithholdingTaxDetails
	FROM #ReceivableInvoiceInfo RI
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RWTD ON RI.ReceivableDetailId = RWTD.ReceivableDetailId AND RWTD.IsActive = 1
	LEFT JOIN ReceiptApplicationReceivableDetails RARD ON RI.ReceivableDetailId =  RARD.ReceivableDetailId AND RARD.IsActive = 1
	GROUP BY
		RI.ReceivableInvoiceId

	CREATE INDEX IX_ReceivableId ON #ReceivableWithholdingTaxDetails (ReceivableInvoiceId)

	SELECT
		SUM(ReceivableTaxDetails.Amount_Amount) AS TaxAmount
		,SUM(ReceivableTaxDetails.Balance_Amount) AS TaxRemaining
		,RII.ReceivableInvoiceId
		,RII.ReceivableTypeId
	INTO #TaxDetails
	FROM #ReceivableInvoiceInfo RII
	JOIN ReceivableTaxDetails
	ON ReceivableTaxDetails.ReceivableDetailId = RII.ReceivableDetailId
	AND ReceivableTaxdetails.IsActive = 1
	GROUP BY
	RII.ReceivableInvoiceId
	,RII.ReceivableTypeId
	OPTION(LOOP JOIN)

	CREATE INDEX IX_ReceivableInvoiceId	ON #TaxDetails (ReceivableInvoiceId)

	SELECT
		ISNULL(SUM(ReceiptApplicationReceivableDetails.ReceivedAmount_Amount), 0) AS ReceivableApplied
		,ISNULL(SUM(ReceiptApplicationReceivableDetails.TaxApplied_Amount), 0) AS TaxApplied
		,RII.ReceivableInvoiceId
		,RII.ReceivableTypeId
	INTO #ReceiptDetails
	FROM #ReceivableInvoiceInfo RII
	INNER JOIN ReceiptApplicationReceivableDetails
	ON ReceiptApplicationReceivableDetails.ReceivableDetailId = RII.ReceivableDetailId
	AND ReceiptApplicationReceivableDetails.IsActive = 1
	INNER JOIN ReceiptApplications
	ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
	INNER JOIN Receipts
	ON Receipts.Id = ReceiptApplications.ReceiptId
	AND Receipts.Status IN ('Posted','Completed','Submitted')
	GROUP BY
	RII.ReceivableInvoiceId
	,RII.ReceivableTypeId

	CREATE INDEX IX_ReceivableInvoiceId	ON #ReceiptDetails (ReceivableInvoiceId)


		SELECT
			SUM(RII.ReceivableAmount) ReceivableAmount
			,ISNULL(MAX(TD.TaxAmount),0) TaxAmount
			,SUM(RII.ReceivableRemaining) ReceivableRemaining
			,ISNULL(MAX(TD.TaxRemaining),0) TaxRemaining
			,RII.ReceivableInvoiceId ReceivableInvoiceId
			,RII.ReceivableTypeId ReceivableTypeId
			INTO #ReceivableInvoiceAmountDetails
		FROM #ReceivableInvoiceInfo RII
		LEFT JOIN #TaxDetails TD
		ON TD.ReceivableInvoiceId = RII.ReceivableInvoiceId
		AND TD.ReceivableTypeId = RII.ReceivableTypeId
		GROUP BY
		RII.ReceivableInvoiceId
		,RII.ReceivableTypeId
		HAVING
		SUM(RII.ReceivableRemaining) + ISNULL(MAX(TD.TaxRemaining),0) != 0

	SELECT
		ReceivableInvoices.Number AS InvoiceNumber
		,ReceivableTypes.Name AS ReceivableType
		,ReceivableInvoices.DueDate DueDate
		,ISNULL(CTE_ReceivableInvoicesInfo.ReceivableAmount ,0) ReceivableAmount
		,ISNULL(CTE_ReceivableInvoicesInfo.TaxAmount ,0) TaxAmount
		,ISNULL(CTE_ReceivableInvoicesInfo.ReceivableAmount ,0) +  ISNULL(CTE_ReceivableInvoicesInfo.TaxAmount ,0) TotalAmount
		,ISNULL(#ReceiptDetails.ReceivableApplied ,0) ReceivableApplied
		,ISNULL(CTE_ReceivableInvoicesInfo.ReceivableRemaining ,0) ReceivableRemaining
		,ISNULL(#ReceiptDetails.TaxApplied ,0) TaxApplied
		,ISNULL(CTE_ReceivableInvoicesInfo.TaxRemaining ,0) TaxRemaining
		,#ReceivableWithholdingTaxDetails.AdjustedWithholdingTax AS AdjustedWithholdingtax
		,#ReceivableWithholdingTaxDetails.RemainingAdjustedWithholdingtax AS RemainingAdjustedWithholdingtax
		,ReceivableInvoices.Balance_Currency Currency
		,ReceivableInvoices.InvoiceFile_Source
		,ReceivableInvoices.InvoiceFile_Type
		,ReceivableInvoices.InvoiceFile_Content
		,Parties.PartyNumber as [CustomerNumber]
	FROM #ReceivableInvoiceAmountDetails CTE_ReceivableInvoicesInfo
	INNER JOIN ReceivableInvoices
	ON ReceivableInvoices.Id = CTE_ReceivableInvoicesInfo.ReceivableInvoiceId AND ReceivableInvoices.IsDummy = 0 AND ReceivableInvoices.IsActive=1
	INNER JOIN Parties ON
	ReceivableInvoices.CustomerId = Parties.Id
	INNER JOIN ReceivableTypes
	ON ReceivableTypes.Id = CTE_ReceivableInvoicesInfo.ReceivableTypeId
	LEFT JOIN #ReceivableWithholdingTaxDetails
	ON #ReceivableWithholdingTaxDetails.ReceivableInvoiceId = ReceivableInvoices.Id
	LEFT JOIN #ReceiptDetails
	ON  #ReceiptDetails.ReceivableInvoiceId = CTE_ReceivableInvoicesInfo.ReceivableInvoiceId
	AND #ReceiptDetails.ReceivableTypeId = CTE_ReceivableInvoicesInfo.ReceivableTypeId


	DROP TABLE #ReceivableInvoiceInfo
	DROP TABLE #TaxDetails
	DROP TABLE #ReceiptDetails
END

GO

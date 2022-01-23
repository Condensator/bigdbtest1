SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceivablesFromPayoff]
(
@ReceivableIds NVARCHAR(MAX),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON

Select
		R.Id ReceivablesId,
		RD.Id ReceivableDetailId,
		RTD.ReceivableTaxId,
		RTD.Id ReceivableTaxDetailId,
		RTI.Id ReceivableTaxImpositionId,
		RID.ReceivableInvoiceId,
		RID.Id ReceivableInvoiceDetailId
	INTO #ReceivablesToBeUpdated
	FROM Receivables R
	JOIN ConvertCSVToBigIntTable(@ReceivableIds,',') csv ON R.Id = csv.Id
	JOIN ReceivableDetails RD ON RD.ReceivableId = R.Id
	JOIN ReceivableTaxDetails RTD ON RTD.ReceivableDetailId = RD.Id
	JOIN ReceivableTaxImpositions RTI ON RTI.ReceivableTaxDetailId = RTD.Id
	JOIN ReceivableInvoiceDetails RID ON RID.ReceivableDetailId = RD.Id
	WHERE R.IsServiced = 1
		AND R.IsCollected = 0
		AND R.FunderId IS NOT NULL

		UPDATE Receivables
		SET TotalBalance_Amount = 0
			,TotalEffectiveBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM Receivables 
		JOIN #ReceivablesToBeUpdated R ON Receivables.Id = R.ReceivablesId

		UPDATE RD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableDetails RD
		JOIN #ReceivablesToBeUpdated R ON RD.Id = R.ReceivableDetailId

		UPDATE RT
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableTaxes RT 
		JOIN #ReceivablesToBeUpdated R ON RT.Id = R.ReceivableTaxId

		UPDATE RTD
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableTaxDetails RTD 
		JOIN #ReceivablesToBeUpdated R ON RTD.Id = R.ReceivableTaxDetailId

		UPDATE RTI
		SET Balance_Amount = 0
			,EffectiveBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableTaxImpositions RTI 
		JOIN #ReceivablesToBeUpdated R ON RTI.Id = R.ReceivableTaxImpositionId		

		UPDATE RID
		SET Balance_Amount = 0
			,TaxBalance_Amount = 0
			,EffectiveBalance_Amount = 0
			,EffectiveTaxBalance_Amount = 0
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableInvoiceDetails RID 
		JOIN #ReceivablesToBeUpdated R ON RID.Id = R.ReceivableInvoiceDetailId

		SELECT Balance_Amount = SUM(RID.Balance_Amount)
			,TaxBalance_Amount = SUM(RID.TaxBalance_Amount)
			,EffectiveBalance_Amount = SUM(RID.EffectiveBalance_Amount)
			,EffectiveTaxBalance_Amount = SUM(RID.EffectiveTaxBalance_Amount)
			,ReceivableInvoiceID = RID.ReceivableInvoiceId
		INTO #ReceivableInvoiceBalanceDetails
		FROM ReceivableInvoiceDetails RID 
		JOIN (SELECT DISTINCT(ReceivableInvoiceID) FROM #ReceivablesToBeUpdated) AS RD ON RID.ReceivableInvoiceId = RD.ReceivableInvoiceId
		GROUP BY RID.ReceivableInvoiceID 

		UPDATE RI
		SET Balance_Amount = RID.Balance_Amount
			,TaxBalance_Amount = RID.TaxBalance_Amount
			,EffectiveBalance_Amount = RID.EffectiveBalance_Amount
			,EffectiveTaxBalance_Amount = RID.EffectiveTaxBalance_Amount
			,UpdatedById = @UpdatedById
			,UpdatedTime = @UpdatedTime
		FROM ReceivableInvoices RI 
		JOIN #ReceivableInvoiceBalanceDetails RID ON RI.ID = RID.ReceivableInvoiceId

		DROP TABLE #ReceivablesToBeUpdated
		DROP TABLE #ReceivableInvoiceBalanceDetails
END

GO

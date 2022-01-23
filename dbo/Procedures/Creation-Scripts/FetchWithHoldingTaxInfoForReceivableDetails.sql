SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[FetchWithHoldingTaxInfoForReceivableDetails]
(
	@ReceivableDetailIds IdCollection READONLY
)
AS
BEGIN
	SELECT * INTO #ReceivableDetailIds FROM @ReceivableDetailIds

	SELECT RDWTD.BasisAmount_Amount,
		RDWTD.BasisAmount_Currency,
		RDWTD.Tax_Amount ,
		RDWTD.Tax_Currency,
		RDWTD.Balance_Amount,
		RDWTD.Balance_Currency,
		RDWTD.EffectiveBalance_Amount,
		RDWTD.EffectiveBalance_Currency,
		RD.Id AS ReceivableDetailId
	INTO #ReceivableDetailWithholdingTaxDetails
	FROM #ReceivableDetailIds RD
	INNER JOIN ReceivableDetailsWithholdingTaxDetails RDWTD ON RD.Id = RDWTD.ReceivableDetailId AND RDWTD.IsActive = 1

	SELECT
		CAST(1 AS BIT) AS WithholdingTaxAssessed,
		ISNULL(RDWTD.BasisAmount_Amount, 0.00)  WithHoldingBasis_Amount,
		ISNULL(RDWTD.BasisAmount_Currency, Amount_Currency)  WithHoldingBasis_Currency,
		ISNULL(RDWTD.Tax_Amount, 0.00)  WithHoldingTaxAmount_Amount,
		ISNULL(RDWTD.Tax_Currency, Amount_Currency) WithHoldingTaxAmount_Currency,
		ISNULL(RDWTD.Balance_Amount, 0.00) WithholdingTaxBalance_Amount,
		ISNULL(RDWTD.Balance_Currency, Amount_Currency) WithholdingTaxBalance_Currency,
		ISNULL(RDWTD.EffectiveBalance_Amount, 0.00) WithholdingTaxEffectiveBalance_Amount,
		ISNULL(RDWTD.EffectiveBalance_Currency, Amount_Currency) WithholdingTaxEffectiveBalance_Currency,
		RD.Id AS ReceivableDetailId,
		RD.Id
	FROM #ReceivableDetailIds RDIds
	INNER JOIN ReceivableDetails RD ON RDIds.Id = RD.Id AND RD.IsActive = 1
	INNER JOIN ReceivableWithholdingTaxDetails RWTD ON RD.ReceivableId = RWTD.ReceivableId AND RWTD.IsActive = 1
	LEFT JOIN #ReceivableDetailWithholdingTaxDetails RDWTD ON RD.Id = RDWTD.ReceivableDetailId
END

GO

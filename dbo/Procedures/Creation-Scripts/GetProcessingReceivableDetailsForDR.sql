SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetProcessingReceivableDetailsForDR]
(
	@ReceivableIds IdCollection READONLY 
)
AS
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN
	SELECT 
		RD.Id,
		RD.ReceivableId,
		RD.Amount_Amount Amount,
		RD.Balance_Amount Balance,
		RD.EffectiveBalance_Amount EffectiveBalance
	INTO #ReceivableDetailTemp
	FROM ReceivableDetails RD
		JOIN @ReceivableIds R ON RD.ReceivableId = R.Id AND RD.IsActive = 1;

	SELECT 
		RTD.Id,
		RT.ReceivableId,
		RTD.ReceivableTaxId,
		RTD.Amount_Amount Amount,
		RTD.Balance_Amount Balance,
		RTD.EffectiveBalance_Amount EffectiveBalance
	INTO #ReceivableTaxDetailTemp
	FROM #ReceivableDetailTemp RD
		JOIN ReceivableTaxes RT ON RD.ReceivableId = RT.ReceivableId AND RT.IsActive = 1
		JOIN ReceivableTaxDetails RTD ON RT.Id = RTD.ReceivableTaxId AND RTD.ReceivableDetailId = RD.Id AND RTD.IsActive = 1;

	SELECT 
		RTI.Id,
		RTI.ReceivableTaxDetailId,
		RTI.Amount_Amount Amount,
		RTI.Balance_Amount Balance,
		RTI.EffectiveBalance_Amount EffectiveBalance
	INTO #ReceivableTaxImpositionTemp
	FROM #ReceivableTaxDetailTemp RTD
		JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId AND RTI.IsActive = 1;

	SELECT * FROM #ReceivableDetailTemp
	SELECT * FROM #ReceivableTaxDetailTemp
	SELECT * FROM #ReceivableTaxImpositionTemp;

	DROP TABLE #ReceivableDetailTemp
	DROP TABLE #ReceivableTaxDetailTemp
	DROP TABLE #ReceivableTaxImpositionTemp

END

GO

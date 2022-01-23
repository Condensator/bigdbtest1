SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ExtractDataForInvoiceGeneration_Taxes] (
	@JobStepInstanceId BIGINT,
	@IsWithHoldingTaxApplicable BIT
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	CREATE TABLE #TaxInfo(
		ExtractId BIGINT PRIMARY KEY,
		OriginalTaxBalance DECIMAL(16,2),
		OriginalEffectiveTaxBalance DECIMAL(16, 2),
		OriginalTaxAmount DECIMAL(16,2)
	)

	INSERT INTO #TaxInfo(ExtractId, OriginalTaxBalance, OriginalEffectiveTaxBalance, OriginalTaxAmount)
	SELECT 
		IRD.Id,
		SUM(RTD.Balance_Amount) OriginalTaxBalance,
		SUM(RTD.EffectiveBalance_Amount) OriginalEffectiveTaxBalance,
		SUM(RTD.Amount_Amount) OriginalTaxAmount
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN ReceivableTaxDetails RTD ON IRD.ReceivableDetailId = RTD.ReceivableDetailId
		AND RTD.IsActive = 1
	WHERE IRD.JobStepInstanceId = @JobStepInstanceId AND IRD.IsActive=1
	GROUP BY IRD.Id, RTD.ReceivableDetailId

	UPDATE IRD
	SET 
		OriginalTaxBalance = T.OriginalTaxBalance,
		OriginalEffectiveTaxBalance = T.OriginalEffectiveTaxBalance,
		TaxAmount = T.OriginalTaxAmount
	FROM InvoiceReceivableDetails_Extract IRD 
	INNER JOIN #TaxInfo T ON IRD.Id = T.ExtractId

	--If WithHoldingTaxes are applicable, then it's a Filter Criteria
	UPDATE IRD SET
	IsActive = CASE 
		WHEN RWHT.Id IS NOT NULL THEN 1
		ELSE 0
	END
	FROM InvoiceReceivableDetails_Extract IRD
	LEFT JOIN ReceivableWithholdingTaxDetails RWHT ON IRD.ReceivableId=RWHT.ReceivableId AND RWHT.IsActive=1
	WHERE @IsWithHoldingTaxApplicable = 1 AND IRD.IsActive=1

	UPDATE IRD
	SET IsWithHoldingTaxAssessed = 1,  --TODO: Remove Column IsWithHoldingTaxAssessed (Not Needed)
		WithHoldingTaxBalance = Balance_Amount
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN ReceivableDetailsWithholdingTaxDetails RDWHT 
		ON IRD.ReceivableDetailId = RDWHT.ReceivableDetailId AND RDWHT.IsActive = 1
	WHERE @IsWithHoldingTaxApplicable = 1 AND IRD.IsActive=1 AND IRD.JobStepInstanceId=@JobStepInstanceId

END

GO

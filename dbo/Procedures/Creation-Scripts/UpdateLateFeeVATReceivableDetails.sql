SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateLateFeeVATReceivableDetails] 
(
	@JobStepInstanceId				BIGINT,
	@ReceivableTypeValues_LateFee	NVARCHAR(10)
)
AS
BEGIN
	
	UPDATE VAT
	SET VAT.BasisAmount=LFR.TaxBasisAmount_Amount
		,VAT.BasisAmountCurrency=LFR.TaxBasisAmount_Currency
	FROM VATReceivableLocationDetailExtract VAT 
	JOIN ReceivableTypes RT ON VAT.ReceivableTypeId = RT.Id
	JOIN Receivables R ON VAT.ReceivableId = R.Id
	JOIN LateFeeReceivables LFR ON R.SourceTable = @ReceivableTypeValues_LateFee 
									AND R.SourceId = LFR.Id
	WHERE RT.Name=@ReceivableTypeValues_LateFee
		  AND VAT.JobStepInstanceId = @JobStepInstanceId

END

GO

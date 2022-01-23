SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ValidateBillToesForInvoiceGeneration] (
	@JobStepInstanceId BIGINT
	)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ReceivableTaxType_VAT NVARCHAR(3) = 'VAT' 

	CREATE TABLE #ValidBillToDetails(
		BillToId BIGINT,
		ReceivableCategory NVARCHAR(20),
		InvoiceFormatId BIGINT,
		InvoiceOutputFormat NVARCHAR(5),
		ReceivableTaxType NVARCHAR(20)
	)

	CREATE NONCLUSTERED INDEX IX_ValidBillTo ON #ValidBillToDetails(BillToId, ReceivableCategory, ReceivableTaxType) INCLUDE (InvoiceFormatId, InvoiceOutputFormat)

	INSERT INTO #ValidBillToDetails(BillToId, ReceivableCategory, InvoiceFormatId, InvoiceOutputFormat, ReceivableTaxType)
	SELECT 
			BIP.BillToId,
			BIF.ReceivableCategory,
			CASE WHEN D.ReceivableTaxType = @ReceivableTaxType_VAT THEN BIF.VATInvoiceFormatId ELSE BIF.InvoiceFormatId END,
			BIF.InvoiceOutputFormat,
			D.ReceivableTaxType
	FROM InvoiceReceivableDetails_Extract D
	INNER JOIN BillToInvoiceParameters BIP ON D.BillToId = BIP.BillToId
		AND BIP.IsActive = 1
	INNER JOIN BillToInvoiceFormats BIF ON BIP.BillToId = BIF.BillToId
		AND BIF.IsActive = 1
		AND D.ReceivableCategoryName = BIF.ReceivableCategory --TODO: Change BIF ReceivableCategory to ReceivableCategoryId ; Add referential integrity in BIF and non-clustered composite with BillToId
	WHERE D.JobStepInstanceId=@JobStepInstanceId
	GROUP BY BIP.BillToId,
		BIF.ReceivableCategory,
		BIF.InvoiceFormatId,
		BIF.InvoiceOutputFormat,
		BIF.VATInvoiceFormatId,
		D.ReceivableTaxType

	UPDATE IRD
	SET IsActive = 1,
		InvoiceFormatId = V.InvoiceFormatId,
		InvoiceOutputFormat = V.InvoiceOutputFormat
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN #ValidBillToDetails V ON IRD.BillToId=V.BillToId 
		AND IRD.ReceivableCategoryName=V.ReceivableCategory 
		AND IRD.ReceivableTaxType = V.ReceivableTaxType
		AND IRD.JobStepInstanceId=@JobStepInstanceId 
	
	DROP TABLE #ValidBillToDetails

END

GO

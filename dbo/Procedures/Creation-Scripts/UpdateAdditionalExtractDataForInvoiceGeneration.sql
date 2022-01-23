SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateAdditionalExtractDataForInvoiceGeneration] (
	@JobStepInstanceId BIGINT,
	@OneTimeACHStatus_Reversed NVARCHAR(100)
	)
AS
BEGIN
	SET NOCOUNT ON;
	
	UPDATE IRD
	SET LocationId = AL.LocationId
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN AssetLocations AL ON AL.AssetId = IRD.AssetId
		AND AL.IsActive = 1	AND AL.IsCurrent = 1
	WHERE IRD.IsActive=1 AND IRD.JobStepInstanceId = @JobStepInstanceId

	UPDATE IRD
	SET AssetPurchaseOrderNumber = A.CustomerPurchaseOrderNumber
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN Assets A ON IRD.AssetId=A.Id
	WHERE IRD.SplitCustomerPurchaseOrderNumber = 1 AND IRD.JobStepInstanceId=@JobStepInstanceId AND IRD.IsActive=1 

	UPDATE IRD
	SET AlternateBillingCurrencyISO = CCOD.ISO
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN Currencies CC ON IRD.AlternateBillingCurrencyId = CC.Id
	INNER JOIN CurrencyCodes CCOD on CC.CurrencyCodeId = CCOD.Id
	WHERE IRD.JobStepInstanceId=@JobStepInstanceId  AND IRD.IsActive=1 

	UPDATE IRD
	SET IsACH = 1
	FROM InvoiceReceivableDetails_Extract IRD
	INNER JOIN ACHSchedules ACHS ON IRD.ReceivableId = ACHS.ReceivableId
	AND ACHS.IsActive = 1 AND ACHS.[Status] != @OneTimeACHStatus_Reversed AND IRD.JobStepInstanceId=@JobStepInstanceId  AND IRD.IsActive=1 

END

GO

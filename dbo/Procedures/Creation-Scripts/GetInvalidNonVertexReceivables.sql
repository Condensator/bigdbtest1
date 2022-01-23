SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvalidNonVertexReceivables]
(
	@JobStepInstanceId BIGINT,
	@UALCode NVARCHAR(100)
)
AS
BEGIN
	SELECT 
		DISTINCT L.LocationCode 
	FROM NonVertexReceivableDetailExtract RD
		INNER JOIN SalesTaxLocationDetailExtract L ON RD.LocationId =L.LocationId AND RD.JobStepInstanceId = L.JobStepInstanceId
		LEFT JOIN NonVertexTaxRateDetailExtract TaxRates ON  RD.ReceivableDetailId = TaxRates.ReceivableDetailId  AND RD.JobStepInstanceId = TaxRates.JobStepInstanceId
	WHERE  L.IsVertexSupportedLocation = 0 AND TaxRates.ReceivableDetailId IS NULL  AND RD.JobStepInstanceId = @JobStepInstanceId;

	SELECT
			STR.ReceivableId,
			STR.ReceivableDetailId,
			STR.ReceivableDueDate,
			STR.AssetId,
			STR.InValidErrorCode,
			ISNULL(C.SequenceNumber,'') AS SequenceNumber
	FROM SalesTaxReceivableDetailExtract STR
		LEFT JOIN Contracts C on C.Id = STR.ContractId
	WHERE InvalidErrorCode = @UALCode AND STR.IsVertexSupported = 0
		AND STR.JobStepInstanceId =@JobStepInstanceId;
END

GO

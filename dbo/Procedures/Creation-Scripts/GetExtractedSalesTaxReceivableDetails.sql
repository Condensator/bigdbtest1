SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetExtractedSalesTaxReceivableDetails]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN

SELECT
	LegalEntityName,
	ReceivableId,
	ReceivableDetailId,
	ReceivableDueDate,
	AssetId,
	InvalidErrorCode
FROM SalesTaxReceivableDetailExtract
WHERE IsVertexSupported = 1 AND JobStepInstanceId = @JobStepInstanceId;

END

GO

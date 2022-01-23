SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetVATTaxReversalDetails]
(
	@JobStepInstanceId				BIGINT,
	@ReceivableTaxType_VAT			NVARCHAR(10)
)
AS
BEGIN

SELECT 
	ReceivableId,ReceivableTaxId,ReceivableTaxDetailId, ReceivableDetailId, AssetLocationId, ReceivableTaxRowVersion,
	ReceivableTaxDetailRowVersion, ReceivableDetailRowVersion, AssetLocationRowVersion,UpfrontTaxSundryId,ReceivableTaxType
FROM ReversalReceivableDetail_Extract
WHERE ReceivableTaxId IS NOT NULL AND JobStepInstanceId = @JobStepInstanceId
	AND IsVertexSupported = 0 AND ErrorCode IS NULL AND ReceivableTaxType = @ReceivableTaxType_VAT

END

GO

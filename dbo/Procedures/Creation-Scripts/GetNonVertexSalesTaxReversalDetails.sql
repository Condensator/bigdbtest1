SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetNonVertexSalesTaxReversalDetails]
(
@JobStepInstanceId			BIGINT,
@ReceivableTaxTypeSalesTax	NVARCHAR(20)
)
AS
BEGIN
SELECT 
	ReceivableId,ReceivableTaxId,ReceivableTaxDetailId, ReceivableDetailId, AssetLocationId, ReceivableTaxRowVersion,
	ReceivableTaxDetailRowVersion, ReceivableDetailRowVersion, AssetLocationRowVersion,UpfrontTaxSundryId,ReceivableTaxType
FROM ReversalReceivableDetail_Extract
WHERE IsVertexSupported = 0 AND ErrorCode IS NULL AND ReceivableTaxId IS NOT NULL 
	AND JobStepInstanceId = @JobStepInstanceId AND ReceivableTaxType = @ReceivableTaxTypeSalesTax
;
END

GO

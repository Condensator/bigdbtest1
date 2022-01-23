SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetNonVertexSalesTaxReversalDetailsForAdjustment]
(
@JobStepInstanceId BIGINT
)
AS
BEGIN
SELECT ReceivableTaxId,ReceivableTaxDetailId, ReceivableDetailId, AssetLocationId, ReceivableTaxRowVersion,
ReceivableTaxDetailRowVersion, ReceivableDetailRowVersion, AssetLocationRowVersion,UpfrontTaxSundryId, ContractId
FROM ReversalReceivableDetail_Extract
WHERE IsVertexSupported = 0 AND ErrorCode IS NULL AND ReceivableTaxId IS NOT NULL AND JobStepInstanceId = @JobStepInstanceId
;
END

GO

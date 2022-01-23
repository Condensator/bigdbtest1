SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetExtractedVertexWSTransactions]
(
@JobStepInstanceId BIGINT,
@UnknownTaxBasis NVARCHAR(10)
)
AS
BEGIN

SELECT
	ReceivableId,
	ReceivableDetailId,
	DueDate,
	LeaseUniqueID,
	AssetId
FROM VertexWSTransactionExtract
WHERE TaxBasis IS NULL OR TaxBasis = '' OR TaxBasis = @UnknownTaxBasis
AND VertexWSTransactionExtract.JobStepInstanceId =@JobStepInstanceId

END

GO

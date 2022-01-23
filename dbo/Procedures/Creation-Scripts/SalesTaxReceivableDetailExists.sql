SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SalesTaxReceivableDetailExists]
(
@JobStepInstanceId BIGINT
)
AS
SET NOCOUNT ON;
BEGIN

SELECT isnull(ReceivableTaxType,'_') as ReceivableTaxType, IsVertexSupported FROM SalesTaxReceivableDetailExtract WHERE JobStepInstanceId = @JobStepInstanceId
GROUP BY ReceivableTaxType,IsVertexSupported

END

GO

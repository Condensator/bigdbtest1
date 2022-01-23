SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[TruncateSalesTaxBatchProcessTables]
AS
SET NOCOUNT ON;
BEGIN
TRUNCATE TABLE SalesTaxReceivableDetail_Extract
TRUNCATE TABLE SalesTaxAssetDetail_Extract
TRUNCATE TABLE SalesTaxAssetSKUDetail_Extract
TRUNCATE TABLE SalesTaxAssetLocationDetail_Extract
TRUNCATE TABLE SalesTaxLocationDetail_Extract
TRUNCATE TABLE SalesTaxContractBasedSplitupReceivableDetail_Extract
-- Vertex Tables
TRUNCATE TABLE VertexUpfrontRentalDetail_Extract
TRUNCATE TABLE VertexUpfrontCostDetail_Extract
TRUNCATE TABLE VertexReceivableCodeDetail_Extract
TRUNCATE TABLE VertexLocationTaxAreaDetail_Extract
TRUNCATE TABLE VertexCustomerDetail_Extract
TRUNCATE TABLE VertexContractDetail_Extract
TRUNCATE TABLE VertexWSTransaction_Extract
TRUNCATE TABLE VertexWSTransactionChunks_Extract
TRUNCATE TABLE VertexWSTransactionChunkDetails_Extract
TRUNCATE TABLE VertexAssetDetail_Extract
TRUNCATE TABLE VertexAssetSKUDetail_Extract
-- Non vertex tables
TRUNCATE TABLE NonVertexAssetDetail_Extract
TRUNCATE TABLE NonVertexLocationDetail_Extract;
TRUNCATE TABLE NonVertexReceivableCodeDetail_Extract
TRUNCATE TABLE NonVertexCustomerDetail_Extract
TRUNCATE TABLE NonVertexLeaseDetail_Extract
TRUNCATE TABLE NonVertexUpfrontRentalDetail_Extract
TRUNCATE TABLE NonVertexUpfrontCostDetail_Extract
TRUNCATE TABLE NonVertexTaxExempt_Extract
TRUNCATE TABLE NonVertexReceivableDetail_Extract
TRUNCATE TABLE NonVertexTaxRateDetail_Extract
TRUNCATE TABLE NonVertexImpositionLevelTaxDetail_Extract
TRUNCATE TABLE NonVertexTax_Extract
END

GO
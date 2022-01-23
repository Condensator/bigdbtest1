SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ClearSalesTaxProcessForVertexOutstandingReceivablesTables]
(  
	@JobStepInstanceId BIGINT
) 
AS 
SET NOCOUNT ON;

BEGIN

IF OBJECT_ID('SalesTaxReceivableDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxReceivableDetailExtract                       WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxReceivableSKUDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxReceivableSKUDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxContractBasedSplitupReceivableDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxContractBasedSplitupReceivableDetailExtract   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxAssetDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxAssetDetailExtract							   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxAssetSKUDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxAssetSKUDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxAssetLocationDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxAssetLocationDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('SalesTaxLocationDetailExtract') IS NOT NULL
BEGIN
DELETE FROM SalesTaxLocationDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END

--Vertex
IF OBJECT_ID('VertexLocationTaxAreaDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexLocationTaxAreaDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexCustomerDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexCustomerDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexContractDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexContractDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexAssetDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexAssetDetailExtract							   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexAssetSKUDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexAssetSKUDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexReceivableCodeDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexReceivableCodeDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexUpfrontRentalDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexUpfrontRentalDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexUpfrontCostDetailExtract') IS NOT NULL
BEGIN
DELETE FROM VertexUpfrontCostDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexWSTransactionExtract') IS NOT NULL
BEGIN
DELETE FROM VertexWSTransactionExtract							   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexWSTransactionChunksExtract') IS NOT NULL
BEGIN
DELETE FROM VertexWSTransactionChunksExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('VertexWSTransactionChunkDetailsExtract') IS NOT NULL
BEGIN
DELETE FROM VertexWSTransactionChunkDetailsExtract				   WHERE JobStepInstanceId = @JobStepInstanceId;
END

END

GO

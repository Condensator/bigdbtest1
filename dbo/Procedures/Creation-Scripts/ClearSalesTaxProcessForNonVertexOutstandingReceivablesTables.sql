SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[ClearSalesTaxProcessForNonVertexOutstandingReceivablesTables]
(  
	@JobStepInstanceId BIGINT
) 
AS 
SET NOCOUNT ON;

BEGIN

-- Non vertex tables
IF OBJECT_ID('NonVertexAssetDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexAssetDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexCustomerDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexCustomerDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexImpositionLevelTaxDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexImpositionLevelTaxDetailExtract			   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexLeaseDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexLeaseDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexLocationDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexLocationDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexReceivableCodeDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexReceivableCodeDetailExtract				   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexReceivableDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexReceivableDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexTaxExemptExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexTaxExemptExtract							   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexTaxExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexTaxExtract								   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexTaxRateDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexTaxRateDetailExtract						   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexUpfrontCostDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexUpfrontCostDetailExtract					   WHERE JobStepInstanceId = @JobStepInstanceId;
END
IF OBJECT_ID('NonVertexUpfrontRentalDetailExtract') IS NOT NULL
BEGIN
DELETE FROM NonVertexUpfrontRentalDetailExtract				   WHERE JobStepInstanceId = @JobStepInstanceId;
END

END

GO

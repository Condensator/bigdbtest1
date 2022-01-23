SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ClearSalesTaxReversalExtractTables]
(
	@JobStepInstanceId BIGINT
)
AS
BEGIN
SET NOCOUNT ON

DELETE FROM ReversalReceivableDetail_Extract                       WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalReceivableSKUDetail_Extract					   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalLocationDetail_Extract						   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalCustomerDetail_Extract					       WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalContractDetail_Extract						   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalAssetLocationDetail_Extract					   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalFlexFieldDetail_Extract						   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReversalTaxExemptDetail_Extract						   WHERE JobStepInstanceId = @JobStepInstanceId;
DELETE FROM ReceivableDetailsForReversalProcess_Extract			   WHERE JobStepInstanceId = @JobStepInstanceId;




END

GO

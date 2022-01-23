SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[UpdateCPUContractForBaseChargeGeneration]
(
	@CPUAssetInputParam UpdateCPUAssetBaseReceivablesGeneratedTillDateForBaseChargeGeneration READONLY,
	@CPUScheduleInputParam UpdateCPUScheduleBaseJobRanForCompletionForBaseChargeGeneration READONLY,
	@CPUBaseStructureInputParam UpdateCPUBaseStructureNumberOfPaymentsForBaseChargeGeneration READONLY
)
AS
BEGIN
	
	SET NOCOUNT ON;


	IF EXISTS(SELECT 1 FROM @CPUAssetInputParam)
	BEGIN
		UPDATE	
			CPUAssets
		SET 
			BaseReceivablesGeneratedTillDate = CAIP.BaseReceivablesGeneratedTillDate
		FROM 
			CPUAssets
			JOIN @CPUAssetInputParam CAIP ON CPUAssets.Id = CAIP.Id
	END


	IF EXISTS(SELECT 1 FROM @CPUScheduleInputParam)
	BEGIN
		UPDATE	
			CPUSchedules
		SET 
			BaseJobRanForCompletion = CSIP.BaseJobRanForCompletion
		FROM 
			CPUSchedules
			JOIN @CPUScheduleInputParam CSIP ON CPUSchedules.Id = CSIP.Id
	END


	IF EXISTS(SELECT 1 FROM @CPUBaseStructureInputParam)
	BEGIN
		UPDATE	
			CPUBaseStructures
		SET 
			NumberofPayments = CBSIP.NumberOfPayments
		FROM 
			CPUBaseStructures
			JOIN @CPUBaseStructureInputParam CBSIP ON CPUBaseStructures.Id = CBSIP.Id
	END


	SET NOCOUNT OFF;
END

GO

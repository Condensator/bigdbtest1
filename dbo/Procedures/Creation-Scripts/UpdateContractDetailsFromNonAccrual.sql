SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[UpdateContractDetailsFromNonAccrual] 
(
	@ContractToUpdateForNonAccrual				ContractToUpdateForNonAccrual			READONLY,
	@NonAccrualContractsToUpdate				NonAccrualContractsToUpdate				READONLY,
	@ContractBillingPreferencesToInactivate		ContractBillingPreferencesToInactivate	READONLY,
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;

	SELECT * INTO #ContractToUpdateForNonAccrual FROM @ContractToUpdateForNonAccrual
	SELECT * INTO #NonAccrualContractsToUpdate FROM @NonAccrualContractsToUpdate
	SELECT * INTO #ContractBillingPreferencesToInactivate FROM @ContractBillingPreferencesToInactivate	

	UPDATE Contracts
	SET 
		IsNonAccrual = CI.IsNonAccrual,
		NonAccrualDate = CI.NonAccrualDate,
		ReportStatus = CI.ReportStatus,
		DoubtfulCollectability = CI.DoubtfulCollectability,
		UpdatedTime = @UpdatedTime,
		UpdatedById = @UserId
	FROM Contracts
	JOIN #ContractToUpdateForNonAccrual CI ON CI.Id = Contracts.Id

	IF EXISTS(SELECT TOP 1 Id FROM #NonAccrualContractsToUpdate)
	BEGIN
		UPDATE NonAccrualContracts
		SET 
			IsNonAccrualApproved = NAC.IsNonAccrualApproved,
			PostDate = NAC.PostDate,
			UpdatedTime = @UpdatedTime,
			UpdatedById = @UserId
		FROM NonAccrualContracts
		JOIN #NonAccrualContractsToUpdate NAC ON NAC.Id = NonAccrualContracts.Id
	END

	IF EXISTS(SELECT TOP 1 Id FROM #ContractBillingPreferencesToInactivate)
	BEGIN
		UPDATE ContractBillingPreferences
		SET 
			IsActive = 0,
			UpdatedTime = @UpdatedTime,
			UpdatedById = @UserId
		FROM ContractBillingPreferences
		JOIN #ContractBillingPreferencesToInactivate CBP ON CBP.Id = ContractBillingPreferences.Id
	END
	
	DROP TABLE #ContractToUpdateForNonAccrual
	DROP TABLE #NonAccrualContractsToUpdate
	DROP TABLE #ContractBillingPreferencesToInactivate

END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateDeferredTaxesForAutoPayoff]
(
	@PayoffInputs AutoPayoff_DeferredTaxUpdateInput READONLY,
	@UserId BIGINT,
	@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN

	SELECT DeferredTax.ContractId, Id = DeferredTax.Id, DeferredTax.[Date], DeferredTax.IsReprocess
	INTO #DeferredTaxes
	FROM @PayoffInputs Payoff
	JOIN DeferredTaxes DeferredTax ON Payoff.ContractId = DeferredTax.ContractId
	WHERE DeferredTax.IsScheduled = 1;

	SELECT DISTINCT(Payoff.ContractId)
	INTO #ContractsToIgnore
	FROM @PayoffInputs Payoff
	JOIN #DeferredTaxes DeferredTax ON Payoff.ContractId = DeferredTax.ContractId
	WHERE DeferredTax.IsReprocess = 1 AND DeferredTax.[Date] <= Payoff.PayoffEffectiveDate;

	SELECT 
		DeferredTax.Id,
		DeferredTax.IsReprocess, 
		RowNumber = ROW_NUMBER() OVER (PARTITION BY DeferredTax.ContractId ORDER BY DeferredTax.[Date] ASC)
	INTO #DeferredTaxesSorted
	FROM @PayoffInputs Payoff
	JOIN #DeferredTaxes DeferredTax ON Payoff.ContractId = DeferredTax.ContractId
	LEFT JOIN #ContractsToIgnore ContractToIgnore ON DeferredTax.ContractId = ContractToIgnore.ContractId
	WHERE ContractToIgnore.ContractId IS NULL AND DeferredTax.[Date] > Payoff.PayoffEffectiveDate;

	UPDATE DeferredTaxToUpdate 
	SET 
		IsReprocess = 1, 
		UpdatedById = @UserId, 
		UpdatedTime = @UpdatedTime
	FROM DeferredTaxes DeferredTaxToUpdate
	JOIN #DeferredTaxesSorted DeferredTax ON DeferredTaxToUpdate.Id = DeferredTax.Id
	WHERE DeferredTax.RowNumber = 1 AND DeferredTax.IsReprocess = 0;

	UPDATE DeferredTaxToUpdate 
	SET 
		IsReprocess = 0, 
		UpdatedById = @UserId, 
		UpdatedTime = @UpdatedTime
	FROM DeferredTaxes DeferredTaxToUpdate
	JOIN #DeferredTaxesSorted DeferredTax ON DeferredTaxToUpdate.Id = DeferredTax.Id
	WHERE DeferredTax.RowNumber > 1 AND DeferredTax.IsReprocess = 1;	
END

GO

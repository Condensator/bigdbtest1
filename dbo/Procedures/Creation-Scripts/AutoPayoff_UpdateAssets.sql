SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[AutoPayoff_UpdateAssets]
(
	@Payoffs AssetUpdate_PayoffData READONLY,
	@AssetInputs AssetUpdate_AssetData READONLY,
	@SourceModule NVARCHAR(44),
	@AssetHistoryReason	NVARCHAR(46),
	@AssetStatusInventory NVARCHAR(34),
	@AssetStatusInvestor NVARCHAR(34),
	@UserId	BIGINT,
	@UpdatedTime DATETIMEOFFSET
)  
AS  
BEGIN  
	SET NOCOUNT ON;  

	UPDATE Assets 
	SET [Status] = assetInput.[Status],  
		PreviousSequenceNumber = PayoffInfo.SequenceNumber,  
		CustomerId = CASE WHEN assetInput.[Status] IN (@AssetStatusInventory, @AssetStatusInvestor) THEN assetInput.CustomerId ELSE Assets.CustomerId END,  
		IsOffLease = CASE WHEN assetInput.[Status] IN (@AssetStatusInventory, @AssetStatusInvestor) THEN 1 ELSE Assets.IsOffLease END,  
		IsOnCommencedLease = 0,  
		UpdatedById = @UserId,  
		UpdatedTime = @UpdatedTime  
	FROM Assets
		JOIN @AssetInputs assetInput ON Assets.Id = assetInput.AssetId
		JOIN @Payoffs PayoffInfo ON assetInput.PayoffId = PayoffInfo.PayoffId;

	UPDATE AssetGLDetails 
	SET BookDepreciationGLTemplateId = ISNULL(assetInput.BookDepGLTemplateId, AssetGLDetails.BookDepreciationGLTemplateId),
		UpdatedById = @UserId, 
		UpdatedTime = @UpdatedTime  
	FROM AssetGLDetails  
		JOIN @AssetInputs assetInput ON AssetGLDetails.Id = assetInput.AssetId  
	WHERE assetInput.BookDepGLTemplateId IS NOT NULL;  

	UPDATE AssetLocations  
	SET IsCurrent = 0,  
		UpdatedById = @UserId,  
		UpdatedTime = @UpdatedTime  
	FROM AssetLocations
		JOIN Locations ON AssetLocations.LocationId = Locations.Id  
		JOIN @AssetInputs assetInput ON AssetLocations.AssetId = assetInput.AssetId
	WHERE AssetLocations.IsCurrent = 1  
		AND Locations.CustomerId IS NOT NULL  
		AND (assetInput.CustomerId IS NULL OR Locations.CustomerId <> assetInput.CustomerId);  


	INSERT INTO AssetHistories  
	(
		Reason,
		AsOfDate,
		AcquisitionDate,  
		[Status],  
		FinancialType, 
		SourceModule,  
		SourceModuleId,
		CreatedById, 
		CreatedTime, 
		CustomerId,  
		ParentAssetId,  
		LegalEntityId, 
		AssetId, 
		ContractId,  
		PropertyTaxReportCodeId, 
		IsReversed
	)  
	SELECT  
		@AssetHistoryReason,
		PayoffInfo.PayoffEffectiveDate,  
		Assets.AcquisitionDate, 
		Assets.[Status],  
		Assets.FinancialType,  
		@SourceModule,  
		PayoffInfo.PayoffId,
		@UserId, 
		@UpdatedTime,  
		Assets.CustomerId,  
		Assets.ParentAssetId,  
		Assets.LegalEntityId,  
		Assets.Id,
		CASE WHEN assetInput.[Status] IN (@AssetStatusInventory, @AssetStatusInvestor) THEN NULL ELSE PayoffInfo.ContractId END,  
		Assets.PropertyTaxReportCodeId, 
		0
	FROM Assets  
	JOIN @AssetInputs assetInput ON Assets.Id = assetInput.AssetId  
	JOIN @Payoffs PayoffInfo ON assetInput.PayoffId = PayoffInfo.PayoffId

	UPDATE TaxDepEntities  
	SET IsTaxDepreciationTerminated = 1,
		IsComputationPending = 1,  
		TerminatedByLeaseId = PayoffInfo.ContractId,  
		TaxDepDisposalTemplateId = assetInput.TaxDepDisposalTemplateId,
		TerminationDate = PayoffInfo.PayoffEffectiveDate,
		TaxProceedsAmount_Amount = assetInput.PayOffAmount,  
		TaxProceedsAmount_Currency = PayoffInfo.Currency,  
		UpdatedById = @UserId,  
		UpdatedTime = @UpdatedTime  
	FROM TaxDepEntities TaxDepEntities  
		JOIN @AssetInputs assetInput ON TaxDepEntities.AssetId = assetInput.AssetId
		JOIN @Payoffs PayoffInfo ON assetInput.PayoffId = PayoffInfo.PayoffId  
	WHERE assetInput.IsTaxDepEntityUpdateApplicable = 1; 
  
END

GO

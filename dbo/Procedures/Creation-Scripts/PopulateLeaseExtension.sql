SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[PopulateLeaseExtension]
(
	@EntityType NVARCHAR(30),
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@FilterOption NVARCHAR(10),
	@CustomerId BIGINT,
	@ContractId BIGINT,
	@ProcessThroughDate DATETIMEOFFSET,
	@ProcessThroughDateOption NVARCHAR(30),
	@JobStepInstanceId BIGINT,
	@UnknownHoldingStatus NVARCHAR(10),
	@HFSHoldingStatus NVARCHAR(10),
	@OriginatedHFSHoldingStatus NVARCHAR(20),
	@FullSaleSyndicationType NVARCHAR(20),
	@CommencedBookingStatus NVARCHAR(20),
	@UnknownCapitalizationType NVARCHAR(20),
	@invoiceSensitiveOption NVARCHAR(20),
	@AllFilterOption NVARCHAR(10),
	@OneFilterOption NVARCHAR(10),
	@CustomerEntityType NVARCHAR(15),
	@LeaseEntityType NVARCHAR(15),
	@LegalEntityIds IdList READONLY
)AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF
	DECLARE @True BIT = 1
	DECLARE @False BIT = 0

	;WITH CTE_Leases AS
	(
		SELECT 	
			leaseFinance.Id AS LeaseFinanceId,
			leaseFinance.ContractId,
			leaseFinance.CustomerId,
			leaseFinanceDetail.BillOTPForSoftAssets,
			leaseFinanceDetail.MaturityDate,
			leaseFinanceDetail.LastExtensionARUpdateRunDate,
			leaseFinanceDetail.LastSupplementalARUpdateRunDate,
			leaseFinance.HoldingStatus,
			contract.SyndicationType,
			UpdateThroughDate = CASE WHEN @ProcessThroughDateOption=@invoiceSensitiveOption
									 THEN 
										CASE WHEN contractBilling.InvoiceLeaddays != 0 
											 THEN DATEADD(DAY, contractBilling.InvoiceLeaddays, @ProcessThroughDate)
											 ELSE DATEADD(DAY, customer.InvoiceLeadDays, @ProcessThroughDate)
										END
									ELSE 
										@ProcessThroughDate
								END,
			IsSyndicatedAtInception = CASE WHEN leaseFinance.HoldingStatus = @UnknownHoldingStatus 
										   THEN 1 
										   ELSE 0 
									  END,
			IsFullSale =  CASE WHEN (leaseFinance.HoldingStatus = @HFSHoldingStatus OR leaseFinance.HoldingStatus = @OriginatedHFSHoldingStatus) AND contract.SyndicationType = @FullSaleSyndicationType
							   THEN 1 ELSE 0 END
		FROM 
			LeaseFinanceDetails AS leaseFinanceDetail
			JOIN LeaseFinances AS leaseFinance ON leaseFinanceDetail.Id = leaseFinance.Id
			JOIN Customers AS customer ON leaseFinance.CustomerId = customer.Id
			JOIN Contracts AS contract ON leaseFinance.ContractId = contract.Id
			JOIN ContractBillings AS contractBilling ON leaseFinance.ContractId = contractBilling.Id
			JOIN @LegalEntityIds AS legalEntity ON leaseFinance.LegalEntityId = legalEntity.Id
		WHERE
			leaseFinance.BookingStatus= @CommencedBookingStatus
			AND leaseFinanceDetail.IsOverTermLease=@True
			AND leaseFinance.IsCurrent=@True
			AND (@FilterOption = @AllFilterOption
			OR (@EntityType = @CustomerEntityType AND @FilterOption = @OneFilterOption AND customer.Id = @CustomerId)
			OR (@EntityType = @LeaseEntityType AND @FilterOption = @OneFilterOption AND contract.Id = @ContractId))
	)
		SELECT 
			LeaseFinanceId,
			ContractId,
			CustomerId,
			BillOTPForSoftAssets,
			HoldingStatus,
			SyndicationType,
			MaturityDate,
			UpdateThroughDate,
			IsSyndicatedAtInception,
			IsFullSale
		INTO 
			#PrimaryLeases
		FROM 
			CTE_Leases
		WHERE 
			MaturityDate <= UpdateThroughDate
			AND (LastExtensionARUpdateRunDate IS NULL OR LastExtensionARUpdateRunDate < UpdateThroughDate )
			AND (LastSupplementalARUpdateRunDate IS NULL OR LastSupplementalARUpdateRunDate < UpdateThroughDate)

	/* Exclude Leases which has only soft asset */
	;With CTE_LeaseAsset AS
	(
		SELECT 
			leaseAsset.LeaseFinanceId, 
			Count(leaseAsset.LeaseFinanceId) as LeaseAssetCount
		FROM 
			LeaseAssets AS leaseAsset
		WHERE 
			leaseAsset.IsActive=1
		GROUP BY 
			leaseAsset.LeaseFinanceId
	),
	CTE_LeaseSoftAsset AS
	(
		SELECT 
			leaseAsset.LeaseFinanceId , 
			Count(leaseAsset.LeaseFinanceId) as LeaseSoftAssetCount
		FROM 
			LeaseAssets AS leaseAsset
			JOIN Assets AS asset ON leaseAsset.AssetId = asset.Id
			JOIN AssetTypes AS assetType ON asset.TypeId = assetType.Id
		WHERE 
			leaseAsset.IsActive=1 AND
			assetType.IsSoft = 1 AND 
			leaseAsset.CapitalizationType != @UnknownCapitalizationType
		GROUP BY 
			leaseAsset.LeaseFinanceId
	)

	SELECT 
		Lease.LeaseFinanceId
	INTO 
		#LeaseIdsToBeExcluded
	FROM 
		CTE_LeaseAsset AS LeaseAsset
		JOIN CTE_LeaseSoftAsset AS SoftAsset ON LeaseAsset.LeaseFinanceId = SoftAsset.LeaseFinanceId
		JOIN #PrimaryLeases AS Lease ON LeaseAsset.LeaseFinanceId = Lease.LeaseFinanceId
	WHERE 
		LeaseAsset.LeaseAssetCount = SoftAsset.LeaseSoftAssetCount
		AND Lease.BillOTPForSoftAssets = 0

	/* Exclude Syndicated HFS lease */
	;WITH CTE_HoldingStatusAsOfJobRunPeriod AS
	(
		SELECT 
			LeaseFinanceId
			, ROW_NUMBER() OVER (PARTITION BY contractHoldingStatusHistories.ContractId ORDER BY contractHoldingStatusHistories.HoldingStatusStartDate DESC ,contractHoldingStatusHistories.Id DESC ) AS RowNum
			, contractHoldingStatusHistories.HoldingStatus
		FROM 
			#PrimaryLeases AS lease
			JOIN ContractHoldingStatusHistories AS contractHoldingStatusHistories ON contractHoldingStatusHistories.ContractId = lease.ContractId
		WHERE 
			contractHoldingStatusHistories.IsActive = @True
			AND lease.IsSyndicatedAtInception = @False
			AND lease.IsFullSale = @False
			AND contractHoldingStatusHistories.HoldingStatusStartDate <= lease.MaturityDate
	)

	INSERT INTO 
		#LeaseIdsToBeExcluded
	SELECT 
		lease.LeaseFinanceId
	FROM 
		#PrimaryLeases as lease
		JOIN CTE_HoldingStatusAsOfJobRunPeriod as contractHoldingstatus on lease.LeaseFinanceId = contractHoldingstatus.LeaseFinanceId
	WHERE 
		contractHoldingstatus.RowNum = 1
		AND (contractHoldingstatus.HoldingStatus = @HFSHoldingStatus OR contractHoldingstatus .HoldingStatus = @OriginatedHFSHoldingStatus)
	
	INSERT INTO
		LeaseExtensionJobExtracts
		(
			LeaseFinanceId,
			JobStepInstanceId,
			CreatedById, 
			CreatedTime, 
			IsSubmitted, 
			ContractId,
			ComputedProcessThroughDate
		)
	SELECT
		p.LeaseFinanceId, 
		@JobStepInstanceId, 
		@CreatedById, 
		@CreatedTime, 
		0, 
		p.ContractId, 
		p.UpdateThroughDate
	FROM 
		#PrimaryLeases p
		LEFT JOIN #LeaseIdsToBeExcluded e on p.LeaseFinanceId = e.LeaseFinanceId
	WHERE 
		e.LeaseFinanceId IS NULL

	IF OBJECT_ID('tempDB.#PrimaryLeases') IS NOT NULL
		DROP TABLE #PrimaryLeases

	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
  
CREATE PROCEDURE [dbo].[UpdateReceivableDetailForPayoffAssets]
(  
 @AssetIds AssetIdInfoForRD READONLY,    
 @PayoffEffectiveDate DATE = NULL, 
 @ContractId BIGINT,   
 @PayoffId BIGINT,   
 @ContractTypeCT NVARCHAR(MAX),    
 @PayoffSourceTable NVARCHAR(MAX),     
 @BilledStatusNotInvoiced NVARCHAR(MAX),    
 @CPUScheduleSourceTable NVARCHAR(11),  
 @PayoffStatusInvoiceGeneration NVARCHAR(MAX),    
 @PayoffStatusPending NVARCHAR(MAX),  
 @PayoffStatusSubmittedForFinalApproval NVARCHAR(MAX),  
 @StopInvoicingRentals BIT,    
 @IsPayoffActivation BIT,  
 @UpdatedById BIGINT,  
 @UpdatedTime DATETIMEOFFSET  
)  
WITH RECOMPILE
AS  
BEGIN  
	SET NOCOUNT ON;  
	
	DECLARE @ShouldSetStopInvoicingFromParams BIT = 0 

	IF @StopInvoicingRentals = 1 OR @IsPayoffActivation = 1
	BEGIN
		SET @ShouldSetStopInvoicingFromParams = 1
	END

	CREATE TABLE #SelectedAssets  
	(  
	AssetId BIGINT,  
	LeaseAssetId BIGINT  
	)  
  
	CREATE CLUSTERED INDEX IX_SelectedAssets ON #SelectedAssets (AssetId, LeaseAssetId)  
  
	INSERT INTO #SelectedAssets(AssetId,LeaseAssetId)  
	SELECT AssetId, LeaseAssetId FROM @AssetIds;  
  
	CREATE TABLE #AssetsInOtherQuotes(
	AssetId BIGINT PRIMARY KEY,
	PayoffEffectiveDate DATE
	)

 /* Find PayoffAssets and PayoffEffective date from other PayoffQuotes with StopInvoicingFutureRentals as 1 */  
	INSERT INTO #AssetsInOtherQuotes(AssetId, PayoffEffectiveDate)
	SELECT SelAsset.AssetId, MIN(Payoffs.PayoffEffectiveDate)    
	FROM Payoffs  
	JOIN PayoffAssets ON Payoffs.Id = PayoffAssets.PayoffId AND Payoffs.StopInvoicingFutureRentals = 1 AND PayoffAssets.IsActive = 1  
	JOIN #SelectedAssets SelAsset ON PayoffAssets.LeaseAssetId = SelAsset.LeaseAssetId  
	WHERE Payoffs.Id != @PayoffId         
	AND Payoffs.[Status] IN (@PayoffStatusInvoiceGeneration, @PayoffStatusPending, @PayoffStatusSubmittedForFinalApproval)      
	GROUP BY SelAsset.AssetId;  
  
	CREATE TABLE #ReceivableDetailsToUpdate(
		Id BIGINT,
		ShouldStopInvoicingFromParams BIT NOT NULL,
		ShouldStopInvoicingDueToDateCheck BIT NOT NULL
	)

	CREATE CLUSTERED INDEX IX_DetailInfo ON #ReceivableDetailsToUpdate(Id, ShouldStopInvoicingDueToDateCheck, ShouldStopInvoicingFromParams)

	INSERT INTO #ReceivableDetailsToUpdate(Id, ShouldStopInvoicingFromParams, ShouldStopInvoicingDueToDateCheck)
	SELECT 
		RecDetail.Id, 
		ShouldStopInvoicingFromParams = CASE 
			WHEN @ShouldSetStopInvoicingFromParams = 0 THEN 0
			WHEN @IsPayoffActivation = 1 THEN 1
			WHEN Schedule.StartDate >= @PayoffEffectiveDate THEN 1
			ELSE 0
		END,
		ShouldStopInvoicingDueToDateCheck = CASE
			WHEN OtherQuote.AssetId IS NULL THEN 1
			WHEN (OtherQuote.AssetId IS NOT NULL AND Schedule.StartDate < OtherQuote.PayoffEffectiveDate) THEN 1
			ELSE 0
		END
	FROM #SelectedAssets SelAsset
	JOIN ReceivableDetails RecDetail ON SelAsset.AssetId = RecDetail.AssetId 
		AND RecDetail.BilledStatus = @BilledStatusNotInvoiced  
		AND RecDetail.IsActive = 1  
	JOIN Receivables Receivable ON RecDetail.ReceivableId = Receivable.Id   
		AND Receivable.SourceTable = '_'    
		AND Receivable.IsActive = 1  
	JOIN LeasePaymentSchedules Schedule ON Receivable.PaymentScheduleId = Schedule.Id  
		AND Schedule.IsActive = 1  
	LEFT JOIN #AssetsInOtherQuotes OtherQuote ON SelAsset.AssetId = OtherQuote.AssetId  
	WHERE  
	Receivable.EntityId = @ContractId  
	AND Receivable.EntityType = @ContractTypeCT  
	AND (Receivable.SourceTable IS NULL OR Receivable.SourceTable != @PayoffSourceTable)  
	AND (Receivable.SourceId IS NULL OR Receivable.SourceId != @PayoffId)  
	AND Receivable.SourceTable != @CPUScheduleSourceTable  
  
 /* Set all ReceivableDetails.IsStopInvoicing flag to 0 for schdule due-date prior to min of other-payoff-quote.payoffeffective-date. */  

	UPDATE RD  
	SET StopInvoicing = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime 
	FROM ReceivableDetails RD INNER JOIN #ReceivableDetailsToUpdate R ON RD.Id=R.Id
	WHERE R.ShouldStopInvoicingDueToDateCheck = 1 AND RD.StopInvoicing = 1

	IF @ShouldSetStopInvoicingFromParams = 1  
	BEGIN   	
		DECLARE @TargetStopInvoicing BIT = 1
	
		IF @StopInvoicingRentals = 1
		BEGIN
			SET @TargetStopInvoicing = 0
		END

		UPDATE RD  
		SET StopInvoicing = @StopInvoicingRentals, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime 
		FROM ReceivableDetails RD INNER JOIN #ReceivableDetailsToUpdate R ON RD.Id=R.Id
		WHERE R.ShouldStopInvoicingFromParams = 1 AND RD.StopInvoicing = @TargetStopInvoicing
	END  
   
	DROP TABLE #AssetsInOtherQuotes;  
	DROP TABLE #ReceivableDetailsToUpdate;  
	DROP TABLE #SelectedAssets;    
END

GO

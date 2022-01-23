SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceGenerationSplitNumberIdentifier]
(
	@JobStepInstanceId			BIGINT,
	@ChunkNumber				BIGINT
)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @TotalRows BIGINT = 0

	CREATE TABLE #InvoiceSplitReceivableDetails(
	   ExtractId BIGINT,
	   ReceivableDetailId BIGINT NOT NULL PRIMARY KEY,
	   GroupNumber INT,
	   SplitNumber INT,
	   ContractId BIGINT,
	   LocationId BIGINT,
	   AssetId BIGINT,
	   AdjustmentBasisReceivableDetailId BIGINT NULL,
	   IsAdjustmentReceivable BIT NOT NULL,
	   IsReceivableTypeRental BIT NOT NULL,
	   SplitRentalInvoiceByAsset BIT NOT NULL,
	   SplitCreditsByOriginalInvoice BIT NOT NULL,
	   SplitByReceivableAdjustments BIT NOT NULL,
	   SplitRentalInvoiceByContract BIT NOT NULL,
	   SplitLeaseRentalInvoiceByLocation BIT NOT NULL,
	   SplitReceivableDueDate BIT NOT NULL,
	   SplitCustomerPurchaseOrderNumber BIT NOT NULL,
	   AssetPurchaseOrderNumber NVARCHAR(40),
	   ReceivableDueDate DATE,
	   OriginalInvoiceNumber NVARCHAR(40)
	)

	INSERT INTO #InvoiceSplitReceivableDetails(
	   ExtractId,
	   ReceivableDetailId,
	   GroupNumber,
	   SplitNumber,
	   ContractId,
	   LocationId,
	   AssetId,
	   AdjustmentBasisReceivableDetailId,
	   IsAdjustmentReceivable,
	   IsReceivableTypeRental,
	   SplitRentalInvoiceByAsset,
	   SplitCreditsByOriginalInvoice,
	   SplitByReceivableAdjustments,
	   SplitRentalInvoiceByContract,
	   SplitLeaseRentalInvoiceByLocation,
	   SplitReceivableDueDate,
	   SplitCustomerPurchaseOrderNumber,
	   AssetPurchaseOrderNumber,
	   ReceivableDueDate,
	   OriginalInvoiceNumber
	)
	SELECT
		 IRDE.Id
		,IRDE.ReceivableDetailId
		,IRDE.GroupNumber
		,CAST(0 AS INT)
		,IRDE.ContractId
		,IRDE.LocationId
		,IRDE.AssetId
		,IRDE.AdjustmentBasisReceivableDetailId
		,CASE WHEN IRDE.AdjustmentBasisReceivableDetailId IS NOT NULL THEN 1 ELSE  0 END AS IsAdjustmentReceivable --TODO: Should Move this column in header level?
		,IRDE.IsReceivableTypeRental
		,IRDE.SplitRentalInvoiceByAsset
		,CASE WHEN IRDE.ReceivableTaxType = 'VAT' THEN 1 ELSE IRDE.SplitCreditsByOriginalInvoice END AS SplitCreditsByOriginalInvoice
		,IRDE.SplitByReceivableAdjustments
		,IRDE.SplitRentalInvoiceByContract
		,IRDE.SplitLeaseRentalInvoiceByLocation
		,IRDE.SplitReceivableDueDate
		,IRDE.SplitCustomerPurchaseOrderNumber
		,IRDE.AssetPurchaseOrderNumber
		,IRDE.ReceivableDueDate
		,IRDE.OriginalInvoiceNumber
	FROM InvoiceReceivableDetails_Extract IRDE
	JOIN InvoiceChunkDetails_Extract ICD ON IRDE.BillToId = ICD.BillToId 
		AND IRDE.JobStepInstanceId = ICD.JobStepInstanceId AND ICD.ChunkNumber=@ChunkNumber
	WHERE IRDE.JobStepInstanceId = @JobStepInstanceId AND IRDE.IsActive=1 
	;
	
	SET @TotalRows = @@ROWCOUNT

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberContract
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId, 
			CASE WHEN SplitRentalInvoiceByContract = 1 THEN 
				RANK() OVER (ORDER BY GroupNumber, ContractId) 
			ELSE 
				SplitNumber 
		     END AS SplitNumberContract
		FROM #InvoiceSplitReceivableDetails
     ) SP ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	;

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberRecDueDate
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId,
			CASE WHEN SplitReceivableDueDate = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, ReceivableDueDate)
			ELSE	
				SplitNumber
			END AS SplitNumberRecDueDate
		FROM #InvoiceSplitReceivableDetails
	 ) SP
	 ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	 ;

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberPO
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId,
			CASE WHEN SplitCustomerPurchaseOrderNumber = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, AssetPurchaseOrderNumber)
			ELSE	
				SplitNumber
			END AS SplitNumberPO
		FROM #InvoiceSplitReceivableDetails
	 ) SP
	 ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	 ;

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberLocation
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId,
			CASE WHEN IsReceivableTypeRental = 1 AND SplitLeaseRentalinvoiceByLocation = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, LocationId)
			ELSE	
				SplitNumber
			END AS SplitNumberLocation
		FROM #InvoiceSplitReceivableDetails
	 ) SP
	 ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	;

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberAsset
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId,
			CASE WHEN IsReceivableTypeRental = 1 AND SplitRentalInvoiceByAsset = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, AssetId)
			ELSE	
				SplitNumber
			END AS SplitNumberAsset
		FROM #InvoiceSplitReceivableDetails
	 ) SP
	 ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	 ;

	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = SP.SplitNumberAdj
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN (
		SELECT 
			ReceivableDetailId,
			CASE WHEN SplitByReceivableAdjustments = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, IsAdjustmentReceivable)
			ELSE	
				SplitNumber
			END AS SplitNumberAdj
		FROM #InvoiceSplitReceivableDetails
	 ) SP
	 ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	 ;

	 ;WITH CTE AS(
	     SELECT 
			I.ReceivableDetailId,
			CASE WHEN I.SplitCreditsByOriginalInvoice = 1 THEN 
				RANK() OVER (ORDER BY SplitNumber, RI.Id)
			ELSE	
				SplitNumber
			END AS SplitNumberCreditOrgInv,
			RI.Number AS OriginalInvoiceNumber
		FROM #InvoiceSplitReceivableDetails I
		INNER JOIN ReceivableInvoiceDetails RIDS ON RIDS.ReceivableDetailId = I.AdjustmentBasisReceivableDetailId AND RIDS.IsActive=1
		INNER JOIN ReceivableInvoices RI ON RI.Id = RIDS.ReceivableInvoiceId AND RI.IsActive=1 --TODO: Make Heavy Joins not a part of CTE but, as a part of the IRD table itself
	 )
	UPDATE #InvoiceSplitReceivableDetails
		SET SplitNumber = CASE WHEN ISD.SplitCreditsByOriginalInvoice =1 
							   THEN @TotalRows + ISD.SplitNumber + SP.SplitNumberCreditOrgInv
							   ELSE ISD.SplitNumber
						  END,
			OriginalInvoiceNumber = SP.OriginalInvoiceNumber
	FROM #InvoiceSplitReceivableDetails ISD
	JOIN CTE SP ON ISD.ReceivableDetailId = SP.ReceivableDetailId
	 ;
	 
	 CREATE TABLE #ExtractUpdates(
	   ExtractId BIGINT PRIMARY KEY,
	   SplitNumber INT,
	   OriginalInvoiceNumber NVARCHAR(40)
	 )

	 INSERT INTO #ExtractUpdates(ExtractId, SplitNumber,OriginalInvoiceNumber)
	 SELECT ExtractId, SplitNumber,OriginalInvoiceNumber FROM #InvoiceSplitReceivableDetails
	 WHERE SplitNumber!=0

	UPDATE IRD
		SET SplitNumber = ISD.SplitNumber,OriginalInvoiceNumber=ISD.OriginalInvoiceNumber
	FROM InvoiceReceivableDetails_Extract IRD
	JOIN #ExtractUpdates ISD ON IRD.Id = ISD.ExtractId
	
	DROP TABLE #InvoiceSplitReceivableDetails
	DROP TABLE #ExtractUpdates
END

GO

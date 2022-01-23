SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[InvoiceGenerationFunderOwnedReceivableClearing]
(
	@ChunkNumber				BIGINT,
	@JobStepInstanceId			BIGINT,
	@CreatedById				BIGINT,
	@CreatedTime				DATETIMEOFFSET
)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @True AS BIT = CONVERT(BIT, 1)
	DECLARE @False AS BIT = CONVERT(BIT, 0)
	
	CREATE TABLE #InvoiceFunderReceivableDetails(
		ReceivableId BIGINT,
		ReceivableDetailId BIGINT PRIMARY KEY,
		IsDiscountingProceeds BIT NOT NULL
	)

	CREATE NONCLUSTERED INDEX IX_ReceivableDR ON  #InvoiceFunderReceivableDetails(ReceivableId) INCLUDE (IsDiscountingProceeds)

	INSERT INTO #InvoiceFunderReceivableDetails(ReceivableId, ReceivableDetailId, IsDiscountingProceeds)
	SELECT 
		IRDE.ReceivableId,
		IRDE.ReceivableDetailId,
		IRDE.IsDiscountingProceeds
	FROM InvoiceReceivableDetails_Extract IRDE
	INNER JOIN InvoiceChunkDetails_Extract ICD ON IRDE.BillToId = ICD.BillToId 
		AND IRDE.JobStepInstanceId = ICD.JobStepInstanceId AND ICD.ChunkNumber = @ChunkNumber
	WHERE IRDE.JobStepInstanceId = @JobStepInstanceId AND IRDE.IsActive = 1
		AND (IRDE.IsFunderOwnedReceivable = 1 OR IRDE.IsDiscountingProceeds = 1)
	;

	CREATE TABLE #InvoiceFunderReceivableTaxDetails(
		ReceivableTaxDetailId BIGINT PRIMARY KEY
	)

	INSERT INTO #InvoiceFunderReceivableTaxDetails(ReceivableTaxDetailId)
	SELECT 
		RTD.Id ReceivableTaxDetailId
	FROM #InvoiceFunderReceivableDetails IRDE
	INNER JOIN ReceivableTaxDetails RTD ON IRDE.ReceivableDetailId = RTD.ReceivableDetailId
		AND RTD.IsActive = 1
	;

	UPDATE Receivables
	SET TotalBalance_Amount = 0
		,TotalEffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableDetails FR 
	JOIN Receivables R ON R.Id = FR.ReceivableId AND FR.IsDiscountingProceeds = 0

	UPDATE ReceivableWithholdingTaxDetails
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableDetails FR 
	JOIN ReceivableWithholdingTaxDetails RWHTD ON RWHTD.ReceivableId = FR.ReceivableId AND RWHTD.IsActive=1 AND FR.IsDiscountingProceeds = 0

	UPDATE RD
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
		,LeaseComponentBalance_Amount = 0
		,NonLeaseComponentBalance_Amount = 0
	FROM #InvoiceFunderReceivableDetails FR
	JOIN ReceivableDetails RD ON RD.Id = FR.ReceivableDetailId AND FR.IsDiscountingProceeds = 0

	UPDATE RDWD
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableDetails FR
	JOIN ReceivableDetailsWithholdingTaxDetails RDWD ON RDWD.ReceivableDetailId = FR.ReceivableDetailId AND RDWD.IsActive=1 AND FR.IsDiscountingProceeds = 0

	UPDATE RT
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableDetails FR
	JOIN ReceivableTaxes RT ON RT.ReceivableId = FR.ReceivableId

	UPDATE RTD
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableTaxDetails FR
	JOIN ReceivableTaxDetails RTD ON RTD.Id = FR.ReceivableTaxDetailId

	UPDATE RTI
	SET Balance_Amount = 0
		,EffectiveBalance_Amount = 0
		,UpdatedById = @CreatedById
		,UpdatedTime = @CreatedTime
	FROM #InvoiceFunderReceivableTaxDetails FR
	JOIN ReceivableTaxDetails RTD ON FR.ReceivableTaxDetailId = RTD.Id
	JOIN ReceivableTaxImpositions RTI ON RTD.Id = RTI.ReceivableTaxDetailId

END

GO

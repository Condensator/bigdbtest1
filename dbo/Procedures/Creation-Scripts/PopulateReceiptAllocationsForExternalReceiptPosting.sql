SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateReceiptAllocationsForExternalReceiptPosting]
(
	@JobStepInstanceId									BIGINT, 
	@UserId												BIGINT,
	@AllowCashPostingAcrossCustomers					BIT,
	@ReceiptEntityTypeValues_Customer					NVARCHAR(20),
	@ReceiptEntityTypeValues_Lease						NVARCHAR(20),
	@ReceiptEntityTypeValues_Loan						NVARCHAR(20),
	@ReceiptEntityTypeValues_LeveragedLease				NVARCHAR(20),
	@ReceiptEntityTypeValues_Unknown					NVARCHAR(20),
	@ReceiptAllocationEntityTypeValues_Lease			NVARCHAR(20),
	@ReceiptAllocationEntityTypeValues_Loan				NVARCHAR(20),
	@ReceiptAllocationEntityTypeValues_LeveragedLease	NVARCHAR(20),
	@ReceiptAllocationEntityTypeValues_UnAllocated		NVARCHAR(20),
	@ReceiptClassificationValues_NonAccrualNonDSL		NVARCHAR(20),
	@ReceiptClassificationValues_NonAccrualNonDSLNonCash		NVARCHAR(30)
)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		Id,ReceiptId, ReceiptAmount, LegalEntityId, ContractId, DumpId, JobStepInstanceId, EntityType 
	INTO #CustomerReceipts_Extract
	FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId
	AND IsValid = 1
	
	SELECT DISTINCT ReceiptId 
	INTO #ReceiptsWithApplication
	FROM ReceiptApplicationReceivableDetails_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId
	
	INSERT INTO ReceiptAllocations_Extract
	(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
	SELECT
		RE.ReceiptId
		,CASE
			WHEN RWA.ReceiptId IS NULL THEN @ReceiptAllocationEntityTypeValues_UnAllocated
			ELSE @ReceiptEntityTypeValues_Customer
		 END
		,SUM(RE.ReceiptAmount)
		,@JobStepInstanceId
		,RE.LegalEntityId
		,NULL
		,0
		,@UserId
		,GETDATE()
	FROM #CustomerReceipts_Extract RE 
	LEFT JOIN #ReceiptsWithApplication RWA ON RWA.ReceiptId = RE.ReceiptId
	WHERE RE.JobStepInstanceId = @JobStepInstanceId

	GROUP BY		 
		 RE.ReceiptId
		,RE.LegalEntityId
		,RE.ContractId
		,RE.EntityType
		,RWA.ReceiptId
	;


END

GO

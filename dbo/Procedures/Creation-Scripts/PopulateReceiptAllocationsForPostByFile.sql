SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateReceiptAllocationsForPostByFile] 
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
		ReceiptId, ReceiptAmount, LegalEntityId, ContractId, DumpId, JobStepInstanceId, EntityType 
	INTO #CustomerReceipts_Extract
	FROM Receipts_Extract WHERE JobStepInstanceId = @JobStepInstanceId
	AND EntityType = @ReceiptEntityTypeValues_Customer
	AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSL
	AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSLNonCash
	;

	INSERT INTO ReceiptAllocations_Extract
	(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, InvoiceId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
	SELECT
		RE.ReceiptId
		,RPBF.EntityType
		,RPBF.ReceiptAmount
		,@JobStepInstanceId
		,RE.LegalEntityId
		,RPBF.ComputedContractId
		,RPBF.ComputedReceivableInvoiceId
		,RPBF.IsStatementInvoice
		,@UserId
		,GETDATE()
	FROM #CustomerReceipts_Extract RE 
	JOIN ReceiptPostByFileExcel_Extract RPBF ON RE.JobStepInstanceId = RPBF.JobStepInstanceId
		AND RE.DumpId = RPBF.GroupNumber
	WHERE RE.JobStepInstanceId = @JobStepInstanceId
	AND (RPBF.EntityType = @ReceiptEntityTypeValues_Lease OR RPBF.EntityType = @ReceiptEntityTypeValues_Loan)
	;

	INSERT INTO ReceiptAllocations_Extract
	(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
	SELECT
		RE.ReceiptId
		,CASE WHEN @AllowCashPostingAcrossCustomers = 1 THEN @ReceiptAllocationEntityTypeValues_UnAllocated
			  WHEN RE.EntityType = @ReceiptEntityTypeValues_LeveragedLease THEN @ReceiptAllocationEntityTypeValues_LeveragedLease
					ELSE @ReceiptAllocationEntityTypeValues_UnAllocated
			END
		,SUM(RPBF.ReceiptAmount)
		,@JobStepInstanceId
		,RE.LegalEntityId
		,CASE WHEN @AllowCashPostingAcrossCustomers = 1 THEN  NULL ELSE RE.ContractId END
		,0
		,@UserId
		,GETDATE()
	FROM #CustomerReceipts_Extract RE 
	JOIN ReceiptPostByFileExcel_Extract RPBF ON RE.JobStepInstanceId = RPBF.JobStepInstanceId
		AND RE.DumpId = RPBF.GroupNumber
	WHERE RE.JobStepInstanceId = @JobStepInstanceId
	AND RPBF.EntityType <> @ReceiptEntityTypeValues_Lease AND RPBF.EntityType <> @ReceiptEntityTypeValues_Loan
	GROUP BY
		RE.ReceiptId
		,RE.LegalEntityId
		,RE.ContractId
		,RE.EntityType
	;

	INSERT INTO ReceiptAllocations_Extract
	(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
	SELECT
		ReceiptId
		,CASE 
			WHEN @AllowCashPostingAcrossCustomers = 1  OR Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Customer OR 
				Receipts_Extract.EntityType = @ReceiptAllocationEntityTypeValues_UnAllocated THEN
					@ReceiptAllocationEntityTypeValues_UnAllocated
				WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Lease THEN @ReceiptAllocationEntityTypeValues_Lease
				WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Loan THEN @ReceiptAllocationEntityTypeValues_Loan
				WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_LeveragedLease THEN @ReceiptAllocationEntityTypeValues_LeveragedLease
				ELSE @ReceiptAllocationEntityTypeValues_UnAllocated
			END
		,ReceiptAmount
		,@JobStepInstanceId
		,LegalEntityId
		, CASE WHEN (@AllowCashPostingAcrossCustomers = 1  OR Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Customer OR 
				Receipts_Extract.EntityType = @ReceiptAllocationEntityTypeValues_UnAllocated) THEN NULL ELSE ContractId END
		,0
		,@UserId
		,GETDATE()
	FROM Receipts_Extract
	WHERE JobStepInstanceId = @JobStepInstanceId
	AND EntityType <> @ReceiptEntityTypeValues_Customer
	AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSL 
	AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSLNonCash

END

GO

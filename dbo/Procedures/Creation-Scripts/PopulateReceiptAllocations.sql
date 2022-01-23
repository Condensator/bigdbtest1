SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateReceiptAllocations] 
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

	IF(@AllowCashPostingAcrossCustomers = 1)
		INSERT INTO ReceiptAllocations_Extract
		(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
		SELECT
			ReceiptId
			,@ReceiptAllocationEntityTypeValues_UnAllocated
			,ReceiptAmount --credit applied from receiptapp calculated from code
			,@JobStepInstanceId
			,LegalEntityId
			,NULL
			,0
			,@UserId
			,GETDATE()
		FROM Receipts_Extract
		WHERE JobStepInstanceId = @JobStepInstanceId
		AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSL 
		AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSLNonCash

	ELSE
		INSERT INTO ReceiptAllocations_Extract
		(ReceiptId, EntityType, AllocationAmount, JobStepInstanceId, LegalEntityId, ContractId, IsStatementInvoiceCalculationRequired, CreatedById, CreatedTime)
		SELECT
			ReceiptId
			,CASE 
				WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Customer OR Receipts_Extract.EntityType = '_' THEN
						@ReceiptAllocationEntityTypeValues_UnAllocated
					WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Lease THEN @ReceiptAllocationEntityTypeValues_Lease
					WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Loan THEN @ReceiptAllocationEntityTypeValues_Loan
					WHEN Receipts_Extract.EntityType = @ReceiptEntityTypeValues_LeveragedLease THEN @ReceiptAllocationEntityTypeValues_LeveragedLease
					ELSE @ReceiptAllocationEntityTypeValues_UnAllocated
				END
			,ReceiptAmount --credit applied from receiptapp calculated from code
			,@JobStepInstanceId
			,LegalEntityId
			,CASE
				WHEN  (Receipts_Extract.EntityType = @ReceiptEntityTypeValues_Customer OR Receipts_Extract.EntityType = '_' ) THEN NULL
				ELSE  ContractId END
			,0
			,@UserId
			,GETDATE()
		FROM Receipts_Extract
		WHERE JobStepInstanceId = @JobStepInstanceId
		AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSL 
		AND ReceiptClassification <> @ReceiptClassificationValues_NonAccrualNonDSLNonCash
END

GO

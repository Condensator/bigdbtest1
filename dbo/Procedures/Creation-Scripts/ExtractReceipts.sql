SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[ExtractReceipts]
(
	@ReceiptId BIGINT,
	@ReceiptApplicationId BIGINT, 
	@JobStepInstanceId BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIME,
	@ReceiptAllocationEntityTypeValues_UnAllocated NVARCHAR(20),
	@ReceivableEntityTypeValues_CT NVARCHAR(20),
	@ReceivableEntityTypeValues_DT NVARCHAR(20),
	@IsReversal BIT = 0
)
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON

	DECLARE @SecurityDepositGLTemplate BIGINT = 
        (SELECT TOP 1 RC.GLTemplateId 
		FROM SecurityDepositApplications SDA 
        INNER JOIN SecurityDeposits SD ON SDA.SecurityDepositId = SD.Id
        INNER JOIN ReceivableCodes RC ON SD.ReceivableCodeId = RC.Id
		AND SDA.ReceiptId = @ReceiptId);

	INSERT INTO Receipts_Extract
	(
		ReceiptId, ReceiptNumber, Currency, PostDate, ReceivedDate, ReceiptClassification, LegalEntityId, ReceiptBatchId, IsValid, JobStepInstanceId, 
		CreatedById, CreatedTime, LineOfBusinessId, CostCenterId,InstrumentTypeId,BranchId, ContractId, DiscountingId, EntityType, ReceiptGLTemplateId, 
		CustomerId, ReceiptAmount,BankAccountId,ReceiptApplicationId,UnallocatedDescription,CurrencyId, IsNewReceipt,ReceiptType, SecurityDepositGLTemplateId, PPTEscrowGLTemplateId, SecurityDepositLiabilityAmount, SecurityDepositLiabilityContractAmount)
	SELECT 
	
		r.Id
		,r.Number
		,ReceiptAmount_Currency
		, CASE WHEN @IsReversal = 0 THEN ra.PostDate ELSE r.ReversalPostDate END 
		,ReceivedDate
		,ReceiptClassification
		,r.LegalEntityId
		,ReceiptBatchId
		,CAST(1 AS BIT)
		,@JobStepInstanceId
		,@CreatedById
		,@CreatedTime
		,LineOfBusinessId
		,CostCenterId
		,InstrumentTypeId
		,BranchId
		,r.ContractId
		,DiscountingId
		,r.EntityType
		,ReceiptGLTemplateId
		,CustomerId
		,r.ReceiptAmount_Amount
		,BankAccountId
		,ra.Id
		,ral.[Description]
		,CurrencyId
		,CAST(0 AS BIT)
		,rt.ReceiptTypeName
        ,@SecurityDepositGLTemplate
        ,r.EscrowGLTemplateId
        ,r.SecurityDepositLiabilityAmount_Amount
        ,r.SecurityDepositLiabilityContractAmount_Amount
	FROM Receipts r
	JOIN ReceiptApplications ra ON r.Id = ra.ReceiptId
    JOIN ReceiptTypes rt ON r.TypeId = rt.Id
	LEFT JOIN ReceiptAllocations ral ON R.Id = ral.ReceiptId AND ral.IsActive = 1
		AND ral.EntityType = @ReceiptAllocationEntityTypeValues_UnAllocated
	WHERE r.Id = @ReceiptId AND (RA.Id = @ReceiptApplicationId)
	;

	CREATE TABLE #ReceivablePreviousApplied
	(
		ReceiptId					BIGINT,
		ReceivableDetailId			BIGINT,
		ReceiptApplicationId		BIGINT,
		PrepaidAmount_Amount		DECIMAL(16, 2),
		LeaseComponentPrepaidAmount_Amount		DECIMAL(16, 2),
		NonLeaseComponentPrepaidAmount_Amount		DECIMAL(16, 2),
		PrepaidTaxAmount_Amount		DECIMAL(16, 2)
	)

	IF(@IsReversal = 1)
		INSERT INTO #ReceivablePreviousApplied
		SELECT
				RA.ReceiptId
			,RARD.ReceivableDetailId
			,RARD.ReceiptApplicationId
			,CAST(SUM(RARD.PrepaidAmount_Amount)  AS DECIMAL(16, 2)) PrepaidAmount_Amount
			,CAST(SUM(RARD.LeaseComponentPrepaidAmount_Amount)  AS DECIMAL(16, 2)) LeaseComponentPrepaidAmount_Amount
			,CAST(SUM(RARD.NonLeaseComponentPrepaidAmount_Amount)  AS DECIMAL(16, 2)) NonLeaseComponentPrepaidAmount_Amount
			,CAST(SUM(RARD.PrepaidTaxAmount_Amount)  AS DECIMAL(16, 2)) PrepaidTaxAmount_Amount
		FROM Receipts R
		INNER JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId
		INNER JOIN ReceiptApplicationReceivableDetails RARD ON R.Id = @ReceiptId 
			AND RA.Id =  RARD.ReceiptApplicationId AND RARD.IsActive = 1
		WHERE (RARD.PrepaidAmount_Amount <> 0.00 OR RARD.PrepaidTaxAmount_Amount <> 0.00)
		GROUP BY
				RA.ReceiptId
			,RARD.ReceiptApplicationId
			,RARD.ReceivableDetailId
	ELSE
		INSERT INTO #ReceivablePreviousApplied
		SELECT
			 RA.ReceiptId
			,RARD.ReceivableDetailId
			,@ReceiptApplicationId
			,CAST(SUM(RARD.PrepaidAmount_Amount) AS DECIMAL(16, 2)) PrepaidAmount_Amount
			,CAST(SUM(RARD.LeaseComponentPrepaidAmount_Amount)  AS DECIMAL(16, 2)) LeaseComponentPrepaidAmount_Amount
			,CAST(SUM(RARD.NonLeaseComponentPrepaidAmount_Amount)  AS DECIMAL(16, 2)) NonLeaseComponentPrepaidAmount_Amount
			,CAST(SUM(RARD.PrepaidTaxAmount_Amount) AS DECIMAL(16, 2)) PrepaidTaxAmount_Amount
		FROM Receipts R
		INNER JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId
		INNER JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId
		WHERE R.Id = @ReceiptId AND RA.Id <> @ReceiptApplicationId AND RARD.IsActive = 1
		GROUP BY
			 RA.ReceiptId
			,RARD.ReceivableDetailId
	;

	INSERT INTO dbo.ReceiptApplicationReceivableDetails_Extract
	(
		ReceiptId, AmountApplied, TaxApplied, BookAmountApplied, ReceivableDetailId, JobStepInstanceId, 
		ReceivableDetailIsActive, InvoiceId, ContractId, DiscountingId, CreatedById, CreatedTime, 
		ReceivableId, ReceiptApplicationReceivableDetailId, PrevAmountAppliedForReApplication, 
		PrevBookAmountAppliedForReApplication, PrevTaxAppliedForReApplication, PrevAdjustedWithHoldingTaxForReApplication, ReceiptApplicationId,
		PrevPrePaidForReApplication, PrevPrePaidTaxForReApplication, IsReApplication, AdjustedWithHoldingTax,
		LeaseComponentAmountApplied,NonLeaseComponentAmountApplied,PrevLeaseComponentAmountAppliedForReApplication,PrevNonLeaseComponentAmountAppliedForReApplication
		,PrevPrePaidLeaseComponentForReApplication,PrevPrePaidNonLeaseComponentForReApplication, WithHoldingTaxBookAmountApplied)
	SELECT 		
		ra.ReceiptId
		,RARD.AmountApplied_Amount
		,RARD.TaxApplied_Amount
		,rard.BookAmountApplied_Amount
		,rard.ReceivableDetailId
		,@JobStepInstanceId
		,rd.IsActive
		,RID.ReceivableInvoiceId
		,CASE WHEN r.EntityType = @ReceivableEntityTypeValues_CT THEN r.EntityId ELSE NULL END AS ContractId
		,CASE WHEN r.EntityType = @ReceivableEntityTypeValues_DT THEN r.EntityId ELSE NULL END AS DiscountingId
		,@CreatedById
		,@CreatedTime
		,RD.ReceivableId
		,rard.Id
		,CASE WHEN rard.IsReApplication = 1 AND @IsReversal = 0 THEN 
				rard.PreviousAmountApplied_Amount 
			  ELSE 0 END 
		,CASE WHEN rard.IsReApplication = 1 AND @IsReversal = 0 THEN 
				rard.PreviousBookAmountApplied_Amount 
				ELSE 0 END 
		,CASE WHEN rard.IsReApplication = 1 AND @IsReversal = 0 THEN 
				rard.PreviousTaxApplied_Amount 
			  ELSE 0 END 
		,CASE WHEN rard.IsReApplication = 1 AND @IsReversal = 0 THEN 
				rard.PreviousAdjustedWithHoldingTax_Amount 
			  ELSE 0 END
		,ra.Id
		,CASE WHEN rard.IsReApplication = 1 OR @IsReversal = 1
			THEN PA.PrepaidAmount_Amount 
		 ELSE NULL END 
		,CASE WHEN rard.IsReApplication = 1 OR @IsReversal = 1
			THEN PA.PrepaidTaxAmount_Amount 
		 ELSE NULL END
		,rard.IsReApplication
		,rard.AdjustedWithholdingTax_Amount
		,RARD.LeaseComponentAmountApplied_Amount
		,RARD.NonLeaseComponentAmountApplied_Amount
		,CASE WHEN RARD.IsReApplication = 1 AND @IsReversal = 0 THEN 
				RARD.PrevLeaseComponentAmountApplied_Amount 
			  ELSE 0 END 
		,CASE WHEN RARD.IsReApplication = 1 AND @IsReversal = 0 THEN 
				RARD.PrevNonLeaseComponentAmountApplied_Amount 
				ELSE 0 END 
        ,CASE WHEN rard.IsReApplication = 1 OR @IsReversal = 1
			THEN PA.LeaseComponentPrepaidAmount_Amount 
		 ELSE NULL END 
		 ,CASE WHEN rard.IsReApplication = 1 OR @IsReversal = 1
			THEN PA.NonLeaseComponentPrepaidAmount_Amount 
		 ELSE NULL END 
		,rard.WithHoldingTaxBookAmountApplied_Amount
	FROM ReceiptApplicationReceivableDetails rard
	JOIN ReceiptApplications ra ON rard.ReceiptApplicationId = ra.Id AND ra.ReceiptId = @ReceiptId
	JOIN ReceivableDetails rd ON rard.ReceivableDetailId = rd.Id AND rd.IsActive = 1
	JOIN Receivables r ON rd.ReceivableId = r.Id AND r.IsActive = 1
	LEFT JOIN ReceivableInvoiceDetails RID ON rd.Id = RID.ReceivableDetailId AND RID.IsActive = 1
	LEFT JOIN ReceivableInvoices RI ON RID.ReceivableInvoiceId = RI.Id AND RI.IsActive = 1
	LEFT JOIN #ReceivablePreviousApplied PA ON PA.ReceivableDetailId = RARD.ReceivableDetailId AND RA.ReceiptId = PA.ReceiptId
		AND PA.ReceiptApplicationId = RARD.ReceiptApplicationId
	WHERE rard.IsActive = 1 AND (ra.Id = @ReceiptApplicationId OR @IsReversal = 1) AND (RI.Id IS NULL OR RI.IsDummy = 0) 

	INSERT INTO UnappliedReceipts_Extract ([ReceiptId],[Currency],[BankAccountId],[CreatedById],[CreatedTime],[CurrentAmountApplied],[AllocationReceiptId],[OriginalReceiptBalance],[ReceiptAllocationId],
		[OriginalAllocationAmountApplied],[EntityType],[ContractId],[DiscountingId],[CustomerId],[LegalEntityId],[LineOfBusinessId],[CostCenterId],
		[InstrumentTypeId],[BranchId],[ContractLegalEntityId],[AcquisitionId],[DealProductTypeId],[ReceiptGLTemplateId],[JobStepInstanceId])
    SELECT 
            @ReceiptId [ReceiptId],
            AR.ReceiptAmount_Currency [Currency],
            AR.BankAccountId [BankAccountId],
            @CreatedById [CreatedById],
            @CreatedTime [CreatedTime],
            UR.AmountApplied_Amount [CurrentAmountApplied],
            RA.ReceiptId [AllocationReceiptId],
            AR.Balance_Amount [OriginalReceiptBalance],
            RA.Id [ReceiptAllocationId],
            RA.AmountApplied_Amount [OriginalAllocationAmountApplied],
            AR.EntityType [EntityType],
            AR.[ContractId],
            AR.[DiscountingId],
            AR.[CustomerId],
            AR.[LegalEntityId],
            AR.[LineOfBusinessId],
            AR.[CostCenterId],
            AR.[InstrumentTypeId],
            AR.[BranchId],
            CASE WHEN Lease.Id IS NOT NULL THEN Lease.LegalEntityId
                    WHEN Loan.Id IS NOT NULL THEN Loan.LegalEntityId
                    WHEN LevLease.Id IS NOT NULL THEN LevLease.LegalEntityId
                    ELSE NULL END [ContractLegalEntityId],
            CASE WHEN Lease.Id IS NOT NULL THEN Lease.[AcquisitionId]
                    WHEN Loan.Id IS NOT NULL THEN Loan.[AcquisitionId]
                    WHEN LevLease.Id IS NOT NULL THEN LevLease.[AcquisitionId]
                    ELSE NULL END [AcquisitionId],
            C.[DealProductTypeId],
            AR.[ReceiptGLTemplateId],
            @JobStepInstanceId
    FROM UnappliedReceipts UR 
    JOIN ReceiptAllocations RA ON UR.ReceiptAllocationId = RA.Id AND RA.IsActive = 1
    JOIN Receipts AR ON RA.ReceiptId = AR.Id
    LEFT JOIN Contracts C ON AR.ContractId = C.Id
    LEFT JOIN LeaseFinances Lease ON C.Id = Lease.ContractId AND Lease.IsCurrent = 1
    LEFT JOIN LoanFinances Loan ON C.Id = Loan.ContractId AND Loan.IsCurrent = 1
    LEFT JOIN LeveragedLeases LevLease ON C.Id = LevLease.ContractId AND LevLease.IsCurrent = 1
    LEFT JOIN DiscountingFinances DF ON AR.DiscountingId = DF.DiscountingId AND DF.IsCurrent = 1
	WHERE UR.ReceiptId = @ReceiptId
	AND UR.IsActive = 1	
END

GO

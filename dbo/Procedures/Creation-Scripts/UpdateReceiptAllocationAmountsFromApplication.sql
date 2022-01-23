SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateReceiptAllocationAmountsFromApplication]
(
	@ReceiptId							BIGINT,
	@ReceivableEntityTypeValues_CT		NVARCHAR(5),
	@ReceiptStatusValues_Approved		NVARCHAR(10),
	@CreditAppliedAmount				DECIMAL(16, 2),
	@AllocationEntityType_Unallocated	NVARCHAR(14),
	@CashTypeId							BIGINT,
	@UpdatedById						BIGINT,
	@UpdatedTime						DATETIMEOFFSET
)
AS
BEGIN
	SET NOCOUNT ON;
	
	-- Allocation AmountApplied should be updated to 0 if no amount is refunded (UnallocatedRefundDetails.ReceiptAllocationId - UnallocatedRefund.Status = 'Approved')
	SELECT 
		URD.ReceiptAllocationId,
		URD.AmountToBeCleared_Amount
	INTO #ApprovedReceiptUnallocatedRefundDetails
	FROM ReceiptAllocations RA
		INNER JOIN UnallocatedRefundDetails URD ON RA.Id = URD.ReceiptAllocationId
		INNER JOIN UnallocatedRefunds UR ON URD.UnallocatedRefundId = UR.Id AND UR.Status = @ReceiptStatusValues_Approved
	WHERE RA.ReceiptId = @ReceiptId AND RA.IsActive = 1
	
	UPDATE RA
	SET
		AmountApplied_Amount = A.AmountApplied
	FROM ReceiptAllocations RA
	JOIN ( 
			SELECT 
				RA.Id ReceiptAllocationId, 
				ISNULL(SUM(URD.AmountToBeCleared_Amount), 0) AS AmountApplied  
			FROM ReceiptAllocations RA
				LEFT JOIN #ApprovedReceiptUnallocatedRefundDetails URD ON RA.Id = URD.ReceiptAllocationId
			WHERE RA.ReceiptId = @ReceiptId AND RA.IsActive = 1 
			GROUP BY RA.Id
		 ) A ON RA.Id = A.ReceiptAllocationId

	-- Allocation AmountApplied should be updated to 0 if no amount is applied in unappliedReceipts
	SELECT 
		UR.ReceiptAllocationId, 
		UR.AmountApplied_Amount
	INTO #UnAppliedApprovedReceipts
	FROM ReceiptAllocations RA
		INNER JOIN UnappliedReceipts UR ON RA.Id = UR.ReceiptAllocationId AND UR.IsActive = 1 
		INNER JOIN Receipts R ON UR.ReceiptId = R.Id AND R.Status = @ReceiptStatusValues_Approved
	WHERE RA.ReceiptId = @ReceiptId AND RA.IsActive = 1
	
	UPDATE RA
	SET
		AmountApplied_Amount = AmountApplied_Amount + A.AmountApplied
	FROM ReceiptAllocations RA
	JOIN ( 
			SELECT 
				RA.Id ReceiptAllocationId, 
				ISNULL(SUM(UR.AmountApplied_Amount), 0) AS AmountApplied
			FROM ReceiptAllocations RA
				LEFT JOIN #UnAppliedApprovedReceipts UR ON RA.Id = UR.ReceiptAllocationId
			WHERE RA.ReceiptId = @ReceiptId AND RA.IsActive = 1
			GROUP BY RA.Id
		 ) A ON RA.Id = A.ReceiptAllocationId
	
	--Update Currently Added Credit Amount

	UPDATE RA
		SET AllocationAmount_Amount = AllocationAmount_Amount + @CreditAppliedAmount
	FROM ReceiptAllocations RA
	JOIN Receipts R ON RA.ReceiptId = R.Id AND RA.ReceiptId = @ReceiptId
	WHERE RA.IsActive = 1 AND (RA.EntityType = @AllocationEntityType_Unallocated OR R.ContractId IS NOT NULL) 

	;WITH CTE AS 
	(
		SELECT RA.ReceiptId, RARD.ReceivableDetailId, RD.ReceivableId, 
			SUM(RARD.AmountApplied_Amount - RARD.AdjustedWithholdingTax_Amount + RARD.TaxApplied_Amount) AS AmountApplied
		FROM ReceiptApplications RA
		INNER JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId AND RARD.IsActive = 1 
		INNER JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id 
		WHERE RA.ReceiptId = @ReceiptId AND (RARD.IsReApplication = 1 OR RARD.AmountApplied_Amount + RARD.TaxApplied_Amount > 0)
		GROUP BY RA.ReceiptId, RARD.ReceivableDetailId, RD.ReceivableId
	)
	SELECT CTE.ReceiptId AS ReceiptId, C.Id AS ContractId, SUM(AmountApplied) TotalAmountApplied
	INTO #AmountAppliedGroupedByContracts
	FROM CTE 
	INNER JOIN Receivables R ON CTE.ReceivableId = R.Id
	LEFT JOIN Contracts C ON R.EntityId = C.Id AND R.EntityType = @ReceivableEntityTypeValues_CT
	WHERE CTE.AmountApplied <> 0
	GROUP BY CTE.ReceiptId, C.Id
	
	--Contract Based Allocations Amount Update --Check Balance for WHT Receipt Allocations
	SELECT AA.ReceiptId, RA.Id AS ReceiptAllocationId, RA.ContractId, (RA.AllocationAmount_Amount - RA.AmountApplied_Amount) AS Balance, TotalAmountApplied
	INTO #ContractBasedAllocations
	FROM ReceiptAllocations RA 
	INNER JOIN #AmountAppliedGroupedByContracts AA ON AA.ReceiptId = RA.ReceiptId AND RA.ContractId = AA.ContractId AND RA.IsActive = 1

	--Balance More that Amount Applied
	UPDATE ReceiptAllocations
		SET AmountApplied_Amount += TotalAmountApplied,
		    UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime
	FROM ReceiptAllocations RA
	INNER JOIN #ContractBasedAllocations CBA ON RA.Id = CBA.ReceiptAllocationId
	WHERE Balance > 0 AND Balance >= TotalAmountApplied

	UPDATE #AmountAppliedGroupedByContracts
		SET TotalAmountApplied = 0
	FROM #AmountAppliedGroupedByContracts AA
	INNER JOIN #ContractBasedAllocations CBA ON AA.ReceiptId = CBA.ReceiptId AND AA.ContractId = CBA.ContractId
	WHERE Balance > 0 AND Balance >= CBA.TotalAmountApplied

	--Balance Less that Amount Applied
	UPDATE ReceiptAllocations
		SET AmountApplied_Amount += Balance,
		    UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime
	FROM ReceiptAllocations RA
	INNER JOIN #ContractBasedAllocations CBA ON RA.Id = CBA.ReceiptAllocationId
	WHERE Balance > 0 AND Balance < TotalAmountApplied

	UPDATE #AmountAppliedGroupedByContracts
		SET TotalAmountApplied -= Balance
	FROM #AmountAppliedGroupedByContracts AA
	INNER JOIN #ContractBasedAllocations CBA ON AA.ReceiptId = CBA.ReceiptId AND AA.ContractId = CBA.ContractId
	WHERE Balance > 0 AND Balance < CBA.TotalAmountApplied;

	--Unallocated Allocation Amount Update
	WITH CTE_TotalAmountAppliedForReceipt AS
	(
		SELECT AA.ReceiptId, RA.Id AS AllocationId, (RA.AllocationAmount_Amount - RA.AmountApplied_Amount) AS UnallocatedBalance, SUM(ISNULL(AA.TotalAmountApplied,0)) AS TotalAmountApplied
		FROM ReceiptAllocations RA
		LEFT JOIN #AmountAppliedGroupedByContracts AA ON RA.ReceiptId = AA.ReceiptId AND RA.IsActive = 1 
		WHERE RA.ReceiptId = @ReceiptId AND RA.ContractId IS NULL
		GROUP BY AA.ReceiptId, RA.Id, RA.AllocationAmount_Amount, RA.AmountApplied_Amount
	)
	UPDATE ReceiptAllocations
		SET AmountApplied_Amount += TotalAmountApplied,
		    UpdatedById = @UpdatedById,
			UpdatedTime = @UpdatedTime
	FROM CTE_TotalAmountAppliedForReceipt TAA
	INNER JOIN ReceiptAllocations RA ON TAA.AllocationId = RA.Id
	WHERE UnallocatedBalance > 0 AND UnallocatedBalance >= TotalAmountApplied

	UPDATE Receipts
		SET Balance_Amount = (SELECT SUM(AllocationAmount_Amount - AmountApplied_Amount) FROM ReceiptAllocations WHERE ReceiptId = @ReceiptId),
		CashTypeId = CASE WHEN @CashTypeId IS NOT NULL THEN @CashTypeId ELSE CashTypeId END
	WHERE Id = @ReceiptId

END

GO

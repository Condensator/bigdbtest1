SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[SPHC_UnAppliedReceipt_Reconciliation]
(
	@ResultOption NVARCHAR(20),
	@LegalEntityIds ReconciliationId READONLY,
	@ContractIds ReconciliationId READONLY,  
	@CustomerIds ReconciliationId READONLY,
	@DiscountingIds ReconciliationId READONLY
)
AS
BEGIN
	SET NOCOUNT ON
	SET ANSI_WARNINGS OFF

	IF OBJECT_ID('tempdb..#EligibleReceipts') IS NOT NULL 
	BEGIN
		DROP TABLE #EligibleReceipts
	END
	IF OBJECT_ID('tempdb..#RARDDetails') IS NOT NULL 
	BEGIN
		DROP TABLE #RARDDetails
	END
	IF OBJECT_ID('tempdb..#GLTrialBalance') IS NOT NULL 
	BEGIN
		DROP TABLE #GLTrialBalance
	END
	IF OBJECT_ID('tempdb..#GLPostedAmount') IS NOT NULL 
	BEGIN
		DROP TABLE #GLPostedAmount
	END
	IF OBJECT_ID('tempdb..#SyndicationFunderRemitting') IS NOT NULL 
	BEGIN
		DROP TABLE #SyndicationFunderRemitting
	END
	IF OBJECT_ID('tempdb..#ClearedReceipts') IS NOT NULL 
	BEGIN
		DROP TABLE #ClearedReceipts
	END
	IF OBJECT_ID('tempdb..#RefundedAmount') IS NOT NULL 
	BEGIN
		DROP TABLE #RefundedAmount
	END
	IF OBJECT_ID('tempdb..#RefundedDetails') IS NOT NULL 
	BEGIN
		DROP TABLE #RefundedDetails
	END
	IF OBJECT_ID('tempdb..#RefundGLAmount') IS NOT NULL 
	BEGIN
		DROP TABLE #RefundGLAmount
	END
	IF OBJECT_ID('tempdb..#ResultList') IS NOT NULL 
	BEGIN
		DROP TABLE #ResultList
	END
	IF OBJECT_ID('tempdb..#NonCashSalesTax') IS NOT NULL
	BEGIN
		DROP TABLE #NonCashSalesTax;
	END;
	IF OBJECT_ID('tempdb..#ReceiptRefund') IS NOT NULL
	BEGIN
		DROP TABLE #ReceiptRefund;
	END;
	IF OBJECT_ID('tempdb..#RefundBalanceAmount') IS NOT NULL
	BEGIN
		DROP TABLE #RefundBalanceAmount;
	END;
	IF OBJECT_ID('tempdb..#ReceiptSummary') IS NOT NULL
	BEGIN
		DROP TABLE #ReceiptSummary;
	END;
	IF OBJECT_ID('tempdb..#ClearedReceiptDetails') IS NOT NULL
	BEGIN
		DROP TABLE #ClearedReceiptDetails;
	END;
	IF OBJECT_ID('tempdb..#ClearedAmountGL') IS NOT NULL
	BEGIN
		DROP TABLE #ClearedAmountGL;
	END;
	IF OBJECT_ID('tempdb..#RefundedTableValue') IS NOT NULL
	BEGIN
		DROP TABLE #RefundedTableValue;
	END;

	SELECT syndication.ContractId
		 , rft.Id AS SyndicationId
	INTO #SyndicationFunderRemitting
	FROM ReceivableForTransfers syndication
		 INNER JOIN ReceivableForTransfers rft ON rft.ContractId = syndication.Id
	WHERE rft.ApprovalStatus = 'Approved'
		  AND rft.Id IN
	(
		SELECT ReceivableForTransferId
		FROM ReceivableForTransferFundingSources
		WHERE SalesTaxResponsibility = 'RemitOnly'
	);

	CREATE NONCLUSTERED INDEX IX_Id ON #SyndicationFunderRemitting(ContractId)

	DECLARE @True BIT= 1;
	DECLARE @False BIT= 0;
	DECLARE @LegalEntitiesCount BIGINT = ISNULL((SELECT COUNT(*) FROM @LegalEntityIds), 0)
	DECLARE @ContractsCount BIGINT = ISNULL((SELECT COUNT(*) FROM @ContractIds), 0)
	DECLARE @CustomersCount BIGINT = ISNULL((SELECT COUNT(*) FROM @CustomerIds), 0)
	DECLARE @DiscountingsCount BIGINT= ISNULL((SELECT COUNT(*) FROM @DiscountingIds), 0);

	SELECT DISTINCT
		   r.Id
		 , r.Number
		 , CASE
			   WHEN r.EntityType = 'Customer'
			   THEN r.CustomerId
			   WHEN r.EntityType IN('Lease', 'Loan')
			   THEN r.ContractId
			   WHEN r.EntityType = 'Discounting'
			   THEN r.DiscountingId
			   ELSE Null
		   END AS EntityId
		 , r.EntityType
		 , CASE 
				WHEN r.EntityType IN ('Lease', 'Loan')
				THEN 'Contract'
				WHEN r.EntityType = 'Customer'
				THEN 'Customer'
				WHEN  r.EntityType = 'Discounting'
				THEN 'Discounting'
				ELSE NULL
		   END AS GLEntityType
		 , p.PartyName
		 , p.Alias
		 , c.SequenceNumber
		 , c.Alias as ContractAlias
		 , le.Name AS LegalEntityName
		 , rt.ReceiptTypeName
		 , r.ReceiptClassification
		 , r.ReceiptAmount_Amount AS ReceiptAmount
		 , r.Balance_Amount AS BalanceAmount
		 , r.Status
		 , le.Id AS LegalEntityId
	INTO #EligibleReceipts
	FROM Receipts r
		 INNER JOIN LegalEntities le ON r.LegalEntityId = le.Id
		 INNER JOIN ReceiptTypes rt ON rt.Id = r.TypeId
		 LEFT JOIN Parties p ON r.CustomerId = p.Id
		 LEFT JOIN Contracts c ON c.Id = r.ContractId
		 LEFT JOIN Payables payable ON payable.SourceId = r.Id 
									   AND payable.SourceTable = 'Receipt'
									   AND payable.Status != 'Inactive'
	WHERE ((r.Status IN('Completed', 'Posted')
	AND r.Balance_Amount > 0 ) OR payable.Id IS NOT NULL)
	AND @True = (CASE 
					   WHEN @LegalEntitiesCount > 0 AND EXISTS (SELECT Id FROM @LegalEntityIds WHERE Id = R.LegalEntityId) THEN @True
					   WHEN @LegalEntitiesCount = 0 THEN @True ELSE @False END)
	AND @True = (CASE 
					   WHEN @CustomersCount > 0 AND EXISTS (SELECT Id FROM @CustomerIds WHERE Id = R.CustomerId) THEN @True
					   WHEN @CustomersCount = 0 THEN @True ELSE @False END)
	AND (@True = (CASE 
					    WHEN @ContractsCount > 0 AND EXISTS (SELECT Id FROM @ContractIds WHERE Id = R.ContractId AND R.EntityType IN ('Lease', 'Loan')) THEN @True
						WHEN @ContractsCount = 0 AND @DiscountingsCount = 0 THEN @True ELSE @False END)
						  OR @True = (CASE 
										  WHEN @DiscountingsCount > 0 AND EXISTS (SELECT Id FROM @DiscountingIds WHERE Id = R.DiscountingId AND R.EntityType = 'Discounting') THEN @True
										  WHEN @DiscountingsCount = 0 AND @ContractsCount = 0 THEN @True ELSE @False END))
 
	CREATE NONCLUSTERED INDEX IX_Id ON #EligibleReceipts(Id)

	SELECT r.Id
		 , SUM(CASE
				   WHEN receivable.FunderId IS NULL
				   THEN rard.AmountApplied_Amount
				   ELSE 0.00
			   END) AS LessorOwnedAmountApplied
		 , SUM(CASE
				   WHEN receivable.FunderId IS NULL
				   THEN rard.TaxApplied_Amount
				   ELSE 0.00
			   END) AS TaxAmountApplied
		 , SUM(CASE
				   WHEN receivable.FunderId IS NOT NULL
				   THEN rard.AmountApplied_Amount
				   ELSE 0.00
			   END) AS SyndicatedAmountApplied
		 , SUM(CASE
				   WHEN receivable.FunderId IS NOT NULL
				   THEN rard.TaxApplied_Amount
				   ELSE 0.00
			   END) AS SyndicatedTaxAmountApplied
		 , SUM(CASE
				   WHEN rard.AmountApplied_Amount < 0.00
				   THEN rard.AmountApplied_Amount
				   ELSE 0.00
			   END) AS CreditAmountApplied
	INTO #RARDDetails
	FROM #EligibleReceipts r
		 INNER JOIN ReceiptApplications ra ON r.Id = ra.ReceiptId AND r.Status IN('Completed', 'Posted')
		 INNER JOIN ReceiptApplicationReceivableDetails rard ON ra.Id = rard.ReceiptApplicationId
		 INNER JOIN ReceivableDetails rd ON rd.Id = rard.ReceivableDetailId
		 INNER JOIN Receivables receivable ON receivable.Id = rd.ReceivableId
		 LEFT JOIN #SyndicationFunderRemitting funderRemitting ON funderRemitting.ContractId = receivable.EntityId AND receivable.EntityType = 'CT'
	WHERE rard.IsActive = 1
		  AND rd.IsActive = 1
		  AND receivable.IsActive = 1
	GROUP BY r.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #RARDDetails(Id)

	SELECT SUM(CASE WHEN receivable.FunderId IS NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS LessorPortionNonCash
			, SUM(CASE WHEN receivable.FunderId IS NOT NULL THEN rard.TaxApplied_Amount ELSE 0.00 END) AS FunderPortionNonCash
			, er.Id
	INTO #NonCashSalesTax
	FROM #EligibleReceipts er
	INNER JOIN ReceiptApplications ra ON er.Id = ra.ReceiptId
	INNER JOIN ReceiptApplicationReceivableDetails rard ON ra.Id = rard.ReceiptApplicationId
	INNER JOIN ReceivableDetails rd ON rd.Id = rard.ReceivableDetailId
	INNER JOIN Receivables receivable ON receivable.Id = rd.ReceivableId
	INNER JOIN ReceivableTaxes rt ON rt.ReceivableId = receivable.Id
	WHERE rt.IsActive = 1
			AND rt.IsCashBased = 1
			AND rt.IsDummy = 0
			AND receivable.IsCollected = 1
			AND receivable.IsActive = 1
			AND er.ReceiptClassification = 'NonCash'
	GROUP BY er.Id

	CREATE NONCLUSTERED INDEX IX_Id ON #NonCashSalesTax(Id);

	SELECT DISTINCT
		   receipt.Id
		 , refundDetails.AmountToBeCleared_Amount AS Amount
		 , refund.Id AS RefundId
		 , IIF(receipt.EntityType = '_', receipt.LegalEntityId, receipt.EntityId) AS EntityId
		 , IIF(receipt.GLEntityType IS NULL AND receipt.EntityType = '_', 'LegalEntity', receipt.GLEntityType) AS EntityType
	INTO #ClearedReceiptDetails
	FROM #EligibleReceipts receipt
		 INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
		 INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
		 INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
	WHERE refund.TYPE = 'Clearing'
		  AND refund.Status = 'Approved'

	CREATE NONCLUSTERED INDEX IX_Id ON #ClearedReceiptDetails(Id)

	SELECT Id
			, SUM(Amount) AS Amount
	INTO #ClearedReceipts
	FROM #ClearedReceiptDetails
	GROUP BY Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #ClearedReceipts(Id)

	SELECT t.ReceiptId
			, SUM(CreditAmount - DebitAmount) AS Amount
	INTO #ClearedAmountGL
	FROM
	(
		SELECT DISTINCT 
				gljd.Id
				, CASE
					WHEN gljd.IsDebit = 1
					THEN gljd.Amount_Amount
					ELSE 0
				END DebitAmount
				, CASE
					WHEN gljd.IsDebit = 0
					THEN gljd.Amount_Amount
					ELSE 0
				END CreditAmount
				, cleared.Id AS ReceiptId
		FROM #ClearedReceiptDetails cleared
				INNER JOIN GLJournalDetails gljd ON gljd.SourceId = cleared.RefundId
				INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
				INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
												AND glei.IsActive = 1
				INNER JOIN Receipts r ON cleared.Id = r.Id
				INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
													AND gltt.IsActive = 1
		WHERE glei.Name = 'IncomeToClear'
				AND gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
				AND gljd.EntityId = cleared.EntityId
				AND gljd.EntityType = cleared.EntityType
	) AS t
	GROUP BY t.ReceiptId;

	CREATE NONCLUSTERED INDEX IX_Id ON #ClearedAmountGL(ReceiptId)

	SELECT  t.Id,
		   SUM(t.Amount) AS Amount,
		   SUM(t.PendingAmount) AS PendingAmount,
		   SUM(t.BalanceAmount) AS BalanceAmount
	INTO #RefundedAmount
	FROM
	(SELECT DISTINCT receipt.Id
		 ,  CASE WHEN p.IsGLPosted = 1
					  AND p.Status = 'Approved'
				 THEN p.Amount_Amount
				 ELSE 0.00
		    END AS Amount
		 ,  CASE WHEN p.IsGLPosted = 0
					  AND p.Status = 'Pending'
				 THEN p.Amount_Amount
				 ELSE 0.00
		    END AS PendingAmount			
		,  CASE WHEN p.Status != 'Inactive'
				 THEN p.Balance_Amount
				 ELSE 0.00
		    END AS BalanceAmount								 					   
		 , p.Id AS PayableId
	FROM #EligibleReceipts receipt
		 INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
		 INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
		 INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
		 JOIN Payables p ON p.SourceId = Receipt.Id
							AND p.SourceTable = 'Receipt'
							
	WHERE refund.TYPE = 'Refund'
		  AND refund.Status = 'Approved') as t
	GROUP BY t.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #RefundedAmount(Id)

	SELECT DISTINCT 
		   receipt.Id
		 , pgl.GLJournalId
		 , 'Payable' AS Type
		 , p.Amount_Amount
	INTO #RefundedDetails
	FROM #EligibleReceipts receipt
		 INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
		 INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
		 INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
		 JOIN Payables p ON p.SourceId = Receipt.Id
							AND p.SourceTable = 'Receipt'
							AND p.Status = 'Approved'
							AND p.IsGLPosted = 1
		 JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
	WHERE refund.TYPE = 'Refund'
		  AND refund.Status = 'Approved';

	INSERT INTO #RefundedDetails
	SELECT DISTINCT 
		   receipt.Id
		 , refund.Id
		 , 'Refund'
		 , refund.AmountToClear_Amount
	FROM #EligibleReceipts receipt
		 INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
		 INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
		 INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
		 JOIN Payables p ON p.SourceId = Receipt.Id
							AND p.SourceTable = 'Receipt'
							AND p.Status = 'Approved'
							AND p.IsGLPosted = 1
		 LEFT JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
	WHERE refund.TYPE = 'Refund'
		  AND refund.Status = 'Approved'
		  AND pgl.GLJournalId IS NULL;

	CREATE NONCLUSTERED INDEX IX_GLJournalId ON #RefundedDetails(GLJournalId);
	CREATE NONCLUSTERED INDEX IX_Id ON #RefundedDetails(Id);


	SELECT DISTINCT 
			  receipt.Id AS ReceiptId
			, SUM(refundDetails.AmountToBeCleared_Amount) AS Amount
	INTO #RefundedTableValue
	FROM #EligibleReceipts receipt
			INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
			INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
			INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
			JOIN Payables p ON p.SourceId = Receipt.Id
							   AND p.EntityId = refund.Id
			LEFT JOIN PayableGLJournals pgl ON pgl.PayableId = p.Id
	WHERE refund.TYPE = 'Refund'
			AND refund.Status = 'Approved'
			AND pgl.GLJournalId IS NULL
			AND p.SourceTable = 'Receipt'
			AND p.Status = 'Approved'
			AND p.IsGLPosted = 1
			AND p.EntityType = 'RR'
		  GROUP BY receipt.Id
			

	SELECT DISTINCT 
		   receipt.Id
		 , refund.Id AS RefundId
		 , refund.AmountToClear_Amount
	INTO #ReceiptRefund
	FROM #EligibleReceipts receipt
		 INNER JOIN ReceiptAllocations ra ON receipt.Id = ra.ReceiptId
		 INNER JOIN UnallocatedRefundDetails refundDetails ON refundDetails.ReceiptAllocationId = ra.Id
		 INNER JOIN UnallocatedRefunds refund ON refundDetails.UnallocatedRefundId = refund.Id
	WHERE refund.TYPE = 'Refund'
		  AND refund.Status = 'Approved'
		  AND receipt.Status = 'Reversed';

	SELECT refund.Id
 		  ,ABS(SUM(CASE
				   WHEN gljd.Isdebit = 0
				   THEN GLJD.Amount_Amount
				   ELSE 0.00
			   END) - SUM(CASE
							  WHEN gljd.Isdebit = 1
							  THEN GLJD.Amount_Amount
							  ELSE 0.00
						  END)) AS Amount
	INTO #RefundGLAmount
	FROM GLJournalDetails gljd
		 INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
		 INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
										 AND glei.IsActive = 1
		 INNER JOIN #RefundedDetails refund ON (refund.GLJournalId = gljd.GLJournalId AND type = 'Payable') 
											   OR (refund.GLJournalId = gljd.EntityId AND type = 'Refund' AND EntityType ='ReceiptRefund')
		 INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
											   AND gltt.IsActive = 1
	WHERE (glei.Name = 'UnAppliedAR' AND gltt.Name = 'PayableCash')
	GROUP BY refund.Id;

	 	
	CREATE NONCLUSTERED INDEX IX_Id ON #RefundGLAmount(Id);

	UPDATE #RefundGLAmount SET Amount = t.Amount
	FROM #RefundGLAmount gl
	INNER JOIN (SELECT SUM(Amount_Amount) AS Amount, Id AS ReceiptId from #RefundedDetails GROUP BY Id) as [table] ON gl.Id = [table].ReceiptId
	INNER JOIN (SELECT v.ReceiptId, SUM(v.Amount) AS Amount from #RefundedTableValue v GROUP BY v.ReceiptId) as t ON t.ReceiptId = gl.Id
	WHERE gl.Amount = [table].Amount

	SELECT refund.Id
		 ,ABS(SUM(CASE
				   WHEN gljd.Isdebit = 0
				   THEN GLJD.Amount_Amount
				   ELSE 0.00
			   END) - SUM(CASE
							  WHEN gljd.Isdebit = 1
							  THEN GLJD.Amount_Amount
							  ELSE 0.00
						  END)) AS Amount
	INTO #RefundBalanceAmount
	FROM GLJournalDetails gljd
		 INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
		 INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId
										 AND glei.IsActive = 1
		 INNER JOIN #ReceiptRefund refund ON refund.RefundId = gljd.EntityId
													AND gljd.EntityType = 'ReceiptRefund'
		 INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id
											   AND gltt.IsActive = 1
		 LEFT JOIN #RefundGLAmount rgl ON rgl.Id = refund.Id
	WHERE glei.Name = 'UnAppliedAR' 
		  AND gltt.Name = 'PayableCash'
		  AND rgl.Id IS NULL
	GROUP BY refund.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #RefundBalanceAmount(Id);


	   SELECT EntityId
				 , EntityType
				 , EntryItemId
				 , SUM(DebitAmount) DebitAmount
				 , SUM(CreditAmount) CreditAmount
				 , MatchingEntryName
				 , SourceId
				 , GLJournalId
				 , GLTemplateId
				 , MatchingGLTemplateId
				 , MatchingTransactionTypeName
			INTO #GLTrialBalance
			FROM
			(
				SELECT DISTINCT gljd.EntityId AS EntityId
					 , gljd.EntityType AS EntityType
					 , glei.Id AS EntryItemId
					 , CASE
						   WHEN gljd.IsDebit = 1
						   THEN gljd.Amount_Amount
						   ELSE 0.00
					   END DebitAmount
					 , CASE
						   WHEN gljd.IsDebit = 0
						   THEN gljd.Amount_Amount
						   ELSE 0.00
					   END CreditAmount
					 , mglei.Name MatchingEntryName
					 , gljd.SourceId
					 , gljd.GLJournalId
					 , gltd.GLTemplateId
					 , mgltd.GLTemplateId AS MatchingGLTemplateId
					 , mgltt.Name AS MatchingTransactionTypeName
					 , gljd.Id
				FROM GLJournalDetails gljd
					 INNER JOIN GLTemplateDetails gltd ON gltd.Id = gljd.GLTemplateDetailId
					 INNER JOIN GLEntryItems glei ON glei.Id = gltd.EntryItemId AND glei.IsActive = 1
					 INNER JOIN GLTransactionTypes gltt ON glei.GLTransactionTypeId = gltt.Id AND gltt.IsActive = 1
					 INNER JOIN ReceiptGLJournals rgl ON rgl.GLJournalId = gljd.GLJournalId
					 INNER JOIN #EligibleReceipts er ON er.Id = rgl.ReceiptId
					 LEFT JOIN GLTemplateDetails mgltd ON gljd.MatchingGLTemplateDetailId = mgltd.Id
					 LEFT JOIN GLEntryItems mglei ON mglei.Id = mgltd.EntryItemId AND mglei.IsActive = 1
					 LEFT JOIN GLTransactionTypes mgltt ON mgltt.Id = mglei.GLTransactionTypeId AND mgltt.IsActive = 1
					 WHERE glei.Name IN ('Cash', 'Receivable', 'ChargeoffRecovery', 'GainOnRecovery', 'ChargeOffExpense', 'Expense', 'SecurityDeposit', 'Payable', 'UnappliedAR', 'IncomeToClear','FinancingChargeoffRecovery', 'FinancingGainOnRecovery', 'FinancingChargeOffExpense')
			) AS T
			GROUP BY EntityId
				   , EntityType
				   , EntryItemId
				   , MatchingEntryName
				   , SourceId
				   , GLJournalId
				   , GLTemplateId
				   , MatchingGLTemplateId
				   , MatchingTransactionTypeName;

	CREATE NONCLUSTERED INDEX IX_Id ON #GLTrialBalance(EntryItemId);
	CREATE NONCLUSTERED INDEX IX_GLJournalId ON #GLTrialBalance(GLJournalId);

	SELECT t.Id
		 , SUM(t.NetReceiptDebitAmount - t.NetReceiptCreditAmount) AS NetReceiptAmount
		 , SUM(t.LessorOwnedReceivableAppliedCreditAmount - t.LessorOwnedReceivableAppliedDebitAmount) AS LessorOwnedReceivableAmount
		 , SUM(t.TaxAmountAppliedCredit - t.TaxAmountAppliedDebit ) AS TaxAmountAppliedAmount
		 , SUM(t.SyndicatedAmountAppliedCredit - t.SyndicatedAmountAppliedDebit) AS SyndicatedAmountApplied
		 , SUM(t.UnAppliedAmountCredit - t.UnAppliedAmountDebit) AS UnAppliedAmount
	INTO #GLPostedAmount
	FROM
	(
		SELECT er.Id
			 , CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Cash', 'Expense', 'SecurityDeposit', 'Payable')
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END NetReceiptDebitAmount
			 , CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Cash', 'Expense', 'SecurityDeposit', 'Payable')
				   THEN gld.CreditAmount
				   ELSE 0.00
			  END NetReceiptCreditAmount
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Receivable', 'GainOnRecovery', 'ChargeoffRecovery' , 'FinancingChargeoffRecovery', 'FinancingGainOnRecovery', 'FinancingChargeOffExpense', 'ChargeOffExpense')
						AND (gld.MatchingEntryName != 'DueToThirdPartyAR' OR gld.MatchingEntryName IS NULL)
						AND (gld.MatchingTransactionTypeName NOT IN ('SyndicatedAR', 'SalesTax') OR gld.MatchingTransactionTypeName IS NULL)
				   THEN gld.DebitAmount
				   ELSE 0.00
			  END LessorOwnedReceivableAppliedDebitAmount
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Receivable', 'GainOnRecovery', 'ChargeoffRecovery' , 'FinancingChargeoffRecovery', 'FinancingGainOnRecovery', 'FinancingChargeOffExpense', 'ChargeOffExpense')
						AND (gld.MatchingEntryName != 'DueToThirdPartyAR' OR gld.MatchingEntryName IS NULL)
						AND (gld.MatchingTransactionTypeName NOT IN ('SyndicatedAR', 'SalesTax') OR gld.MatchingTransactionTypeName IS NULL)
				   THEN gld.CreditAmount
				   ELSE 0.00
			  END LessorOwnedReceivableAppliedCreditAmount
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Receivable')
						AND gld.MatchingTransactionTypeName = 'SalesTax'
						AND gld.MatchingEntryName IN ('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
				   THEN gld.DebitAmount
				   ELSE 0.00
			  END TaxAmountAppliedDebit
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name IN ('Receivable')
						AND gld.MatchingTransactionTypeName = 'SalesTax'
						AND gld.MatchingEntryName IN ('SalesTaxReceivable', 'PrePaidSalesTaxReceivable')
				   THEN gld.CreditAmount
				   ELSE 0.00
			  END TaxAmountAppliedCredit
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name = 'Receivable'
						AND gld.MatchingEntryName IN ('DueToThirdPartyAR', 'PrePaidDueToThirdPartyAR', 'SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
						AND MatchingTransactionTypeName IN ('SyndicatedAR', 'SalesTax')
				   THEN gld.DebitAmount
				   ELSE 0.00
			  END SyndicatedAmountAppliedDebit
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name = 'Receivable'
						AND gld.MatchingEntryName IN ('DueToThirdPartyAR', 'PrePaidDueToThirdPartyAR', 'SyndicatedSalesTaxReceivable', 'PrePaidSyndicatedSalesTaxReceivable')
						AND MatchingTransactionTypeName IN ('SyndicatedAR', 'SalesTax')
				   THEN gld.CreditAmount
				   ELSE 0.00
			  END SyndicatedAmountAppliedCredit
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name = 'UnappliedAR'
				   THEN gld.DebitAmount
				   ELSE 0.00
			   END UnAppliedAmountDebit
			, CASE
				   WHEN gltt.Name IN('ReceiptCash', 'ReceiptNonCash')
						AND glei.Name = 'UnappliedAR'
				   THEN gld.CreditAmount
				   ELSE 0.00
			   END UnAppliedAmountCredit
		FROM #GLTrialBalance gld
			 INNER JOIN GLEntryItems glei ON gld.EntryItemId = glei.Id
											 AND glei.IsActive = 1
			 INNER JOIN GLTransactionTypes gltt ON GLEI.GLTransactionTypeId = GLTT.Id
												   AND gltt.IsActive = 1
			 INNER JOIN ReceiptGLJournals rgl ON rgl.GLJournalId = gld.GLJournalId
			 INNER JOIN #EligibleReceipts er ON er.Id = rgl.ReceiptId
	) AS t
	GROUP BY t.Id;

	CREATE NONCLUSTERED INDEX IX_Id ON #GLPostedAmount(Id);

	SELECT *
		 , CASE
			   WHEN NetReceiptAmount_Difference != 0.00
					OR [LessorOwnedReceivableAmountApplied_Difference] != 0.00
					OR [LessorOwnedSalesTaxAmountApplied_Difference] != 0.00
					OR [FunderOwnedReceivableAndSalesTaxAmountApplied_Difference] != 0.00
					OR [Cleared_Difference] != 0.00
					OR [Refunded_Difference] != 0.00
					OR [BalanceAmount_Difference] != 0.00
			   THEN 'Problem Record'
			   ELSE 'Not Problem Record'
		   END AS Result
	INTO #ResultList
	FROM
	(
		SELECT er.Number
			 , er.EntityType
			 , er.EntityId
			 , er.LegalEntityName [ReceiptLegalEntity]
			 , er.ReceiptClassification
			 , er.ReceiptTypeName
			 , er.PartyName AS CustomerName
			 , er.Alias
			 , er.SequenceNumber
			 , er.ContractAlias
			 , ISNULL(er.ReceiptAmount, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS NetReceiptAmount_Table
			 , ISNULL(gl.NetReceiptAmount, 0.00) AS NetReceiptAmount_GL
			 , ISNULL(er.ReceiptAmount, 0.00) - ISNULL(gl.NetReceiptAmount, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS NetReceiptAmount_Difference
			 , ISNULL(rard.CreditAmountApplied, 0.00) AS [CreditReceivables_Table]
			 , ISNULL(rard.LessorOwnedAmountApplied, 0.00) AS [LessorOwnedReceivableAmountApplied_Table]
			 , ISNULL(gl.LessorOwnedReceivableAmount, 0.00) AS [LessorOwnedReceivableAmountApplied_GL]
			 , ISNULL(rard.LessorOwnedAmountApplied, 0.00) - ISNULL(gl.LessorOwnedReceivableAmount, 0.00) [LessorOwnedReceivableAmountApplied_Difference]
			 , ISNULL(rard.TaxAmountApplied, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS [LessorOwnedSalesTaxAmountApplied_Table]
			 , ISNULL(gl.TaxAmountAppliedAmount, 0.00) AS [LessorOwnedSalesTaxAmountApplied_GL]
			 , ISNULL(rard.TaxAmountApplied, 0.00) - ISNULL(gl.TaxAmountAppliedAmount, 0.00) - ISNULL(ncst.LessorPortionNonCash, 0.00) AS [LessorOwnedSalesTaxAmountApplied_Difference]
			 , ISNULL(rard.SyndicatedAmountApplied, 0.00) AS [FunderOwnedReceivableAmountApplied_Table]
			 , ISNULL(rard.SyndicatedTaxAmountApplied, 0.00) - ISNULL(ncst.FunderPortionNonCash, 0.00) AS [FunderOwnedSalesTaxReceivableAmountApplied_Table]
			 , ISNULL(gl.SyndicatedAmountApplied, 0.00) AS [FunderOwnedReceivableAndSalesTaxAmountApplied_GL]
			 , ISNULL(rard.SyndicatedAmountApplied, 0.00) + ISNULL(rard.SyndicatedTaxAmountApplied, 0.00) - ISNULL(gl.SyndicatedAmountApplied, 0.00) - - ISNULL(ncst.FunderPortionNonCash, 0.00) AS [FunderOwnedReceivableAndSalesTaxAmountApplied_Difference]
			 , ISNULL(cr.Amount, 0.00) AS [Cleared_Table]
			 , ISNULL(cleared.Amount, 0.00) AS [Cleared_GL]
			 , ISNULL(cr.Amount, 0.00) - ISNULL(cleared.Amount, 0.00) AS [Cleared_Difference]
			 , ISNULL(refund.Amount, 0.00) AS [Refunded_Table]
			 , ABS(ISNULL(refundGL.Amount, 0.00) - ISNULL(rba.Amount, 0.00)) AS [Refunded_GL]
			 , ISNULL(refund.Amount, 0.00) - ISNULL(refundGL.Amount, 0.00) - ISNULL(rba.Amount, 0.00) AS [Refunded_Difference]
			, CASE WHEN er.Status = 'Reversed' AND  ISNULL(refund.Amount, 0.00) =  ISNULL(er.ReceiptAmount, 0.00)
					THEN 0.00
					WHEN er.Status = 'Reversed'
					THEN ISNULL(refund.BalanceAmount, 0.00)
					ELSE ISNULL(er.BalanceAmount, 0.00) + ISNULL(refund.PendingAmount, 0.00)
			   END AS [BalanceAmount_Table]
			 , ABS(ISNULL(gl.UnAppliedAmount, 0.0)) - ABS(ISNULL(refundGL.Amount, 0.00) - ISNULL(rba.Amount, 0.00)) - ISNULL(cleared.Amount, 0.00) AS [BalanceAmount_GL]
			  , CASE WHEN er.Status = 'Reversed' AND  ISNULL(refund.Amount, 0.00) =  ISNULL(er.ReceiptAmount, 0.00)
					THEN 0.00
					WHEN er.Status = 'Reversed'
					THEN ISNULL(refund.BalanceAmount, 0.00)
					ELSE ISNULL(er.BalanceAmount, 0.00) + ISNULL(refund.PendingAmount, 0.00)
			   END - ABS(ABS(ISNULL(gl.UnAppliedAmount, 0.0)) - ABS(ISNULL(refundGL.Amount, 0.00) - ISNULL(rba.Amount, 0.00)) - ISNULL(cleared.Amount, 0.00)) AS [BalanceAmount_Difference]
		FROM #EligibleReceipts er
			 LEFT JOIN #GLPostedAmount gl ON er.Id = gl.Id
			 LEFT JOIN #RARDDetails rard ON er.Id = rard.Id
			 LEFT JOIN #ClearedReceipts cr ON er.Id = cr.Id
			 LEFT JOIN #RefundedAmount refund ON er.Id = refund.Id
			 LEFT JOIN #RefundGLAmount refundGL ON er.Id = refundGL.Id
			 LEFT JOIN #NonCashSalesTax ncst ON er.Id = ncst.Id
			 LEFT JOIN #RefundBalanceAmount rba ON  er.Id = rba.Id
			 LEFT JOIN #ClearedAmountGL cleared ON er.Id = cleared.ReceiptId
	) AS t;

	CREATE NONCLUSTERED INDEX IX_Id ON #ResultList(Number)

	SELECT name AS Name, 0 AS Count, CAST (0 AS BIT) AS IsProcessed, CAST('' AS NVARCHAR(max)) AS Label
	INTO #ReceiptSummary
	FROM tempdb.sys.columns
	WHERE object_id = OBJECT_ID('tempdb..#ResultList')
	AND Name LIKE '%Difference';

	DECLARE @query NVARCHAR(MAX);
	DECLARE @TableName NVARCHAR(max);
	WHILE EXISTS (SELECT 1 FROM #ReceiptSummary WHERE IsProcessed = 0)
	BEGIN
	SELECT TOP 1 @TableName = Name FROM #ReceiptSummary WHERE IsProcessed = 0

	SET @query = 'UPDATE #ReceiptSummary SET Count = (SELECT COUNT(*) FROM #ResultList WHERE ' + @TableName+ ' != 0.00), IsProcessed = 1
					WHERE Name = '''+ @TableName+''' ;'
	EXEC (@query)
	END

	UPDATE #ReceiptSummary SET 
							   Label = CASE
										   WHEN Name = 'NetReceiptAmount_Difference'
										   THEN '1_Net Receipt Amount_Difference'
										   WHEN Name = 'LessorOwnedReceivableAmountApplied_Difference'
										   THEN '2_Lessor Owned Receivable Amount Applied_Difference'
										   WHEN Name = 'LessorOwnedSalesTaxAmountApplied_Difference'
										   THEN '3_Lessor Owned SalesTax Amount Applied_Difference'
										   WHEN Name = 'FunderOwnedReceivableAndSalesTaxAmountApplied_Difference'
										   THEN '4_Funder Owned Receivable & Sales Tax Amount Applied_Difference'
										   WHEN Name = 'Cleared_Difference'
										   THEN '5_Cleared Amount_Difference'
										   WHEN Name = 'Refunded_Difference'
										   THEN '6_Refunded_Difference'
										   WHEN Name = 'BalanceAmount_Difference'
										   THEN '7_Balance Amount_Difference'
									   END;

	SELECT Label AS Name, Count
	FROM #ReceiptSummary

	IF (@ResultOption = 'All')
	BEGIN
    SELECT *
    FROM #ResultList
	ORDER BY Number;
	END

	IF (@ResultOption = 'Failed')
	BEGIN
	SELECT *
	FROM #ResultList
	WHERE Result = 'Problem Record'
	ORDER BY Number;
	END

	IF (@ResultOption = 'Passed')
	BEGIN
	SELECT *
	FROM #ResultList
	WHERE Result = 'Not Problem Record'
	ORDER BY Number;
	END

	DECLARE @TotalCount BIGINT;
	SELECT @TotalCount = ISNULL(COUNT(*), 0) FROM #ResultList
	DECLARE @InCorrectCount BIGINT;
	SELECT @InCorrectCount = ISNULL(COUNT(*), 0) FROM #ResultList WHERE Result  = 'Problem Record' 
	DECLARE @Messages StoredProcMessage
		
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('TotalReceipts', (Select 'Receipts=' + CONVERT(nvarchar(40), @TotalCount)))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceiptSuccessful', (Select 'ReceiptSuccessful=' + CONVERT(nvarchar(40), (@TotalCount - @InCorrectCount))))
	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceiptIncorrect', (Select 'ReceiptIncorrect=' + CONVERT(nvarchar(40), @InCorrectCount)))

	INSERT INTO @Messages(Name, ParameterValuesCsv) VALUES('ReceiptResultOption', (Select 'ResultOption=' + CONVERT(nvarchar(40), @ResultOption)))

	SELECT * FROM @Messages


	SET NOCOUNT OFF
	SET ANSI_WARNINGS ON 

	DROP TABLE #EligibleReceipts
	DROP TABLE #RARDDetails
	DROP TABLE #GLTrialBalance
	DROP TABLE #GLPostedAmount
	DROP TABLE #SyndicationFunderRemitting
	DROP TABLE #ClearedReceipts
	DROP TABLE #RefundedAmount
	DROP TABLE #RefundedDetails
	DROP TABLE #RefundGLAmount
	DROP TABLE #ResultList
	DROP TABLE #NonCashSalesTax
	DROP TABLE #ReceiptRefund
	DROP TABLE #RefundBalanceAmount
	DROP TABLE #ReceiptSummary
	DROP TABLE #ClearedReceiptDetails
	DROP TABLE #ClearedAmountGL
	DROP TABLE #RefundedTableValue;
END

GO

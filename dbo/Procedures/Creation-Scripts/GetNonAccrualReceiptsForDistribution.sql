SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 
CREATE PROCEDURE [dbo].[GetNonAccrualReceiptsForDistribution]
(  
   @BatchCount BIGINT  
  ,@JobStepInstanceId BIGINT
)  
AS  
BEGIN  
 SELECT TOP (@BatchCount) RE.Id, RE.ReceiptId, PBF.NonAccrualCategory,PBF.ComputedReceivableInvoiceId
 INTO #BatchedExtract  
 FROM Receipts_Extract RE
 INNER JOIN 
 (
 SELECT RPBF.GroupNumber, RPBF.NonAccrualCategory, Max(RPBF.ComputedReceivableInvoiceId) AS ComputedReceivableInvoiceId
 FROM ReceiptPostByFileExcel_Extract RPBF 
 WHERE RPBF.JobStepInstanceId=@JobStepInstanceId AND RPBF.HasError=0 AND RPBF.CreateUnallocatedReceipt=0
 AND (RPBF.NonAccrualCategory='SingleWithRentals' OR RPBF.NonAccrualCategory='SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory='GroupedRentals')
 GROUP BY RPBF.GroupNumber, RPBF.NonAccrualCategory
 ) PBF 
 ON RE.ReceiptId = PBF.GroupNumber AND RE.JobStepInstanceId = @JobStepInstanceId
 WHERE RE.IsReceiptHierarchyProcessed IS NULL
	
 UPDATE Receipts_Extract  
 SET Receipts_Extract.IsReceiptHierarchyProcessed = 1  
 FROM #BatchedExtract INNER JOIN Receipts_Extract  
 ON #BatchedExtract.Id = Receipts_Extract.Id  
 
;WITH ReceiptReceivableDetailsInfo AS (
	SELECT re.ReceiptId as ReceiptId,
		   ReceivableDetails.EffectiveBalance_Amount as EffectiveBalance,
		   0.00 as EffectiveTaxBalance,
		   ReceivableDetails.EffectiveBookBalance_Amount AS EffectiveBookBalance,
		   ReceivableDetails.Id as ReceivableDetailId,
		   InvoiceId=ReceivableInvoiceDetails.ReceivableInvoiceId,
		   Receivables.CustomerId as CustomerId,
		   case when Receivables.entitytype = 'CT' then Receivables.EntityId else null end as ContractId,
		   null as DiscountingId,
		   ReceivableTypes.Id as ReceivableTypeId,
		   ReceivableTypes.[Name] as ReceivableType,
		   Receivables.PaymentScheduleId,
		   Receivables.Id as ReceivableId,
		   ReceivableDetails.IsActive as IsReceivableDetailActive,
		   Receivables.EntityType as ReceivableEntityType,
		   Receivables.EntityId as ReceivableEntityId,
		   Receivables.DueDate as DueDate,
		   Receivables.IncomeType as IncomeType,
		   ReceivableInvoiceId = ReceivableInvoiceDetails.ReceivableInvoiceId,
		   ReceivableDetails.LeaseComponentAmount_Currency AS Currency,
		   ReceivableDetails.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		   ReceivableDetails.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance
	FROM 
	Receipts_Extract re 
	INNER JOIN #BatchedExtract 
		ON re.Id = #BatchedExtract.Id AND (#BatchedExtract.NonAccrualCategory='SingleWithRentals' OR #BatchedExtract.NonAccrualCategory='GroupedRentals')
	INNER JOIN Receivables ON Receivables.EntityId = re.ContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1
	INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
	INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
	INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1		LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive=1
	WHERE (Receivables.IsDummy = 0 OR (re.PayDownId IS NOT NULL AND ReceivableInvoiceDetails.ReceivableInvoiceId = #BatchedExtract.ComputedReceivableInvoiceId))
		AND Receivables.IsCollected = 1
		AND ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount != 0.00
		AND (ReceivableTypes.[Name]='LoanInterest' or ReceivableTypes.[Name]='LoanPrincipal')
		AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
UNION
	SELECT re.ReceiptId as ReceiptId,
		rid.EffectiveBalance_Amount as EffectiveBalance,
		rid.EffectiveTaxBalance_Amount as EffectiveTaxBalance,
		0.00 AS EffectiveBookBalance,
		rid.ReceivableDetailId,
		rid.ReceivableInvoiceId as InvoiceId,
		r.CustomerId as CustomerId,
		case when r.entitytype = 'CT' then r.EntityId else null end as ContractId,
		null as DiscountingId,
		ReceivableTypes.Id as ReceivableTypeId,
		ReceivableTypes.[Name] as ReceivableType,
		r.PaymentScheduleId,
		r.Id as ReceivableId,
		rd.IsActive as IsReceivableDetailActive,
		r.EntityType as ReceivableEntityType,
		r.EntityId as ReceivableEntityId,
		DueDate = r.DueDate,
		IncomeType = r.IncomeType,
		ReceivableInvoiceId =rid.ReceivableInvoiceId,
		rd.LeaseComponentAmount_Currency AS Currency,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance
	FROM 
	Receipts_Extract re INNER JOIN #BatchedExtract ON re.Id = #BatchedExtract.Id AND #BatchedExtract.NonAccrualCategory='SingleWithOnlyNonRentals'
	INNER JOIN ReceiptPostByFileExcel_Extract rpfe ON rpfe.GroupNumber = re.ReceiptId AND rpfe.JobStepInstanceId = @JobStepInstanceId 
	INNER JOIN ReceivableInvoices ri ON ri.id = rpfe.ComputedReceivableInvoiceId AND ri.isactive = 1
	INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
	INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
	INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
	INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
	INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1 
	and (ReceivableTypes.[Name]!='LoanInterest' AND ReceivableTypes.[Name]!='LoanPrincipal')
	WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR rpfe.IsApplyCredit = 1)
	AND RID.EntityId = 
		CASE 
			WHEN rpfe.EntityType = 'Loan' THEN rpfe.ComputedContractId
			ELSE RID.EntityId 
		END
	AND RID.EntityType = 
		CASE 
			WHEN rpfe.EntityType = 'Loan' THEN 'CT'
			ELSE RID.EntityType 
		END
UNION
	SELECT re.ReceiptId as ReceiptId,
		rid.EffectiveBalance_Amount as EffectiveBalance,
		rid.EffectiveTaxBalance_Amount as EffectiveTaxBalance,
		0.00 AS EffectiveBookBalance,
		rid.ReceivableDetailId,
		si.StatementInvoiceId as InvoiceId,
		r.CustomerId as CustomerId,
		case when r.entitytype = 'CT' then r.EntityId else null end as ContractId,
		null as DiscountingId,
		ReceivableCodes.Id as ReceivableTypeId,
		ReceivableTypes.[Name] as ReceivableType,
		r.PaymentScheduleId,
		r.Id as ReceivableId,
		rd.IsActive as IsReceivableDetailActive,
		r.EntityType as ReceivableEntityType,
		r.EntityId as ReceivableEntityId,
		DueDate = r.DueDate,
		IncomeType = r.IncomeType,
        ReceivableInvoiceId = si.ReceivableInvoiceId,
		rd.LeaseComponentAmount_Currency AS Currency,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance
	FROM 
	Receipts_Extract re INNER JOIN #BatchedExtract ON re.Id = #BatchedExtract.Id AND #BatchedExtract.NonAccrualCategory='SingleWithOnlyNonRentals'
	INNER JOIN ReceiptPostByFileExcel_Extract rpfe 
	ON rpfe.GroupNumber = re.ReceiptId AND rpfe.JobStepInstanceId = @JobStepInstanceId 
	INNER JOIN ReceivableInvoiceStatementAssociations si ON si.StatementInvoiceId = rpfe.ComputedReceivableInvoiceId 
	INNER JOIN ReceivableInvoices ri ON ri.id = si.ReceivableInvoiceId AND ri.isactive = 1
	INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
	INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
	INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
	INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
	INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1 
	and (ReceivableTypes.[Name]!='LoanInterest' AND ReceivableTypes.[Name]!='LoanPrincipal')
	WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR rpfe.IsApplyCredit = 1)
	AND RID.EntityId = 
		CASE 
			WHEN rpfe.EntityType = 'Loan' THEN rpfe.ComputedContractId
			ELSE RID.EntityId 
		END
	AND RID.EntityType = 
		CASE 
			WHEN rpfe.EntityType = 'Loan' THEN 'CT'
			ELSE RID.EntityType 
		END
 )
 SELECT 
	 ReceiptId, EffectiveBalance, EffectiveTaxBalance, EffectiveBookBalance, ReceivableDetailId, InvoiceId, CustomerId,
	 ContractId, DiscountingId, ReceivableTypeId, ReceivableType, PaymentScheduleId, ReceivableId, IsReceivableDetailActive, 
	 ReceivableEntityType, ReceivableEntityId, DueDate, IncomeType, ReceivableInvoiceId,Currency,LeaseComponentBalance,NonLeaseComponentBalance
 INTO #ReceiptReceivableDetailsInfo
	FROM ReceiptReceivableDetailsInfo

;WITH MaxReceivableDetailDueDates AS(
		SELECT RRD.ReceiptId, MAX(RRD.DueDate) AS MaxDueDate 
		FROM #ReceiptReceivableDetailsInfo RRD WHERE RRD.ReceivableType='LoanPrincipal' AND (RRD.EffectiveBalance)>=0
		GROUP BY RRD.ReceiptId
 ), FutureReceivablesInfo AS(
	SELECT BE.Id,
	CountOfPaymentSchedules=
	SUM(
	CASE
		WHEN (PS.DueDate > MRD.MaxDueDate) THEN 1
		ELSE 0
	END
	)
	FROM Receipts_Extract RE 
	INNER JOIN #BatchedExtract BE ON RE.Id=BE.Id AND RE.ReceiptId=BE.ReceiptId
	INNER JOIN MaxReceivableDetailDueDates MRD ON RE.ReceiptId=MRD.ReceiptId
	INNER JOIN LoanFinances LF ON RE.ContractId=LF.ContractId AND LF.IsCurrent=1
	INNER JOIN LoanPaymentSchedules PS ON LF.Id=PS.LoanFinanceId
	GROUP BY BE.Id
 )
 SELECT 
		RE.ReceiptNumber, RE.ReceiptAmount, RE.Currency, RE.ReceivedDate,
		RE.LegalEntityId, RE.LineOfBusinessId, RE.CostCenterId, RE.InstrumentTypeId,
		ContractId=
		CASE 
			WHEN RE.DiscountingId IS NULL THEN RE.ContractId
			ELSE RE.ContractId
		END, 
		RE.DiscountingId, RE.ReceiptId, RE.EntityType AS ReceiptEntityType, CAST(1 AS BIT) AS IsNonAccrualLoan, 
		ReceiptHierarchyTemplateId=
		CASE 
			WHEN (BE.NonAccrualCategory = 'SingleWithOnlyNonRentals') THEN (RE.ReceiptHierarchyTemplateId)
			ELSE NULL
		END,
		HasFutureReceivables=
		CASE
			WHEN (FRI.Id IS NOT NULL AND FRI.CountOfPaymentSchedules>0) THEN CAST(1 AS BIT) 
			ELSE CAST(0 AS BIT) 
		END,
		CAST(0 AS BIT)  AS IsStatementInvoice
 FROM Receipts_Extract RE 
 INNER JOIN #BatchedExtract BE ON RE.Id = BE.Id AND RE.ReceiptId=BE.ReceiptId
 --INNER JOIN ReceiptPostByFileExcel_Extract RBP ON RBP.GroupNumber = RE.ReceiptId AND RBP.JobStepInstanceId = RE.JobStepInstanceId 
 AND RE.JobStepInstanceId = @JobStepInstanceId
 LEFT OUTER JOIN FutureReceivablesInfo FRI ON RE.Id=FRI.Id

 ;WITH DistinctReceivableDetails AS (
	SELECT DISTINCT ReceivableDetailId FROM #ReceiptReceivableDetailsInfo
 ), PreviousApplicationData AS (
	SELECT
		PreviousApplications.ReceivableDetailId,
		SUM(PreviousApplications.TotalPreviousReceivedTowardsInterest) AS TotalPreviousReceivedTowardsInterest  --Only this Non-Zero
	FROM
	(
		--Strictly From Non-Accrual Perspective 
		SELECT 
			ReceiptApplicationReceivableDetails.ReceivableDetailId,
			CASE 
				WHEN Receipts.ReceiptClassification = 'Cash' OR Receipts.ReceiptClassification = 'NonAccrualNonDSL' THEN  
					SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount)  
				WHEN Receipts.ReceiptClassification = 'NonCash' OR Receipts.ReceiptClassification = 'NonAccrualNonDSLNonCash' THEN 
					SUM(ReceiptApplicationReceivableDetails.ReceivedTowardsInterest_Amount - ReceiptApplicationReceivableDetails.AdjustedWithholdingTax_Amount) 
				ELSE 0.00 
			END AS TotalPreviousReceivedTowardsInterest  
		FROM ReceiptApplications
		JOIN ReceiptApplicationReceivableDetails ON ReceiptApplications.Id = ReceiptApplicationReceivableDetails.ReceiptApplicationId
		JOIN DistinctReceivableDetails ON ReceiptApplicationReceivableDetails.ReceivableDetailId = DistinctReceivableDetails.ReceivableDetailId
		JOIN Receipts ON ReceiptApplications.ReceiptId = Receipts.Id
		WHERE ReceiptApplicationReceivableDetails.IsActive = 1
		AND (Receipts.Status = 'Posted' OR Receipts.Status = 'ReadyForPosting' OR Receipts.Status = 'Pending' 
		OR Receipts.Status = 'Completed' OR Receipts.Status = 'Submitted')  
		GROUP BY ReceiptApplicationReceivableDetails.ReceivableDetailId,Receipts.ReceiptClassification  
	) PreviousApplications
	GROUP BY PreviousApplications.ReceivableDetailId
 )
 SELECT 
	 ReceiptId, EffectiveBalance, EffectiveTaxBalance, EffectiveBookBalance, RRD.ReceivableDetailId, InvoiceId, CustomerId,
	 ContractId, DiscountingId, ReceivableTypeId, ReceivableType, PaymentScheduleId, ReceivableId, IsReceivableDetailActive, 
	 ReceivableEntityType, ReceivableEntityId, DueDate, IncomeType, ReceivableInvoiceId,Currency,LeaseComponentBalance,NonLeaseComponentBalance,
	 ISNULL(RDWD.Tax_Amount, 0) AS WithHoldingTaxAmount,
 	 ISNULL(RDWD.BasisAmount_Amount, 0) AS WithHoldingBasis,
     ISNULL(RDWD.EffectiveBalance_Amount, 0) AS WithHoldingTaxBalance,
	 ISNULL(P.TotalPreviousReceivedTowardsInterest, 0) AS TotalPreviousReceivedTowardsInterest
  FROM #ReceiptReceivableDetailsInfo RRD
  LEFT JOIN PreviousApplicationData P ON RRD.ReceivableDetailId = P.ReceivableDetailId 
  LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWD
	ON RRD.ReceivableDetailId=RDWD.ReceivableDetailId AND RDWD.IsActive=1
 
 DROP TABLE #BatchedExtract  
 DROP TABLE #ReceiptReceivableDetailsInfo
END  

GO

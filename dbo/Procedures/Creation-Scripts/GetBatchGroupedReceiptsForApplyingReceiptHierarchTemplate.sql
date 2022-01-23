SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[GetBatchGroupedReceiptsForApplyingReceiptHierarchTemplate]
(  
	@BatchCount										BIGINT  ,
	@JobStepInstanceId								BIGINT,
	@VATInvoiceNotFullyCleared						NVARCHAR(200),
	@VatTaxOutstandingBalanceNotCompletelyApplied	NVARCHAR(200),
	@InvoiceTaxBalanceNotClearedForReceiptBatch		NVARCHAR(500),
	@IsPostingAllowed								BIT,
	@ReceiptBatchId									BIGINT NULL
)  
AS  
BEGIN  

	SELECT TOP (@BatchCount) RE.Id, RE.ReceiptId  
	INTO #BatchedExtract  
	FROM Receipts_Extract RE
	INNER JOIN ReceiptPostByFileExcel_Extract RPBF ON RE.ReceiptId = RPBF.GroupNumber 
	AND RE.JobStepInstanceId = RPBF.JobStepInstanceId
	WHERE RE.IsReceiptHierarchyProcessed is null AND RE.ReceiptHierarchyTemplateId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0
	AND RE.JobStepInstanceId = @JobStepInstanceId AND RPBF.HasError = 0 AND 
	(
		(RPBF.ComputedIsGrouped = 1 AND RPBF.IsInvoiceInMultipleReceipts=0
			AND RPBF.ComputedIsDSL = 0 AND RPBF.ComputedIsFullPosting = 0 AND RPBF.NonAccrualCategory IS NULL) 
				OR 
		(RPBF.ComputedIsGrouped = 1 AND RPBF.IsInvoiceInMultipleReceipts=0 AND RPBF.ComputedIsDSL = 0 
			AND	RPBF.NonAccrualCategory='GroupedNonRentals') 
	)
	group by RE.id, RE.ReceiptId

	UPDATE Receipts_Extract  
	SET Receipts_Extract.IsReceiptHierarchyProcessed = 1  
	FROM #BatchedExtract INNER JOIN Receipts_Extract  
	ON #BatchedExtract.Id = Receipts_Extract.Id  

	SELECT 
	#BatchedExtract.Id,
	#BatchedExtract.ReceiptId, 
	RPBF.GroupNumber AS DumpReceiptId, 
	RPBF.Id AS DumpId,
	IsNonAccrual=
	CASE
		WHEN RPBF.NonAccrualCategory='GroupedNonRentals' THEN 1
		ELSE 0
	END 
	INTO #NonAccrualBatchedExtractDetails
	FROM #BatchedExtract LEFT JOIN ReceiptPostByFileExcel_Extract RPBF 
	ON #BatchedExtract.ReceiptId=RPBF.GroupNumber AND RPBF.JobStepInstanceId=@JobStepInstanceId
	WHERE RPBF.HasError=0 AND RPBF.ComputedReceivableInvoiceId IS NOT NULL

	SELECT NA.Id, NA.ReceiptId,
	ContainsNonAccrualRecords=
	CASE
		WHEN SUM(NA.IsNonAccrual)=0 THEN 0
		ELSE 1
	END
	INTO #GroupedReceiptsWithNonAccrualInfo
	FROM #NonAccrualBatchedExtractDetails NA
	GROUP BY NA.Id, NA.ReceiptId


	CREATE TABLE #ReceiptReceivableDetails(
		Number					NVARCHAR(200), 
		ReceivableInvoiceId		BIGINT, 
		ReceiptAmount			DECIMAL(16, 2), 
		ReceiptId BIGINT NULL,
		EffectiveBalance DECIMAL(16,2) NULL,
		EffectiveTaxBalance DECIMAL(16,2) NULL,
		EffectiveBookBalance DECIMAL(16,2) NULL,
		ReceivableDetailId BIGINT NULL,
		InvoiceId BIGINT NULL,
		CustomerId BIGINT NULL,
		ContractId BIGINT NULL,
		DiscountingId BIGINT NULL,
		ReceivableTypeId BIGINT NULL,
		ReceivableType NVARCHAR(42) NULL,
		PaymentScheduleId BIGINT NULL,
		ReceivableId BIGINT NULL,
		IsReceivableDetailActive BIT NULL,
		ReceivableEntityType NVARCHAR(4) NULL,
		ReceivableEntityId BIGINT NULL,
		DueDate DATE NULL,
		IncomeType NVARCHAR(32) NULL,
		Currency NVARCHAR(42) NULL,
		LeaseComponentBalance DECIMAL(16,2) NULL,
		NonLeaseComponentBalance DECIMAL(16,2) NULL,
		ReceivableTaxType		NVARCHAR(40)
	)
		
	--Segregating Grouped Receipts which do not have any Non-Accrual Line Item File Records
	;WITH GroupedReceiptsNotContainingNonAccrualRecords AS(
		SELECT NA.Id, NA.ReceiptId FROM #GroupedReceiptsWithNonAccrualInfo NA
		WHERE NA.ContainsNonAccrualRecords=0
	)
	INSERT INTO #ReceiptReceivableDetails(Number, ReceivableInvoiceId, ReceiptAmount, ReceiptId, EffectiveBalance, EffectiveTaxBalance, EffectiveBookBalance, 
		ReceivableDetailId,InvoiceId,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,
		ReceivableEntityType,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance, ReceivableTaxType)
	SELECT 
		RI.Number,
		RI.Id,
		RE.ReceiptAmount,
		re.ReceiptId as ReceiptId,
		(rid.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) as EffectiveBalance,
		rid.EffectiveTaxBalance_Amount as EffectiveTaxBalance,
		0.00 AS EffectiveBookBalance,
		rid.ReceivableDetailId,
		rid.ReceivableInvoiceId as InvoiceId,
		r.CustomerId as CustomerId,
		case when r.entitytype = 'CT' then r.EntityId else null end as ContractId,
		case when r.entitytype = 'DT' then r.EntityId else null end as DiscountingId,
		ReceivableTypes.Id as ReceivableTypeId,
		ReceivableTypes.[Name] as ReceivableType,
		r.PaymentScheduleId,
		r.Id as ReceivableId,
		rd.IsActive as IsReceivableDetailActive,
		r.EntityType as ReceivableEntityType,
		r.EntityId as ReceivableEntityId,
		DueDate = r.DueDate,
		IncomeType = r.IncomeType,
		rd.LeaseComponentAmount_Currency AS Currency,
		rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
		RE.ReceivableTaxType
	FROM 
	Receipts_Extract re INNER JOIN GroupedReceiptsNotContainingNonAccrualRecords GNA ON re.Id = GNA.Id
	INNER JOIN (select 
				ComputedReceivableInvoiceId, 
				GroupNumber, EntityType, 
				ComputedContractId, ComputedDiscountingId,
				IsApplyCredit,
				ReceivableTaxType  
				FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId = @JobStepInstanceId 
				and ComputedIsFullPosting = 0
				and HasError = 0 group by 
				ComputedReceivableInvoiceId, GroupNumber, EntityType, ComputedContractId, ComputedDiscountingId, IsApplyCredit, ReceivableTaxType) rpfe 
	ON rpfe.GroupNumber = re.ReceiptId 
	INNER JOIN ReceivableInvoices ri ON ri.id = rpfe.ComputedReceivableInvoiceId AND ri.isactive = 1
	INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
	INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
	INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
	INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
	INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1
	LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RD.Id = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
	WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR rpfe.IsApplyCredit = 1)
	AND RID.EntityId = CASE WHEN rpfe.EntityType = 'Lease' OR rpfe.EntityType = 'Loan' THEN rpfe.ComputedContractId
									WHEN rpfe.EntityType = 'Discounting' THEN rpfe.ComputedDiscountingId
									ELSE RID.EntityId END
			AND RID.EntityType = CASE WHEN rpfe.EntityType = 'Lease' OR rpfe.EntityType = 'Loan' THEN 'CT'
									  WHEN rpfe.EntityType = 'Discounting' THEN 'DT'
									  ELSE RID.EntityType END


	--Segregating Grouped Receipts which have some Non-Accrual Line Item File Records
	SELECT NA.Id, NA.ReceiptId 
	INTO #GroupedReceiptsContainingNonAccrualRecords
	FROM #GroupedReceiptsWithNonAccrualInfo NA
	WHERE NA.ContainsNonAccrualRecords=1

	IF EXISTS(SELECT 1 FROM #GroupedReceiptsContainingNonAccrualRecords)
	BEGIN
		
		--For each individual line item in the Groups containing Non-Accrual Non-Rental records, we gather Receipt Receivable Details for the Cash Line items (1)
		--And for the Non-Accrual Non-Rentals (2)

		--Fetching Cash (1)
		;WITH CashFileReceiptRecords AS(
		SELECT NA.DumpReceiptId, NA.DumpId from #NonAccrualBatchedExtractDetails NA INNER JOIN #GroupedReceiptsContainingNonAccrualRecords GNA
		ON NA.Id=GNA.Id ANd NA.ReceiptId=GNA.ReceiptId WHERE NA.IsNonAccrual=0
		)
		INSERT INTO #ReceiptReceivableDetails(Number, ReceivableInvoiceId, ReceiptAmount,ReceiptId,EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,
			ReceivableDetailId,InvoiceId,CustomerId,ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,
			ReceivableEntityType,ReceivableEntityId,DueDate,IncomeType,Currency,LeaseComponentBalance,NonLeaseComponentBalance,ReceivableTaxType)
			SELECT 
					RI.Number,
					RI.Id,
					RPBF.ReceiptAmount,
					CASH.DumpReceiptId as ReceiptId,
					(rid.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) as EffectiveBalance,
					rid.EffectiveTaxBalance_Amount as EffectiveTaxBalance,
					0.00 AS EffectiveBookBalance,
					rid.ReceivableDetailId,
					rid.ReceivableInvoiceId as InvoiceId,
					r.CustomerId as CustomerId,
					case when r.entitytype = 'CT' then r.EntityId else null end as ContractId,
					case when r.entitytype = 'DT' then r.EntityId else null end as DiscountingId,
					ReceivableTypes.Id as ReceivableTypeId,
					ReceivableTypes.[Name] as ReceivableType,
					r.PaymentScheduleId,
					r.Id as ReceivableId,
					rd.IsActive as IsReceivableDetailActive,
					r.EntityType as ReceivableEntityType,
					r.EntityId as ReceivableEntityId,
					DueDate = r.DueDate,
					IncomeType = r.IncomeType,
					rd.LeaseComponentAmount_Currency AS Currency,
		            rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		            rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance,
					RPBF.ReceivableTaxType
		FROM CashFileReceiptRecords CASH 
		INNER JOIN ReceiptPostByFileExcel_Extract RPBF ON CASH.DumpId=RPBF.Id AND CASH.DumpReceiptId=RPBF.GroupNumber
		INNER JOIN ReceivableInvoices ri ON ri.id = RPBF.ComputedReceivableInvoiceId AND ri.isactive = 1
		INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
		INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
		INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
		INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
		INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1
		LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RD.Id = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
		WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR RPBF.IsApplyCredit = 1)
		AND RID.EntityId = 
			CASE 
				WHEN RPBF.EntityType = 'Lease' OR RPBF.EntityType = 'Loan' THEN RPBF.ComputedContractId
				WHEN RPBF.EntityType = 'Discounting' THEN RPBF.ComputedDiscountingId
				ELSE RID.EntityId 
			END
		AND RID.EntityType = 
			CASE WHEN RPBF.EntityType = 'Lease' OR RPBF.EntityType = 'Loan' THEN 'CT'
				 WHEN RPBF.EntityType = 'Discounting' THEN 'DT'
				 ELSE RID.EntityType 
			END
		
		--Fetching Non-Accrual Non-Rentals (2)
		;WITH NonAccrualFileReceiptRecords AS(
		SELECT NA.DumpReceiptId, NA.DumpId from #NonAccrualBatchedExtractDetails NA INNER JOIN #GroupedReceiptsContainingNonAccrualRecords GNA
		ON NA.Id=GNA.Id ANd NA.ReceiptId=GNA.ReceiptId WHERE NA.IsNonAccrual=1
		)
		INSERT INTO #ReceiptReceivableDetails(ReceiptId,EffectiveBalance,EffectiveTaxBalance,EffectiveBookBalance,ReceivableDetailId,InvoiceId,CustomerId,
			ContractId,DiscountingId,ReceivableTypeId,ReceivableType,PaymentScheduleId,ReceivableId,IsReceivableDetailActive,ReceivableEntityType,ReceivableEntityId,DueDate,IncomeType
			 ,Currency,LeaseComponentBalance,NonLeaseComponentBalance)
			SELECT 
					NA.DumpReceiptId as ReceiptId,
					(rid.EffectiveBalance_Amount - ISNULL(RDWTH.EffectiveBalance_Amount, 0.00)) as EffectiveBalance,
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
					rd.LeaseComponentAmount_Currency AS Currency,
		            rd.LeaseComponentBalance_Amount AS LeaseComponentBalance,
		            rd.NonLeaseComponentBalance_Amount AS NonLeaseComponentBalance
		FROM NonAccrualFileReceiptRecords NA INNER JOIN ReceiptPostByFileExcel_Extract RPBF ON NA.DumpId=RPBF.Id AND NA.DumpReceiptId=RPBF.GroupNumber
		INNER JOIN ReceivableInvoices ri ON ri.id = RPBF.ComputedReceivableInvoiceId AND ri.isactive = 1
		INNER JOIN ReceivableInvoiceDetails rid ON rid.receivableInvoiceid = ri.id
		INNER JOIN ReceivableDetails rd on rid.ReceivableDetailId = rd.id and rd.isactive = 1
		INNER JOIN Receivables r on rd.ReceivableId = r.id and r.isactive = 1
		INNER JOIN ReceivableCodes on ReceivableCodes.id = r.ReceivableCodeId and receivablecodes.isactive = 1
		INNER JOIN ReceivableTypes on ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id and receivabletypes.isactive = 1
		LEFT JOIN ReceivableDetailsWithholdingTaxDetails RDWTH ON RD.Id = RDWTH.ReceivableDetailId AND RDWTH.IsActive = 1
		WHERE (rid.EffectiveBalance_Amount + rid.EffectiveTaxBalance_Amount > 0 OR RPBF.IsApplyCredit = 1)
		AND (ReceivableTypes.[Name]!='LoanInterest' AND ReceivableTypes.[Name]!='LoanPrincipal')
		AND RID.EntityId = 
			CASE 
				WHEN RPBF.EntityType = 'Loan' THEN RPBF.ComputedContractId
				ELSE RID.EntityId 
			END
		AND RID.EntityType = 
			CASE 
				WHEN RPBF.EntityType = 'Loan' THEN 'CT'
				ELSE RID.EntityType 
			END
	END

	DECLARE @ValidateVATInvoiceForPostByFileTable  ValidateVATInvoiceForPostByFileTable							  
	INSERT INTO @ValidateVATInvoiceForPostByFileTable
	SELECT Number, ReceivableInvoiceId, ReceiptAmount, ReceivableDetailId, ReceiptId FROM #ReceiptReceivableDetails
	WHERE ReceivableTaxType = 'VAT'
	EXEC ValidateVATInvoiceForPostByFile @ValidateVATInvoiceForPostByFileTable, @VATInvoiceNotFullyCleared, @VatTaxOutstandingBalanceNotCompletelyApplied, 
										 @InvoiceTaxBalanceNotClearedForReceiptBatch, @JobStepInstanceId, @IsPostingAllowed, @ReceiptBatchId


	SELECT 
		re.ReceiptNumber, re.ReceiptAmount, re.Currency, re.ReceivedDate,
		re.LegalEntityId, re.LineOfBusinessId, re.CostCenterId, re.InstrumentTypeId,
		case when re.DiscountingId is null then re.ContractId
		else re.ContractId
		end as ContractId, re.DiscountingId, re.ReceiptId, re.EntityType AS ReceiptEntityType, CAST(0 AS BIT) as IsNonAccrualLoan, re.ReceiptHierarchyTemplateId,
		re.ReceivableTaxType
	from Receipts_Extract re INNER JOIN #BatchedExtract ON re.Id = #BatchedExtract.Id AND re.ReceiptId = #BatchedExtract.ReceiptId  
	WHERE RE.IsValid = 1                                 
 
	--Fetching ReceiptAmounts for Individual records within each group
	SELECT 
		rpfe.ComputedReceivableInvoiceId as InvoiceId, rpfe.ReceiptAmount as ReceiptAmount, 
		rpfe.GroupNumber as ReceiptId, RI.EffectiveTaxBalance_Amount EffectiveTaxBalance,
		CASE WHEN rpfe.ReceiptAmount > RI.EffectiveTaxBalance_Amount THEN
			 (rpfe.ReceiptAmount - RI.EffectiveTaxBalance_Amount) 
		ELSE 
			0.00
		END AS ReceiptTaxBalance
	from ReceiptPostByFileExcel_Extract rpfe 
	INNER JOIN #BatchedExtract ON rpfe.GroupNumber = #BatchedExtract.ReceiptId
	AND rpfe.JobStepInstanceId = @JobStepInstanceId
	INNER JOIN ReceivableInvoices RI ON RI.Id = RPFE.ComputedReceivableInvoiceId
	WHERE RPFE.ErrorMessage IS NULL

	SELECT
		RRD.ReceiptId,
		EffectiveBalance,
		EffectiveTaxBalance,
		EffectiveBookBalance,
		ReceivableDetailId,
		InvoiceId,
		CustomerId,
		ContractId,
		DiscountingId,
		ReceivableTypeId,
		ReceivableType,
		PaymentScheduleId,
		ReceivableId,
		IsReceivableDetailActive,
		ReceivableEntityType,
		ReceivableEntityId,
		DueDate,
		IncomeType,
		InvoiceId AS ReceivableInvoiceId,
		RRD.Currency,
		LeaseComponentBalance,
		NonLeaseComponentBalance
	FROM #ReceiptReceivableDetails RRD
	JOIN ReceiptPostByFileExcel_Extract PBF ON RRD.InvoiceId = PBF.ComputedReceivableInvoiceId
	AND RRD.ReceiptId = PBF.GroupNumber
	WHERE PBF.JobStepInstanceId = @JobStepInstanceId AND PBF.ErrorMessage IS NULL
 
 DROP TABLE #BatchedExtract
 DROP TABLE #NonAccrualBatchedExtractDetails
 DROP TABLE #GroupedReceiptsWithNonAccrualInfo
 DROP TABLE #ReceiptReceivableDetails

END

GO

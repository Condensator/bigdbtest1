SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[PopulateReceiptExtractDataForReceipts]  
(  
 @ReceiptBatchId  BIGINT,   
 @PostDate   DATETIME,   
 @JobStepInstanceId BIGINT,   
 @UserId    BIGINT  
)  
AS  
BEGIN  
SET NOCOUNT OFF;  
   
--For Individual Full Posting, Individual Partial Posting and Individual Non-Accrual Receipts  
INSERT INTO Receipts_Extract (  
	ReceiptId,   
	ReceiptNumber,   
	Currency,   
	ReceivedDate,   
	ReceiptClassification,   
	ContractId,   
	EntityType,    
	ReceiptGLTemplateId,    
	CustomerId,    
	ReceiptAmount,    
	DiscountingId,   
	LegalEntityId,   
	InstrumentTypeId,   
	CostCenterId,   
	CurrencyId,    
	LineOfBusinessId,   
	BankAccountId,  
	DumpId,   
	IsValid,   
	IsNewReceipt,   
	ReceiptBatchId,   
	PostDate,   
	JobStepInstanceId,   
	CreatedById,   
	CreatedTime,
	PayOffId,
	PayDownId,
	CashTypeId,
	ReceiptTypeId,
	Comment,
	CheckNumber,
	ReceivableTaxType
)  
SELECT   
	RPBF.GroupNumber,   
	RPBF.FileReceiptNumber,   
	RPBF.Currency,   
	RPBF.ReceivedDate,   
	ReceiptClassification = 
	CASE 
		WHEN (RPBF.NonAccrualCategory='SingleWithRentals' AND RPBF.CreateUnallocatedReceipt = 0) THEN 'NonAccrualNonDSL'  
		ELSE 'Cash' 
	END,   
	ContractId = CASE WHEN (RPBF.ComputedDiscountingId IS NOT NULL) THEN NULL  
		ELSE RPBF.ComputedContractId END,   
	RPBF.EntityType,    
	RPBF.ComputedGLTemplateId,    
	RPBF.ComputedCustomerId,    
	RPBF.ReceiptAmount,    
	RPBF.ComputedDiscountingId,   
	RPBF.ComputedLegalEntityId,   
	RPBF.ComputedInstrumentTypeId,   
	RPBF.ComputedCostCenterId,   
	RPBF.ComputedCurrencyId,    
	RPBF.ComputedLineOfBusinessId,   
	RPBF.ComputedBankAccountId,  
	RPBF.GroupNumber,   
	1,   
	1,   
	@ReceiptBatchId,   
	@PostDate,   
	@JobStepInstanceId,   
	@UserId,   
	SYSDATETIMEOFFSET(),
	CASE
	WHEN RPBF.PayOffId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayOffId
	END,
	CASE
	WHEN RPBF.PayDownId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayDownId
	END,  
	RPBF.ComputedCashTypeId,
	RPBF.ComputedReceiptTypeId,
	RPBF.Comment,
	RPBF.CheckNumber,
	RPBF.ReceivableTaxType
FROM ReceiptPostByFileExcel_Extract AS RPBF  
WHERE RPBF.JobStepInstanceId = @JobStepInstanceId  
AND RPBF.HasError = 0  
AND RPBF.ComputedIsGrouped = 0  
AND RPBF.ComputedIsDSL = 0 
AND (RPBF.NonAccrualCategory = 'SingleUnAllocated' OR RPBF.NonAccrualCategory = 'SingleWithRentals' 
OR RPBF.NonAccrualCategory = 'SingleWithOnlyNonRentals' OR RPBF.NonAccrualCategory IS NULL)

 --For NA-Paydown Non-Rentals
 IF EXISTS(SELECT 1 FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND HasError = 0 AND PayDownId IS NOT NULL AND NonAccrualCategory='SingleWithRentals') 
 BEGIN

	WITH TaxDetails AS (
		SELECT ReceivableDetailId = ReceivableDetails.Id, EffectiveTaxBalance = Sum(ReceivableTaxDetails.EffectiveBalance_Amount)
		FROM ReceiptPostByFileExcel_Extract RPBF 
		INNER JOIN ReceivableInvoiceDetails ON RPBF.ComputedReceivableInvoiceid = ReceivableInvoiceDetails.ReceivableInvoiceId AND ReceivableInvoiceDetails.IsActive = 1
		INNER JOIN ReceivableDetails ON ReceivableInvoiceDetails.ReceivableDetailId = ReceivableDetails.Id AND ReceivableDetails.IsActive = 1
		Inner JOIN ReceivableTaxDetails on ReceivableDetails.Id = ReceivableTaxDetails.ReceivableDetailId AND ReceivableTaxDetails.IsActive = 1
		INNER JOIN Receivables ON Receivables.Id = ReceivableDetails.ReceivableId AND Receivables.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		WHERE RPBF.JobStepInstanceId=@JobStepInstanceId
			AND RPBF.NonAccrualCategory = 'SingleWithRentals'
			AND Receivables.IsCollected = 1
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY ReceivableDetails.Id
	)
	SELECT Distinct
	RPBF.Id,
	RentalBalance = SUM(
	CASE
		WHEN (ReceivableTypes.Name = 'LoanInterest' OR ReceivableTypes.Name = 'LoanPrincipal') THEN ISNULL(ReceivableDetails.EffectiveBalance_Amount,0)
		ELSE CAST(0 AS Decimal)
	END),
	NonRentalBalance = SUM(
	CASE
		WHEN (ReceivableTypes.Name != 'LoanInterest' AND ReceivableTypes.Name != 'LoanPrincipal') THEN ISNULL(ReceivableDetails.EffectiveBalance_Amount,0) + ISNULL(TaxDetails.EffectiveTaxBalance, 0.00)
		ELSE CAST(0 AS Decimal)
	END)
	INTO #NAPayDownAmount
		FROM ReceiptPostByFileExcel_Extract RPBF 
		INNER JOIN ReceivableInvoices ON RPBF.ComputedReceivableInvoiceId = ReceivableInvoices.Id
		INNER JOIN Receivables ON Receivables.EntityId = RPBF.ComputedContractId and Receivables.EntityType = 'CT' AND Receivables.IsActive = 1 AND Receivables.DueDate <= ReceivableInvoices.DueDate
		INNER JOIN ReceivableDetails ON Receivables.Id = ReceivableDetails.ReceivableId AND ReceivableDetails.IsActive = 1
		INNER JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id	AND ReceivableCodes.IsActive = 1  
		INNER JOIN ReceivableTypes ON ReceivableCodes.ReceivableTypeId = ReceivableTypes.Id AND ReceivableTypes.IsActive = 1
		LEFT JOIN TaxDetails ON ReceivableDetails.Id = TaxDetails.ReceivableDetailId
		LEFT JOIN ReceivableInvoiceDetails ON ReceivableDetails.Id = ReceivableInvoiceDetails.ReceivableDetailId AND ReceivableInvoiceDetails.IsActive = 1
		WHERE RPBF.JobStepInstanceId=@JobStepInstanceId
			AND RPBF.NonAccrualCategory = 'SingleWithRentals'
			AND Receivables.IsCollected = 1
			AND (ReceivableDetails.EffectiveBookBalance_Amount + ReceivableDetails.EffectiveBalance_Amount + IsNull(TaxDetails.EffectiveTaxBalance, 0.00)) != 0.00
			AND (ReceivableTypes.[Name]='LoanInterest' OR ReceivableTypes.[Name]='LoanPrincipal' OR ReceivableInvoiceDetails.ReceivableInvoiceId = rpbf.ComputedReceivableInvoiceId)
			AND (Receivables.IncomeType!='InterimInterest' AND Receivables.IncomeType!='TakeDownInterest')
		GROUP BY RPBF.Id,RPBF.ReceiptAmount
		Having RPBF.ReceiptAmount > 
			SUM(CASE WHEN (ReceivableTypes.Name = 'LoanInterest' OR ReceivableTypes.Name = 'LoanPrincipal') THEN ReceivableDetails.EffectiveBalance_Amount 
			ELSE CAST(0 AS Decimal) END)
	
	UPDATE RE
	SET ReceiptAmount = 
	CASE
		WHEN RE.ReceiptAmount <= (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN NAPaydown.RentalBalance
		WHEN RE.ReceiptAmount > (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN RE.ReceiptAmount - NAPaydown.NonRentalBalance
	END
	FROM Receipts_Extract RE 
	JOIN ReceiptPostByFileExcel_Extract PBF ON PBF.GroupNumber = RE.ReceiptId
	JOIN #NAPayDownAmount NAPaydown ON NAPaydown.Id = PBF.Id
	Where PBF.JobStepInstanceId = @JobStepInstanceId

	DECLARE @MINReceiptId BIGINT 
	set @MINReceiptId = (select Min(GroupNumber) from ReceiptPostByFileExcel_Extract where JobStepInstanceId = @JobStepInstanceId)

	INSERT INTO Receipts_Extract (  
		ReceiptId,   
		ReceiptNumber,   
		Currency,   
		ReceivedDate,   
		ReceiptClassification,   
		ContractId,   
		EntityType,    
		ReceiptGLTemplateId,    
		CustomerId,    
		ReceiptAmount,    
		DiscountingId,   
		LegalEntityId,   
		InstrumentTypeId,   
		CostCenterId,   
		CurrencyId,    
		LineOfBusinessId,   
		BankAccountId,  
		DumpId,   
		IsValid,   
		IsNewReceipt,   
		ReceiptBatchId,   
		PostDate,   
		JobStepInstanceId,   
		CreatedById,   
		CreatedTime,
		PayOffId,
		PayDownId,
		CashTypeId,
		ReceiptTypeId,
		Comment,
		CheckNumber,
		ReceivableTaxType
	)  
	SELECT   
		@MINReceiptId - RANK() OVER (ORDER BY RPBF.GroupNumber DESC) AS ReceiptId,
		RPBF.FileReceiptNumber,   
		RPBF.Currency,   
		RPBF.ReceivedDate,   
		ReceiptClassification = 'Cash',   
		ContractId = RPBF.ComputedContractId,   
		RPBF.EntityType,    
		RPBF.ComputedGLTemplateId,    
		RPBF.ComputedCustomerId,
		CASE
			WHEN RPBF.ReceiptAmount <= (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN RPBF.ReceiptAmount - NAPaydown.RentalBalance
			WHEN RPBF.ReceiptAmount > (NAPaydown.RentalBalance + NAPaydown.NonRentalBalance) THEN NAPaydown.NonRentalBalance
		END AS ReceiptAmount,
		RPBF.ComputedDiscountingId,   
		RPBF.ComputedLegalEntityId,   
		RPBF.ComputedInstrumentTypeId,   
		RPBF.ComputedCostCenterId,   
		RPBF.ComputedCurrencyId,    
		RPBF.ComputedLineOfBusinessId,   
		RPBF.ComputedBankAccountId,  
		RPBF.GroupNumber,   
		1,   
		1,   
		@ReceiptBatchId,   
		@PostDate,   
		@JobStepInstanceId,   
		@UserId,   
		SYSDATETIMEOFFSET(),
		CASE
		WHEN RPBF.PayOffId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayOffId
		END,
		CASE
		WHEN RPBF.PayDownId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayDownId
		END,  
		RPBF.ComputedCashTypeId,
		RPBF.ComputedReceiptTypeId,
		RPBF.Comment,
		RPBF.CheckNumber,
		RPBF.ReceivableTaxType
	FROM ReceiptPostByFileExcel_Extract AS RPBF 
	JOIN #NAPayDownAmount NAPaydown ON NAPaydown.Id = RPBF.Id
	WHERE RPBF.JobStepInstanceId = @JobStepInstanceId  
	AND RPBF.HasError = 0  
	AND RPBF.ComputedIsGrouped = 0  
	AND RPBF.ComputedIsDSL = 0 
	AND RPBF.NonAccrualCategory='SingleWithRentals'
	AND RPBF.PayDownId IS NOT NULL
	AND NAPaydown.NonRentalBalance > 0
	AND RPBF.CreateUnallocatedReceipt = 0

 END

   
 --For Any Grouped Receipts  
 IF EXISTS(SELECT 1 FROM ReceiptPostByFileExcel_Extract WHERE JobStepInstanceId = @JobStepInstanceId AND HasError = 0 AND ComputedIsGrouped = 1 ) 
 BEGIN
	 -- Group By Entity  
	 SELECT 
		GroupNumber, EntityType, Entity   
	 INTO #ReceiptExtract  
	 FROM ReceiptPostByFileExcel_Extract   
	 WHERE JobStepInstanceId = @JobStepInstanceId 
		AND HasError = 0 AND ComputedIsGrouped = 1  
	 GROUP BY GroupNumber, EntityType, Entity  
   
	 -- Identifying groups with Identical Entity and EntityType  
	 SELECT GroupNumber INTO #IdenticalEntities FROM #ReceiptExtract   
	 GROUP BY GroupNumber HAVING COUNT(1) = 1  
  
	 -- Insert into Receipts_Extract when Entity & EntityType are identical for the group.  
	 INSERT INTO Receipts_Extract (ReceiptId, ReceiptNumber, Currency, ReceivedDate, ReceiptClassification, 
		ContractId, DiscountingId, LegalEntityId, InstrumentTypeId, CostCenterId, LineOfBusinessId, BankAccountId,   
		ReceiptGLTemplateId, ReceiptAmount, CurrencyId, CustomerId, EntityType,  
		DumpId, IsValid, IsNewReceipt, ReceiptBatchId, PostDate, JobStepInstanceId, CreatedById, CreatedTime, 
		PayOffId, PayDownId, CashTypeId, ReceiptTypeId,Comment, CheckNumber, ReceivableTaxType)  
	 SELECT 
		  RPBF.GroupNumber, 
		  RPBF.FileReceiptNumber, 
		  RPBF.Currency, 
		  RPBF.ReceivedDate,   
		  ReceiptClassification = CASE WHEN (RPBF.ComputedIsDSL = 1) THEN 'DSL'  
				  WHEN (RPBF.NonAccrualCategory = 'GroupedRentals') THEN 'NonAccrualNonDSL'  
				  ELSE 'Cash' END,   
		  ContractId = CASE WHEN (RPBF.ComputedDiscountingId IS NOT NULL) THEN NULL  
				ELSE RPBF.ComputedContractId END,   
		  RPBF.ComputedDiscountingId, RPBF.ComputedLegalEntityId, RPBF.ComputedInstrumentTypeId,   
		  RPBF.ComputedCostCenterId, RPBF.ComputedLineOfBusinessId, RPBF.ComputedBankAccountId, RPBF.ComputedGLTemplateId,   
		  SUM(RPBF.ReceiptAmount), RPBF.ComputedCurrencyId, RPBF.ComputedCustomerId, RPBF.EntityType,  
		  RPBF.GroupNumber, 1, 1, @ReceiptBatchId, @PostDate, @JobStepInstanceId, @UserId, GETDATE(),
		  CASE
			WHEN RPBF.PayOffId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayOffId
		  END,
		  CASE
			WHEN RPBF.PayDownId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayDownId
		  END,
		  RPBF.ComputedCashTypeId,
		  RPBF.ComputedReceiptTypeId,
		  STUFF((SELECT '. ' + RPBFComment.Comment
           FROM ReceiptPostByFileExcel_Extract RPBFComment 
           WHERE RPBFComment.JobStepInstanceId = @JobStepInstanceId
			AND RPBFComment.GroupNumber = RPBF.GroupNumber
          FOR XML PATH('')), 1, 2, '') ,
		  RPBF.CheckNumber,
		  RPBF.ReceivableTaxType
	 FROM ReceiptPostByFileExcel_Extract AS RPBF  
	 INNER JOIN #IdenticalEntities ON #IdenticalEntities.GroupNumber = RPBF.GroupNumber  
	 WHERE RPBF.JobStepInstanceId = @JobStepInstanceId  
	  AND RPBF.HasError = 0  
	  AND RPBF.ComputedIsGrouped = 1  
	  AND RPBF.ComputedIsDSL = 0  
	  AND (RPBF.NonAccrualCategory = 'GroupedRentals' OR RPBF.NonAccrualCategory = 'GroupedNonRentals' OR RPBF.NonAccrualCategory IS NULL)
	 GROUP BY 
		RPBF.GroupNumber, RPBF.FileReceiptNumber, RPBF.Currency, RPBF.ReceivedDate, RPBF.ComputedIsDSL,  
		RPBF.NonAccrualCategory, RPBF.ComputedDiscountingId, RPBF.ComputedContractId,   
		RPBF.ComputedDiscountingId, RPBF.ComputedLegalEntityId, RPBF.ComputedInstrumentTypeId,   
		RPBF.ComputedCostCenterId, RPBF.ComputedLineOfBusinessId, RPBF.ComputedBankAccountId, RPBF.ComputedGLTemplateId,   
		RPBF.ComputedCurrencyId, RPBF.ComputedCustomerId, RPBF.EntityType, RPBF.CreateUnallocatedReceipt, RPBF.PayOffId, RPBF.PayDownId,
		RPBF.ComputedCashTypeId, RPBF.ComputedReceiptTypeId, RPBF.CheckNumber, RPBF.ReceivableTaxType
   
	 -- Identifying groups with different Entity and EntityType  
	 ;WITH DifferentEntitiesCte AS   
	 (  
	  SELECT GroupNumber  
	  FROM #ReceiptExtract  
	  GROUP BY GroupNumber HAVING COUNT(1) > 1  
	 )   
	 -- Get details of group with different Entity and EntityType  
	 , DifferentEntityDetailsCte AS   
	 (  
	  SELECT DifferentEntitiesCte.GroupNumber, RPBF.Entity, RPBF.EntityType, RPBF.ComputedCustomerId  
	  FROM DifferentEntitiesCte  
	  JOIN ReceiptPostByFileExcel_Extract AS RPBF ON RPBF.GroupNumber = DifferentEntitiesCte.GroupNumber AND RPBF.JobStepInstanceId = @JobStepInstanceId AND RPBF.HasError = 0  
	  GROUP BY DifferentEntitiesCte.GroupNumber, RPBF.EntityType, RPBF.Entity, RPBF.ComputedCustomerId  
	 )  
	 -- Group by customer   
	 , CustomerGroupCte AS   
	 (  
	  SELECT GroupNumber, ComputedCustomerId   
	  FROM DifferentEntityDetailsCte   
	  GROUP BY GroupNumber, ComputedCustomerId   
	 )  
	 SELECT   
	  GroupNumber,   
	  CASE WHEN COUNT(1) > 1 THEN '_' ELSE 'Customer' END AS EntityType,   
	  CASE WHEN COUNT(1) > 1 THEN NULL ELSE MAX(ComputedCustomerId) END AS CustomerId  
	 INTO #GroupedEntityDetails   
	 FROM CustomerGroupCte  
	 GROUP BY GroupNumber   
  
	 INSERT INTO Receipts_Extract (ReceiptId, ReceiptNumber, Currency, ReceivedDate, ReceiptClassification,   
	  ContractId, DiscountingId, LegalEntityId, InstrumentTypeId, CostCenterId, LineOfBusinessId, BankAccountId,  
	  ReceiptGLTemplateId, ReceiptAmount, CurrencyId, CustomerId, EntityType,  
	  DumpId, IsValid, IsNewReceipt, ReceiptBatchId, PostDate, JobStepInstanceId, CreatedById, CreatedTime, 
	  PayOffId, PayDownId, CashTypeId, ReceiptTypeId,Comment, CheckNumber, ReceivableTaxType)  
	 SELECT 
		RPBF.GroupNumber, 
		RPBF.FileReceiptNumber, 
		RPBF.Currency, 
		RPBF.ReceivedDate,   
		ReceiptClassification = CASE WHEN (RPBF.NonAccrualCategory = 'GroupedRentals') THEN 'NonAccrualNonDSL' ELSE 'Cash' END,   
		NULL, NULL, RPBF.ComputedLegalEntityId, RPBF.ComputedInstrumentTypeId,   
		RPBF.ComputedCostCenterId, RPBF.ComputedLineOfBusinessId, RPBF.ComputedBankAccountId, RPBF.ComputedGLTemplateId,   
		SUM(RPBF.ReceiptAmount), RPBF.ComputedCurrencyId, #GroupedEntityDetails.CustomerId, #GroupedEntityDetails.EntityType,  
		RPBF.GroupNumber, 1, 1, @ReceiptBatchId, @PostDate, @JobStepInstanceId, @UserId, GETDATE(),
		CASE
			WHEN RPBF.PayOffId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayOffId
		END,
		CASE
			WHEN RPBF.PayDownId IS NOT NULL AND RPBF.CreateUnallocatedReceipt=0 THEN RPBF.PayDownId
		END,
	    RPBF.ComputedCashTypeId,
		RPBF.ComputedReceiptTypeId,
		STUFF((SELECT '. ' + RPBFComment.Comment
        FROM ReceiptPostByFileExcel_Extract RPBFComment 
        WHERE RPBFComment.JobStepInstanceId = @JobStepInstanceId
		AND RPBFComment.GroupNumber = RPBF.GroupNumber
        FOR XML PATH('')), 1, 2, ''),	
		RPBF.CheckNumber,
		RPBF.ReceivableTaxType
	 FROM ReceiptPostByFileExcel_Extract AS RPBF  
	 INNER JOIN #GroupedEntityDetails ON #GroupedEntityDetails.GroupNumber = RPBF.GroupNumber  
	 WHERE RPBF.JobStepInstanceId = @JobStepInstanceId  
	  AND RPBF.HasError = 0  
	  AND RPBF.ComputedIsGrouped = 1  
	  AND RPBF.ComputedIsDSL = 0  
	  AND (RPBF.NonAccrualCategory = 'GroupedRentals' OR RPBF.NonAccrualCategory = 'GroupedNonRentals' OR RPBF.NonAccrualCategory IS NULL)
	 GROUP BY RPBF.GroupNumber, RPBF.FileReceiptNumber, RPBF.Currency, RPBF.ReceivedDate, RPBF.ComputedIsDSL,  
	 RPBF.NonAccrualCategory, RPBF.ComputedLegalEntityId, RPBF.ComputedInstrumentTypeId,   
	 RPBF.ComputedCostCenterId, RPBF.ComputedLineOfBusinessId, RPBF.ComputedBankAccountId, RPBF.ComputedGLTemplateId,   
	 RPBF.ComputedCurrencyId, #GroupedEntityDetails.CustomerId, #GroupedEntityDetails.EntityType, RPBF.CreateUnallocatedReceipt, 
	 RPBF.PayOffId, RPBF.PayDownId , RPBF.ComputedCashTypeId, RPBF.ComputedReceiptTypeId, RPBF.CheckNumber, RPBF.ReceivableTaxType
  
	 IF OBJECT_ID('tempdb..#ReceiptExtract') IS NOT NULL DROP TABLE #ReceiptExtract  
	 IF OBJECT_ID('tempdb..#IdenticalEntities') IS NOT NULL DROP TABLE #IdenticalEntities  
	 IF OBJECT_ID('tempdb..#GroupedEntityDetails') IS NOT NULL DROP TABLE #GroupedEntityDetails 
	  
	END

END

GO

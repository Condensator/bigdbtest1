SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  
CREATE PROC [dbo].[PopulateLockBoxExtractDataForAllReceipts]   
(  
 @ReceiptBatchId      BIGINT,   
 @PostDate       DATETIME,   
 @JobStepInstanceId     BIGINT,   
 @UserId        BIGINT,  
 @ReceiptClassificationValues_DSL NVARCHAR(10),  
 @ReceivableEntityTypeValues_CT  NVARCHAR(10),  
 @ReceivableEntityTypeValues_DT  NVARCHAR(10)  
)  
AS  
BEGIN  
  
 SET NOCOUNT ON;  
 DECLARE @RoundingValue DECIMAL(16,2) = 0.01;

  CREATE TABLE #RARD_ExtractTemp  
(  
	RARD_ExtractId BIGINT,  
	ReceiptId BIGINT,
	ReceivableId BIGINT,  
	ReceivableDetailId BIGINT,
	AmountApplied DECIMAL(16,2), 
	LeaseComponentAmountApplied DECIMAL(16,2), 
	NonLeaseComponentAmountApplied DECIMAL(16,2),  
)  

CREATE TABLE #RARD_Extracts
(  
	RARD_ExtractId BIGINT,  
	ReceiptId BIGINT,
	ReceivableId BIGINT,  
	ReceivableDetailId BIGINT,
	RowNumber BIGINT,
	Amount_Amount DECIMAL(16,2), 
	ComponentType NVARCHAR(20)
) 

CREATE TABLE #UpdatedRARDTemp
(
  Id BIGINT,
)

 INSERT INTO Receipts_Extract (  
  ReceiptId,   
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
  CheckNumber)  
 SELECT   
  RPBL.LockBoxReceiptId,   
  RPBL.Currency,   
  RPBL.ReceivedDate,  
  RPBL.ReceiptClassification,  
  ContractId = CASE WHEN RPBL.ContractId IS NOT NULL THEN ContractId ELSE NULL END,   
  RPBL.EntityType,    
  RPBL.GLTemplateId,    
  RPBL.CustomerId,    
  RPBL.ReceivedAmount,    
  RPBL.DiscountingId,   
  RPBL.LegalEntityId,   
  RPBL.InstrumentTypeId,   
  RPBL.CostCenterId,   
  RPBL.CurrencyId,    
  RPBL.LineOfBusinessId,   
  RPBL.BankAccountId,  
  RPBL.Id,   
  1,   
  1,   
  @ReceiptBatchId,   
  @PostDate,   
  @JobStepInstanceId,   
  @UserId,   
  GETDATE(),  
  CASE  
   WHEN RPBL.PayOffId IS NOT NULL AND RPBL.CreateUnallocatedReceipt=0 THEN RPBL.PayOffId  
  END,  
  CASE  
   WHEN RPBL.PayDownId IS NOT NULL AND RPBL.CreateUnallocatedReceipt=0 THEN RPBL.PayDownId  
  END,  
  RPBL.CashTypeId,  
  RPBL.ReceiptTypeId,  
  RPBL.Comment,  
  RPBL.CheckNumber  
 FROM ReceiptPostByLockBox_Extract AS RPBL  
 WHERE RPBL.JobStepInstanceId = @JobStepInstanceId  
  AND RPBL.IsValid = 1  
  AND RPBL.ReceiptClassification <> @ReceiptClassificationValues_DSL  
  AND RPBL.IsNonAccrualLoan=0  
  
 -- For IsFullPosting = 1 AND HasMoreInvoice = 0,   
 SELECT   
  RID.EffectiveBalance_Amount,   
  RID.EffectiveTaxBalance_Amount,   
  BookAmountApplied = CASE WHEN ((RT.[Name] = 'LoanInterest' OR RT.[Name] = 'LoanPrincipal')   
        AND (R.IncomeType != 'InterimInterest' AND R.IncomeType != 'TakeDownInterest'))  
       THEN RD.EffectiveBookBalance_Amount  
       ELSE 0.00 END,   
  RID.ReceivableDetailId,   
  RD.IsActive,   
  RID.ReceivableInvoiceId,   
  ContractId = CASE WHEN (R.EntityType = @ReceivableEntityTypeValues_CT) THEN R.EntityId ELSE NULL END,   
  DiscountingId = CASE WHEN (R.EntityType = @ReceivableEntityTypeValues_DT) THEN R.EntityId ELSE NULL END,   
  R.Id ReceivableId,   
  RPBL.LockBoxReceiptId,  
  RPBL.ContractNumber,  
  RPBL.Id AS DumpId ,
  R.EntityType AS ReceivableEntityType,
  ISNULL(RD.LeaseComponentBalance_Amount,0.00) AS LeaseComponentBalance,
  ISNULL(RD.NonLeaseComponentBalance_Amount,0.00) AS NonLeaseComponentBalance
 INTO #ReceiptPostByLockBox_Extract  
 FROM ReceiptPostByLockBox_Extract RPBL  
 INNER JOIN ReceivableInvoices RI ON RPBL.ReceivableInvoiceId = RI.Id AND IsActive = 1
 INNER JOIN ReceivableInvoiceDetails RID ON RPBL.ReceivableInvoiceId = RID.ReceivableInvoiceId  
 INNER JOIN ReceivableDetails RD ON RID.ReceivableDetailId = RD.Id  
 INNER JOIN Receivables R ON RD.ReceivableId = R.Id  
 INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id  
 INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id  
 WHERE RPBL.JobStepInstanceId = @JobStepInstanceId  
  AND RPBL.ReceiptClassification <> @ReceiptClassificationValues_DSL  
  AND RPBL.IsValid = 1 AND RPBL.IsFullPosting = 1  
  AND RPBL.HasMoreInvoice = 0  
  AND RPBL.IsNonAccrualLoan=0  
  AND RPBL.CreateUnallocatedReceipt = 0  
 ;  
  
 INSERT INTO ReceiptApplicationReceivableDetails_Extract (  
  AmountApplied,   
  TaxApplied,   
  BookAmountApplied,   
  ReceivableDetailId,   
  ReceivableDetailIsActive,   
  InvoiceId,   
  ContractId,   
  DiscountingId,   
  ReceivableId,   
  ReceiptId,   
  JobStepInstanceId,   
  ReceiptApplicationReceivableDetailId,   
  CreatedById,   
  CreatedTime,  
  DumpId,  
  IsReApplication,
  LeaseComponentAmountApplied,
  NonLeaseComponentAmountApplied
  )
  OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
 SELECT   
  EffectiveBalance_Amount,   
  EffectiveTaxBalance_Amount,   
  BookAmountApplied,   
  ReceivableDetailId,   
  IsActive,   
  ReceivableInvoiceId,   
  ContractId,   
  DiscountingId,   
  ReceivableId,   
  LockBoxReceiptId,   
  @JobStepInstanceId,   
  0,   
  @UserId,   
  GETDATE(),  
  DumpId,  
  0,
  ISNULL(ROUND(((EffectiveBalance_Amount * LeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS LeaseComponentAmountApplied,
  ISNULL(ROUND(((EffectiveBalance_Amount * NonLeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS NonLeaseComponentAmountApplied
 FROM #ReceiptPostByLockBox_Extract  
 WHERE ContractNumber IS NULL OR ContractNumber = ''  
 ;  
  
 INSERT INTO ReceiptApplicationReceivableDetails_Extract (  
  AmountApplied,   
  TaxApplied,   
  BookAmountApplied,   
  ReceivableDetailId,   
  ReceivableDetailIsActive,   
  InvoiceId,   
  ContractId,   
  DiscountingId,   
  ReceivableId,   
  ReceiptId,   
  JobStepInstanceId,   
  ReceiptApplicationReceivableDetailId,   
  CreatedById,   
  CreatedTime,  
  DumpId,  
  IsReApplication,
  LeaseComponentAmountApplied,
  NonLeaseComponentAmountApplied)  
  OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
 SELECT   
  EffectiveBalance_Amount,   
  EffectiveTaxBalance_Amount,   
  BookAmountApplied,   
  ReceivableDetailId,   
  IsActive,   
  RPBLT.ReceivableInvoiceId,   
  RPBLT.ContractId,   
  RPBLT.DiscountingId,   
  ReceivableId,   
  RPBL.LockBoxReceiptId,   
  @JobStepInstanceId,   
  0,   
  @UserId,   
  GETDATE(),  
  RPBL.LockBoxReceiptId,  
  0,
  ISNULL(ROUND(((EffectiveBalance_Amount * LeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS LeaseComponentAmountApplied,
  ISNULL(ROUND(((EffectiveBalance_Amount * NonLeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS NonLeaseComponentAmountApplied
 FROM #ReceiptPostByLockBox_Extract RPBLT  
 JOIN ReceiptPostByLockBox_Extract RPBL ON RPBLT.DumpId=RPBL.Id AND RPBLT.LockBoxReceiptid=RPBL.LockBoxReceiptId  
 WHERE 
 ReceivableEntityType = @ReceivableEntityTypeValues_CT AND RPBL.ContractNumber IS NOT NULL AND RPBL.ContractNumber != '' AND 
	(RPBL.IsValidContract = 0 OR RPBL.IsInvoiceContractAssociated = 0 OR (RPBL.ContractId = RPBLT.ContractId))
 ;  
  
 INSERT INTO ReceiptApplicationReceivableDetails_Extract (  
  AmountApplied,   
  TaxApplied,   
  BookAmountApplied,   
  ReceivableDetailId,   
  ReceivableDetailIsActive,   
  InvoiceId,   
  ContractId,   
  DiscountingId,   
  ReceivableId,   
  ReceiptId,   
  JobStepInstanceId,   
  ReceiptApplicationReceivableDetailId,   
  CreatedById,   
  CreatedTime,  
  DumpId,  
  IsReApplication,
  LeaseComponentAmountApplied,
  NonLeaseComponentAmountApplied)
  OUTPUT INSERTED.Id,INSERTED.ReceiptId,INSERTED.ReceivableId,INSERTED.ReceivableDetailId,INSERTED.AmountApplied,INSERTED.LeaseComponentAmountApplied,INSERTED.NonLeaseComponentAmountApplied into #RARD_ExtractTemp
 SELECT   
  EffectiveBalance_Amount,   
  EffectiveTaxBalance_Amount,   
  BookAmountApplied,   
  ReceivableDetailId,   
  IsActive,   
  RPBLT.ReceivableInvoiceId,   
  RPBLT.ContractId,   
  RPBLT.DiscountingId,   
  ReceivableId,   
  RPBL.LockBoxReceiptId,   
  @JobStepInstanceId,   
  0,   
  @UserId,   
  GETDATE(),  
  RPBL.LockBoxReceiptId,  
  0,
  ISNULL(ROUND(((EffectiveBalance_Amount * LeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS LeaseComponentAmountApplied,
  ISNULL(ROUND(((EffectiveBalance_Amount * NonLeaseComponentBalance)/NULLIF(LeaseComponentBalance + NonLeaseComponentBalance,0)),2),0.00) AS NonLeaseComponentAmountApplied
 FROM #ReceiptPostByLockBox_Extract RPBLT  
 JOIN ReceiptPostByLockBox_Extract RPBL ON RPBLT.DumpId=RPBL.Id AND RPBLT.LockBoxReceiptid=RPBL.LockBoxReceiptId  
 WHERE 
 ReceivableEntityType = @ReceivableEntityTypeValues_DT AND RPBL.ContractNumber IS NOT NULL AND RPBL.ContractNumber != '' AND 
	(RPBL.IsValidContract = 0 OR RPBL.IsInvoiceContractAssociated = 0 OR (RPBL.DiscountingId = RPBLT.DiscountingId))
   
    INSERT INTO #RARD_Extracts(RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,Amount_Amount,ComponentType,RowNumber)
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,LeaseComponentAmountApplied AS Amount_Amount,'Lease',
	CASE WHEN LeaseComponentAmountApplied >= NonLeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE
    UNION ALL
	SELECT RARD_ExtractId,ReceiptId,ReceivableId,ReceivableDetailId,NonLeaseComponentAmountApplied AS Amount_Amount,'NonLease',
	CASE WHEN NonLeaseComponentAmountApplied > LeaseComponentAmountApplied THEN 1 ELSE 2 END AS RowNumber
	FROM #RARD_ExtractTemp RE

    UPDATE #RARD_Extracts
	SET Amount_Amount = Amount_Amount + RoundingValue
	OUTPUT INSERTED.RARD_ExtractId INTO #UpdatedRARDTemp
	FROM #RARD_Extracts
	JOIN (
	        SELECT #RARD_ExtractTemp.RARD_ExtractId,(#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) DifferenceAfterDistribution,
			CASE WHEN (#RARD_ExtractTemp.AmountApplied - SUM(Amount_Amount)) < 0 THEN -(@RoundingValue) ELSE @RoundingValue END AS RoundingValue
		    FROM  #RARD_ExtractTemp
			JOIN #RARD_Extracts ON #RARD_ExtractTemp.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId
			GROUP BY  #RARD_ExtractTemp.ReceivableId,#RARD_ExtractTemp.ReceivableDetailId,#RARD_ExtractTemp.RARD_ExtractId,#RARD_ExtractTemp.AmountApplied
			HAVING #RARD_ExtractTemp.AmountApplied <> SUM(Amount_Amount)
         ) AS AppliedRARD_Extracts
		 ON #RARD_Extracts.RARD_ExtractId = AppliedRARD_Extracts.RARD_ExtractId
    WHERE  (#RARD_Extracts.RowNumber <= CAST(AppliedRARD_Extracts.DifferenceAfterDistribution/RoundingValue AS BIGINT)
	     AND AppliedRARD_Extracts.RARD_ExtractId = #RARD_Extracts.RARD_ExtractId)
		
	UPDATE ReceiptApplicationReceivableDetails_Extract
       SET LeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'Lease' THEN #RARD_Extracts.Amount_Amount ELSE LeaseComponentAmountApplied END
           ,NonLeaseComponentAmountApplied = CASE WHEN #RARD_Extracts.ComponentType = 'NonLease' THEN #RARD_Extracts.Amount_Amount ELSE NonLeaseComponentAmountApplied END
   FROM #RARD_Extracts
       INNER JOIN ReceiptApplicationReceivableDetails_Extract RARDE ON #RARD_Extracts.RARD_ExtractId = RARDE.Id
       INNER JOIN #UpdatedRARDTemp ON RARDE.Id = #UpdatedRARDTemp.Id

DROP TABLE #RARD_ExtractTemp
DROP TABLE #RARD_Extracts
DROP TABLE #UpdatedRARDTemp

END  

GO

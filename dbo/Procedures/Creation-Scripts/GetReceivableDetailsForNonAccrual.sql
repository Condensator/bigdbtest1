SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[GetReceivableDetailsForNonAccrual]  
(  
 @ContractIds  ContractIds      READONLY,  
 @ReceivableTypeIds ReceivableTypeIds    READONLY,  
 @ReceivableEntityTypeValues_CT      NVARCHAR(5),  
 @ReceiptClassificationValues_NonCash    NVARCHAR(24),  
 @ReceiptClassificationValues_NonAccrualNonDSLCash NVARCHAR(24),  
 @ReceiptStatusValues_Pending      NVARCHAR(24),  
 @ReceiptStatusValues_Posted       NVARCHAR(24),  
 @ReceiptStatusValues_ReadyForPosting    NVARCHAR(24),  
 @IncludeFunderOwnedReceivables      BIT  
)  
AS    
BEGIN    
 SET NOCOUNT ON;    
    
 SELECT * INTO #ContractIds FROM @ContractIds    
 SELECT * INTO #ReceivableTypeIds FROM @ReceivableTypeIds    
 
 ;WITH EligibleInfo AS (
	SELECT C.Id AS ContractId, R.Id AS ReceivableId
	FROM #ContractIds C INNER JOIN Receivables R ON C.Id = R.EntityId AND R.EntityType = @ReceivableEntityTypeValues_CT
	AND R.IsActive = 1 
 )
 SELECT     
  E.ContractId AS ContractId,    
  Receivables.Id AS ReceivableId,    
  Receivables.TotalAmount_Amount AS TotalAmount,    
  Receivables.TotalEffectiveBalance_Amount AS TotalEffectiveBalance,    
  Receivables.DueDate,    
  LeasePaymentSchedules.StartDate,    
  LeasePaymentSchedules.EndDate,    
  ReceivableCodes.AccountingTreatment,    
  Receivables.IncomeType,    
  Receivables.FunderId  
 INTO #EligibleReceivables    
 FROM EligibleInfo E
 JOIN Receivables WITH (FORCESEEK) ON E.ReceivableId = Receivables.Id AND Receivables.IsDummy = 0
 JOIN ReceivableCodes ON Receivables.ReceivableCodeId = ReceivableCodes.Id    
 JOIN #ReceivableTypeIds ON ReceivableCodes.ReceivableTypeId = #ReceivableTypeIds.Id     
 JOIN LeasePaymentSchedules ON Receivables.PaymentScheduleId = LeasePaymentSchedules.Id    
 WHERE (@IncludeFunderOwnedReceivables = 1 OR Receivables.FunderId IS NULL)    
 
 CREATE CLUSTERED INDEX IX_EligibleReceivables_ReceivableId ON #EligibleReceivables (ReceivableId)

 SELECT R.ReceivableId, RARD.Id
 INTO #RARD
 FROM #EligibleReceivables R    
 JOIN ReceivableDetails RD ON R.ReceivableId = RD.ReceivableId AND RD.IsActive=1    
 JOIN ReceiptApplicationReceivableDetails RARD WITH(FORCESEEK) ON RD.Id = RARD.ReceivableDetailId AND RARD.IsActive=1    

 SELECT     
  R.ReceivableId,    
  SUM(RARD.AmountApplied_Amount) AS CashApplied,    
  MAX(Receipt.ReceivedDate) LastReceiptDate    
 INTO #CashApplications    
 FROM #RARD R    
 JOIN ReceiptApplicationReceivableDetails RARD ON R.Id = RARD.Id     
 JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id    
 JOIN Receipts Receipt ON RA.ReceiptId = Receipt.Id AND Receipt.Status IN (@ReceiptStatusValues_Pending, @ReceiptStatusValues_Posted, @ReceiptStatusValues_ReadyForPosting)    
 WHERE Receipt.ReceiptClassification NOT IN (@ReceiptClassificationValues_NonCash,@ReceiptClassificationValues_NonAccrualNonDSLCash)    
 GROUP BY R.ReceivableId  
   
 SELECT     
  Receivable.ContractId,    
  Receivable.ReceivableId,    
  Receivable.TotalAmount,    
  Receivable.TotalEffectiveBalance,    
  Receivable.DueDate,    
  Receivable.StartDate,    
  Receivable.EndDate,    
  Receivable.AccountingTreatment,    
  ISNULL(CashApp.CashApplied,0.00) AS CashApplied,    
  CashApp.LastReceiptDate,    
  Receivable.IncomeType ReceivableIncomeType,    
  Receivable.FunderId  
 FROM #EligibleReceivables Receivable    
 LEFT JOIN #CashApplications CashApp ON Receivable.ReceivableId = CashApp.ReceivableId    
    
 DROP TABLE #EligibleReceivables     
 DROP TABLE #CashApplications    
 DROP TABLE #ContractIds    
 DROP TABLE #ReceivableTypeIds    
 DROP TABLE #RARD 
    
END

GO

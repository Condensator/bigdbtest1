SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[DueDateCalculatorForStatementInvoice] (  
 @JobStepInstanceId BIGINT,
 @ChunkNumber BIGINT,
 @StatementInvoiceFrequency_Monthly NVARCHAR(100),
 @StatementInvoiceFrequency_Quarterly NVARCHAR(100),
 @StatementInvoiceFrequency_HalfYearly NVARCHAR(100),
 @StatementInvoiceFrequency_Yearly NVARCHAR(100),
 @ReceivableEntityType_CT NVARCHAR(100),
 @ReceivableEntityType_CU NVARCHAR(100),
 @ReceivableEntityType_DT NVARCHAR(100),
 @ContractFilterEntityType_Lease NVARCHAR(100),
 @ContractFilterEntityType_Loan NVARCHAR(100)
 )  
AS  
BEGIN  
 SET NOCOUNT ON;  
  
 DECLARE @True AS BIT = CONVERT(BIT, 1)  
 DECLARE @False AS BIT = CONVERT(BIT, 0)  
     
  CREATE TABLE #NextPossibleStatementGenerationDueDates(  
	  NextPossibleStatementGenerationDueDate DATE,  
	  StatementDueDay INT,  
	  ReceivableInvoiceId BIGINT  
  )  

  CREATE NONCLUSTERED INDEX IX_ReceivableInvoiceId ON #NextPossibleStatementGenerationDueDates(ReceivableInvoiceId);

  CREATE TABLE #ChunkBillToes(
		BillToId BIGINT PRIMARY KEY
	)

	INSERT INTO #ChunkBillToes(BillToId)
	SELECT BillToId FROM InvoiceChunkDetails_Extract 
	WHERE JobStepInstanceId=@JobStepInstanceId AND ChunkNumber=@ChunkNumber


 SELECT * INTO #ReceivableInvoiceDueDay FROM  
 (  
 SELECT   
  SIRD.ReceivableInvoiceId,  
  LFD.DueDay,  
  CASE   
   WHEN (SIRD.CT_InvoiceLeadDays = 0  OR SIRD.SplitRentalInvoiceByContract = 0)
    THEN SIRD.CU_InvoiceLeadDays  
   ELSE SIRD.CT_InvoiceLeadDays  
  END AS LeadDays  
 FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 INNER JOIN LeaseFinances LF ON SIRD.ContractId = LF.ContractId   
  AND SIRD.EntityType = @ReceivableEntityType_CT AND SIRD.ContractType=@ContractFilterEntityType_Lease  
 INNER JOIN LeaseFinanceDetails LFD ON LF.Id = LFD.Id  
 WHERE SIRD.JobStepInstanceId = @JobStepInstanceId AND SIRD.IsCurrentInstance = 0  
 UNION ALL  
 SELECT   
  SIRD.ReceivableInvoiceId,  
  LF.DueDay,  
  CASE   
   WHEN (SIRD.CT_InvoiceLeadDays = 0  OR SIRD.SplitRentalInvoiceByContract = 0)  
    THEN SIRD.CU_InvoiceLeadDays  
   ELSE SIRD.CT_InvoiceLeadDays  
  END AS LeadDays  
 FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 INNER JOIN LoanFinances LF ON SIRD.ContractId = LF.ContractId   
  AND SIRD.EntityType = @ReceivableEntityType_CT AND SIRD.ContractType=@ContractFilterEntityType_Loan  
 WHERE SIRD.JobStepInstanceId = @JobStepInstanceId  AND SIRD.IsCurrentInstance = 0  
 UNION ALL  
 SELECT   
  SIRD.ReceivableInvoiceId,  
  DF.DueDay,  
  CASE   
   WHEN (SIRD.CT_InvoiceLeadDays = 0  OR SIRD.SplitRentalInvoiceByContract = 0) 
    THEN SIRD.CU_InvoiceLeadDays  
   ELSE SIRD.CT_InvoiceLeadDays  
  END AS LeadDays  
  FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 INNER JOIN Discountings D ON SIRD.ContractId = D.Id  
  AND SIRD.EntityType = @ReceivableEntityType_DT  
 INNER JOIN DiscountingFinances DF ON D.Id = DF.DiscountingId  
 WHERE SIRD.JobStepInstanceId = @JobStepInstanceId AND SIRD.IsCurrentInstance = 0  
 UNION ALL  
 SELECT   
  SIRD.ReceivableInvoiceId,  
  BT.StatementDueDay,  
  SIRD.CU_InvoiceLeadDays LeadDays  
  FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 JOIN BillToes BT ON SIRD.BillToId = BT.Id  
 WHERE SIRD.JobStepInstanceId = @JobStepInstanceId AND SIRD.EntityType = @ReceivableEntityType_CU  AND SIRD.IsCurrentInstance = 0  
 ) AS #temp  
 GROUP BY #temp.ReceivableInvoiceId,#temp.DueDay,#temp.LeadDays  
   
 SELECT SIRD.ReceivableInvoiceId,  
   SIRD.EntityType,  
   SIRD.EntityId,  
   CASE WHEN SIRD.ReceivableDueDate != SIRD.InvoiceDueDate  
      THEN DATEADD(DAY,0-SIRD.CT_InvoiceTransitDays,SIRD.InvoiceDueDate)  
      ELSE SIRD.InvoiceDueDate  
   END AS ComputedInvoiceDueDate  
   ,SIRD.LastStatementGeneratedDueDate  
   ,CASE WHEN SIRD.SplitRentalInvoiceByContract = 1 OR SIRD.IsInvoiceSensitive = 0  
    THEN SIRD.JobProcessThroughDate  
    ELSE DATEADD(Day,CASE WHEN SIRD.SplitRentalInvoiceByContract = 1 THEN SIRD.CT_InvoiceLeadDays ELSE SIRD.CU_InvoiceLeadDays END - RIDD.LeadDays,SIRD.JobProcessThroughDate)  
   END AS ComputedProcessThroughDate  
   ,CASE WHEN SIRD.SplitRentalInvoiceByContract = 1 AND SIRD.EntityType = @ReceivableEntityType_CT   
      AND RIDD.DueDay != 0  
      THEN RIDD.DueDay  
      ELSE BT.StatementDueDay  
   END AS StatementDueDay  
   ,CASE   
    WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Monthly THEN 1  
    WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Quarterly THEN 3  
    WHEN BT.StatementFrequency = @StatementInvoiceFrequency_HalfYearly THEN 6  
    WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Yearly THEN 12  
    ELSE 1  
   END StatementFrequency  
   ,SIRD.CU_InvoiceTransitDays  
 INTO #ComputedInvoiceDueDays  
  FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 INNER JOIN #ReceivableInvoiceDueDay RIDD ON SIRD.ReceivableInvoiceId = RIDD.ReceivableInvoiceId  
	AND SIRD.JobStepInstanceId = @JobStepInstanceId
 INNER JOIN BillToes BT ON SIRD.BillToId = BT.Id  
   
 SELECT  
 DISTINCT  
  EntityId  
 ,EntityType  
 ,ReceivableInvoiceId  
 ,ComputedInvoiceDueDate ReceivableInvoiceDueDate  
 ,LastStatementGeneratedDueDate  
 ,StatementDueDay  
 ,DATEDIFF(Month,ComputedInvoiceDueDate,ComputedProcessThroughDate) InvoiceDueDateMonthDifference  
 ,DATEDIFF(Month,LastStatementGeneratedDueDate,ComputedProcessThroughDate) LastGeneratedStatementDueDateMonthDifference  
 ,StatementFrequency * (DATEDIFF(Month,LastStatementGeneratedDueDate,ComputedProcessThroughDate)/ StatementFrequency) CalculatedMonthsToAdd  
 ,ComputedProcessThroughDate  
 ,StatementFrequency MonthsToAdd  
 ,CU_InvoiceTransitDays  
 INTO #DueDateCTETemp  
 FROM #ComputedInvoiceDueDays CIDD  
  
 SELECT   
 DueDateForStatement.ReceivableInvoiceId,  
 CASE WHEN DueDateForStatement.LastStatementGeneratedDueDate IS NOT NULL AND DueDateForStatement.LastStatementGeneratedDueDate < ComputedProcessThroughDate  
   THEN CASE WHEN LastGeneratedStatementDueDateMonthDifference > MonthsToAdd  
       THEN CASE WHEN (DATEADD(MONTH,CalculatedMonthsToAdd,LastStatementGeneratedDueDate)) < ComputedProcessThroughDate          
        THEN DATEADD(MONTH,CalculatedMonthsToAdd,LastStatementGeneratedDueDate)  
         ELSE CASE WHEN StatementDueDay > Day(ComputedProcessThroughDate)   
           AND DATEADD(MONTH, CalculatedMonthsToAdd-MonthsToAdd,LastStatementGeneratedDueDate) != LastStatementGeneratedDueDate  
          THEN DATEADD(MONTH, CalculatedMonthsToAdd - MonthsToAdd,LastStatementGeneratedDueDate)  
          ELSE DATEADD(MONTH, CalculatedMonthsToAdd,LastStatementGeneratedDueDate)  
          END  
         END  
     ELSE DATEADD(MONTH, MonthsToAdd ,LastStatementGeneratedDueDate)     
     END                                              
        ELSE CASE WHEN InvoiceDueDateMonthDifference > MonthsToAdd  
                       THEN CASE WHEN StatementDueDay > Day(ComputedProcessThroughDate)  
                                            THEN DATEADD(MONTH,  
                                            (MonthsToAdd * (InvoiceDueDateMonthDifference/ MonthsToAdd)) - MonthsToAdd, ReceivableInvoiceDueDate)  
                                            ELSE DATEADD(MONTH,  
                                            MonthsToAdd * (InvoiceDueDateMonthDifference/ MonthsToAdd), ReceivableInvoiceDueDate)  
                                            END  
                       ELSE  CASE WHEN (DATEADD(MONTH,MonthsToAdd,ReceivableInvoiceDueDate) < ComputedProcessThroughDate OR   
                                       (InvoiceDueDateMonthDifference = MonthsToAdd AND StatementDueDay <= Day(ComputedProcessThroughDate)) OR  
            (InvoiceDueDateMonthDifference < MonthsToAdd AND StatementDueDay <= Day(ReceivableInvoiceDueDate)))  
                                            THEN DATEADD(MONTH,MonthsToAdd,ReceivableInvoiceDueDate)  
                                            ELSE ReceivableInvoiceDueDate  
                                            END  
     END  
 END NextPossibleGenerationStatementDueDate  
 INTO #NextPossibleGenerationStatementDueDateTemp  
 FROM #DueDateCTETemp DueDateForStatement  
  
 SELECT   
 DueDateForStatement.ReceivableInvoiceId,  
 CASE WHEN DAY(EOMONTH(NextPossibleGenerationStatementDueDate)) < StatementDueDay  
  THEN DATEADD(DAY, DAY(EOMONTH(NextPossibleGenerationStatementDueDate))   
  - DAY(NextPossibleGenerationStatementDueDate) ,NextPossibleGenerationStatementDueDate)  
  ELSE DATEADD(DAY, StatementDueDay - DAY(NextPossibleGenerationStatementDueDate),NextPossibleGenerationStatementDueDate)  
  END NextPossibleStatementGenerationDueDate  
 INTO #BasedOnDueDay  
 FROM  
 #DueDateCTETemp DueDateForStatement  
 JOIN #NextPossibleGenerationStatementDueDateTemp NextPossibleDueDateBasedOnFrequency  
  ON NextPossibleDueDateBasedOnFrequency.ReceivableInvoiceId = DueDateForStatement.ReceivableInvoiceId  
  
 INSERT INTO #NextPossibleStatementGenerationDueDates(ReceivableInvoiceId,StatementDueDay,NextPossibleStatementGenerationDueDate)  
 SELECT  
  DISTINCT  
  BODD.ReceivableInvoiceId,  
  StatementDueDay,  
  NextPossibleGenerationStatementDueDate = BODD.NextPossibleStatementGenerationDueDate  
 FROM #BasedOnDueDay BODD  
 JOIN #DueDateCTETemp DueDateForStatement   
  ON BODD.ReceivableInvoiceId = DueDateForStatement.ReceivableInvoiceId  
   
 SELECT   
   SIRD.ReceivableInvoiceId  
  ,CASE WHEN NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate > ComputedInvoiceDueDays.ComputedProcessThroughDate
			  THEN DATEADD(MONTH,	CASE   
									WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Monthly THEN -1  
									WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Quarterly THEN -3  
									WHEN BT.StatementFrequency = @StatementInvoiceFrequency_HalfYearly THEN -6  
									WHEN BT.StatementFrequency = @StatementInvoiceFrequency_Yearly THEN -12  
									ELSE -1 END
			  ,NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate)
			  ELSE NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate
			  END
			  AS CalculatedDueDate
			  ,1 AS IsOffPeriod  
 INTO #StatementInvoiceCalculatedDueDate  
  FROM InvoiceChunkDetails_Extract ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON ICDE.JobStepInstanceId=@JobStepInstanceId AND SIRD.BillToId= ICDE.BillToId AND ICDE.ChunkNumber = @ChunkNumber 
	--Remove SIRD.IsActive 
  JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates   
   ON SIRD.ReceivableInvoiceId = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId  
     JOIN #ComputedInvoiceDueDays ComputedInvoiceDueDays ON SIRD.EntityId = ComputedInvoiceDueDays.EntityId  
    AND SIRD.EntityType = ComputedInvoiceDueDays.EntityType  
    AND SIRD.ReceivableInvoiceId = ComputedInvoiceDueDays.ReceivableInvoiceId  
  JOIN BillToes BT ON SIRD.BillToId = BT.Id  
  WHERE BT.GenerateStatementInvoice = 1   
 GROUP BY  
  SIRD.ReceivableInvoiceId  
  ,NextPossibleStatementGenerationDueDates.NextPossibleStatementGenerationDueDate  
  ,BT.StatementFrequency
  ,ComputedInvoiceDueDays.ComputedProcessThroughDate
   
 UPDATE SIRD SET  
  SIRD.StatementDueDay = NextPossibleStatementGenerationDueDates.StatementDueDay 
   FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
  JOIN #ComputedInvoiceDueDays CIDD ON CIDD.ReceivableInvoiceId = SIRD.ReceivableInvoiceId  
  JOIN #NextPossibleStatementGenerationDueDates NextPossibleStatementGenerationDueDates ON SIRD.ReceivableInvoiceId = NextPossibleStatementGenerationDueDates.ReceivableInvoiceId  
  WHERE SIRD.LastStatementGeneratedDueDate IS NULL AND SIRD.JobStepInstanceId=@JobStepInstanceId  
   
 UPDATE StatementInvoiceReceivableDetails_Extract  
 SET ComputedSIDueDate = CASE   
        WHEN IsCurrentInstance = 1 THEN InvoiceDueDate   
        WHEN SIRD.LastStatementGeneratedDueDate IS NULL THEN SIRD.InvoiceDueDate  
		WHEN IsCurrentInstance = 0 THEN DATEADD(DAY,CASE WHEN SIRD.EntityType = @ReceivableEntityType_CT THEN (SIRD.CT_InvoiceTransitDays) WHEN SIRD.EntityType = @ReceivableEntityType_CU THEN (SIRD.CU_InvoiceTransitDays) END,SICDD.CalculatedDueDate)
        ELSE SICDD.CalculatedDueDate  
       END,  
  IsOffPeriod =  CASE   
        WHEN IsCurrentInstance = 1 THEN 0   
        ELSE 1  
       END  
  FROM #ChunkBillToes ICDE
 JOIN StatementInvoiceReceivableDetails_Extract SIRD 
	ON SIRD.BillToId= ICDE.BillToId -- Remove SIRD.IsActive
 LEFT JOIN #StatementInvoiceCalculatedDueDate SICDD ON SICDD.ReceivableInvoiceId = SIRD.ReceivableInvoiceId   
 WHERE SIRD.JobStepInstanceId=@JobStepInstanceId  
  
 DROP TABLE #ReceivableInvoiceDueDay  
 DROP TABLE #ComputedInvoiceDueDays  
 DROP TABLE #NextPossibleStatementGenerationDueDates  
 DROP TABLE #StatementInvoiceCalculatedDueDate  
 DROP TABLE #DueDateCTETemp  
 DROP TABLE #NextPossibleGenerationStatementDueDateTemp  
 DROP TABLE #BasedOnDueDay  
  
END

GO

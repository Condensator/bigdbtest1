SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateEffectiveBalanceForWHTWaiver]  
(  
@WHTWaiverReceivableDetails WHTWaiverReceivableDetailsInfo READONLY ,  
@ReceiptId BIGINT  
)  
AS  
BEGIN  
  
    SELECT * INTO #WHTWaiverDetails FROM @WHTWaiverReceivableDetails  
    SELECT R.Id ReceivableId,SUm(AdjustedWHTAmount) AdjustedWHTAmount INTO #ReceivableWHTWaiverDetails 
    FROM @WHTWaiverReceivableDetails WHT
    JOIN ReceivableDetails RD ON WHT.ReceivableDetailId = Rd.Id
    JOIN receivables R ON RD.ReceivableId = R.Id
    GROUP BY R.Id
  
         UPDATE ReceivableDetailsWithholdingTaxDetails  
         SET Balance_Amount = Balance_Amount - WHT.AdjustedWHTAmount, EffectiveBalance_Amount = 0.00
         FROM ReceivableDetailsWithholdingTaxDetails RDWHT  
         JOIN #WHTWaiverDetails WHT ON RDWHT.ReceivableDetailId = WHT.ReceivableDetailId  
  
      UPDATE ReceivableWithholdingTaxDetails  
         SET Balance_Amount = Balance_Amount - WHT.AdjustedWHTAmount
         , EffectiveBalance_Amount = EffectiveBalance_Amount - WHT.AdjustedWHTAmount  
         FROM ReceivableWithholdingTaxDetails RWHT  
         JOIN #ReceivableWHTWaiverDetails WHT ON RWHT.ReceivableId = WHT.ReceivableId  
  
         UPDATE ReceiptApplicationReceivableDetails   
         SET AdjustedWithholdingTax_Amount = WHT.AdjustedWHTAmount  
         ,PreviousAdjustedWithHoldingTax_Amount = WHT.AdjustedWHTAmount  
         ,IsActive = 1  
         FROM ReceiptApplicationReceivableDetails RARD  
         JOIN #WHTWaiverDetails WHT ON RARD.ReceivableDetailId = WHT.ReceivableDetailId  
         JOIN ReceiptApplications RA ON RARD.ReceiptApplicationId = RA.Id  
         JOIN Receipts R ON RA.ReceiptId = R.Id AND R.Id = @ReceiptId  
           
    DROP TABLE #WHTWaiverDetails  
  
END  

GO

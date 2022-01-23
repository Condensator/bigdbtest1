SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEffectiveBalanceForWHTWaiverReversal]
(
@ReceiptId BIGINT 
)
AS
BEGIN  
  
DECLARE @ProcessingReceivableDetailIds TABLE (ReceivableDetailId BIGINT,AdjustedWHTAmount DECIMAL(16,2))  
DECLARE @ProcessingReceivableIds TABLE (ReceivableId BIGINT,AdjustedWHTAmount DECIMAL(16,2))  
  
    INSERT INTO @ProcessingReceivableDetailIds  
    SELECT   
        RARD.ReceivableDetailId  
        ,SUM(RARD.AdjustedWithholdingTax_Amount )AdjustedWHTAmount  
    FROM Receipts R  
    JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId  
    JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceiptApplicationId = RA.Id AND RARD.IsActive = 1  
    WHERE R.Id = @ReceiptId  
    GROUP BY RARD.ReceivableDetailId  
  
    INSERT INTO @ProcessingReceivableIds  
    SELECT   
        Rec.Id  
        ,SUM(RARD.AdjustedWithholdingTax_Amount )AdjustedWHTAmount  
    FROM Receipts R  
    JOIN ReceiptApplications RA ON R.Id = RA.ReceiptId  
    JOIN ReceiptApplicationReceivableDetails RARD ON RARD.ReceiptApplicationId = RA.Id AND RARD.IsActive = 1  
    JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id AND RD.IsActive = 1  
    JOIN Receivables Rec ON RD.ReceivableId = Rec.Id AND Rec.IsActive = 1  
    WHERE R.Id = @ReceiptId  
    GROUP BY Rec.Id  
  
    --select * from @ProcessingReceivableDetailIds  
       
    --UPDATE ReceivableDetailsWithholdingTaxDetails SET  
    --     Balance_Amount = Balance_Amount + WHT.AdjustedWHTAmount  
    --    ,EffectiveBalance_Amount = EffectiveBalance_Amount + WHT.AdjustedWHTAmount  
    --FROM ReceivableDetailsWithholdingTaxDetails RDWHT  
    --JOIN @ProcessingReceivableDetailIds WHT ON RDWHT.ReceivableDetailId = WHT.ReceivableDetailId  
  
    --UPDATE ReceivableWithholdingTaxDetails SET  
    --     Balance_Amount = RWHT.Balance_Amount + WHT.AdjustedWHTAmount  
    --    ,EffectiveBalance_Amount = RWHT.EffectiveBalance_Amount + WHT.AdjustedWHTAmount  
    --FROM ReceivableWithholdingTaxDetails RWHT  
    --JOIN @ProcessingReceivableIds WHT ON RWHT.ReceivableId = WHT.ReceivableId  
  
END  

GO

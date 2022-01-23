SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateBookBalanceAndReceiptForNonAccrual]
(
@NonAccrualNonDSLReceiptInfo NonAccrualNonDSLReceiptInfo READONLY,
@Currency NVARCHAR(6),
@CurrentTime DATETIMEOFFSET,
@CurrentUserId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
MERGE ReceiptApplicationReceivableDetails AS RARD
USING(SELECT ReceiptApplicationId,ReceivableDetailId,BookAmountApplied
FROM @NonAccrualNonDSLReceiptInfo)
AS Source
ON RARD.ReceiptApplicationId = Source.ReceiptApplicationId AND RARD.ReceivableDetailId = Source.ReceivableDetailId AND RARD.IsActive = 1
WHEN MATCHED THEN
UPDATE SET BookAmountApplied_Amount = BookAmountApplied_Amount + Source.BookAmountApplied,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
WHEN NOT MATCHED THEN
INSERT
(
	AmountApplied_Amount
	,AmountApplied_Currency
	,TaxApplied_Amount
	,TaxApplied_Currency
	,IsActive
	,CreatedById
	,CreatedTime
	,ReceivableDetailId
	,ReceiptApplicationId
	,PreviousAmountApplied_Amount
	,PreviousAmountApplied_Currency
	,IsReApplication
	,PreviousTaxApplied_Amount
	,PreviousTaxApplied_Currency
	,ReceiptApplicationInvoiceId
	,ReceivableInvoiceId
	,PayableId
	,IsGLPosted
	,IsTaxGLPosted
	,RecoveryAmount_Amount
	,RecoveryAmount_Currency
	,GainAmount_Amount
	,GainAmount_Currency
	,BookAmountApplied_Amount
	,BookAmountApplied_Currency
	,SundryPayableId
	,SundryReceivableId
	,PreviousBookAmountApplied_Amount
	,PreviousBookAmountApplied_Currency
	,ReceiptApplicationReceivableGroupId
	,PrepaidAmount_Amount
	,PrepaidAmount_Currency
	,PrepaidTaxAmount_Amount
	,PrepaidTaxAmount_Currency
	,AdjustedWithholdingTax_Amount
	,AdjustedWithholdingTax_Currency
	,ReceivedAmount_Amount
	,ReceivedAmount_Currency
	,PreviousAdjustedWithHoldingTax_Amount
	,PreviousAdjustedWithHoldingTax_Currency	
	,LeaseComponentAmountApplied_Amount
	,LeaseComponentAmountApplied_Currency
	,NonLeaseComponentAmountApplied_Amount
	,NonLeaseComponentAmountApplied_Currency
	,PrevLeaseComponentAmountApplied_Amount
	,PrevLeaseComponentAmountApplied_Currency
	,PrevNonLeaseComponentAmountApplied_Amount
	,PrevNonLeaseComponentAmountApplied_Currency
	,LeaseComponentPrepaidAmount_Amount
	,LeaseComponentPrepaidAmount_Currency
	,NonLeaseComponentPrepaidAmount_Amount
	,NonLeaseComponentPrepaidAmount_Currency
	,WithHoldingTaxBookAmountApplied_Amount
	,WithHoldingTaxBookAmountApplied_Currency
	,ReceivedTowardsInterest_Amount
	,ReceivedTowardsInterest_Currency
)
VALUES
(	  0.00,
@Currency,
0.00,
@Currency,
CAST(1 AS BIT),
@CurrentUserId,
@CurrentTime,
ReceivableDetailId,
ReceiptApplicationId,
0.00,
@Currency,
CAST(0 AS BIT),
0.00,
@Currency,
NULL,
NULL,
NULL,
CAST(0 AS BIT),
CAST(0 AS BIT),
0.0,
@Currency,
0.0,
@Currency,
BookAmountApplied,
@Currency,
NULL,
NULL,
BookAmountApplied,
@Currency,
NULL ,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency,
0.00,
@Currency
);
UPDATE ReceivableDetails
SET EffectiveBookBalance_Amount = EffectiveBookBalance_Amount - RDInfo.BookAmountApplied,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM ReceivableDetails
JOIN (SELECT ReceivableDetailId,SUM(BookAmountApplied) BookAmountApplied
FROM @NonAccrualNonDSLReceiptInfo GROUP BY ReceivableDetailId)
AS RDInfo ON ReceivableDetails.Id = RDInfo.ReceivableDetailId
DECLARE @ReceivableIds TABLE(ReceivableId BIGINT);
INSERT INTO @ReceivableIds
SELECT DISTINCT ReceivableId FROM @NonAccrualNonDSLReceiptInfo
UPDATE Receivables
SET TotalBookBalance_Amount = ReceivableInfo.TotalEffectiveBookBalance,
UpdatedById = @CurrentUserId,
UpdatedTime = @CurrentTime
FROM Receivables
JOIN (SELECT R.ReceivableId,SUM(EffectiveBookBalance_Amount) TotalEffectiveBookBalance
FROM @ReceivableIds R
JOIN ReceivableDetails RD ON R.ReceivableId = RD.ReceivableId
WHERE RD.IsActive=1
GROUP BY R.ReceivableId)
AS ReceivableInfo ON ReceivableInfo.ReceivableId = Receivables.Id
SET NOCOUNT OFF;
END

GO

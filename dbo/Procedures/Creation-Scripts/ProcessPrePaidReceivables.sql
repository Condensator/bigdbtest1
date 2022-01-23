SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ProcessPrePaidReceivables]
(
@ReceiptId BIGINT,
@IsReversal BIT,
@Currency NVARCHAR(3),
@PrepaidReceivableSummary PrepaidReceivableSummary READONLY,
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
DECLARE @DefaultAmount DECIMAL = 0.00;
IF( @IsReversal = 0 )
BEGIN
MERGE PrepaidReceivables AS PrepaidReceivable
USING (SELECT * FROM @PrepaidReceivableSummary) AS PrepaidReceivableSummary
ON PrepaidReceivable.Receivableid = PrepaidReceivableSummary.ReceivableId AND PrepaidReceivable.ReceiptId = @ReceiptId AND PrepaidReceivable.IsActive=1
WHEN MATCHED THEN
UPDATE SET PrepaidReceivable.PrePaidAmount_Amount = CASE WHEN PrepaidReceivableSummary.IsGLPosted = 1 THEN PrepaidReceivable.PrePaidAmount_Amount ELSE PrepaidReceivable.PrePaidAmount_Amount + PrepaidReceivableSummary.TotalReceivableAmountToPostGL END,
PrepaidReceivable.FinancingPrePaidAmount_Amount = CASE WHEN PrepaidReceivableSummary.IsGLPosted = 1 THEN PrepaidReceivable.FinancingPrePaidAmount_Amount ELSE PrepaidReceivable.FinancingPrePaidAmount_Amount + PrepaidReceivableSummary.TotalFinancingReceivableAmountToPostGL END,
PrepaidReceivable.PrePaidTaxAmount_Amount = CASE WHEN PrepaidReceivableSummary.IsTaxGLPosted = 1 THEN PrepaidReceivable.PrePaidTaxAmount_Amount ELSE PrepaidReceivable.PrePaidTaxAmount_Amount + PrepaidReceivableSummary.TotalTaxAmountToPostGL END,
PrepaidReceivable.UpdatedById = @CurrentUserId,
PrepaidReceivable.UpdatedTime = @CurrentTime
WHEN NOT MATCHED THEN
INSERT (ReceivableId,ReceiptId,IsActive,PrePaidAmount_Amount,PrePaidAmount_Currency, FinancingPrePaidAmount_Amount, FinancingPrePaidAmount_Currency, PrePaidTaxAmount_Amount,PrePaidTaxAmount_Currency,CreatedById,CreatedTime)
VALUES	(PrepaidReceivableSummary.ReceivableId
,@ReceiptId
,1
,CASE WHEN PrepaidReceivableSummary.IsGLPosted = 1 THEN @DefaultAmount ELSE PrepaidReceivableSummary.TotalReceivableAmountToPostGL END
,@Currency
,CASE WHEN PrepaidReceivableSummary.IsGLPosted = 1 THEN @DefaultAmount ELSE PrepaidReceivableSummary.TotalFinancingReceivableAmountToPostGL END
,@Currency
,CASE WHEN PrepaidReceivableSummary.IsTaxGLPosted = 1 THEN @DefaultAmount ELSE PrepaidReceivableSummary.TotalTaxAmountToPostGL END
,@Currency
,@CurrentUserId
,@CurrentTime);
END
ELSE
BEGIN
MERGE PrepaidReceivables AS PrepaidReceivable
USING (SELECT * FROM @PrepaidReceivableSummary) AS PrepaidReceivableSummary
ON PrepaidReceivable.Receivableid = PrepaidReceivableSummary.ReceivableId AND PrepaidReceivable.ReceiptId = @ReceiptId AND PrepaidReceivable.IsActive=1
WHEN MATCHED THEN
UPDATE SET PrepaidReceivable.IsActive = 0;
END
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateReceiptApplicationBookAmountApplied]
(
@ReceiptApplicationIds ReceiptApplicationIdCollection Readonly,
@ReceivableIncomeTypeValues_InterimInterest NVARCHAR(40),
@ReceivableIncomeTypeValues_TakeDownInterest NVARCHAR(40),
@ReceivableTypeValues_LoanInterest NVARCHAR(40),
@ReceivableTypeValues_LoanPrincipal NVARCHAR(40),
@UpdatedById BigInt,
@UpdatedTime DateTimeOffset
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ReceiptApplicationReceivableDetails
SET BookAmountApplied_Amount = RARD.AmountApplied_Amount,
WithHoldingTaxBookAmountApplied_Amount = RARD.AdjustedWithholdingTax_Amount,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM @ReceiptApplicationIds RA
INNER JOIN ReceiptApplicationReceivableDetails RARD ON RA.Id = RARD.ReceiptApplicationId AND RARD.IsActive = 1
INNER JOIN ReceivableDetails RD ON RARD.ReceivableDetailId = RD.Id AND RD.IsActive = 1
INNER JOIN Receivables R ON RD.ReceivableId = R.Id AND R.IsActive=1
INNER JOIN ReceivableCodes RC ON R.ReceivableCodeId = RC.Id
INNER JOIN ReceivableTypes RT ON RC.ReceivableTypeId = RT.Id AND RT.Name IN (@ReceivableTypeValues_LoanInterest,@ReceivableTypeValues_LoanPrincipal)
WHERE R.IncomeType != @ReceivableIncomeTypeValues_InterimInterest AND R.IncomeType != @ReceivableIncomeTypeValues_TakeDownInterest
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ExtractPassThroughReceivablesForReceipt]
(
	@JobStepInstanceId	BIGINT,
	@CreatedById BIGINT,
	@CreatedTime DATETIMEOFFSET,
	@SundryTypeValues_PassThrough NVARCHAR(30),
	@AccountingTreatmentValues_CashBased NVARCHAR(30),
	@AccountingTreatmentValues_Memo NVARCHAR(30),
	@PayableSourceTableValues_SundryRecurPaySch NVARCHAR(30),
	@PayableSourceTableValues_SundryPayable NVARCHAR(30),
	@ReceivableSourceTableValues_Sundry NVARCHAR(20),
	@ReceivableSourceTableValues_SundryRecurring NVARCHAR(20),
	@PayableStatusValues_Inactive NVARCHAR(17),
	@PayableCreationSourceTableValues_RARD NVARCHAR(5)
)
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

--Sundry Pass Through

INSERT INTO [dbo].[ReceiptPassThroughReceivables_Extract] ([CreatedById],[CreatedTime],[ReceivableId],[PassThroughPayableDueDate],
[TotalPayableAmount],[PaidPayableAmount],[VendorId],[PayableRemitToId],[PayableCodeId],[SourceId],[SourceTable],[PassThroughPercent],[JobStepInstanceId],[WithholdingTaxRate])
SELECT
	@CreatedById [CreatedById],
	@CreatedTime [CreatedTime],
	RARD.ReceivableId [ReceivableId],
	S.PayableDueDate [PassThroughPayableDueDate],
	S.PayableAmount_Amount [TotalPayableAmount],
	0 [PaidPayableAmount],
	S.VendorId [VendorId],
	S.PayableRemitToId [PayableRemitToId],
	S.PayableCodeId [PayableCodeId],
	S.Id [SourceId],
	@PayableSourceTableValues_SundryPayable [SourceTable],
	0 [PassThroughPercent],
	@JobStepInstanceId [JobStepInstanceId],
	MAX(S.PayableWithholdingTaxRate) WithholdingTaxRate
FROM 
(
	SELECT ReceivableId,SourceId FROM ReceiptReceivableDetails_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId AND SourceTable = @ReceivableSourceTableValues_Sundry
	AND AccountingTreatment IN(@AccountingTreatmentValues_CashBased,@AccountingTreatmentValues_Memo)
	GROUP BY ReceivableId,SourceId
) RARD
JOIN Sundries S ON RARD.SourceId = S.Id AND S.IsActive = 1
GROUP BY 
	RARD.ReceivableId,
	S.Id,
	S.PayableDueDate,
	S.PayableAmount_Amount,
	S.VendorId,
	S.PayableRemitToId,
	S.PayableCodeId

UPDATE ReceiptPassThroughReceivables_Extract
SET PaidPayableAmount = R.PaidPayableAmount
FROM ReceiptPassThroughReceivables_Extract RPR
JOIN (Select RPR.ReceivableId, SUM(ISNULL(P.Amount_Amount,0)) PaidPayableAmount
	  FROM ReceiptPassThroughReceivables_Extract RPR
	  JOIN ReceivableDetails RD ON RPR.ReceivableId = RD.ReceivableId AND RD.IsActive = 1
	  JOIN ReceiptApplicationReceivableDetails RARD ON  RD.Id = RARD.ReceivableDetailId AND RARD.IsActive = 1
	  JOIN Payables P ON RPR.SourceId = P.SourceId AND P.SourceTable = @PayableSourceTableValues_SundryPayable AND RARD.Id = P.CreationSourceId AND P.CreationSourceTable = @PayableCreationSourceTableValues_RARD AND P.Status <> @PayableStatusValues_Inactive
	  WHERE JobStepInstanceId = @JobStepInstanceId 
	  GROUP BY RPR.ReceivableId) R ON RPR.ReceivableId = R.ReceivableId AND JobStepInstanceId = @JobStepInstanceId

--Sundry Recurring Pass Through

INSERT INTO [dbo].[ReceiptPassThroughReceivables_Extract] ([CreatedById],[CreatedTime],[ReceivableId],[PassThroughPayableDueDate],
[TotalPayableAmount],[PaidPayableAmount],[VendorId],[PayableRemitToId],[PayableCodeId],[SourceId],[SourceTable],[PassThroughPercent],[JobStepInstanceId],[WithholdingTaxRate])
SELECT
	@CreatedById [CreatedById],
	@CreatedTime [CreatedTime],
	RARD.ReceivableId [ReceivableId],
	SR.FirstDueDate [PassThroughPayableDueDate],
	SRPS.PayableAmount_Amount [TotalPayableAmount],
	SUM(ISNULL(P.Amount_Amount,0)) [PaidPayableAmount],
	SR.VendorId [VendorId],
	SR.PayableRemitToId [PayableRemitToId],
	SR.PayableCodeId [PayableCodeId],
	SRPS.Id [SourceId],
	@PayableSourceTableValues_SundryRecurPaySch [SourceTable],
	0 [PassThroughPercent],
	@JobStepInstanceId [JobStepInstanceId],
	MAX(SR.PayableWithholdingTaxRate) WithholdingTaxRate
FROM 
(
	SELECT ReceivableId,SourceId FROM ReceiptReceivableDetails_Extract 
	WHERE JobStepInstanceId = @JobStepInstanceId AND SourceTable = @ReceivableSourceTableValues_SundryRecurring
	AND AccountingTreatment IN(@AccountingTreatmentValues_CashBased,@AccountingTreatmentValues_Memo)
	GROUP BY ReceivableId,SourceId
) RARD
JOIN SundryRecurringPaymentSchedules SRPS ON RARD.ReceivableId = SRPS.ReceivableId AND SRPS.IsActive = 1
JOIN SundryRecurrings SR ON SRPS.SundryRecurringId = SR.Id AND SR.SundryType = @SundryTypeValues_PassThrough AND SR.IsActive = 1
LEFT JOIN Payables P ON SRPS.Id = P.SourceId AND P.SourceTable = @PayableSourceTableValues_SundryRecurPaySch AND P.Status <> @PayableStatusValues_Inactive
GROUP BY 
	RARD.ReceivableId,
	SRPS.Id,
	SR.FirstDueDate,
	SRPS.PayableAmount_Amount,
	SR.VendorId,
	SR.PayableRemitToId,
	SR.PayableCodeId

END

GO

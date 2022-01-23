SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdatePassthroughPayables]
(
@PassthroughPayables PassthroughPayables READONLY,
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
DECLARE @output TABLE (DST_PayableId BIGINT,SRC_ReceiptApplicationReceivableDetailId BIGINT);
MERGE INTO Payables DST
USING @PassthroughPayables SRC
ON 1=0
WHEN NOT MATCHED THEN
INSERT (
EntityType,
EntityId,
Amount_Amount,
Amount_Currency,
Balance_Amount,
Balance_Currency,
TaxPortion_Amount,
TaxPortion_Currency,
DueDate,
Status,
SourceTable,
SourceId,
InternalComment,
IsGLPosted,
CurrencyId,
PayableCodeId,
LegalEntityId,
PayeeId,
RemitToId,
AdjustmentBasisPayableId,
CreationSourceTable,
CreatedById,
CreatedTime
)
VALUES(
EntityType,
EntityId,
Amount,
Currency,
Balance,
Currency,
TaxPortion,
Currency,
DueDate,
Status,
SourceTable,
SourceId,
InternalComment,
IsGLPosted,
CurrencyId,
PayableCodeId,
LegalEntityId,
PayeeId,
RemitToId,
AdjustmentBasisPayableId,
'_',
@UpdatedById,
@UpdatedTime)
OUTPUT INSERTED.ID,SRC.ReceiptApplicationReceivableDetailId INTO @output(DST_PayableId,SRC_ReceiptApplicationReceivableDetailId);
UPDATE ReceiptApplicationReceivableDetails
SET PayableId = [Output].DST_PayableId,
UpdatedById = @UpdatedById,
UpdatedTime = @UpdatedTime
FROM @output [Output]
JOIN ReceiptApplicationReceivableDetails RARD ON Output.SRC_ReceiptApplicationReceivableDetailId = RARD.Id
END

GO

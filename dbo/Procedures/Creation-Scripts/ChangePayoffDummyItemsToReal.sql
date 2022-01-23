SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ChangePayoffDummyItemsToReal]
(
@PayoffId BIGINT,
@PayoffReceivableSourceTable NVARCHAR(20),
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
(SELECT ReceivableId = R.Id INTO #DummyReceivableIds FROM Receivables R
JOIN Sundries S ON S.ReceivableId = R.Id
JOIN PayoffSundries PFS ON S.Id = PFS.SundryId AND PFS.PayoffId = @PayoffId
WHERE R.IsDummy = 1 AND R.IsActive = 1 AND
(PFS.Id IS NOT NULL AND PFS.IsActive = 1 AND S.IsActive = 1))
UNION
(SELECT ReceivableId = R.Id  FROM Receivables R
JOIN Payoffs PF ON R.SourceId = PF.Id AND R.SourceTable = @PayoffReceivableSourceTable AND PF.Id = @PayoffId
WHERE R.IsDummy = 1 AND R.IsActive = 1 AND
((PF.Id IS NOT NULL AND R.ReceivableCodeId IS NOT NULL AND R.ReceivableCodeId IN (PF.PayoffReceivableCodeId, PF.BuyoutReceivableCodeId, PF.PropertyTaxEscrowReceivableCodeId))))
UPDATE RT SET RT.IsDummy = CONVERT(BIT, 0),UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime FROM ReceivableTaxes RT
JOIN #DummyReceivableIds DR ON RT.ReceivableId = DR.ReceivableId;
UPDATE R SET R.IsDummy = CONVERT(BIT, 0),UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime FROM Receivables R
JOIN #DummyReceivableIds DR ON R.Id = DR.ReceivableId;
UPDATE RI SET RI.IsDummy = CONVERT(BIT,0),UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime FROM ReceivableInvoices RI
JOIN PayoffInvoices PF ON RI.Id = PF.InvoiceId AND PF.PayoffId = @PayoffId
DROP TABLE #DummyReceivableIds
END

GO

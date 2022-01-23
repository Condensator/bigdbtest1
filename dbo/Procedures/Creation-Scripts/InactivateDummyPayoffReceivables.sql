SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivateDummyPayoffReceivables]
(
@PayoffId BIGINT,
@PayoffReceivableSourceTable NVARCHAR(50),
@CurrentUserId BIGINT,
@CurrentTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
SELECT Id INTO #ReceivableIds FROM Receivables WHERE SourceId = @PayoffId AND SourceTable = @PayoffReceivableSourceTable AND IsDummy = 1 and IsActive = 1
UPDATE ReceivableTaxDetails SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM ReceivableTaxDetails
JOIN ReceivableTaxes ON ReceivableTaxDetails.ReceivableTaxId = ReceivableTaxes.Id
JOIN #ReceivableIds ON ReceivableTaxes.ReceivableId = #ReceivableIds.Id
UPDATE ReceivableTaxes SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM ReceivableTaxes
JOIN #ReceivableIds ON ReceivableTaxes.ReceivableId = #ReceivableIds.Id
UPDATE ReceivableDetailsWithholdingTaxDetails SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM ReceivableDetailsWithholdingTaxDetails
JOIN ReceivableWithholdingTaxDetails ON ReceivableDetailsWithholdingTaxDetails.ReceivableWithholdingTaxDetailId = ReceivableWithholdingTaxDetails.Id
JOIN #ReceivableIds ON ReceivableWithholdingTaxDetails.ReceivableId = #ReceivableIds.Id
UPDATE ReceivableWithholdingTaxDetails SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM ReceivableWithholdingTaxDetails
JOIN #ReceivableIds ON ReceivableWithholdingTaxDetails.ReceivableId = #ReceivableIds.Id
UPDATE ReceivableDetails SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM ReceivableDetails
JOIN #ReceivableIds ON ReceivableDetails.ReceivableId = #ReceivableIds.Id
UPDATE Receivables SET IsActive = 0,UpdatedById = @CurrentUserId,UpdatedTime = @CurrentTime
FROM Receivables
JOIN #ReceivableIds ON Receivables.Id = #ReceivableIds.Id
SET NOCOUNT OFF
END

GO

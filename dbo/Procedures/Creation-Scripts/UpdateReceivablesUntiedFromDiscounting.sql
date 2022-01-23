SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceivablesUntiedFromDiscounting]
(
@PaymentScheduleId NVARCHAR(MAX),
@UpdatedById BIGINT,
@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE Rec
SET
Rec.IsCollected = 1,
Rec.RemitToId = C.RemitToId,
Rec.[UpdatedById] = @UpdatedById,
Rec.[UpdatedTime] = @UpdatedTime
FROM Receivables Rec
JOIN Contracts C ON C.Id = Rec.EntityId
JOIN ConvertCSVToBigIntTable(@PaymentScheduleId,',') csv ON Rec.PaymentScheduleId = csv.Id
WHERE Rec.IsActive = 1
SET NOCOUNT OFF;
END

GO

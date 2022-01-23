SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdateReceivableGL]
(
@ReceivableParam ReceivableParam READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Receivables SET IsGLPosted = 1, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Receivables
JOIN @ReceivableParam ReceivableParam ON Receivables.Id = ReceivableParam.Id
SET NOCOUNT OFF;
END

GO

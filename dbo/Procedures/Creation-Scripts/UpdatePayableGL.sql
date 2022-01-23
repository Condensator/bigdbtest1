SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[UpdatePayableGL]
(
@PayableParam PayableParam READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Payables SET IsGLPosted = 1, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM Payables
JOIN @PayableParam PayableParam ON Payables.Id = PayableParam.Id
SET NOCOUNT OFF;
END

GO

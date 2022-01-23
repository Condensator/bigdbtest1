SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[InactivatePendingACHSchedules]
(
@ACHReceivableParam ACHReceivableParam READONLY
,@UpdatedById BIGINT
,@UpdatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE ACHSchedules SET IsActive = 0, UpdatedById = @UpdatedById, UpdatedTime = @UpdatedTime
FROM ACHSchedules
JOIN @ACHReceivableParam RecParam ON ACHSchedules.ReceivableId = RecParam.ReceivableId
WHERE ACHSchedules.Status = 'Pending'
SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateIsFailedForFailedLeaseId]
( 
	  @LeaseId BIGINT
)
AS
BEGIN
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
EXEC sp_getapplock @Resource='stgLease', @LockMode='Exclusive';
UPDATE stgLease SET IsFailed = 1, UpdatedById = 1, UpdatedTime= SYSDATETIMEOFFSET()
WHERE IsMigrated = 0 AND R_LeaseFinanceId = @LeaseId
END

GO

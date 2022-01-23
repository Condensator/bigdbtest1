SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE   PROCEDURE [dbo].[SmallLeaseSelectForCommencement]
(	
	@UserId BIGINT,
	@ModuleIterationStatusId BIGINT,
	@CreatedTime DATETIMEOFFSET = NULL,
	@ProcessedRecords BIGINT OUT,
	@FailedRecords BIGINT OUT,
	@ToolIdentifier INT
)
AS
BEGIN
SET NOCOUNT ON

	
BEGIN TRANSACTION
	
update stglease set IsMigrated=0 where SequenceNumber not in (SELECT sequencenumber
FROM stglease l
INNER JOIN stgleasefinancedetail lfd
ON lfd.id = l.id
INNER JOIN stgleaseasset la
ON la.leaseid = l.id
where l.ToolIdentifier is null or l.ToolIdentifier=@ToolIdentifier
GROUP BY  SequenceNumber ,NumberOfPayments
having COUNT(*)  >1000)
and (ToolIdentifier is null or ToolIdentifier=@ToolIdentifier)

	COMMIT TRANSACTION
	
	set @FailedRecords=0;
	set @ProcessedRecords=1;
	SET NOCOUNT OFF;
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[InactivateUser]
(
@LoginName NVARCHAR(20),
@DeactivationDate DATETIMEOFFSET,
@ApprovalStatus NVARCHAR(16),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON;
UPDATE Users SET ApprovalStatus=@ApprovalStatus,DeactivationDate=@DeactivationDate,UpdatedById = @CreatedById,UpdatedTime = @CreatedTime
where Users.LoginName=@LoginName AND ApprovalStatus = 'Approved'
END

GO

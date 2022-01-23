SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetJobIdForGLTransfer]
(
@Alias NVARCHAR,
@UserId BIGINT
)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT TOP 1 Id FROM Jobs WHERE Name = @Alias AND CreatedById = @UserId
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END

GO

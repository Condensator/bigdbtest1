SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[CreateLegalStatusHistories]
(
@CustomerId BIGINT ,
@LegalStatusID BIGINT,
@SourceModule NVARCHAR(20),
@CreatedById BIGINT,
@CreatedTime DATETIMEOFFSET
)
AS
BEGIN
SET NOCOUNT ON
UPDATE LegalStatusHistories SET IsActive = 0 WHERE CustomerID = @CustomerId
UPDATE Customers SET LegalStatusId = @LegalStatusID WHERE Id = @CustomerId
INSERT INTO [dbo].[LegalStatusHistories]
([AssignmentDate]
,[IsActive]
,[CreatedById]
,[CreatedTime]
,[LegalStatusId]
,[CustomerId]
,[SourceModule])
VALUES
(GETDATE()
,1
,@CreatedById
,@CreatedTime
,@LegalStatusID
,@CustomerId
,@SourceModule)
END

GO

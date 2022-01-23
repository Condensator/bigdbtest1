SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[GetNextFromSequenceGenerators]
(
@Module NVARCHAR(MAX),
@NextNumber BIGINT OUTPUT,
@CreatedTime DATETIMEOFFSET = NULL
)
AS
BEGIN
SET NOCOUNT ON
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
UPDATE SequenceGenerators
SET @NextNumber = Next=Next+1,
UpdatedTime = @CreatedTime
WHERE
Module = @Module
END

GO

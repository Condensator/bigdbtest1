SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[VP_SetNextInSequenceGenerators]
(
@Module NVARCHAR(MAX),
@NextNumber BIGINT,
@CreatedTime DATETIMEOFFSET = NULL
)
AS
BEGIN
IF(@CreatedTime IS NULL)
SET @CreatedTime = SYSDATETIMEOFFSET();
UPDATE SequenceGenerators
SET Next=@NextNumber,
UpdatedTime = @CreatedTime
WHERE
Module = @Module
END

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	
CREATE PROCEDURE [dbo].[UpdateResourceEntries]
(
	@ResourceEntries ResourceEntryCollection READONLY,
	@CurrentUserId BIGINT
)
AS 
SET NOCOUNT ON;
BEGIN

MERGE [dbo].[EntityResources] AS T
USING (SELECT * FROM @ResourceEntries) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET Value = S.Value,[UpdatedById]= @CurrentUserId,[UpdatedTime]= GETDATE()
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[EntityType],[EntityId],[Culture],[Name],[Value])
    VALUES (@CurrentUserId,GETDATE(),S.[EntityType],S.[EntityId],S.[Culture],S.[Name],S.[Value]);

END

GO

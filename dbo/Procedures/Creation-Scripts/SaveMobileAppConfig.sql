SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveMobileAppConfig]
(
 @val [dbo].[MobileAppConfig] READONLY
)
AS
SET NOCOUNT ON;
DECLARE @Output TABLE(
 [Action] NVARCHAR(10) NOT NULL,
 [Id] bigint NOT NULL,
 [Token] int NOT NULL,
 [RowVersion] BIGINT,
 [OldRowVersion] BIGINT
)
MERGE [dbo].[MobileAppConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AppId]=S.[AppId],[IsActive]=S.[IsActive],[Name]=S.[Name],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserMenu]=S.[UserMenu]
WHEN NOT MATCHED THEN
	INSERT ([AppId],[CreatedById],[CreatedTime],[IsActive],[Name],[UserMenu])
    VALUES (S.[AppId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Name],S.[UserMenu])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

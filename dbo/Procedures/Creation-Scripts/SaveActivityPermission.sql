SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityPermission]
(
 @val [dbo].[ActivityPermission] READONLY
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
MERGE [dbo].[ActivityPermissions] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ActivityTypePermissionId]=S.[ActivityTypePermissionId],[IsActive]=S.[IsActive],[Permission]=S.[Permission],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([ActivityId],[ActivityTypePermissionId],[CreatedById],[CreatedTime],[IsActive],[Permission],[UserId])
    VALUES (S.[ActivityId],S.[ActivityTypePermissionId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Permission],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

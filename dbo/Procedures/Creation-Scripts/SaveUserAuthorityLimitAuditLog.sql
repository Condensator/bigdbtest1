SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUserAuthorityLimitAuditLog]
(
 @val [dbo].[UserAuthorityLimitAuditLog] READONLY
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
MERGE [dbo].[UserAuthorityLimitAuditLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AuditOperation]=S.[AuditOperation],[AuditSourceId]=S.[AuditSourceId],[AuthorityId]=S.[AuthorityId],[Description]=S.[Description],[IsActive]=S.[IsActive],[Limit_Amount]=S.[Limit_Amount],[Limit_Currency]=S.[Limit_Currency],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([AuditOperation],[AuditSourceId],[AuthorityId],[CreatedById],[CreatedTime],[Description],[IsActive],[Limit_Amount],[Limit_Currency],[UserId])
    VALUES (S.[AuditOperation],S.[AuditSourceId],S.[AuthorityId],S.[CreatedById],S.[CreatedTime],S.[Description],S.[IsActive],S.[Limit_Amount],S.[Limit_Currency],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

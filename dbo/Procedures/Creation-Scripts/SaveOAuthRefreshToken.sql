SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveOAuthRefreshToken]
(
 @val [dbo].[OAuthRefreshToken] READONLY
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
MERGE [dbo].[OAuthRefreshTokens] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ExpiresUtc]=S.[ExpiresUtc],[IsActive]=S.[IsActive],[IssuedUtc]=S.[IssuedUtc],[OAuthClientId]=S.[OAuthClientId],[ProtectedTicket]=S.[ProtectedTicket],[RefreshTokenKey]=S.[RefreshTokenKey],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ExpiresUtc],[IsActive],[IssuedUtc],[OAuthClientId],[ProtectedTicket],[RefreshTokenKey])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ExpiresUtc],S.[IsActive],S.[IssuedUtc],S.[OAuthClientId],S.[ProtectedTicket],S.[RefreshTokenKey])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

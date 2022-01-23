SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveUserLoginAudit]
(
 @val [dbo].[UserLoginAudit] READONLY
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
MERGE [dbo].[UserLoginAudits] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ClientIPAddress]=S.[ClientIPAddress],[IsLoginSuccessful]=S.[IsLoginSuccessful],[IsWindowsAuthenticated]=S.[IsWindowsAuthenticated],[LoginName]=S.[LoginName],[LogoutTime]=S.[LogoutTime],[Site]=S.[Site],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserAgent]=S.[UserAgent],[UserId]=S.[UserId]
WHEN NOT MATCHED THEN
	INSERT ([ClientIPAddress],[CreatedById],[CreatedTime],[IsLoginSuccessful],[IsWindowsAuthenticated],[LoginName],[LogoutTime],[Site],[UserAgent],[UserId])
    VALUES (S.[ClientIPAddress],S.[CreatedById],S.[CreatedTime],S.[IsLoginSuccessful],S.[IsWindowsAuthenticated],S.[LoginName],S.[LogoutTime],S.[Site],S.[UserAgent],S.[UserId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

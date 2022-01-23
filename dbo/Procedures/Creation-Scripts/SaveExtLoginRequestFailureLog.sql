SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveExtLoginRequestFailureLog]
(
 @val [dbo].[ExtLoginRequestFailureLog] READONLY
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
MERGE [dbo].[ExtLoginRequestFailureLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ErrorMessage]=S.[ErrorMessage],[HeaderKey]=S.[HeaderKey],[LoginRequest]=S.[LoginRequest],[LoginStatus]=S.[LoginStatus],[PortalName]=S.[PortalName],[Request]=S.[Request],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserName]=S.[UserName]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[ErrorMessage],[HeaderKey],[LoginRequest],[LoginStatus],[PortalName],[Request],[UserName])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[ErrorMessage],S.[HeaderKey],S.[LoginRequest],S.[LoginStatus],S.[PortalName],S.[Request],S.[UserName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

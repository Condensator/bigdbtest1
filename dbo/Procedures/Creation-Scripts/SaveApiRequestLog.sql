SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveApiRequestLog]
(
 @val [dbo].[ApiRequestLog] READONLY
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
MERGE [dbo].[ApiRequestLogs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ApplicationName]=S.[ApplicationName],[CorrelationId]=S.[CorrelationId],[ElapsedMilliseconds]=S.[ElapsedMilliseconds],[HostName]=S.[HostName],[HttpRequestClientHostIP]=S.[HttpRequestClientHostIP],[LoginAuditId]=S.[LoginAuditId],[Method]=S.[Method],[RawUrl]=S.[RawUrl],[RequestContent]=S.[RequestContent],[ResponseContent]=S.[ResponseContent],[StatusCode]=S.[StatusCode],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[UserName]=S.[UserName]
WHEN NOT MATCHED THEN
	INSERT ([ApplicationName],[CorrelationId],[CreatedById],[CreatedTime],[ElapsedMilliseconds],[HostName],[HttpRequestClientHostIP],[LoginAuditId],[Method],[RawUrl],[RequestContent],[ResponseContent],[StatusCode],[UserName])
    VALUES (S.[ApplicationName],S.[CorrelationId],S.[CreatedById],S.[CreatedTime],S.[ElapsedMilliseconds],S.[HostName],S.[HttpRequestClientHostIP],S.[LoginAuditId],S.[Method],S.[RawUrl],S.[RequestContent],S.[ResponseContent],S.[StatusCode],S.[UserName])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

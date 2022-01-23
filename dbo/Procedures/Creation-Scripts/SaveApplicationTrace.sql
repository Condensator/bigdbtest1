SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveApplicationTrace]
(
 @val [dbo].[ApplicationTrace] READONLY
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
MERGE [dbo].[ApplicationTraces] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [CorrelationId]=S.[CorrelationId],[Source]=S.[Source],[TraceFile_Content]=S.[TraceFile_Content],[TraceFile_Source]=S.[TraceFile_Source],[TraceFile_Type]=S.[TraceFile_Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CorrelationId],[CreatedById],[CreatedTime],[Source],[TraceFile_Content],[TraceFile_Source],[TraceFile_Type])
    VALUES (S.[CorrelationId],S.[CreatedById],S.[CreatedTime],S.[Source],S.[TraceFile_Content],S.[TraceFile_Source],S.[TraceFile_Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

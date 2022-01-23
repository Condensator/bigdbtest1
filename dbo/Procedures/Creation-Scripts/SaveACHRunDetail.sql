SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHRunDetail]
(
 @val [dbo].[ACHRunDetail] READONLY
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
MERGE [dbo].[ACHRunDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHRunFileId]=S.[ACHRunFileId],[EntityId]=S.[EntityId],[IsPending]=S.[IsPending],[IsReversed]=S.[IsReversed],[TraceNumber]=S.[TraceNumber],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHRunFileId],[ACHRunId],[CreatedById],[CreatedTime],[EntityId],[IsPending],[IsReversed],[TraceNumber])
    VALUES (S.[ACHRunFileId],S.[ACHRunId],S.[CreatedById],S.[CreatedTime],S.[EntityId],S.[IsPending],S.[IsReversed],S.[TraceNumber])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

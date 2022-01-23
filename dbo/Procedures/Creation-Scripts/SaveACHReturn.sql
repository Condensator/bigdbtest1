SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveACHReturn]
(
 @val [dbo].[ACHReturn] READONLY
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
MERGE [dbo].[ACHReturns] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ACHReturnFile_Content]=S.[ACHReturnFile_Content],[ACHReturnFile_Source]=S.[ACHReturnFile_Source],[ACHReturnFile_Type]=S.[ACHReturnFile_Type],[ACHRunId]=S.[ACHRunId],[FileLocation]=S.[FileLocation],[JobStepInstanceId]=S.[JobStepInstanceId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ACHReturnFile_Content],[ACHReturnFile_Source],[ACHReturnFile_Type],[ACHRunId],[CreatedById],[CreatedTime],[FileLocation],[JobStepInstanceId])
    VALUES (S.[ACHReturnFile_Content],S.[ACHReturnFile_Source],S.[ACHReturnFile_Type],S.[ACHRunId],S.[CreatedById],S.[CreatedTime],S.[FileLocation],S.[JobStepInstanceId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveActivityStatusForType]
(
 @val [dbo].[ActivityStatusForType] READONLY
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
MERGE [dbo].[ActivityStatusForTypes] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[IsDefault]=S.[IsDefault],[Sequence]=S.[Sequence],[StatusId]=S.[StatusId],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WhoCanChangeId]=S.[WhoCanChangeId],[WhomToNotifyId]=S.[WhomToNotifyId]
WHEN NOT MATCHED THEN
	INSERT ([ActivityTypeId],[CreatedById],[CreatedTime],[IsActive],[IsDefault],[Sequence],[StatusId],[WhoCanChangeId],[WhomToNotifyId])
    VALUES (S.[ActivityTypeId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[IsDefault],S.[Sequence],S.[StatusId],S.[WhoCanChangeId],S.[WhomToNotifyId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

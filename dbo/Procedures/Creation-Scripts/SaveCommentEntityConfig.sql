SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCommentEntityConfig]
(
 @val [dbo].[CommentEntityConfig] READONLY
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
MERGE [dbo].[CommentEntityConfigs] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DefaultCommentTypeId]=S.[DefaultCommentTypeId],[GridName]=S.[GridName],[IsActive]=S.[IsActive],[IsAlertCommentEnabled]=S.[IsAlertCommentEnabled],[QuerySource]=S.[QuerySource],[TextProperty]=S.[TextProperty],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DefaultCommentTypeId],[GridName],[Id],[IsActive],[IsAlertCommentEnabled],[QuerySource],[TextProperty])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DefaultCommentTypeId],S.[GridName],S.[Id],S.[IsActive],S.[IsAlertCommentEnabled],S.[QuerySource],S.[TextProperty])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

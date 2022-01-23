SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveBlueBookValue]
(
 @val [dbo].[BlueBookValue] READONLY
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
MERGE [dbo].[BlueBookValues] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsActive]=S.[IsActive],[Quarter]=S.[Quarter],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[Value_Amount]=S.[Value_Amount],[Value_Currency]=S.[Value_Currency],[Year]=S.[Year]
WHEN NOT MATCHED THEN
	INSERT ([BlueBookId],[CreatedById],[CreatedTime],[IsActive],[Quarter],[Value_Amount],[Value_Currency],[Year])
    VALUES (S.[BlueBookId],S.[CreatedById],S.[CreatedTime],S.[IsActive],S.[Quarter],S.[Value_Amount],S.[Value_Currency],S.[Year])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

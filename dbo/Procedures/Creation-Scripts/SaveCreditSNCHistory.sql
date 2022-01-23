SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveCreditSNCHistory]
(
 @val [dbo].[CreditSNCHistory] READONLY
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
MERGE [dbo].[CreditSNCHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [IsSNCCode]=S.[IsSNCCode],[SNCAgent]=S.[SNCAgent],[SNCRating]=S.[SNCRating],[SNCRatingDate]=S.[SNCRatingDate],[SNCRole]=S.[SNCRole],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[CreditProfileId],[IsSNCCode],[SNCAgent],[SNCRating],[SNCRatingDate],[SNCRole])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[CreditProfileId],S.[IsSNCCode],S.[SNCAgent],S.[SNCRating],S.[SNCRatingDate],S.[SNCRole])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

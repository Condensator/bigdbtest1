SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveStaticHistoryAssetValueHistory]
(
 @val [dbo].[StaticHistoryAssetValueHistory] READONLY
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
MERGE [dbo].[StaticHistoryAssetValueHistories] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AsOfDate]=S.[AsOfDate],[ChangeInAmount_Amount]=S.[ChangeInAmount_Amount],[ChangeInAmount_Currency]=S.[ChangeInAmount_Currency],[NetValue_Amount]=S.[NetValue_Amount],[NetValue_Currency]=S.[NetValue_Currency],[OriginalCost_Amount]=S.[OriginalCost_Amount],[OriginalCost_Currency]=S.[OriginalCost_Currency],[Transaction]=S.[Transaction],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AsOfDate],[ChangeInAmount_Amount],[ChangeInAmount_Currency],[CreatedById],[CreatedTime],[NetValue_Amount],[NetValue_Currency],[OriginalCost_Amount],[OriginalCost_Currency],[StaticHistoryAssetId],[Transaction])
    VALUES (S.[AsOfDate],S.[ChangeInAmount_Amount],S.[ChangeInAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[NetValue_Amount],S.[NetValue_Currency],S.[OriginalCost_Amount],S.[OriginalCost_Currency],S.[StaticHistoryAssetId],S.[Transaction])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveDeferredTaxClearance]
(
 @val [dbo].[DeferredTaxClearance] READONLY
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
MERGE [dbo].[DeferredTaxClearances] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [ClearedAmount_Amount]=S.[ClearedAmount_Amount],[ClearedAmount_Currency]=S.[ClearedAmount_Currency],[ClearedDate]=S.[ClearedDate],[GLTemplateId]=S.[GLTemplateId],[JournalId]=S.[JournalId],[SourceId]=S.[SourceId],[SourceTable]=S.[SourceTable],[Type]=S.[Type],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([ClearedAmount_Amount],[ClearedAmount_Currency],[ClearedDate],[CreatedById],[CreatedTime],[DeferredTaxId],[GLTemplateId],[JournalId],[SourceId],[SourceTable],[Type])
    VALUES (S.[ClearedAmount_Amount],S.[ClearedAmount_Currency],S.[ClearedDate],S.[CreatedById],S.[CreatedTime],S.[DeferredTaxId],S.[GLTemplateId],S.[JournalId],S.[SourceId],S.[SourceTable],S.[Type])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

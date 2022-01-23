SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceiptApplication]
(
 @val [dbo].[ReceiptApplication] READONLY
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
MERGE [dbo].[ReceiptApplications] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [AmountApplied_Amount]=S.[AmountApplied_Amount],[AmountApplied_Currency]=S.[AmountApplied_Currency],[ApplyByReceivable]=S.[ApplyByReceivable],[Comment]=S.[Comment],[CreditApplied_Amount]=S.[CreditApplied_Amount],[CreditApplied_Currency]=S.[CreditApplied_Currency],[IsFullCash]=S.[IsFullCash],[PostDate]=S.[PostDate],[ReceiptHierarchyTemplateId]=S.[ReceiptHierarchyTemplateId],[ReceiptId]=S.[ReceiptId],[ReceivableDisplayOption]=S.[ReceivableDisplayOption],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([AmountApplied_Amount],[AmountApplied_Currency],[ApplyByReceivable],[Comment],[CreatedById],[CreatedTime],[CreditApplied_Amount],[CreditApplied_Currency],[IsFullCash],[PostDate],[ReceiptHierarchyTemplateId],[ReceiptId],[ReceivableDisplayOption])
    VALUES (S.[AmountApplied_Amount],S.[AmountApplied_Currency],S.[ApplyByReceivable],S.[Comment],S.[CreatedById],S.[CreatedTime],S.[CreditApplied_Amount],S.[CreditApplied_Currency],S.[IsFullCash],S.[PostDate],S.[ReceiptHierarchyTemplateId],S.[ReceiptId],S.[ReceivableDisplayOption])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

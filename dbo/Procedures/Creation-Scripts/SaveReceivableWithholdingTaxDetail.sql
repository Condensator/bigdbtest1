SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveReceivableWithholdingTaxDetail]
(
 @val [dbo].[ReceivableWithholdingTaxDetail] READONLY
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
MERGE [dbo].[ReceivableWithholdingTaxDetails] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [Balance_Amount]=S.[Balance_Amount],[Balance_Currency]=S.[Balance_Currency],[BasisAmount_Amount]=S.[BasisAmount_Amount],[BasisAmount_Currency]=S.[BasisAmount_Currency],[EffectiveBalance_Amount]=S.[EffectiveBalance_Amount],[EffectiveBalance_Currency]=S.[EffectiveBalance_Currency],[IsActive]=S.[IsActive],[ReceivableId]=S.[ReceivableId],[Tax_Amount]=S.[Tax_Amount],[Tax_Currency]=S.[Tax_Currency],[TaxRate]=S.[TaxRate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime],[WithholdingTaxCodeDetailId]=S.[WithholdingTaxCodeDetailId]
WHEN NOT MATCHED THEN
	INSERT ([Balance_Amount],[Balance_Currency],[BasisAmount_Amount],[BasisAmount_Currency],[CreatedById],[CreatedTime],[EffectiveBalance_Amount],[EffectiveBalance_Currency],[IsActive],[ReceivableId],[Tax_Amount],[Tax_Currency],[TaxRate],[WithholdingTaxCodeDetailId])
    VALUES (S.[Balance_Amount],S.[Balance_Currency],S.[BasisAmount_Amount],S.[BasisAmount_Currency],S.[CreatedById],S.[CreatedTime],S.[EffectiveBalance_Amount],S.[EffectiveBalance_Currency],S.[IsActive],S.[ReceivableId],S.[Tax_Amount],S.[Tax_Currency],S.[TaxRate],S.[WithholdingTaxCodeDetailId])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO

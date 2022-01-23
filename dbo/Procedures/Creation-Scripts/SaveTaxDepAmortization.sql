SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[SaveTaxDepAmortization]
(
 @val [dbo].[TaxDepAmortization] READONLY
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
MERGE [dbo].[TaxDepAmortizations] With (ForceSeek) AS T
USING (SELECT * FROM @val) AS S
		ON ( T.Id = S.Id)
WHEN MATCHED THEN
	UPDATE SET [DepreciationBeginDate]=S.[DepreciationBeginDate],[FXTaxBasisAmount_Amount]=S.[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency]=S.[FXTaxBasisAmount_Currency],[IsActive]=S.[IsActive],[IsConditionalSale]=S.[IsConditionalSale],[IsStraightLineMethodUsed]=S.[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated]=S.[IsTaxDepreciationTerminated],[TaxBasisAmount_Amount]=S.[TaxBasisAmount_Amount],[TaxBasisAmount_Currency]=S.[TaxBasisAmount_Currency],[TaxDepreciationTemplateId]=S.[TaxDepreciationTemplateId],[TerminationDate]=S.[TerminationDate],[UpdatedById]=S.[UpdatedById],[UpdatedTime]=S.[UpdatedTime]
WHEN NOT MATCHED THEN
	INSERT ([CreatedById],[CreatedTime],[DepreciationBeginDate],[FXTaxBasisAmount_Amount],[FXTaxBasisAmount_Currency],[IsActive],[IsConditionalSale],[IsStraightLineMethodUsed],[IsTaxDepreciationTerminated],[TaxBasisAmount_Amount],[TaxBasisAmount_Currency],[TaxDepEntityId],[TaxDepreciationTemplateId],[TerminationDate])
    VALUES (S.[CreatedById],S.[CreatedTime],S.[DepreciationBeginDate],S.[FXTaxBasisAmount_Amount],S.[FXTaxBasisAmount_Currency],S.[IsActive],S.[IsConditionalSale],S.[IsStraightLineMethodUsed],S.[IsTaxDepreciationTerminated],S.[TaxBasisAmount_Amount],S.[TaxBasisAmount_Currency],S.[TaxDepEntityId],S.[TaxDepreciationTemplateId],S.[TerminationDate])

OUTPUT $action, Inserted.Id, S.Token, Inserted.[RowVersion], Deleted.[RowVersion]
INTO @Output;

SELECT o.Id, o.Token, o.[RowVersion], CASE WHEN s.[RowVersion] <> o.[OldRowVersion] THEN 1 ELSE 0 END as ErrorCode FROM @Output o join @val s on o.Token = s.Token AND [Action] = 'UPDATE'
UNION ALL
SELECT Id, Token, [RowVersion], 0 as ErrorCode FROM @Output WHERE [Action] = 'INSERT';

GO
